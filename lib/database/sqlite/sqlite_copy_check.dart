import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/app_database.dart';
import 'package:bluebubbles/database/sqlite/objectbox_sqlite_copy.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';

// Stage S1 "copy check": copies the messaging set from ObjectBox into an
// SQLite file, verifies it and logs `BBSQL` lines. The startup state machine
// (storage_state.dart) runs it on `bluebubbles.db.partial`.

/// [runSqliteCopyCheck] on a new isolate attached to the ObjectBox store already
/// open at [objectBoxPath] (as the app's worker isolates attach). Closing the
/// attached instance leaves the app's store open.
Future<bool> runSqliteCopyCheckInIsolate({required String objectBoxPath, required String sqlitePath}) {
  return Isolate.run(
    () async {
      final store = Store.attach(getObjectBoxModel(), objectBoxPath);
      try {
        return await runSqliteCopyCheck(store: store, file: File(sqlitePath), log: debugPrint);
      } finally {
        store.close();
      }
    },
    debugName: 'sqlite-copy-check',
  );
}

/// Starts [body] at most once per process, never twice at the same time, and
/// only when [enabled]. Errors are logged, never thrown to the caller.
class SqliteCopyCheckRunner {
  SqliteCopyCheckRunner({required this.enabled, required this.body});

  final bool Function() enabled;
  final Future<void> Function() body;

  Future<void>? _running;
  bool _done = false;

  bool get isRunning => _running != null;

  Future<void> start() {
    if (_running != null) return _running!;
    if (_done || !enabled()) return Future.value();
    _done = true;
    return _running = () async {
      try {
        await body();
      } catch (e) {
        debugPrint('BBSQL error ${e.runtimeType}');
      } finally {
        _running = null;
      }
    }();
  }
}

String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

int _fileSize(File file) {
  var size = 0;
  for (final suffix in ['', '-wal', '-shm']) {
    final part = File('${file.path}$suffix');
    if (part.existsSync()) size += part.lengthSync();
  }
  return size;
}

/// Bump when the copy or its check changes: a file checked by an older version
/// is copied and checked again from scratch on the next launch. v4: schema v2
/// (real foreign keys, messages_fts filled after the bulk insert).
const copyCheckVersion = 4;

/// Copies [store] into the SQLite [file] (resuming an earlier copy), verifies it
/// and records the result in storage_meta. Logs counts, timings, file size and
/// RSS through [log]; never message content. Returns whether it verified.
///
/// Once the copy is verified, or has given up, later launches only log the
/// stored result and touch nothing in ObjectBox: even a count walks the whole
/// message table, and on the phone that kept ~700 MB of ObjectBox resident.
Future<bool> runSqliteCopyCheck({
  required Store store,
  required File file,
  required void Function(String line) log,
  int batchSize = 1000,
  int checkVersion = copyCheckVersion,
  int? stopAfterBatches,
  void Function(double fraction)? onProgress,
}) async {
  final clock = Stopwatch()..start();
  AppDatabase? database;
  try {
    database = AppDatabase(NativeDatabase(file));
    final meta = await readStorageMeta(database);
    final state = meta['copy_state'];
    final version = int.tryParse(meta['check_version'] ?? '') ?? (state == null ? checkVersion : 1);
    final failures = int.tryParse(meta['verify_failures'] ?? '') ?? 0;
    if (version == checkVersion && state == 'verified') {
      log('BBSQL skip: copy verified at ${meta['verified_at']} (check v$checkVersion)');
      return true;
    }
    if (version == checkVersion && state == 'verify_failed' && failures >= ObjectBoxSqliteCopy.maxVerifyFailures) {
      log('BBSQL skip: verification failed $failures times, not retrying');
      log('BBSQL last verify ${meta['verify_result']}');
      return false;
    }
    if (version != checkVersion) {
      // Diagnostics from the older check before its result is replaced.
      if (meta['verify_result'] != null) log('BBSQL previous verify (check v$version) ${meta['verify_result']}');
      await ObjectBoxSqliteCopy.resetTarget(database);
    }
    await database.customStatement(
        'INSERT OR REPLACE INTO storage_meta (key, value) VALUES (?, ?)', ['check_version', '$checkVersion']);
    final mode = version != checkVersion ? 'recheck' : (state == null ? 'new' : 'resume:$state');
    log('BBSQL start mode=$mode messages=${store.box<Message>().count()} rssMb=${_mb(ProcessInfo.currentRss)}');

    final copy = ObjectBoxSqliteCopy(
        source: store,
        target: database,
        batchSize: batchSize,
        log: log,
        stopAfterBatches: stopAfterBatches,
        onProgress: onProgress);
    final report = await copy.run();
    if (!report.completed) {
      log('BBSQL stopped mode=${report.mode.name} ms=${report.elapsed.inMilliseconds}');
      return false;
    }
    final rows = report.rows.entries.map((e) => '${e.key}=${e.value}').join(' ');
    log('BBSQL copied mode=${report.mode.name} $rows ms=${report.elapsed.inMilliseconds} '
        'rssMb=${_mb(ProcessInfo.currentRss)}');

    var result = await copy.verify();
    if (!result.ok && result.rowsComplete) {
      // Rows the app changed between copy and check: re-copy those and check again.
      log('BBSQL verify retry mismatches=${result.mismatches.length}');
      await copy.run();
      result = await copy.verify();
    }
    final counts = result.counts.entries.map((e) => '${e.key}=${e.value[0]}/${e.value[1]}').join(' ');
    log('BBSQL verify ok=${result.ok} sampled=${result.sampled} mismatches=${result.mismatches.length} '
        'ms=${result.elapsed.inMilliseconds} $counts');
    if (result.mismatches.isNotEmpty) log('BBSQL verify first ${result.mismatches.take(10).join('; ')}');

    if (report.mode == CopyMode.full) {
      final fk = await database.customSelect('PRAGMA foreign_key_check').get();
      final quick = await database.customSelect('PRAGMA quick_check').getSingle();
      log('BBSQL integrity quick_check=${quick.data.values.first} foreign_key_violations=${fk.length}');
    }
    await database.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    log('BBSQL done ok=${result.ok} ms=${clock.elapsedMilliseconds} fileMb=${_mb(_fileSize(file))} '
        'rssMb=${_mb(ProcessInfo.currentRss)}');
    return result.ok;
  } catch (e) {
    // The type only: SQLite errors can quote the statement's values.
    log('BBSQL error ${e.runtimeType} after ${clock.elapsedMilliseconds}ms');
    return false;
  } finally {
    await database?.close();
  }
}
