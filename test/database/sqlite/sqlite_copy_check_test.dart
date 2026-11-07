import 'dart:async';
import 'dart:io';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/app_database.dart';
import 'package:bluebubbles/database/sqlite/objectbox_sqlite_copy.dart';
import 'package:bluebubbles/database/sqlite/sqlite_copy_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late Store store;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('bb_copy_check_');
    store = Store(getObjectBoxModel(), directory: '${directory.path}/objectbox');
    final chat = Chat(guid: 'iMessage;-;secret-chat');
    store.box<Chat>().put(chat);
    for (var i = 0; i < 25; i++) {
      final m = Message(guid: 'g$i', text: 'SECRET TEXT $i', dateCreated: DateTime.fromMillisecondsSinceEpoch(1700000000000 + i));
      m.chat.target = chat;
      store.box<Message>().put(m);
    }
  });

  tearDown(() {
    store.close();
    directory.deleteSync(recursive: true);
  });

  test('copy check writes bluebubbles.db, verifies, and logs BBSQL lines without message content', () async {
    final lines = <String>[];
    final file = File('${directory.path}/bluebubbles.db');

    final ok = await runSqliteCopyCheck(store: store, file: file, log: lines.add, batchSize: 10);

    expect(ok, isTrue);
    expect(file.existsSync(), isTrue);
    expect(lines.first, startsWith('BBSQL start'));
    expect(lines.where((l) => l.startsWith('BBSQL copied')), hasLength(1));
    expect(lines.singleWhere((l) => l.startsWith('BBSQL verify')), contains('ok=true'));
    expect(lines.last, startsWith('BBSQL done'));
    expect(lines.last, contains('rssMb='));
    expect(lines.last, contains('fileMb='));
    expect(lines.every((l) => l.startsWith('BBSQL ')), isTrue);
    expect(lines.join('\n'), isNot(contains('SECRET')));
    expect(lines.join('\n'), isNot(contains('secret-chat')));

    final database = AppDatabase.file(file);
    addTearDown(database.close);
    final count = await database.customSelect('SELECT count(*) AS c FROM messages').getSingle();
    expect(count.read<int>('c'), 25);
  });

  test('the copy runs on its own isolate attached to the open store', () async {
    final path = '${directory.path}/bluebubbles.db';
    final ok = await runSqliteCopyCheckInIsolate(objectBoxPath: '${directory.path}/objectbox', sqlitePath: path);
    expect(ok, isTrue);

    final database = AppDatabase.file(File(path));
    addTearDown(database.close);
    final count = await database.customSelect('SELECT count(*) AS c FROM messages').getSingle();
    expect(count.read<int>('c'), 25);
    // The app's store is still open and usable.
    expect(store.box<Message>().count(), 25);
  });

  test('a later launch after a verified copy does not read ObjectBox at all', () async {
    final file = File('${directory.path}/bluebubbles.db');
    expect(await runSqliteCopyCheck(store: store, file: file, log: (_) {}), isTrue);
    // Reading the whole message box on every launch kept ~700 MB of ObjectBox
    // resident on the phone. A closed store throws on any read.
    store.close();
    final lines = <String>[];
    expect(await runSqliteCopyCheck(store: store, file: file, log: lines.add), isTrue);
    expect(lines, hasLength(1));
    expect(lines.single, startsWith('BBSQL skip: copy verified'));
    store = Store(getObjectBoxModel(), directory: '${directory.path}/objectbox');
  });

  test('after giving up, a launch logs the stored check result and does not read ObjectBox', () async {
    final file = File('${directory.path}/bluebubbles.db');
    final database = AppDatabase.file(file);
    await database.customStatement(
        "INSERT INTO storage_meta (key, value) VALUES ('check_version', '$copyCheckVersion'), ('copy_state', 'verify_failed'), "
        "('verify_failures', '2'), ('verify_result', '{\"ok\":false,\"mismatches\":[\"messages 7 date_edited_us\"]}')");
    await database.close();
    store.close();

    final lines = <String>[];
    expect(await runSqliteCopyCheck(store: store, file: file, log: lines.add), isFalse);
    expect(lines, contains('BBSQL skip: verification failed 2 times, not retrying'));
    expect(lines, contains('BBSQL last verify {"ok":false,"mismatches":["messages 7 date_edited_us"]}'));
    expect(lines.where((l) => l.startsWith('BBSQL error')), isEmpty);
    store = Store(getObjectBoxModel(), directory: '${directory.path}/objectbox');
  });

  test('a file from before check versions existed is checked again from scratch', () async {
    final file = File('${directory.path}/bluebubbles.db');
    final database = AppDatabase.file(file);
    await database.customStatement(
        "INSERT INTO storage_meta (key, value) VALUES ('copy_state', 'verify_failed'), ('verify_failures', '2')");
    await database.close();

    final lines = <String>[];
    expect(await runSqliteCopyCheck(store: store, file: file, log: lines.add), isTrue);
    expect(lines.singleWhere((l) => l.startsWith('BBSQL start')), contains('mode=recheck'));
    expect(lines.singleWhere((l) => l.startsWith('BBSQL verify')), contains('ok=true'));
  });

  test('a newer check version copies and checks again, even after an earlier version gave up', () async {
    final file = File('${directory.path}/bluebubbles.db');
    expect(await runSqliteCopyCheck(store: store, file: file, log: (_) {}, checkVersion: 1), isTrue);
    final database = AppDatabase.file(file);
    await database.customStatement(
        "INSERT OR REPLACE INTO storage_meta (key, value) VALUES ('copy_state', 'verify_failed'), ('verify_failures', '2')");
    await database.close();

    final lines = <String>[];
    expect(await runSqliteCopyCheck(store: store, file: file, log: lines.add, checkVersion: 2), isTrue);
    expect(lines.first, startsWith('BBSQL previous verify (check v1) {"ok":true'));
    expect(lines.singleWhere((l) => l.startsWith('BBSQL start')), contains('mode=recheck'));
    expect(lines.singleWhere((l) => l.startsWith('BBSQL copied')), contains('messages=25'));
    expect(lines.singleWhere((l) => l.startsWith('BBSQL verify')), contains('ok=true'));

    final reopened = AppDatabase.file(file);
    addTearDown(reopened.close);
    expect((await readStorageMeta(reopened))['check_version'], '2');

    final again = <String>[];
    expect(await runSqliteCopyCheck(store: store, file: file, log: again.add, checkVersion: 2), isTrue);
    expect(again.single, startsWith('BBSQL skip: copy verified'));
  });

  test('an error is logged as one line without statement parameters and reported as not ok', () async {
    final lines = <String>[];
    // A directory where the database file should be: SQLite cannot open it.
    Directory('${directory.path}/bluebubbles.db').createSync();
    final ok = await runSqliteCopyCheck(store: store, file: File('${directory.path}/bluebubbles.db'), log: lines.add);
    expect(ok, isFalse);
    expect(lines.where((l) => l.startsWith('BBSQL error')), hasLength(1));
    expect(lines.join('\n'), isNot(contains('SECRET')));
  });

  test('the background runner starts once, never concurrently, and only where enabled', () async {
    var runs = 0;
    final gate = Completer<void>();
    final runner = SqliteCopyCheckRunner(
      enabled: () => true,
      body: () async {
        runs++;
        await gate.future;
      },
    );
    final first = runner.start();
    final second = runner.start();
    expect(runner.isRunning, isTrue);
    gate.complete();
    await Future.wait(<Future<void>>[first, second]);
    await runner.start();
    expect(runs, 1);

    var disabledRuns = 0;
    final disabled = SqliteCopyCheckRunner(enabled: () => false, body: () async => disabledRuns++);
    await disabled.start();
    expect(disabledRuns, 0);
  });

  test('the runner swallows body errors so the caller (sync) is never affected', () async {
    final runner = SqliteCopyCheckRunner(enabled: () => true, body: () async => throw StateError('boom'));
    await expectLater(runner.start(), completes);
    expect(runner.isRunning, isFalse);
  });

  test('the copy check starts in the background once the startup sync has finished', () {
    final source = File('lib/services/backend/sync/sync_service.dart').readAsStringSync();
    final finished = source.indexOf('isIncrementalSyncing.value = false;');
    final start = source.indexOf('unawaited(SqliteCopyCheck.instance.start());');
    expect(finished, greaterThan(0));
    expect(start, greaterThan(finished), reason: 'starts after the sync is marked finished, without awaiting it');
    expect(source.substring(finished, start), contains('!chatSyncFailed'));
  });
}
