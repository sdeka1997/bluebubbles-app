import 'dart:convert';
import 'dart:io';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/app_database.dart';
import 'package:bluebubbles/database/sqlite/objectbox_sqlite_copy.dart';
import 'package:bluebubbles/database/sqlite/sqlite_copy_check.dart';
import 'package:bluebubbles/database/sqlite/storage_state.dart';
import 'package:bluebubbles/services/backend/sync/sync_marker.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';

import 'objectbox_sqlite_copy_test.dart' show Fixture, dumpTables, expectFtsConsistent, ftsIds;
import 'schema_v2_test.dart' show writeS1File;

// The startup storage state machine (switch-plan commits 2 and 9): no file /
// partial / ready / failed, the copy into bluebubbles.db.partial, the rename,
// the lock, and a ready copy judged against ObjectBox (decisions 1-2, option A).

Map<String, String?> _meta(Map<String, String?> values) => values;

Future<StorageClassification> classify(StorageFiles files) => inspectStorage(files);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('decideStorage', () {
    test('SQLite once a copy is ready; until then startup waits for the copy; a failed copy stays on ObjectBox', () {
      expect(decideStorage(StorageState.noFile), (store: ActiveStore.sqlite, step: CopyStep.copy, waitForCopy: true));
      expect(decideStorage(StorageState.partial), (store: ActiveStore.sqlite, step: CopyStep.copy, waitForCopy: true));
      expect(decideStorage(StorageState.ready), (store: ActiveStore.sqlite, step: CopyStep.none, waitForCopy: false));
      expect(decideStorage(StorageState.failed), (store: ActiveStore.objectBox, step: CopyStep.none, waitForCopy: false));
    });

    test('platforms without the switch stay on ObjectBox and never copy', () {
      for (final s in StorageState.values) {
        expect(objectBoxOnly(s), (store: ActiveStore.objectBox, step: CopyStep.none, waitForCopy: false));
      }
      expect(platformPlan, same(objectBoxOnly), reason: 'host tests are not Android');
    });
  });

  group('classifyStorage', () {
    const current = '$copyCheckVersion';

    test('no files is noFile', () {
      final c = classifyStorage(readyFile: null, partialFile: null);
      expect((c.state, c.discardReady, c.discardPartial), (StorageState.noFile, false, false));
    });

    test('a ready file is ready, and a leftover partial next to it is discarded', () {
      final c = classifyStorage(
          readyFile: _meta({'storage_state': 'ready', 'check_version': '1'}), partialFile: {});
      expect((c.state, c.discardReady, c.discardPartial), (StorageState.ready, false, true));
    });

    test('the S1 file (bluebubbles.db never marked ready) is stale: discarded, then noFile', () {
      final c = classifyStorage(
          readyFile: _meta({'check_version': '3', 'copy_state': 'verified', 'schema_version': '1'}), partialFile: null);
      expect((c.state, c.discardReady, c.discardPartial), (StorageState.noFile, true, false));
      expect(c.reason, contains('never marked ready'));
    });

    test('a ready file that is out of date is discarded, then noFile', () {
      final c = classifyStorage(
          readyFile: _meta({'storage_state': 'ready'}), partialFile: null, outOfDate: (_) => 'ObjectBox sync moved');
      expect((c.state, c.discardReady, c.discardPartial), (StorageState.noFile, true, false));
      expect(c.reason, 'out of date: ObjectBox sync moved');
    });

    test('an unreadable bluebubbles.db is never deleted: failed for this launch', () {
      final c = classifyStorage(readyFile: unreadableFile, partialFile: null);
      expect((c.state, c.discardReady, c.discardPartial), (StorageState.failed, false, false));
    });

    test('a partial file of the current check is resumed', () {
      final c = classifyStorage(readyFile: null, partialFile: _meta({'check_version': current, 'copy_state': 'copying'}));
      expect((c.state, c.discardReady, c.discardPartial), (StorageState.partial, false, false));
    });

    test('a partial file of an older check, or unreadable, is discarded: noFile', () {
      for (final partial in [_meta({'check_version': '3', 'copy_state': 'copying'}), unreadableFile]) {
        final c = classifyStorage(readyFile: null, partialFile: partial);
        expect((c.state, c.discardReady, c.discardPartial), (StorageState.noFile, false, true));
      }
    });

    test('a partial file whose check gave up is failed', () {
      final c = classifyStorage(readyFile: null, partialFile: _meta({
        'check_version': current,
        'copy_state': 'verify_failed',
        'verify_failures': '${ObjectBoxSqliteCopy.maxVerifyFailures}',
      }));
      expect((c.state, c.discardReady, c.discardPartial), (StorageState.failed, false, false));
      final once = classifyStorage(readyFile: null, partialFile: _meta({
        'check_version': current,
        'copy_state': 'verify_failed',
        'verify_failures': '1',
      }));
      expect(once.state, StorageState.partial);
    });
  });

  group('runStorageStartup', () {
    late Directory obDir;
    late Directory appDir;
    late Fixture fixture;
    late StorageFiles files;

    setUp(() {
      obDir = Directory.systemTemp.createTempSync('bb_state_ob_');
      appDir = Directory.systemTemp.createTempSync('bb_state_app_');
      fixture = Fixture(obDir)..seed();
      files = StorageFiles(appDir);
    });

    tearDown(() {
      fixture.close();
      obDir.deleteSync(recursive: true);
      appDir.deleteSync(recursive: true);
    });

    String dataHash() => sha256.convert(File('${obDir.path}/data.mdb').readAsBytesSync()).toString();

    const marker = '1700000000000:4000';

    Future<StorageState> run(List<String> lines,
            {int? stopAfterBatches, void Function(double)? onProgress, String objectBoxMarker = marker, void Function()? onCopied}) =>
        runStorageStartup(
          store: fixture.store,
          files: files,
          log: lines.add,
          objectBoxMarker: objectBoxMarker,
          batchSize: 7,
          stopAfterBatches: stopAfterBatches,
          onProgress: onProgress,
          onCopied: onCopied,
        );

    test('no file: copies into bluebubbles.db.partial with progress, verifies, renames; ObjectBox untouched', () async {
      final before = dataHash();
      final lines = <String>[];
      final progress = <double>[];
      expect(await run(lines, onProgress: progress.add), StorageState.ready);

      expect(files.partial.existsSync(), isFalse);
      expect(files.ready.existsSync(), isTrue);
      expect(lines, contains('BBSQL storage state=noFile'));
      expect(lines, contains('BBSQL storage ready'));
      expect(progress, isNotEmpty);
      expect(progress.last, 1.0);
      for (var i = 1; i < progress.length; i++) {
        expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
      }
      expect(dataHash(), before);

      final db = AppDatabase.file(files.ready);
      addTearDown(db.close);
      final meta = await readStorageMeta(db);
      expect(meta['storage_state'], 'ready');
      expect(meta['copy_state'], 'verified');
      expect(await ftsIds(db, 'text 7'), hasLength(1));
      expect((await classify(files)).state, StorageState.ready);
    });

    test('killed mid-copy: partial on disk, the next start resumes to the same result as an uninterrupted copy', () async {
      final lines = <String>[];
      expect(await run(lines, stopAfterBatches: 3), StorageState.partial);
      expect(files.ready.existsSync(), isFalse);
      expect(files.partial.existsSync(), isTrue);
      expect((await classify(files)).state, StorageState.partial);

      final resumed = <String>[];
      expect(await run(resumed), StorageState.ready);
      expect(resumed, contains('BBSQL storage state=partial'));

      final otherDir = Directory.systemTemp.createTempSync('bb_state_other_');
      addTearDown(() => otherDir.deleteSync(recursive: true));
      final other = StorageFiles(otherDir);
      expect(await runStorageStartup(store: fixture.store, files: other, log: (_) {}, objectBoxMarker: marker, batchSize: 7),
          StorageState.ready);

      final a = AppDatabase.file(files.ready);
      final b = AppDatabase.file(other.ready);
      addTearDown(a.close);
      addTearDown(b.close);
      expect(await dumpTables(a), await dumpTables(b));
      await expectFtsConsistent(a);
    });

    test('killed after verify but before the rename: the next start only marks it ready and renames', () async {
      // Copy and verify into the partial file directly, as if killed right after.
      expect(await runSqliteCopyCheck(store: fixture.store, file: files.partial, log: (_) {}), isTrue);
      final lines = <String>[];
      fixture.store.close();
      // A closed store throws on any read: the verified partial must not be copied again.
      expect(await runStorageStartup(store: fixture.store, files: files, log: lines.add, objectBoxMarker: marker),
          StorageState.ready);
      expect(lines.where((l) => l.startsWith('BBSQL skip: copy verified')), hasLength(1));
      fixture.store = Store(getObjectBoxModel(), directory: obDir.path);
    });

    test("the phone's S1 file (schema v1, check v3) is discarded and copied afresh, never migrated", () async {
      writeS1File(appDir);
      final lines = <String>[];
      expect(await run(lines), StorageState.ready);
      expect(lines.first, startsWith('BBSQL discard bluebubbles.db'));
      expect(lines, contains('BBSQL storage state=noFile'));
      expect(lines.singleWhere((l) => l.startsWith('BBSQL start')), contains('mode=new'));

      final db = AppDatabase.file(files.ready);
      addTearDown(db.close);
      // Only what ObjectBox holds: none of the S1 fixture's rows (guid 'm1' ... 'm3', 'c1').
      expect((await db.customSelect("SELECT count(*) AS c FROM chats WHERE guid = 'c1'").getSingle()).read<int>('c'), 0);
      expect((await readStorageMeta(db))['storage_state'], 'ready');
    });

    test('a fresh copy records the ObjectBox position; the next start keeps it and copies nothing', () async {
      var copied = 0;
      expect(await run([], onCopied: () => copied++), StorageState.ready);
      expect(copied, 1);
      final db = AppDatabase.file(files.ready);
      expect((await readStorageMeta(db))[CopyFingerprint.metaKey], marker);
      await db.close();

      final before = files.ready.lastModifiedSync();
      final lines = <String>[];
      expect(await run(lines, onCopied: () => copied++), StorageState.ready);
      expect(lines, contains('BBSQL storage current'));
      expect(copied, 1);
      expect(files.ready.lastModifiedSync(), before);
    });

    test("decision 1: a ready copy with no recorded position (seq.42d's) is discarded and copied fresh", () async {
      expect(await run([]), StorageState.ready);
      final db = AppDatabase.file(files.ready);
      await db.customStatement("DELETE FROM storage_meta WHERE key = '${CopyFingerprint.metaKey}'");
      await db.close();

      final lines = <String>[];
      expect(await run(lines), StorageState.ready);
      expect(lines.first, 'BBSQL discard bluebubbles.db: out of date: no ObjectBox position recorded');
      expect(lines.singleWhere((l) => l.startsWith('BBSQL start')), contains('mode=new'));
    });

    test('decision 2: an ObjectBox build ran since (its sync moved): the whole copy is redone, edits included', () async {
      expect(await run([]), StorageState.ready);
      // On the undo build: an old message edited, one deleted, and the sync moved.
      final messages = fixture.store.box<Message>();
      final old = messages.query(Message_.guid.equals('m4')).build().findFirst()!;
      old.text = 'edited while rolled back';
      messages.put(old);

      final before = dataHash();
      final lines = <String>[];
      var copied = 0;
      expect(await run(lines, objectBoxMarker: '1700000999000:4100', onCopied: () => copied++), StorageState.ready);
      expect(lines.first, 'BBSQL discard bluebubbles.db: out of date: ObjectBox sync moved');
      expect(copied, 1);
      expect(dataHash(), before);

      final db = AppDatabase.file(files.ready);
      addTearDown(db.close);
      expect(await ftsIds(db, 'edited while'), [old.id]);
      expect((await readStorageMeta(db))[CopyFingerprint.metaKey], '1700000999000:4100');
      await expectFtsConsistent(db);
    });

    test('decision 2: ObjectBox holding messages the copy lacks, at the same position, is out of date too', () async {
      expect(await run([]), StorageState.ready);
      final newer = Message(guid: 'rolled-back', text: 'arrived on the ObjectBox build', dateCreated: DateTime.utc(2027));
      newer.chat.target = fixture.alice;
      fixture.store.box<Message>().put(newer);

      final lines = <String>[];
      expect(await run(lines), StorageState.ready);
      expect(lines.first, 'BBSQL discard bluebubbles.db: out of date: ObjectBox has newer messages');
      final db = AppDatabase.file(files.ready);
      addTearDown(db.close);
      expect(await ftsIds(db, 'ObjectBox build'), [newer.id]);
    });

    test('failed: no copy, the app stays on ObjectBox, and it is logged', () async {
      final db = AppDatabase.file(files.partial);
      await db.customStatement("INSERT INTO storage_meta (key, value) VALUES ('check_version', '$copyCheckVersion'), "
          "('copy_state', 'verify_failed'), ('verify_failures', '${ObjectBoxSqliteCopy.maxVerifyFailures}'), "
          "('verify_result', '{\"ok\":false}')");
      await db.close();
      fixture.store.close();

      final lines = <String>[];
      expect(await runStorageStartup(store: fixture.store, files: files, log: lines.add, objectBoxMarker: marker),
          StorageState.failed);
      expect(decideStorage(StorageState.failed).store, ActiveStore.objectBox);
      expect(lines, contains('BBSQL storage state=failed'));
      expect(lines.where((l) => l.startsWith('BBSQL storage failed: staying on ObjectBox')), hasLength(1));
      expect(files.ready.existsSync(), isFalse);
      fixture.store = Store(getObjectBoxModel(), directory: obDir.path);
    });

    test('another process holding sqlite-copy.lock: this start copies nothing', () async {
      final holder = await Process.start('python3', [
        '-c',
        'import fcntl,sys,time\n'
            'f=open(sys.argv[1],"a")\n'
            'fcntl.lockf(f, fcntl.LOCK_EX)\n'
            'print("locked", flush=True)\n'
            'time.sleep(60)\n',
        files.lock.path,
      ]);
      addTearDown(holder.kill);
      await holder.stdout.transform(utf8.decoder).firstWhere((s) => s.contains('locked'));

      final lines = <String>[];
      expect(await run(lines), StorageState.noFile);
      expect(lines, contains('BBSQL storage busy: sqlite-copy.lock is held by another process'));
      expect(files.partial.existsSync(), isFalse);
      expect(files.ready.existsSync(), isFalse);
    });

    test('the copy runs on its own isolate attached to the open store and reports progress', () async {
      final progress = <double>[];
      var copied = 0;
      final state = await runStorageStartupInIsolate(
        objectBoxPath: obDir.path,
        directoryPath: appDir.path,
        objectBoxMarker: marker,
        onProgress: progress.add,
        onCopied: () => copied++,
        log: (_) {},
      );
      expect(state, StorageState.ready);
      expect(copied, 1);
      expect(progress.last, 1.0);
      expect(files.ready.existsSync(), isTrue);
      // The app's store is still open and usable.
      expect(fixture.store.box<Message>().count(), greaterThan(0));
    });
  });

  group('waiting for storage', () {
    StoragePlan waitUntilReady(StorageState s) =>
        (store: ActiveStore.sqlite, step: CopyStep.copy, waitForCopy: s != StorageState.ready);

    test('with ObjectBox active nothing ever waits, so nothing reads the files', () async {
      expect(storageNeverWaits(decide: objectBoxOnly), isTrue);
      var reads = 0;
      await waitForStorage(decide: objectBoxOnly, read: () async {
        reads++;
        return StorageState.partial;
      }, poll: const Duration(hours: 1));
      expect(reads, 0);
    });

    test('when the plan says wait, an isolate polls until the copy is ready', () async {
      expect(storageNeverWaits(decide: waitUntilReady), isFalse);
      final states = [StorageState.noFile, StorageState.partial, StorageState.partial, StorageState.ready];
      var reads = 0;
      await waitForStorage(read: () async => states[reads++], decide: waitUntilReady, poll: Duration.zero);
      expect(reads, 4);
    });

    test('the DartWorker proceeds unless the plan says wait (ObjectBox active: always proceeds)', () {
      for (final s in StorageState.values) {
        expect(workerMayProceed(s, decide: objectBoxOnly), isTrue, reason: s.name);
        expect(workerMayProceed(s), s == StorageState.ready || s == StorageState.failed, reason: s.name);
        expect(workerMayProceed(s, decide: waitUntilReady), s == StorageState.ready, reason: s.name);
      }
    });
  });

  group('startup wiring', () {
    final startup = File('lib/helpers/backend/startup_tasks.dart').readAsStringSync();
    final database = File('lib/database/database.dart').readAsStringSync();
    final sync = File('lib/services/backend/sync/sync_service.dart').readAsStringSync();

    String body(String source, String signature) {
      final start = source.indexOf(signature);
      expect(start, greaterThan(0), reason: signature);
      final end = source.indexOf('\n  static ', start + signature.length);
      return source.substring(start, end < 0 ? source.length : end);
    }

    test('main starts the state machine from Database.init; the S1 check after sync is gone', () {
      expect(body(database, 'static Future<void> init()'), contains('StorageStartup.start()'));
      expect(sync, isNot(contains('SqliteCopyCheck')));
      expect(sync, isNot(contains('sqlite_copy_check')));
    });

    test('worker isolates wait for storage before opening the database', () {
      for (final sig in ['static Future<void> initGlobalIsolateServices(', 'static Future<void> initSyncIsolateServices(']) {
        final b = body(startup, sig);
        expect(b.indexOf('StorageStartup.waitUntilUsable()'), allOf(greaterThan(0), lessThan(b.indexOf('Database.init()'))),
            reason: sig);
      }
    });

    test('the DartWorker records whether it may proceed before handling pushes', () {
      final b = body(startup, 'static Future<void> initBackgroundIsolate(');
      expect(b.indexOf('StorageStartup.checkWorker()'), allOf(greaterThan(0), lessThan(b.indexOf('Database.init()'))));
    });
  });
}
