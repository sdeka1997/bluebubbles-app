// The latest pointer is the database's (latestPointerTriggers in
// app_database.dart): every write that adds, removes, moves or retypes a
// message re-points its chat, whichever code path made it.
import 'dart:io';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:bluebubbles/database/sqlite/storage.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

import 'sqlite_seed.dart';

void main() {
  setUpAll(() {
    if (!GetIt.I.isRegistered<BaseLogger>()) GetIt.I.registerSingleton<BaseLogger>(BaseLogger());
  });

  late Db db;
  late ChatRepo chats;

  setUp(() {
    db = Db.memory();
    chats = ChatRepo(db);
  });
  tearDown(() => db.close());

  Future<String?> latest(int chatId) async => (await chats.byId(chatId))!.latestMessage?.guid;
  Future<void> run(String sql, [List<Object?> args = const []]) => db.write((tx) => tx.execute(sql, args));

  test('a stored message becomes the preview; an older one does not', () async {
    await (Seed()
          ..chat(1)
          ..message(1, 1, baseMs + 2000, guid: 'newer')
          ..message(2, 1, baseMs + 1000, guid: 'older'))
        .into(db);
    expect(await latest(1), 'newer');
    expect((await chats.byId(1))!.dbOnlyLatestMessageDate, at(baseMs + 2000));
  });

  test('status items, deleted rows and group-photo state never list a thread', () async {
    await (Seed()
          ..chat(1)
          ..message(1, 1, baseMs + 1000, guid: 'text')
          ..message(2, 1, baseMs + 2000, guid: 'rename', itemType: 2)
          ..message(3, 1, baseMs + 3000, guid: 'photo', itemType: 3, groupActionType: 3)
          ..message(4, 1, baseMs + 4000, guid: 'gone', deleted: true)
          ..message(5, 1, baseMs + 5000, guid: 'reaction-is-ordinary', reactionTo: 'text'))
        .into(db);
    expect(await latest(1), 'reaction-is-ordinary');
    await run('DELETE FROM messages WHERE id = 5');
    expect(await latest(1), 'text');
  });

  test('a thread holding only status items lists nothing', () async {
    await (Seed()
          ..chat(1)
          ..message(1, 1, baseMs + 1000, guid: 'text')
          ..message(2, 1, baseMs + 2000, guid: 'removed', itemType: 1))
        .into(db);
    await run('DELETE FROM messages WHERE id = 1');
    final c = (await chats.byId(1))!;
    expect(c.latestMessage, isNull);
    expect(c.dbOnlyLatestMessageDate, isNull);
  });

  test('delete, unsend (soft delete) and undo re-point the chat', () async {
    await (Seed()
          ..chat(1)
          ..message(1, 1, baseMs + 1000, guid: 'a')
          ..message(2, 1, baseMs + 2000, guid: 'b'))
        .into(db);
    await run('UPDATE messages SET date_deleted_us = 1 WHERE id = 2');
    expect(await latest(1), 'a');
    await run('UPDATE messages SET date_deleted_us = NULL WHERE id = 2');
    expect(await latest(1), 'b');
  });

  test('moving messages re-points both chats', () async {
    await (Seed()
          ..chat(1)
          ..chat(2)
          ..message(1, 1, baseMs + 1000, guid: 'stays')
          ..message(2, 1, baseMs + 3000, guid: 'moves')
          ..message(3, 2, baseMs + 2000, guid: 'twin'))
        .into(db);
    await run("UPDATE messages SET apple_chat_guid = 'chat-2' WHERE id = 2");
    expect(await latest(1), 'stays');
    expect(await latest(2), 'moves');
  });

  test('retyping a row and re-dating it re-point the chat', () async {
    await (Seed()
          ..chat(1)
          ..message(1, 1, baseMs + 1000, guid: 'a')
          ..message(2, 1, baseMs + 2000, guid: 'b'))
        .into(db);
    await run('UPDATE messages SET item_type = 2 WHERE id = 2');
    expect(await latest(1), 'a');
    await run('UPDATE messages SET item_type = 0, sort_at_us = ? WHERE id = 2', [at(baseMs).microsecondsSinceEpoch]);
    expect(await latest(1), 'a', reason: 'newest is the last row of the chat screen, by sort_at');
  });

  test('a message saved through the repository re-points its chat', () async {
    await (Seed()
          ..chat(1)
          ..message(1, 1, baseMs + 1000, guid: 'a'))
        .into(db);
    final fresh = Message(guid: 'fresh', dateCreated: at(baseMs + 5000), text: 'fresh', isFromMe: true);
    fresh.chat.targetId = 1;
    await db.write((tx) => MessageRepo(tx).upsert(tx, [fresh]));
    expect(await latest(1), 'fresh');
  });

  test('saving a chat from memory never moves its pointer', () async {
    await (Seed()
          ..chat(1)
          ..message(1, 1, baseMs + 1000, guid: 'a')
          ..message(2, 1, baseMs + 2000, guid: 'b'))
        .into(db);
    final stale = (await chats.byId(1))!
      ..dbLatestMessage.targetId = 1
      ..dbOnlyLatestMessageDate = at(baseMs + 1000);
    await db.write((tx) => chats.upsert(tx, [stale]));
    expect(await latest(1), 'b');
    expect((await chats.byId(1))!.dbOnlyLatestMessageDate, at(baseMs + 2000));
  });

  test('a write that does not touch the listing columns does not re-point', () async {
    await (Seed()
          ..chat(1)
          ..message(1, 1, baseMs + 1000, guid: 'a'))
        .into(db);
    await db.write((tx) async {}); // the seed's chats regroup on the first write
    final statements = await db.recordStatements(() => run("UPDATE messages SET text = 'edited' WHERE id = 1"));
    expect(statements.where((s) => s.$1.contains('UPDATE chats')), isEmpty);
    expect(await latest(1), 'a');
  });

  group('v4 -> v5 upgrade', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('bb_v5_'));
    tearDown(() async {
      await closeStorage();
      await dir.delete(recursive: true);
    });

    test('recomputes every pointer, installs the triggers, keeps only provable unread', () async {
      final file = File('${dir.path}/bluebubbles.db');
      final seedDb = Db.file(file);
      await (Seed()
            ..chat(1, unread: true)
            ..message(11, 1, baseMs + 1000, guid: 'one-read', isFromMe: false, readMs: baseMs + 1500)
            ..message(12, 1, baseMs + 9000, guid: 'one-photo', itemType: 3, groupActionType: 3)
            ..chat(2, unread: true)
            ..message(21, 2, baseMs + 3000, guid: 'two-unread', isFromMe: false)
            ..message(22, 2, baseMs + 7000, guid: 'two-photo', itemType: 3, groupActionType: 3)
            ..chat(3)
            ..message(31, 3, baseMs + 2000, guid: 'three-text'))
          .into(seedDb);
      await seedDb.close();
      // What a v4 build left: no triggers, pointers at whatever it last wrote.
      final r = raw.sqlite3.open(file.path);
      for (final name in ['messages_latest_insert', 'messages_latest_delete', 'messages_latest_update']) {
        r.execute('DROP TRIGGER $name');
      }
      r.execute('DROP INDEX messages_listing');
      r.execute('UPDATE chats SET latest_message_id = 12 WHERE id = 1');
      r.execute('UPDATE chats SET latest_message_id = 22 WHERE id = 2');
      r.execute('UPDATE chats SET latest_message_id = NULL, latest_message_date_us = NULL WHERE id = 3');
      r.execute('PRAGMA user_version = 4');
      r.dispose();

      final store = await openStorage(dir, onMain: false);
      final repo = ChatRepo(store.db);
      expect((await store.db.select('PRAGMA user_version')).single.values.single, 7);
      final page = await repo.listPage();
      expect(page.map((c) => c.latestMessage?.guid), ['two-unread', 'three-text', 'one-read']);
      expect(page.map((c) => c.hasUnreadMessage), [true, false, false]);
      final triggerNames = (await store.db.select(
        "SELECT name FROM sqlite_master WHERE type = 'trigger' AND name LIKE 'messages_latest_%' ORDER BY name",
      ))
          .map((row) => row['name'])
          .toList();
      expect(triggerNames, ['messages_latest_delete', 'messages_latest_insert', 'messages_latest_update']);

      await store.db.write((tx) => tx.execute('DELETE FROM messages WHERE id = 21'));
      expect((await repo.byId(2))!.latestMessage, isNull, reason: 'the triggers run after the upgrade');
    });
  });
}
