// Option B of PLAN-thread-copies-v2 (#3): a message's real Apple chat is
// stored once (apple_chat_guid); the chat it is filed under (chat_id, the
// thread's shown chat) is the database's, so no save path can file a message
// under a hidden copy, and a copy that leaves a thread takes its messages back.
import 'dart:io';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/contact_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:bluebubbles/database/sqlite/sync_batch_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

import 'sqlite_seed.dart';
import 'sync_batch_test.dart' show chatMap, msgMap, person;

void main() {
  late Db db;
  late ChatRepo chats;
  late MessageRepo messages;

  setUp(() {
    db = Db.memory();
    chats = ChatRepo(db);
    messages = MessageRepo(db);
  });
  tearDown(() => db.close());

  Future<(int?, String?)> filed(String guid) async {
    final row = (await db.select('SELECT chat_id, apple_chat_guid FROM messages WHERE guid = ?', [guid])).single;
    return (row['chat_id'] as int?, row['apple_chat_guid'] as String?);
  }

  Future<int> idOf(String chatGuid) async => (await chats.byGuid(chatGuid))!.id!;

  // Two copies of one 1:1 (same chat identifier) plus an unrelated chat.
  final ana = person('ana@example.com', rowId: 7);
  final imessage = chatMap('iMessage;-;ana@example.com', [ana]);
  final sms = chatMap('SMS;-;ana@example.com', [ana]);
  final other = chatMap('iMessage;-;bo@example.com', [person('bo@example.com', rowId: 8)]);

  Future<void> seedThread() async {
    await SqliteSyncBatch.bulkSyncData(db, {
      'messagesData': [
        msgMap('i1', baseMs + 1000, chat: imessage, from: ana),
        msgMap('s1', baseMs + 2000, chat: sms, from: ana),
        msgMap('o1', baseMs + 3000, chat: other),
      ],
    });
  }

  group('every save path files a message under its thread, remembering the real chat', () {
    test('sync batch', () async {
      await seedThread();
      final shown = await idOf(imessage['guid']);
      expect(await filed('i1'), (shown, imessage['guid']));
      expect(await filed('s1'), (shown, sms['guid']));
      expect(await filed('o1'), (await idOf(other['guid']), other['guid']));
    });

    test('MessageRepo.upsert with the real chat, and the caller sees where it was filed', () async {
      await seedThread();
      final m = Message(guid: 'live', dateCreated: at(baseMs + 9000), text: 'hi', isFromMe: true);
      m.chat.targetId = await idOf(sms['guid']);
      await db.write((tx) => messages.upsert(tx, [m]));
      expect(await filed('live'), (await idOf(imessage['guid']), sms['guid']));
      expect(m.chat.targetId, await idOf(imessage['guid']), reason: 'the in-memory message follows the stored row');
      expect(m.appleChatGuid, sms['guid']);
    });

    test('a full-row update that writes the real chat back is filed again', () async {
      await seedThread();
      final smsId = await idOf(sms['guid']);
      await db.write(
        (tx) => tx.execute('UPDATE messages SET chat_id = ?, text = ? WHERE guid = ?', [smsId, 'edited', 's1']),
      );
      expect(await filed('s1'), (await idOf(imessage['guid']), sms['guid']));
    });

    test('a message that arrives before its copy joins the thread is filed when it joins', () async {
      await SqliteSyncBatch.bulkSyncData(db, {
        'messagesData': [msgMap('i1', baseMs + 1000, chat: imessage, from: ana)],
      });
      final lone = Message(guid: 'early', dateCreated: at(baseMs + 500), text: 'x', isFromMe: true);
      await db.write((tx) async {
        await tx.execute(
          "INSERT INTO chats (guid, chat_identifier, text_field_attachments_json, lock_chat_name, lock_chat_icon) "
          "VALUES ('SMS;-;ana@example.com', 'other-id', '[]', 0, 0)",
        );
      });
      lone.chat.targetId = await idOf(sms['guid']);
      await db.write((tx) => messages.upsert(tx, [lone]));
      expect((await filed('early')).$1, await idOf(sms['guid']), reason: 'not in a thread yet');
      await db.write(
        (tx) => tx.execute("UPDATE chats SET chat_identifier = 'ana@example.com' WHERE guid = 'SMS;-;ana@example.com'"),
      );
      expect(await filed('early'), (await idOf(imessage['guid']), sms['guid']), reason: 'regrouped in the same write');
    });
  });

  group('regrouping files messages again, with no re-sync', () {
    test('a copy that leaves the thread takes its own messages back', () async {
      await seedThread();
      await db.write((tx) async {
        final smsId = await idOf(sms['guid']);
        await tx.execute('DELETE FROM chat_handles WHERE chat_id = ?', [smsId]);
        await tx.execute("UPDATE chats SET chat_identifier = 'someone-else' WHERE id = ?", [smsId]);
      });
      expect(await filed('s1'), (await idOf(sms['guid']), sms['guid']));
      expect((await filed('i1')).$1, await idOf(imessage['guid']));
    });

    test('deleting the shown chat files the thread under the next copy', () async {
      await seedThread();
      await db.write((tx) => tx.execute('UPDATE chats SET date_deleted_us = 1 WHERE guid = ?', [imessage['guid']]));
      expect((await filed('i1')).$1, await idOf(sms['guid']));
      expect((await filed('s1')).$1, await idOf(sms['guid']));
    });

    test('saving a stale chat from memory never moves its thread', () async {
      await seedThread();
      final stale = (await chats.byGuid(sms['guid']))!..threadKey = 'stale-key';
      await db.write((tx) => chats.upsert(tx, [stale]));
      expect((await chats.byGuid(sms['guid']))!.threadKey, (await chats.byGuid(imessage['guid']))!.threadKey);
    });

    test('putting two numbers on one contact card joins their 1:1s', () async {
      final a = person('+15550001', rowId: 1);
      final b = person('+15550002', rowId: 2);
      final one = chatMap('iMessage;-;+15550001', [a]);
      final two = chatMap('SMS;-;+15550002', [b]);
      await SqliteSyncBatch.bulkSyncData(db, {
        'messagesData': [
          msgMap('a1', baseMs + 1000, chat: one, from: a),
          msgMap('b1', baseMs + 2000, chat: two, from: b),
        ],
      });
      expect((await filed('b1')).$1, await idOf(two['guid']));

      final handles = await db.select('SELECT id FROM handles ORDER BY id');
      await db.write((tx) async {
        final card = ContactV2(nativeContactId: 'card-1', displayName: 'Ana');
        await ContactRepo(tx).upsert(tx, [card]);
        for (final h in handles) {
          await tx.execute('INSERT INTO contact_handles (contact_id, handle_id) VALUES (?, ?)', [card.id, h['id']]);
        }
      });
      expect(await filed('b1'), (await idOf(one['guid']), two['guid']));
    });
  });

  group('v5 -> v6 upgrade', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('bb_v6_'));
    tearDown(() async => dir.delete(recursive: true));

    test('backfills the real chat, files existing messages, and installs the triggers', () async {
      final file = File('${dir.path}/bluebubbles.db');
      final seedDb = Db.file(file);
      await (Seed()
            ..chat(1, guid: 'iMessage;-;ana@example.com')
            ..chat(2, guid: 'SMS;-;ana@example.com')
            ..message(1, 1, baseMs + 1000, guid: 'from-imessage')
            ..message(2, 2, baseMs + 2000, guid: 'from-sms'))
          .into(seedDb);
      await seedDb.close();

      // What a v5 build left: messages can already be filed under the shown
      // chat, but apple_chat_guid may be null; none of the v6 objects exists.
      final r = raw.sqlite3.open(file.path);
      for (final name in [
        'messages_file_insert',
        'messages_file_update',
        'chats_file_thread',
        'chats_regroup_insert',
        'chats_regroup_update',
        'chat_handles_regroup_insert',
        'chat_handles_regroup_delete',
        'contact_handles_regroup_insert',
        'contact_handles_regroup_delete',
      ]) {
        r.execute('DROP TRIGGER $name');
      }
      r.execute('DROP INDEX messages_apple_chat');
      r.execute("UPDATE chats SET thread_key = 'person:ana', chat_identifier = 'ana@example.com' WHERE id IN (1, 2)");
      r.execute('UPDATE messages SET apple_chat_guid = NULL');
      r.execute('PRAGMA user_version = 5');
      r.dispose();

      final upgraded = Db.file(file);
      addTearDown(upgraded.close);
      expect((await upgraded.select('PRAGMA user_version')).single.values.single, 7);
      final rows = await upgraded.select('SELECT guid, chat_id, apple_chat_guid FROM messages ORDER BY id');
      expect(rows, [
        {'guid': 'from-imessage', 'chat_id': 1, 'apple_chat_guid': 'iMessage;-;ana@example.com'},
        {'guid': 'from-sms', 'chat_id': 1, 'apple_chat_guid': 'SMS;-;ana@example.com'},
      ]);
      final objects = await upgraded.select(
        "SELECT type, name FROM sqlite_master WHERE name IN "
        "('messages_apple_chat', 'messages_file_insert', 'messages_file_update', 'chats_file_thread') "
        'ORDER BY name',
      );
      expect(objects.map((row) => row['name']), [
        'chats_file_thread',
        'messages_apple_chat',
        'messages_file_insert',
        'messages_file_update',
      ]);

      await upgraded.write((tx) => tx.execute('UPDATE messages SET chat_id = 2 WHERE guid = ?', ['from-sms']));
      expect(await upgraded.select("SELECT chat_id FROM messages WHERE guid = 'from-sms'"), [
        {'chat_id': 1},
      ], reason: 'the update trigger files a v5 row after upgrade');
    });
  });
}
