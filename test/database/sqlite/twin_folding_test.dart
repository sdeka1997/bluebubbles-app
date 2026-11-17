// Service twins on SQLite: the write that stores a thread's chats regroups
// them (ChatRepo.regroupIfPending before commit), the database files every
// message under the thread's first chat with its Apple chat kept
// (threadFilingTriggers), and the thread takes over its twins' settings.
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
        Chat(guid: 'SMS;-;$person', chatIdentifier: person, muteType: 'temporary_mute', dateDeleted: smsDeleted ? at(baseMs) : null),
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
    await db.write((tx) => tx.execute("UPDATE messages SET apple_chat_guid = 'iMessage;-;elsewhere' WHERE id = 32"));
    events.clear();
  }

  Future<List<String?>> timeline(int chatId) async => (await messages.newest([chatId])).map((m) => m.guid).toList();

  test('every twin is filed under the first chat stored for its thread', () async {
    await seedTwins();
    expect(await timeline(1), ['imsg-newest', 'imsg-own-chat-guid', 'rcs-mid', 'sms-rename', 'sms-old']);
    expect(await timeline(2), isEmpty);
    expect(await timeline(3), isEmpty);
    expect(await timeline(4), ['other']);
  });

  test('every message remembers the Apple chat it came through', () async {
    await seedTwins();
    expect((await messages.byGuid('rcs-mid'))!.appleChatGuid, 'RCS;-;$person');
    expect((await messages.byGuid('imsg-newest'))!.appleChatGuid, 'iMessage;-;$person');
    expect((await messages.byGuid('imsg-own-chat-guid'))!.appleChatGuid, 'iMessage;-;elsewhere');
    expect((await messages.byGuid('sms-old'))!.appleChatGuid, 'SMS;-;$person');
  });

  test('the thread previews its newest ordinary message', () async {
    await seedTwins();
    final thread = (await chats.byId(1))!;
    expect(thread.latestMessage?.guid, 'imsg-newest');
    expect(thread.dbOnlyLatestMessageDate, at(baseMs + 5000));
  });

  test('thread keys are stored for every chat; non-twins keep their own', () async {
    await seedTwins();
    final keys = [for (final id in [1, 2, 3, 4]) (await chats.byId(id))!.threadKey];
    expect(keys[0], isNotNull);
    expect(keys.sublist(0, 3).toSet(), hasLength(1));
    expect(keys[3], isNot(keys[0]));
  });

  test('the thread takes over pin and a custom name, never overriding its own', () async {
    await seedTwins();
    final thread = (await chats.byId(1))!;
    expect(thread.isPinned, isTrue);
    expect(thread.pinIndex, 2);
    expect(thread.muteType, 'temporary_mute');
    expect(thread.displayName, 'Karan');
    expect(thread.lockChatName, isTrue);
  });

  test('a deleted thread hands over to the next twin', () async {
    await seedTwins(smsDeleted: true);
    expect(await timeline(2), ['imsg-newest', 'imsg-own-chat-guid', 'rcs-mid', 'sms-rename', 'sms-old']);
  });

  test('regrouping again changes nothing and posts nothing', () async {
    await seedTwins();
    final again = await db.write((tx) => chats.regroupThreads(tx));
    expect(again, isEmpty);
    expect(events, isEmpty);
  });

  test('a write that fails part way leaves every chat and message where it was', () async {
    await seedTwins();
    await expectLater(
      db.write((tx) async {
        await tx.execute("UPDATE chats SET chat_identifier = 'someone-else' WHERE id = 2");
        await chats.regroupThreads(tx);
        throw StateError('stop');
      }),
      throwsStateError,
    );
    expect(await timeline(1), ['imsg-newest', 'imsg-own-chat-guid', 'rcs-mid', 'sms-rename', 'sms-old']);
    expect(await timeline(2), isEmpty);
  });
}
