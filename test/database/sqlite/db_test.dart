import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

Future<void> _insertChat(WriteTx tx, int id) => tx.execute('INSERT INTO chats (id, guid) VALUES (?, ?)', [id, 'chat-$id']);

Future<int> _count(Db db, String table) async => (await db.select('SELECT count(*) AS c FROM $table')).single['c'] as int;

/// Holds the write lock of [path] for [hold], then commits; replies when it has the lock.
void _lockHolder((SendPort, String, int) args) {
  final (reply, path, holdMs) = args;
  final db = raw.sqlite3.open(path);
  db.execute('BEGIN IMMEDIATE');
  reply.send('locked');
  sleep(Duration(milliseconds: holdMs));
  db.execute('COMMIT');
  db.dispose();
  reply.send('released');
}

void main() {
  // One connection per isolate is the design; these tests open several on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Db db;

  setUp(() => db = Db.memory());
  tearDown(() => db.close());

  test('write commits and reports the changed rows per table, once', () async {
    final events = <DbChanges>[];
    db.changes.listen(events.add);

    await db.write((tx) async {
      await _insertChat(tx, 1);
      await _insertChat(tx, 2);
      await tx.execute("INSERT INTO handles (id, address, unique_address_and_service, service) VALUES (5, 'a', 'a/x', 'x')");
      await tx.execute('UPDATE chats SET display_name = ? WHERE id = 2', ['n']);
    });

    expect(await _count(db, 'chats'), 2);
    expect(events, hasLength(1));
    expect(events.single.tables, {
      'chats': {1, 2},
      'handles': {5},
    });
  });

  test('write rolls back when its body throws, and reports nothing', () async {
    final events = <DbChanges>[];
    db.changes.listen(events.add);

    await expectLater(
      db.write((tx) async {
        await _insertChat(tx, 1);
        throw StateError('boom');
      }),
      throwsStateError,
    );

    expect(await _count(db, 'chats'), 0);
    expect(events, isEmpty);
    // The connection is usable again.
    await db.write((tx) => _insertChat(tx, 3));
    expect(events.single.tables, {
      'chats': {3},
    });
  });

  test('a write that changes nothing posts no event; marked join-table rows are reported', () async {
    final events = <DbChanges>[];
    db.changes.listen(events.add);
    await db.write((tx) async => db.select('SELECT 1'));
    expect(events, isEmpty);

    await db.write((tx) async {
      await _insertChat(tx, 1);
      await tx.execute("INSERT INTO handles (id, address, unique_address_and_service, service) VALUES (5, 'a', 'a/x', 'x')");
      // chat_handles is WITHOUT ROWID: SQLite's update hook does not see it.
      await tx.execute('INSERT INTO chat_handles (chat_id, handle_id) VALUES (1, 5)');
      tx.markChanged('chat_handles', [1]);
    });
    expect(events.single.tables['chat_handles'], {1});
  });

  test('the statements are BEGIN IMMEDIATE ... COMMIT, a nested write joins the outer one', () async {
    final events = <DbChanges>[];
    db.changes.listen(events.add);
    await db.write((tx) async {
      await _insertChat(tx, 1);
      await db.write((inner) async {
        expect(identical(inner, tx), isTrue);
        await _insertChat(inner, 2);
      });
      final inTx = await db.select('SELECT count(*) AS c FROM chats');
      expect(inTx.single['c'], 2);
    });
    expect(events, hasLength(1));
    expect(events.single.tables['chats'], {1, 2});
  });

  test('read sees its own consistent snapshot and refuses a write inside it', () async {
    await db.write((tx) => _insertChat(tx, 1));
    final n = await db.read((r) async => (await r.select('SELECT count(*) AS c FROM chats')).single['c']);
    expect(n, 1);
    await expectLater(db.read((r) => db.write((tx) => _insertChat(tx, 2))), throwsStateError);
    expect(await _count(db, 'chats'), 1);
  });

  test('a slow read on a file database does not block this isolate', () async {
    final directory = await Directory.systemTemp.createTemp('bb_db_background_');
    addTearDown(() => directory.delete(recursive: true));
    final fileDb = Db.file(File('${directory.path}/bluebubbles.db'));
    addTearDown(fileDb.close);
    await fileDb.select('SELECT 1'); // opened, schema made

    final clock = Stopwatch()..start();
    var done = false;
    final slow = fileDb
        .select('WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n WHERE i < 3000000) SELECT count(*) AS c FROM n')
        .whenComplete(() => done = true);
    // The screen draws on this isolate: a timer here must keep firing on time.
    var worstGap = 0;
    var last = clock.elapsedMilliseconds;
    while (!done) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final now = clock.elapsedMilliseconds;
      if (now - last > worstGap) worstGap = now - last;
      last = now;
    }
    expect((await slow).single['c'], 3000000);
    // ignore: avoid_print
    print('Db background: read took ${clock.elapsedMilliseconds}ms, worst timer gap ${worstGap}ms');
    expect(clock.elapsedMilliseconds, greaterThan(200), reason: 'the read must be slow enough to matter');
    expect(worstGap, lessThan(100));
  });

  test('writes to a file database report their changed rows', () async {
    final directory = await Directory.systemTemp.createTemp('bb_db_changes_');
    addTearDown(() => directory.delete(recursive: true));
    final fileDb = Db.file(File('${directory.path}/bluebubbles.db'));
    addTearDown(fileDb.close);
    final events = <DbChanges>[];
    fileDb.changes.listen(events.add);

    await fileDb.write((tx) async {
      await _insertChat(tx, 1);
      await tx.execute('UPDATE chats SET display_name = ? WHERE id = 1', ['n']);
    });
    await expectLater(fileDb.write((tx) async {
      await _insertChat(tx, 2);
      throw StateError('boom');
    }), throwsStateError);
    await fileDb.write((tx) => _insertChat(tx, 3));

    expect(events.map((e) => e.tables), [
      {'chats': {1}},
      {'chats': {3}},
    ]);
  });

  test('a failed statement on a file database throws the SqliteException itself', () async {
    final directory = await Directory.systemTemp.createTemp('bb_db_errors_');
    addTearDown(() => directory.delete(recursive: true));
    final fileDb = Db.file(File('${directory.path}/bluebubbles.db'));
    addTearDown(fileDb.close);
    await fileDb.write((tx) => _insertChat(tx, 1));
    await expectLater(fileDb.write((tx) => _insertChat(tx, 1)),
        throwsA(isA<SqliteException>().having((e) => e.extendedResultCode, 'extendedResultCode', anyOf(1555, 2067))));
  });

  test('a write that stays busy past busy_timeout is retried once and then succeeds', () async {
    final directory = await Directory.systemTemp.createTemp('bb_db_retry_');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/bluebubbles.db';
    final fileDb = Db.file(File(path));
    addTearDown(fileDb.close);
    await fileDb.write((tx) => _insertChat(tx, 1)); // creates the schema

    final replies = ReceivePort();
    final events = StreamIterator(replies);
    // Longer than one busy_timeout, shorter than two.
    await Isolate.spawn(_lockHolder, (replies.sendPort, path, Db.busyTimeoutMs + 2000));
    await events.moveNext();
    expect(events.current, 'locked');

    var attempts = 0;
    final clock = Stopwatch()..start();
    await fileDb.write((tx) async {
      attempts++;
      await _insertChat(tx, 2);
    });
    await events.moveNext();
    await events.cancel();
    // ignore: avoid_print
    print('Db retry: waited ${clock.elapsedMilliseconds}ms, attempts=$attempts');
    expect(attempts, 1, reason: 'BEGIN IMMEDIATE failed before the body ran, so the body ran once');
    expect(clock.elapsedMilliseconds, greaterThan(Db.busyTimeoutMs));
    expect(await _count(fileDb, 'chats'), 2);
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('a write busy for longer than two timeouts fails with SQLITE_BUSY', () async {
    final directory = await Directory.systemTemp.createTemp('bb_db_busy_');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/bluebubbles.db';
    final fileDb = Db.file(File(path));
    addTearDown(fileDb.close);
    await fileDb.write((tx) => _insertChat(tx, 1));

    final replies = ReceivePort();
    final events = StreamIterator(replies);
    await Isolate.spawn(_lockHolder, (replies.sendPort, path, 2 * Db.busyTimeoutMs + 1500));
    await events.moveNext();

    await expectLater(
      fileDb.write((tx) => _insertChat(tx, 2)),
      throwsA(isA<SqliteException>().having((e) => e.resultCode, 'resultCode', 5)),
    );
    await events.moveNext();
    await events.cancel();
    expect(await _count(fileDb, 'chats'), 1);
  }, timeout: const Timeout(Duration(seconds: 40)));
}
