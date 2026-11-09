import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/app_database.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/db_change_events.dart';
import 'package:bluebubbles/database/sqlite/objectbox_sqlite_copy.dart';
import 'package:bluebubbles/database/sqlite/sqlite_copy_check.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/env.dart';
import 'package:bluebubbles/services/backend/java_dart_interop/method_channel_handlers.dart';
import 'package:bluebubbles/services/backend/sync/sync_marker.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

/// Where the messaging store stands on disk at startup (SQLITE-PLAN-2 section 6).
enum StorageState {
  /// No usable SQLite file: a full copy starts.
  noFile,

  /// `bluebubbles.db.partial` from an earlier, unfinished copy: it resumes.
  partial,

  /// `bluebubbles.db`, copied and verified.
  ready,

  /// The copy gave up (or the file can't be read): the app stays on ObjectBox.
  failed,
}

enum CopyStep { copy, none }

typedef StoragePlan = ({ActiveStore store, CopyStep step, bool waitForCopy});

/// The store the app runs on and the copy work for [state] (S2 switch plan,
/// commit 9): SQLite once a current copy is ready; until then startup waits for
/// the copy. A copy that gave up leaves the app on ObjectBox.
StoragePlan decideStorage(StorageState state) => switch (state) {
      StorageState.noFile || StorageState.partial => (store: ActiveStore.sqlite, step: CopyStep.copy, waitForCopy: true),
      StorageState.ready => (store: ActiveStore.sqlite, step: CopyStep.none, waitForCopy: false),
      StorageState.failed => (store: ActiveStore.objectBox, step: CopyStep.none, waitForCopy: false),
    };

/// Platforms without the SQLite switch (desktop, host tests) stay on ObjectBox.
StoragePlan objectBoxOnly(StorageState state) => (store: ActiveStore.objectBox, step: CopyStep.none, waitForCopy: false);

/// Whether no state makes startup wait for the copy (then nothing reads the files to find out).
bool storageNeverWaits({StoragePlan Function(StorageState) decide = decideStorage}) =>
    StorageState.values.every((s) => !decide(s).waitForCopy);

/// Whether the headless DartWorker may handle a push in [state]; otherwise it asks Android to retry.
bool workerMayProceed(StorageState state, {StoragePlan Function(StorageState) decide = decideStorage}) =>
    !decide(state).waitForCopy;

/// Worker isolates: returns once the plan no longer says wait, polling [read] every [poll].
Future<void> waitForStorage({
  required Future<StorageState> Function() read,
  StoragePlan Function(StorageState) decide = decideStorage,
  Duration poll = const Duration(seconds: 1),
}) async {
  if (storageNeverWaits(decide: decide)) return;
  while (decide(await read()).waitForCopy) {
    await Future<void>.delayed(poll);
  }
}

({Db db, StreamSubscription<DbChanges> changes})? _selected;

/// The store this isolate runs on, per the startup plan for the files' state.
/// SQLite: this isolate's own connection to `bluebubbles.db`, whose committed
/// writes reach the main isolate's [DbChangeEvents] (directly on main, as
/// `dbChanged` events from a spawned isolate). When no state selects SQLite the
/// files are not read.
Future<MessagingStore> openSelectedStore({
  required Future<StorageState> Function() read,
  required bool onMain,
  required StorageFiles files,
  StoragePlan Function(StorageState)? decide,
}) async {
  decide ??= platformPlan;
  if (StorageState.values.every((s) => decide!(s).store == ActiveStore.objectBox)) {
    return MessagingStore.forStore(ActiveStore.objectBox);
  }
  final plan = decide(await read());
  // Waiting for the copy (a worker isolate before main has copied): nothing
  // may be opened, and the DartWorker refuses pushes meanwhile. ObjectBox is
  // the inert stand-in; anything written there makes the copy stale, so the
  // next copy takes it along.
  if (plan.store == ActiveStore.objectBox || plan.waitForCopy) return MessagingStore.forStore(ActiveStore.objectBox);
  await closeSelectedStore();
  final db = Db.file(files.ready);
  _selected = (db: db, changes: onMain ? DbChangeEvents.main.attachLocal(db) : DbChangeEvents.postFrom(db));
  return MessagingStore.forStore(ActiveStore.sqlite, db: db);
}

Future<void> closeSelectedStore() async {
  final selected = _selected;
  _selected = null;
  if (selected == null) return;
  await selected.changes.cancel();
  await selected.db.close();
}

class StorageFiles {
  StorageFiles(Directory directory)
      : ready = File(join(directory.path, readyName)),
        partial = File(join(directory.path, '$readyName.partial')),
        lock = File(join(directory.path, 'sqlite-copy.lock'));

  static const readyName = 'bluebubbles.db';

  final File ready;
  final File partial;
  final File lock;

  /// Removes both SQLite files (an unfinished setup starts from nothing).
  void deleteAll() {
    _deleteDatabase(ready);
    _deleteDatabase(partial);
  }
}

/// storage_meta of a file that exists but can't be opened or read.
const unreadableFile = <String, String?>{'_unreadable': 'true'};

bool _unreadable(Map<String, String?> meta) => meta.containsKey('_unreadable');

class StorageClassification {
  StorageClassification(this.state, {this.discardReady = false, this.discardPartial = false, this.reason = ''});

  final StorageState state;

  /// Delete `bluebubbles.db` before acting on [state] (a file never marked ready).
  final bool discardReady;

  /// Delete `bluebubbles.db.partial` before acting on [state].
  final bool discardPartial;
  final String reason;
}

/// Pure: the state for the storage_meta of each file (null: no file).
///
/// Only a file marked `storage_state = ready` (written just before the rename)
/// counts as ready. The S1 copy check left a `bluebubbles.db` on the phone that
/// was never marked: it is discarded and copied afresh rather than migrated, so
/// every ready file comes out of this one path. A `bluebubbles.db` that can't be
/// read is never deleted: the app stays on ObjectBox and logs it.
///
/// [outOfDate] says why a ready file no longer matches ObjectBox (null: it
/// does); such a file is discarded and copied afresh ([CopyFingerprint]).
StorageClassification classifyStorage({
  required Map<String, String?>? readyFile,
  required Map<String, String?>? partialFile,
  int checkVersion = copyCheckVersion,
  String? Function(Map<String, String?> readyMeta)? outOfDate,
}) {
  var discardReady = false;
  var reason = '';
  if (readyFile != null) {
    if (_unreadable(readyFile)) return StorageClassification(StorageState.failed, reason: 'bluebubbles.db unreadable');
    final stale = readyFile['storage_state'] == 'ready' ? outOfDate?.call(readyFile) : null;
    if (readyFile['storage_state'] == 'ready' && stale == null) {
      return StorageClassification(StorageState.ready, discardPartial: partialFile != null, reason: 'leftover partial');
    }
    discardReady = true;
    reason = stale != null
        ? 'out of date: $stale'
        : 'never marked ready (check v${readyFile['check_version']}, schema v${readyFile['schema_version']})';
  }
  if (partialFile == null) return StorageClassification(StorageState.noFile, discardReady: discardReady, reason: reason);
  if (_unreadable(partialFile) || partialFile['check_version'] != '$checkVersion') {
    return StorageClassification(StorageState.noFile,
        discardReady: discardReady,
        discardPartial: true,
        reason: _unreadable(partialFile) ? 'partial unreadable' : 'partial from check v${partialFile['check_version']}');
  }
  final failures = int.tryParse(partialFile['verify_failures'] ?? '') ?? 0;
  if (partialFile['copy_state'] == 'verify_failed' && failures >= ObjectBoxSqliteCopy.maxVerifyFailures) {
    return StorageClassification(StorageState.failed,
        discardReady: discardReady, reason: 'verification failed $failures times');
  }
  return StorageClassification(StorageState.partial, discardReady: discardReady, reason: reason);
}

/// Reads storage_meta without drift, so classifying never migrates or creates a file.
Map<String, String?>? _readMeta(File file) {
  if (!file.existsSync()) return null;
  try {
    final db = raw.sqlite3.open(file.path, mode: raw.OpenMode.readWrite);
    try {
      return {
        for (final row in db.select('SELECT key, value FROM storage_meta')) row['key'] as String: row['value'] as String?,
      };
    } finally {
      db.dispose();
    }
  } catch (_) {
    return unreadableFile;
  }
}

Future<StorageClassification> inspectStorage(StorageFiles files, {CopyFingerprint? current}) async {
  final ready = _readMeta(files.ready);
  return classifyStorage(
    readyFile: ready,
    partialFile: _readMeta(files.partial),
    outOfDate: current == null ? null : (meta) => current.differenceFrom(meta, files.ready),
  );
}

/// What a copy was taken from, decision 1-2 (option A): the ObjectBox build's
/// incremental-sync position at copy time. A SQLite build never moves it and
/// never writes messages to ObjectBox, so a ready file whose recorded position
/// differs, or ObjectBox holding message/attachment ids above what was copied,
/// means an ObjectBox build ran since (an undo): the copy is out of date and
/// is redone in full. A file with no record (copied before this rule) is out
/// of date too.
class CopyFingerprint {
  CopyFingerprint({required this.objectBoxMarker, required this.store});

  /// `lastIncrementalSync:lastIncrementalSyncRowId` of the ObjectBox build.
  final String objectBoxMarker;
  final Store store;

  static const metaKey = 'objectbox_marker';

  static String markerOf(int timestamp, int rowId) => '$timestamp:$rowId';

  /// Why the copy in [file] (its storage_meta is [meta]) no longer matches
  /// ObjectBox, or null when it does. Reads ObjectBox ids from the id index only.
  String? differenceFrom(Map<String, String?> meta, File file) {
    final recorded = meta[metaKey];
    if (recorded == null) return 'no ObjectBox position recorded';
    if (recorded != objectBoxMarker) return 'ObjectBox sync moved';
    final copied = _copiedUpTo(file);
    if (_anyAbove(store.box<Message>().query(Message_.id.greaterThan(copied['messages'] ?? 0)).build())) {
      return 'ObjectBox has newer messages';
    }
    if (_anyAbove(store.box<Attachment>().query(Attachment_.id.greaterThan(copied['attachments'] ?? 0)).build())) {
      return 'ObjectBox has newer attachments';
    }
    return null;
  }

  static bool _anyAbove<T>(Query<T> query) {
    try {
      query.limit = 1;
      return query.findIds().isNotEmpty;
    } finally {
      query.close();
    }
  }

  static Map<String, int> _copiedUpTo(File file) {
    final db = raw.sqlite3.open(file.path, mode: raw.OpenMode.readOnly);
    try {
      return {
        for (final row in db.select('SELECT entity, last_source_id FROM copy_checkpoints'))
          row['entity'] as String: row['last_source_id'] as int,
      };
    } finally {
      db.dispose();
    }
  }
}

void _deleteDatabase(File file) {
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final part = File('${file.path}$suffix');
    if (part.existsSync()) part.deleteSync();
  }
}

/// Marks the verified partial file ready and renames it into place. Killed in
/// between, the next start finds a verified partial and only repeats this.
Future<void> _promote(StorageFiles files, String objectBoxMarker) async {
  final database = AppDatabase.file(files.partial);
  try {
    await database.customStatement(
        'INSERT OR REPLACE INTO storage_meta (key, value) VALUES (?, ?)', [CopyFingerprint.metaKey, objectBoxMarker]);
    await database.customStatement("INSERT OR REPLACE INTO storage_meta (key, value) VALUES ('storage_state', 'ready')");
    await database.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
  } finally {
    await database.close();
  }
  _deleteDatabase(files.ready);
  files.partial.renameSync(files.ready.path);
  _deleteDatabase(files.partial);
}

/// One startup step of the state machine: classify the files, discard stale or
/// out-of-date ones, then copy into `bluebubbles.db.partial` (resuming), verify
/// and rename, or keep a current ready file, or stay put after a failure. Holds
/// `sqlite-copy.lock` throughout, so two engines never copy at once. ObjectBox
/// is only read. Returns the state it leaves behind; never throws.
///
/// [objectBoxMarker] is the ObjectBox build's sync position now
/// ([CopyFingerprint]); a copy records it, and a ready file taken at another
/// position is discarded first. [onCopied] runs once a fresh copy is in place.
Future<StorageState> runStorageStartup({
  required Store store,
  required StorageFiles files,
  required void Function(String line) log,
  required String objectBoxMarker,
  int batchSize = 1000,
  int? stopAfterBatches,
  void Function(double fraction)? onProgress,
  void Function()? onCopied,
}) async {
  final current = CopyFingerprint(objectBoxMarker: objectBoxMarker, store: store);
  RandomAccessFile? lock;
  try {
    lock = files.lock.openSync(mode: FileMode.append);
    try {
      lock.lockSync(FileLock.exclusive);
    } on FileSystemException {
      log('BBSQL storage busy: sqlite-copy.lock is held by another process');
      return (await inspectStorage(files, current: current)).state;
    }

    final found = await inspectStorage(files, current: current);
    if (found.discardReady) {
      log('BBSQL discard bluebubbles.db: ${found.reason}');
      _deleteDatabase(files.ready);
    }
    if (found.discardPartial) {
      log('BBSQL discard bluebubbles.db.partial: ${found.reason}');
      _deleteDatabase(files.partial);
    }
    final state = found.state;
    log('BBSQL storage state=${state.name}');

    switch (decideStorage(state).step) {
      case CopyStep.copy:
        final ok = await runSqliteCopyCheck(
          store: store,
          file: files.partial,
          log: log,
          batchSize: batchSize,
          stopAfterBatches: stopAfterBatches,
          onProgress: onProgress,
        );
        if (!ok) {
          final after = await inspectStorage(files);
          if (after.state == StorageState.failed) log('BBSQL storage failed: staying on ObjectBox (${after.reason})');
          return after.state;
        }
        await _promote(files, objectBoxMarker);
        onProgress?.call(1.0);
        log('BBSQL storage ready');
        onCopied?.call();
        return StorageState.ready;
      case CopyStep.none:
        if (state == StorageState.ready) {
          log('BBSQL storage current');
        } else {
          log('BBSQL storage failed: staying on ObjectBox (${found.reason})');
        }
        return state;
    }
  } catch (e) {
    // The type only: SQLite errors can quote the statement's values.
    log('BBSQL error ${e.runtimeType}');
    try {
      return (await inspectStorage(files)).state;
    } catch (_) {
      return StorageState.failed;
    }
  } finally {
    lock?.closeSync();
  }
}

/// [runStorageStartup] on its own isolate attached to the ObjectBox store
/// already open at [objectBoxPath], so the UI isolate only waits on a port.
/// Progress and log lines come back as they happen; [onCopied] when a fresh
/// copy was put in place.
Future<StorageState> runStorageStartupInIsolate({
  required String objectBoxPath,
  required String directoryPath,
  required String objectBoxMarker,
  required void Function(String line) log,
  void Function(double fraction)? onProgress,
  void Function()? onCopied,
}) async {
  final port = ReceivePort();
  final done = Completer<StorageState>();
  port.listen((message) {
    if (message is double) {
      onProgress?.call(message);
    } else if (message is String) {
      log(message);
    } else if (message is bool) {
      onCopied?.call();
    } else if (message is int) {
      done.complete(StorageState.values[message]);
    }
  });
  final send = port.sendPort;
  try {
    await Isolate.run(_storageIsolateTask(send, objectBoxPath, directoryPath, objectBoxMarker),
        debugName: 'sqlite-storage');
    return await done.future;
  } finally {
    port.close();
  }
}

/// Built here so the closure captures only these sendable values (a closure
/// created inside [runStorageStartupInIsolate] would carry its Completer).
Future<void> Function() _storageIsolateTask(
        SendPort send, String objectBoxPath, String directoryPath, String objectBoxMarker) =>
    () => _storageIsolateBody(send, objectBoxPath, directoryPath, objectBoxMarker);

Future<void> _storageIsolateBody(SendPort send, String objectBoxPath, String directoryPath, String objectBoxMarker) async {
  var state = StorageState.failed;
  try {
    final store = Store.attach(getObjectBoxModel(), objectBoxPath);
    try {
      state = await runStorageStartup(
        store: store,
        files: StorageFiles(Directory(directoryPath)),
        log: send.send,
        objectBoxMarker: objectBoxMarker,
        onProgress: send.send,
        onCopied: () => send.send(true),
      );
    } finally {
      store.close();
    }
  } catch (e) {
    send.send('BBSQL error ${e.runtimeType}');
  }
  send.send(state.index);
}

/// The plan this platform runs: Android switches to SQLite; desktop, web and
/// host tests stay on ObjectBox and never copy.
StoragePlan Function(StorageState) get platformPlan => !kIsWeb && Platform.isAndroid ? decideStorage : objectBoxOnly;

/// The state machine wired into the app's startup.
class StorageStartup {
  static final SqliteCopyCheckRunner _runner = SqliteCopyCheckRunner(
    // Also before setup finishes: Database.init has just emptied both stores,
    // so the copy is instant and setup's sync goes straight into SQLite.
    enabled: () => !identical(platformPlan, objectBoxOnly) && !isIsolate && GetIt.I.isRegistered<SettingsService>(),
    body: () async {
      final settings = SettingsSvc.settings;
      await runStorageStartupInIsolate(
        objectBoxPath: join(Database.appDocPath, 'objectbox'),
        directoryPath: Database.appDocPath,
        objectBoxMarker: CopyFingerprint.markerOf(settings.lastIncrementalSync.value, settings.lastIncrementalSyncRowId.value),
        onProgress: (fraction) => progress.value = fraction,
        onCopied: () => unawaited(resetSqliteMarkers(settings)),
        log: debugPrint,
      );
    },
  );

  /// Shows the progress screen; set by startup before Database.init.
  static void Function()? onWait;

  /// The copy's progress, 0 to 1, for the progress screen while startup waits for it.
  static final ValueNotifier<double> progress = ValueNotifier(0);

  static StorageFiles get files => StorageFiles(Directory(Database.appDocPath));

  /// Main isolate, from Database.init: runs the state machine once per process
  /// and, when the plan makes startup wait for the copy, shows [onWait] (the
  /// progress screen) once a copy is under way, and waits for it.
  static Future<void> start() async {
    if (storageNeverWaits(decide: platformPlan)) return _runner.start();
    final before = await inspectStorage(files);
    final run = _runner.start();
    // A ready file may still turn out stale once the copy isolate compares it
    // with ObjectBox; that case shows the bar from its first progress report.
    if (platformPlan(before.state).waitForCopy) {
      onWait?.call();
    } else {
      void show() {
        progress.removeListener(show);
        onWait?.call();
      }
      progress.addListener(show);
      run.whenComplete(() => progress.removeListener(show));
    }
    await run;
  }

  /// GlobalIsolate and IncrementalSyncIsolate: wait until the plan allows using storage.
  static Future<void> waitUntilUsable() =>
      waitForStorage(read: () async => (await inspectStorage(files)).state, decide: platformPlan);

  /// DartWorker: pushes arriving while storage is not usable ask Android to retry.
  static void checkWorker() {
    if (storageNeverWaits(decide: platformPlan)) return;
    MethodChannelHandlers.storageUsable =
        () async => workerMayProceed((await inspectStorage(files)).state, decide: platformPlan);
  }
}

/// After a fresh copy the SQLite build's own sync markers start over, so its
/// next sync resumes from the ObjectBox position the copy was taken at
/// ([SyncMarker] reads ObjectBox's marker while its own is 0).
Future<void> resetSqliteMarkers(Settings settings) async {
  settings.sqliteLastIncrementalSync.value = 0;
  settings.sqliteLastIncrementalSyncRowId.value = 0;
  settings.sqliteIncrementalCatchUpTotal.value = 0;
  await settings.saveManyAsync(SyncMarkerKeys.sqlite.all);
}
