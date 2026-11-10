// Risk R1 / bench B5 (SQLITE-PLAN-2): two isolates, each with its own
// connection to one SQLite file, writing at the same time.
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:bluebubbles/database/sqlite/app_database.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _counterKey = 'contention_counter';

Future<int> _readCounter(AppDatabase database) async {
  final row = await database
      .customSelect('SELECT value FROM storage_meta WHERE key = ?', variables: [Variable.withString(_counterKey)])
      .getSingleOrNull();
  return int.parse(row?.read<String>('value') ?? '0');
}

Future<void> _writeCounter(AppDatabase database, int value) => database.customStatement(
    'INSERT OR REPLACE INTO storage_meta (key, value) VALUES (?, ?)', [_counterKey, '$value']);

/// One read-modify-write increment the way the app's sync does it: read, then
/// write in the same transaction.
Future<void> _incrementDeferred(AppDatabase database, {Duration hold = Duration.zero}) {
  return database.transaction(() async {
    final value = await _readCounter(database);
    if (hold > Duration.zero) await Future<void>.delayed(hold);
    await _writeCounter(database, value + 1);
  });
}

Future<void> _incrementImmediate(Db db, {Duration hold = Duration.zero}) {
  return db.write((tx) async {
    final value = await _readCounter(db.database);
    if (hold > Duration.zero) await Future<void>.delayed(hold);
    await _writeCounter(db.database, value + 1);
  });
}

/// Worker isolate: [n] increments on its own connection; replies
/// `(failures, firstErrorCode)`.
Future<void> _stressWorker((SendPort, String, int, bool) args) async {
  final (reply, path, n, immediate) = args;
  final db = Db.file(File(path));
  var failures = 0;
  int? firstCode;
  for (var i = 0; i < n; i++) {
    try {
      if (immediate) {
        await _incrementImmediate(db, hold: const Duration(milliseconds: 1));
      } else {
        await _incrementDeferred(db.database, hold: const Duration(milliseconds: 1));
      }
    } on SqliteException catch (e) {
      failures++;
      firstCode ??= e.extendedResultCode;
    }
  }
  await db.close();
  reply.send((failures, firstCode));
}

/// Worker for the step-by-step race: begins, reads, reports 'read', waits for
/// 'go', writes; replies with the error code or 0.
Future<void> _raceWorker((SendPort, String, bool) args) async {
  final (reply, path, immediate) = args;
  final commands = ReceivePort();
  reply.send(commands.sendPort);
  final next = StreamIterator(commands);
  final db = Db.file(File(path));
  final clock = Stopwatch();
  try {
    await next.moveNext(); // 'start'
    clock.start();
    Future<void> body() async {
      final value = await _readCounter(db.database);
      reply.send('read');
      if (!immediate) await next.moveNext(); // 'go'
      await _writeCounter(db.database, value + 1);
    }

    if (immediate) {
      await db.write((_) => body());
    } else {
      await db.database.transaction(body);
    }
    reply.send(('done', 0, clock.elapsedMilliseconds));
  } on SqliteException catch (e) {
    reply.send(('done', e.extendedResultCode, clock.elapsedMilliseconds));
  } finally {
    await db.close();
    await next.cancel();
  }
}

void main() {
  // One connection per isolate is the design; these tests open several on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory directory;
  late String path;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bb_write_contention_');
    path = '${directory.path}/bluebubbles.db';
    final setup = AppDatabase(NativeDatabase(File(path)));
    await _writeCounter(setup, 0);
    await setup.close();
  });
  tearDown(() => directory.delete(recursive: true));

  Future<int> finalCount() async {
    final database = AppDatabase(NativeDatabase(File(path)));
    try {
      return await _readCounter(database);
    } finally {
      await database.close();
    }
  }

  test("drift's deferred BEGIN: the second writer fails with SQLITE_BUSY and its write is lost", () async {
    final replies = ReceivePort();
    final events = StreamIterator(replies);
    await Isolate.spawn(_raceWorker, (replies.sendPort, path, false));
    await events.moveNext();
    final worker = events.current as SendPort;

    final main = AppDatabase(NativeDatabase(File(path)));
    addTearDown(main.close);
    worker.send('start');
    await events.moveNext(); // worker holds a read snapshot
    expect(events.current, 'read');
    await _incrementDeferred(main); // main reads, writes, commits
    worker.send('go'); // worker now writes from its stale snapshot
    await events.moveNext();
    final (_, code, _) = events.current as (String, int, int);
    await events.cancel();

    // ignore: avoid_print
    print('B5 deferred: worker error code=$code final=${await finalCount()} (expected 2 increments)');
    expect(code & 0xff, 5, reason: 'SQLITE_BUSY family (517 = SQLITE_BUSY_SNAPSHOT)');
    expect(await finalCount(), 1, reason: 'one of the two increments is lost');
  });

  test('Db.write (BEGIN IMMEDIATE + busy_timeout): the second writer waits, nothing is lost', () async {
    final replies = ReceivePort();
    final events = StreamIterator(replies);
    await Isolate.spawn(_raceWorker, (replies.sendPort, path, true));
    await events.moveNext();
    final worker = events.current as SendPort;

    final main = Db.file(File(path));
    addTearDown(main.close);
    await main.write((tx) async {
      final value = await _readCounter(main.database);
      worker.send('start'); // worker's BEGIN IMMEDIATE now blocks on the write lock
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _writeCounter(main.database, value + 1);
    });
    await events.moveNext();
    expect(events.current, 'read');
    await events.moveNext();
    final (_, code, waitedMs) = events.current as (String, int, int);
    await events.cancel();

    // ignore: avoid_print
    print('B5 immediate: worker error code=$code waitedMs=$waitedMs final=${await finalCount()}');
    expect(code, 0);
    expect(waitedMs, greaterThanOrEqualTo(200), reason: 'it waited for the lock instead of failing');
    expect(await finalCount(), 2);
  });

  Future<(int, int, List<int?>)> stress({required bool immediate, int perIsolate = 200}) async {
    final replies = ReceivePort();
    for (var i = 0; i < 2; i++) {
      await Isolate.spawn(_stressWorker, (replies.sendPort, path, perIsolate, immediate));
    }
    final results = await replies.take(2).toList();
    final failures = results.fold<int>(0, (n, r) => n + (r as (int, int?)).$1);
    final codes = results.map((r) => (r as (int, int?)).$2).toList();
    return (failures, await finalCount(), codes);
  }

  test('stress, deferred BEGIN: concurrent increments from two isolates fail and lose writes', () async {
    final (failures, count, codes) = await stress(immediate: false);
    // ignore: avoid_print
    print('B5 stress deferred: 2x200 increments -> failures=$failures final=$count lost=${400 - count} codes=$codes');
    expect(failures, greaterThan(0));
    expect(count, 400 - failures);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('stress, Db.write: 2x200 concurrent increments, no failures, none lost', () async {
    final clock = Stopwatch()..start();
    final (failures, count, codes) = await stress(immediate: true);
    // ignore: avoid_print
    print('B5 stress immediate: 2x200 increments -> failures=$failures final=$count '
        'ms=${clock.elapsedMilliseconds} codes=$codes');
    expect(failures, 0);
    expect(count, 400);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
