// Folding merged service twins on SQLite (SQLITE-PLAN-2 S2 test 4): the rules
// of service_twin_helpers.dart foldServiceTwins and the cases of
// test/helpers/service_twins_test.dart, with the messages moved by one UPDATE
// in the same write that regroups, apple_chat_guid kept, and the latest pointer
// right afterwards.
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sqlite_seed.dart';

const person = '+155****1111';

void main() {
  late Db db;
  late ChatRepo chats;
  late MessageRepo messages;
  late List<DbChanges> events;

  setUp(() {
    db = Db.memory();
    chats = ChatRepo(db);
    messages = MessageRepo(db);
    events = [];
    db.changes.listen(events.add);
  });
  tearDown(() => db.close());

  /// One-to-one chats sharing a chat identifier: SMS (1), RCS (2), iMessage (3)
  /// with [person]; a chat with someone else (4).
  Future<void> seedTwins({bool smsDeleted = false}) async {
    await db.write((tx) async {
      await chats.upsert(tx, [
        Chat(guid: 'SMS;-;$person', chatIdentifier: person, dateDeleted: smsDeleted ? at(baseMs) : null),
        Chat(guid: 'RCS;-;$person', chatIdentifier: person, isPinned: true, muteType: 'mute')..pinIndex = 2,
        Chat(guid: 'iMessage;-;$person', chatIdentifier: person, displayName: 'Karan', lockChatName: true),
        Chat(guid: 'iMessage;-;+155****2222', chatIdentifier: '+155****2222'),
      ]);
    });
    await (Seed()
          ..message(11, 1, baseMs + 1000, guid: 'sms-old')
          ..message(12, 1, baseMs + 2000, guid: 'sms-rename', itemType: 2)
          ..message(21, 2, baseMs + 3000, guid: 'rcs-mid')
          ..message(31, 3, baseMs + 5000, guid: 'imsg-newest')
          ..message(32, 3, baseMs + 4000, guid: 'imsg-own-chat-guid')
          ..message(41, 4, baseMs + 9000, guid: 'other'))
        .into(db);
    await db.write((tx) async {
      await tx.execute("UPDATE messages SET apple_chat_guid = 'iMessage;-;elsewhere' WHERE id = 32");
      // The SMS chat is listed by its rename, as a rename-only copy can be.
      await tx.execute('UPDATE chats SET latest_message_id = 12, latest_message_date_us = ? WHERE id = 1',
          [at(baseMs + 2000).microsecondsSinceEpoch]);
    });
    events.clear();
  }

  Future<List<String?>> timeline(int chatId) async => (await messages.newest([chatId])).map((m) => m.guid).toList();

  test('every twin folds into the first chat stored for its thread, in one write', () async {
    await seedTwins();
    final folded = await db.write((tx) async => chats.foldServiceTwins(tx, [(await chats.byId(2))!]));

    expect(folded.keys, unorderedEquals(['RCS;-;$person', 'iMessage;-;$person']));
    expect(folded.values.map((c) => c.id).toSet(), {1}, reason: 'one instance per thread');
    expect(await timeline(1), ['imsg-newest', 'imsg-own-chat-guid', 'rcs-mid', 'sms-rename', 'sms-old']);
    expect(await timeline(2), isEmpty);
    expect(await timeline(3), isEmpty);
    expect(await timeline(4), ['other']);
    expect(events, hasLength(1), reason: 'regroup, move and pointer are one transaction');
    expect(events.single.tables['messages'], {21, 31, 32});
  });

  test('a moved message remembers the chat it came from; one that already knew keeps it', () async {
    await seedTwins();
    await db.write((tx) async => chats.foldServiceTwins(tx, [(await chats.byId(3))!]));
    expect((await messages.byGuid('rcs-mid'))!.appleChatGuid, 'RCS;-;$person');
    expect((await messages.byGuid('imsg-newest'))!.appleChatGuid, 'iMessage;-;$person');
    expect((await messages.byGuid('imsg-own-chat-guid'))!.appleChatGuid, 'iMessage;-;elsewhere');
    expect((await messages.byGuid('sms-old'))!.appleChatGuid, isNull, reason: 'the thread\'s own messages are not touched');
  });

  test('afterwards the thread previews its newest ordinary message', () async {
    await seedTwins();
    final folded = await db.write((tx) async => chats.foldServiceTwins(tx, [(await chats.byId(2))!]));
    final thread = (await chats.byId(1))!;
    expect(thread.latestMessage?.guid, 'imsg-newest');
    expect(thread.dbOnlyLatestMessageDate, at(baseMs + 5000));
    expect(folded.values.first.dbLatestMessage.targetId, 31, reason: 'the returned thread is current');
  });

  test('thread keys are stored for every regrouped chat; non-twins keep their own', () async {
    await seedTwins();
    await db.write((tx) => chats.foldServiceTwins(tx, const []));
    final keys = [for (final id in [1, 2, 3, 4]) (await chats.byId(id))!.threadKey];
    expect(keys[0], isNotNull);
    expect(keys.sublist(0, 3).toSet(), hasLength(1));
    expect(keys[3], isNot(keys[0]));
  });

  test('the thread takes over pin, mute and a custom name, never overriding its own', () async {
    await seedTwins();
    await db.write((tx) => tx.execute("UPDATE chats SET mute_type = 'temporary_mute' WHERE id = 1"));
    await db.write((tx) => chats.foldServiceTwins(tx, const []));
    final thread = (await chats.byId(1))!;
    expect(thread.isPinned, isTrue);
    expect(thread.pinIndex, 2);
    expect(thread.muteType, 'temporary_mute');
    expect(thread.displayName, 'Karan');
    expect(thread.lockChatName, isTrue);
  });

  test('a deleted thread hands over to the next twin', () async {
    await seedTwins(smsDeleted: true);
    final folded = await db.write((tx) => chats.foldServiceTwins(tx, const []));
    expect(folded.keys, unorderedEquals(['SMS;-;$person', 'iMessage;-;$person']));
    expect(folded.values.map((c) => c.id).toSet(), {2});
    expect(await timeline(2), ['imsg-newest', 'imsg-own-chat-guid', 'rcs-mid', 'sms-rename', 'sms-old']);
  });

  test('a twin passed without a local id is found by guid', () async {
    await seedTwins();
    final folded = await db.write((tx) => chats.foldServiceTwins(tx, [Chat(guid: 'RCS;-;$person')]));
    expect(folded['RCS;-;$person']?.id, 1);
    expect(await timeline(2), isEmpty);
  });

  test('folding again changes nothing and posts nothing', () async {
    await seedTwins();
    await db.write((tx) => chats.foldServiceTwins(tx, const []));
    events.clear();
    final twins = [(await chats.byId(2))!, (await chats.byId(3))!];
    final again = await db.write((tx) => chats.foldServiceTwins(tx, twins));
    expect(again.keys, unorderedEquals(['RCS;-;$person', 'iMessage;-;$person']));
    expect(events, isEmpty);
  });

  test('a fold that fails part way leaves every chat and message where it was', () async {
    await seedTwins();
    await expectLater(
      db.write((tx) async {
        await chats.foldServiceTwins(tx, const []);
        throw StateError('stop');
      }),
      throwsStateError,
    );
    expect(await timeline(3), ['imsg-newest', 'imsg-own-chat-guid']);
    expect((await chats.byId(1))!.threadKey, isNull);
  });
}
