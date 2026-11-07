import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/handle_repo.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sqlite_seed.dart';

List<String?> guids(List<Message> messages) => messages.map((m) => m.guid).toList();

void main() {
  late Db db;
  late MessageRepo messages;
  late ChatRepo chats;
  late HandleRepo handles;
  late AttachmentRepo attachments;

  setUp(() async {
    db = Db.memory();
    messages = MessageRepo(db);
    chats = ChatRepo(db);
    handles = HandleRepo(db);
    attachments = AttachmentRepo(db);
  });
  tearDown(() => db.close());

  group('MessageRepo timeline', () {
    test('newest: the chat screen rows only, newest first, with attachments', () async {
      final seed = Seed()
        ..chat(1)
        ..chat(2);
      for (var i = 1; i <= 10; i++) {
        seed.message(i, 1, baseMs + i * 1000);
      }
      seed
        ..message(11, 1, baseMs + 11000, reactionTo: 'm10') // reaction: not a timeline row
        ..message(12, 1, baseMs + 12000, deleted: true) // deleted
        ..message(13, 2, baseMs + 13000) // other chat
        ..attachment(1, 9)
        ..attachment(2, 9)
        ..attachment(3, 13);
      await seed.into(db);

      final page = await messages.newest([1], limit: 4);
      expect(guids(page), ['m10', 'm9', 'm8', 'm7']);
      expect(page[1].dbAttachments.map((a) => a.guid), ['a1', 'a2']);
      expect(page[0].dbAttachments, isEmpty);
      expect(page.first.chat.targetId, 1);

      final withDeleted = await messages.newest([1], limit: 2, includeDeleted: true);
      expect(guids(withDeleted), ['m12', 'm10']);
    });

    test('a received message whose sender this chat cannot place is left out, as today', () async {
      final seed = Seed()
        ..handle(1, address: '+1555', originalRowId: 50)
        ..chat(1, handles: [1])
        ..chat(2) // no participants: nothing is filtered
        ..message(1, 1, baseMs + 1000, isFromMe: false, handleId: 50, originalRowId: 901) // sender known by ROWID
        ..message(2, 1, baseMs + 2000, isFromMe: false, handleId: 77, originalRowId: 902) // unknown sender: dropped
        ..message(3, 1, baseMs + 3000, isFromMe: false, handleId: 77, originalRowId: 903, handleRelationId: 1) // linked
        ..message(4, 1, baseMs + 4000, isFromMe: false, handleId: 77) // never on the server (no ROWID): kept
        ..message(5, 1, baseMs + 5000, handleId: 77, originalRowId: 905) // from me: kept
        ..message(6, 2, baseMs + 6000, isFromMe: false, handleId: 77, originalRowId: 906); // chat without participants
      await seed.into(db);

      expect(guids(await messages.newest([1])), ['m5', 'm4', 'm3', 'm1']);
      expect(guids(await messages.newest([2])), ['m6']);
    });

    test('olderThan / newerThan page by (sort_at, id) and return newest first', () async {
      final seed = Seed()..chat(1);
      for (var i = 1; i <= 10; i++) {
        seed.message(i, 1, baseMs + i * 1000);
      }
      await seed.into(db);

      final m6 = (await messages.byId(6))!;
      expect(guids(await messages.olderThan([1], MessageKey.of(m6), limit: 3)), ['m5', 'm4', 'm3']);
      expect(guids(await messages.newerThan([1], MessageKey.of(m6), limit: 3)), ['m9', 'm8', 'm7']);
      expect(guids(await messages.olderThan([1], MessageKey.of((await messages.byId(1))!))), isEmpty);
    });

    test('around: the target once with N each side; a key that is not a row still centres', () async {
      final seed = Seed()..chat(1);
      for (var i = 1; i <= 9; i++) {
        seed.message(i, 1, baseMs + i * 1000);
      }
      await seed.into(db);

      final m5 = (await messages.byId(5))!;
      expect(guids(await messages.around([1], MessageKey.of(m5), before: 2, after: 2)), ['m7', 'm6', 'm5', 'm4', 'm3']);
      final between = MessageKey(MessageKey.of(m5).sortAtUs + 1, 0);
      expect(guids(await messages.around([1], between, before: 1, after: 1)), ['m6', 'm5']);
    });
  });

  group('MessageRepo lookups', () {
    test('reactionsFor: every associated message of the guids, by server ROWID', () async {
      final seed = Seed()..chat(1);
      seed
        ..message(1, 1, baseMs + 1000)
        ..message(2, 1, baseMs + 2000)
        ..message(3, 1, baseMs + 3000, reactionTo: 'm1', originalRowId: 30)
        ..message(4, 1, baseMs + 4000, reactionTo: 'm2', originalRowId: 10)
        ..message(5, 1, baseMs + 5000, reactionTo: 'm1', originalRowId: 20)
        ..message(6, 1, baseMs + 6000, reactionTo: 'other');
      await seed.into(db);

      expect(guids(await messages.reactionsFor(['m1', 'm2'])), ['m4', 'm5', 'm3']);
      expect(await messages.reactionsFor([]), isEmpty);
    });

    test('byGuid / byId return the message with its attachments, null when missing', () async {
      final seed = Seed()
        ..chat(1)
        ..message(1, 1, baseMs, text: 'hello')
        ..attachment(7, 1);
      await seed.into(db);

      final m = (await messages.byGuid('m1'))!;
      expect(m.id, 1);
      expect(m.text, 'hello');
      expect(m.dbAttachments.single.guid, 'a7');
      expect((await messages.byId(1))!.guid, 'm1');
      expect(await messages.byGuid('nope'), isNull);
      expect(await messages.byId(99), isNull);
    });

    test('thread: originator plus replies, oldest first, no reactions or deleted', () async {
      final seed = Seed()
        ..chat(1)
        ..message(1, 1, baseMs + 1000)
        ..message(2, 1, baseMs + 3000, threadOriginator: 'm1')
        ..message(3, 1, baseMs + 2000, threadOriginator: 'm1')
        ..message(4, 1, baseMs + 4000, threadOriginator: 'm1', reactionTo: 'm2')
        ..message(5, 1, baseMs + 5000, threadOriginator: 'm1', deleted: true)
        ..message(6, 1, baseMs + 6000, threadOriginator: 'other');
      await seed.into(db);

      expect(guids(await messages.thread('m1')), ['m1', 'm3', 'm2']);
    });
  });

  group('ChatRepo', () {
    Future<void> seedChats() async {
      final seed = Seed()
        ..contact(1, 'Ana')
        ..handle(1, address: '+1001', contacts: [1])
        ..handle(2, address: '+1002')
        ..chat(1, guid: 'c-one', latestMessageId: 11, latestMs: baseMs + 1000, handles: [2, 1])
        ..chat(2, latestMs: baseMs + 3000, latestMessageId: 99) // pointer to a message that is gone
        ..chat(3, latestMs: baseMs + 2000)
        ..chat(4, latestMs: baseMs + 9000, deleted: true)
        ..chat(5) // no messages yet
        ..chat(6, latestMs: baseMs + 3000)
        ..message(11, 1, baseMs + 1000, text: 'latest');
      await seed.into(db);
    }

    test('byId / byGuid fill participants with their contacts and the latest message', () async {
      await seedChats();
      final chat = (await chats.byGuid('c-one'))!;
      expect(chat.id, 1);
      expect(chat.handles.map((h) => h.address), ['+1001', '+1002']);
      expect(chat.participants.map((h) => h.id), [1, 2]);
      expect(chat.handles.first.contactsV2.single.displayName, 'Ana');
      expect(chat.handles.last.contactsV2, isEmpty);
      expect(chat.latestMessage?.text, 'latest');
      expect(chat.dbLatestMessage.targetId, 11);

      final dangling = (await chats.byId(2))!;
      expect(dangling.latestMessage, isNull);
      expect(dangling.handles, isEmpty);
      expect(await chats.byId(42), isNull);
    });

    test('listPage: not deleted, newest latest message first, undated last, pages by key', () async {
      await seedChats();
      expect((await chats.listPage()).map((c) => c.id), [6, 2, 3, 1, 5]);

      final ids = <int>[];
      ChatListKey? after;
      while (true) {
        final page = await chats.listPage(after: after, limit: 2);
        if (page.isEmpty) break;
        ids.addAll(page.map((c) => c.id!));
        after = ChatListKey.of(page.last);
      }
      expect(ids, [6, 2, 3, 1, 5]);
    });
  });

  group('HandleRepo / AttachmentRepo', () {
    test('handles by id and by address + service, with contacts', () async {
      final seed = Seed()
        ..contact(1, 'Ana')
        ..contact(2, 'Ana work')
        ..handle(1, address: '+1001', contacts: [1, 2])
        ..handle(2, address: '+1001', service: 'SMS');
      await seed.into(db);

      expect((await handles.byId(1))!.contactsV2.map((c) => c.displayName), unorderedEquals(['Ana', 'Ana work']));
      expect((await handles.byUniqueKey('+1001', 'SMS'))!.id, 2);
      expect((await handles.byUniqueKey('+1001', 'iMessage'))!.contactsV2, hasLength(2));
      expect(await handles.byUniqueKey('+1999', 'SMS'), isNull);
      expect(await handles.byId(9), isNull);
    });

    test('attachments by guid and per message', () async {
      final seed = Seed()
        ..chat(1)
        ..message(1, 1, baseMs)
        ..message(2, 1, baseMs + 1)
        ..attachment(3, 1)
        ..attachment(1, 1)
        ..attachment(2, 2);
      await seed.into(db);

      expect((await attachments.byGuid('a2'))!.message.targetId, 2);
      expect(await attachments.byGuid('zz'), isNull);
      final byMessage = await attachments.forMessages([1, 2, 3]);
      expect(byMessage[1]!.map((a) => a.id), [1, 3]);
      expect(byMessage[2]!.single.guid, 'a2');
      expect(byMessage.containsKey(3), isFalse);
    });
  });
}
