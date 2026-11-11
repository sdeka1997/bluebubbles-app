// Repository writes (SQLITE-PLAN-2 section 4): every write runs inside one
// Db.write, keyed the way the app's ObjectBox actions key them today (guid,
// address/service), keeping the stored row's id.
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/handle_repo.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sqlite_seed.dart';

Message newMessage(String guid, int chatId, int ms, {int? deliveredMs, int? itemType, String? text}) {
  final m = Message(
    guid: guid,
    dateCreated: at(ms),
    dateDelivered: deliveredMs == null ? null : at(deliveredMs),
    itemType: itemType,
    text: text ?? guid,
    isFromMe: true,
  );
  m.chat.targetId = chatId;
  return m;
}

Future<Map<String, Object?>> row(Db db, String table, int id) async =>
    (await db.select('SELECT * FROM $table WHERE id = ?', [id])).single;

void main() {
  late Db db;
  late MessageRepo messages;
  late ChatRepo chats;
  late HandleRepo handles;
  late AttachmentRepo attachments;
  late List<DbChanges> events;

  setUp(() async {
    db = Db.memory();
    messages = MessageRepo(db);
    chats = ChatRepo(db);
    handles = HandleRepo(db);
    attachments = AttachmentRepo(db);
    events = [];
    db.changes.listen(events.add);
  });
  tearDown(() => db.close());

  group('MessageRepo writes', () {
    test('upsert inserts new guids, updates stored ones in place by guid, and computes sort_at', () async {
      await (Seed()
            ..chat(1)
            ..message(7, 1, baseMs, guid: 'old', text: 'before'))
          .into(db);

      final stored = newMessage('old', 1, baseMs, text: 'after');
      final fresh = newMessage('new', 1, baseMs + 5000, deliveredMs: baseMs + 2000);
      final saved = await db.write((tx) => messages.upsert(tx, [stored, fresh]));

      expect(saved.map((m) => m.id), [7, isNot(7)]);
      expect((await messages.byGuid('old'))!.text, 'after');
      final freshRow = await row(db, 'messages', fresh.id!);
      expect(freshRow['sort_at_us'], at(baseMs + 2000).microsecondsSinceEpoch, reason: 'delivered before created');
      expect(freshRow['chat_id'], 1);
      expect(await db.select('SELECT id FROM messages'), hasLength(2));
      expect(events.single.tables['messages'], {7, fresh.id});
    });

    test('a guid twice in one batch is one row; a new message never takes the id it arrived with', () async {
      await (Seed()
            ..chat(1)
            ..message(3, 1, baseMs, guid: 'taken'))
          .into(db);
      final first = newMessage('dup', 1, baseMs + 1);
      final second = newMessage('dup', 1, baseMs + 1, text: 'second');
      final withServerId = newMessage('server', 1, baseMs + 2)..id = 3;
      await db.write((tx) => messages.upsert(tx, [first, second, withServerId]));

      expect(second.id, first.id);
      expect((await messages.byGuid('dup'))!.text, 'second');
      expect(withServerId.id, isNot(3));
      expect((await messages.byId(3))!.guid, 'taken');
    });

    test('replace: a receipt or edit updates the stored row by its old guid, keeps the id and re-sorts', () async {
      await (Seed()
            ..chat(1)
            ..message(5, 1, baseMs + 10000, guid: 'temp-1', text: 'hi'))
          .into(db);
      final incoming = Message(
        guid: 'real-1',
        dateCreated: at(baseMs + 10000),
        dateDelivered: at(baseMs + 4000),
        isDelievered: true,
        dateRead: at(baseMs + 20000),
        error: 0,
      );
      final replaced = await db.write((tx) => messages.replace(tx, 'temp-1', incoming));

      expect(replaced!.id, 5);
      expect(await messages.byGuid('temp-1'), isNull);
      final m = (await messages.byGuid('real-1'))!;
      expect(m.id, 5);
      expect(m.text, 'hi', reason: 'a receipt without text keeps the text');
      expect(m.isDelivered, isTrue);
      expect(m.dateRead, at(baseMs + 20000));
      expect((await row(db, 'messages', 5))['sort_at_us'], at(baseMs + 4000).microsecondsSinceEpoch);
      expect(m.chat.targetId, 1);

      final failed = Message(guid: 'real-1', dateCreated: at(baseMs + 10000), error: 22, errorMessage: 'nope');
      await db.write((tx) => messages.replace(tx, 'real-1', failed));
      final errored = (await messages.byGuid('real-1'))!;
      expect(errored.error, 22);
      expect(errored.dateRead, at(baseMs + 20000), reason: 'a missing date keeps the stored one');
      expect(await db.write((tx) => messages.replace(tx, 'missing', failed)), isNull);
    });

    test('soft delete hides a message from the timeline, restore brings it back', () async {
      await (Seed()
            ..chat(1)
            ..message(1, 1, baseMs)
            ..message(2, 1, baseMs + 1000))
          .into(db);
      expect(await db.write((tx) => messages.softDelete(tx, 'm2', at: at(baseMs + 9000))), isTrue);
      expect((await messages.newest([1])).map((m) => m.guid), ['m1']);
      expect((await messages.byGuid('m2'))!.dateDeleted, at(baseMs + 9000));
      expect(await db.write((tx) => messages.softDelete(tx, 'nope')), isFalse);

      expect(await db.write((tx) => messages.restore(tx, 'm2')), isTrue);
      expect(await db.write((tx) => messages.restore(tx, 'm2')), isFalse, reason: 'already restored');
      expect((await messages.newest([1])).map((m) => m.guid), ['m2', 'm1']);
    });

    test('hard delete removes the rows and detaches their attachments, as the S1 copy does', () async {
      await (Seed()
            ..chat(1)
            ..message(1, 1, baseMs)
            ..message(2, 1, baseMs + 1)
            ..attachment(10, 1)
            ..attachment(11, 2))
          .into(db);
      final removed = await db.write((tx) => messages.delete(tx, ['m1', 'missing']));

      expect(removed, [1]);
      expect(await messages.byGuid('m1'), isNull);
      expect((await attachments.byGuid('a10'))!.message.targetId, 0, reason: 'kept, no longer linked');
      expect((await attachments.byGuid('a11'))!.message.targetId, 2);
    });
  });

  group('ChatRepo writes', () {
    test('upsert by guid keeps the stored id; setParticipants replaces chat_handles and reports the chat', () async {
      await (Seed()
            ..handle(1, address: '+1001')
            ..handle(2, address: '+1002')
            ..handle(3, address: '+1003')
            ..chat(4, guid: 'c-four', handles: [1, 2]))
          .into(db);
      final edited = Chat(guid: 'c-four', displayName: 'Renamed');
      final fresh = Chat(guid: 'c-new', id: 4);
      await db.write((tx) async {
        await chats.upsert(tx, [edited, fresh]);
        await chats.setParticipants(tx, 4, [2, 3]);
      });

      expect(edited.id, 4);
      expect(fresh.id, isNot(4));
      final four = (await chats.byGuid('c-four'))!;
      expect(four.displayName, 'Renamed');
      expect(four.participants.map((h) => h.id), [2, 3]);
      expect(events.single.tables['chat_handles'], {4});
      expect(events.single.tables['chats'], {4, fresh.id});
    });

    test('read and unread state of several chats in one write', () async {
      await (Seed()
            ..chat(1)
            ..chat(2)
            ..chat(3))
          .into(db);
      await db.write((tx) => chats.setUnread(tx, [1, 2], true));
      await db.write((tx) => chats.setLastReadMessageGuid(tx, 2, 'm9'));
      expect((await chats.byId(1))!.hasUnreadMessage, isTrue);
      expect((await chats.byId(2))!.lastReadMessageGuid, 'm9');
      expect((await chats.byId(3))!.hasUnreadMessage, isFalse);
      await db.write((tx) => chats.setUnread(tx, [1, 2, 3], false));
      expect((await chats.byId(2))!.hasUnreadMessage, isFalse);
    });
  });

  // The rules and cases of test/helpers/thread_latest_test.dart against SQLite:
  // refreshLatest is refreshThreadLatestFromDb, keepNewest is keepNewestOf.
  group('latest pointer: full refresh (refreshThreadLatestFromDb)', () {
    Future<Chat> chat1() async => (await chats.byId(1))!;

    test('a thread previews its newest message after copies fold into it', () async {
      final seed = Seed()..chat(1, latestMessageId: 1, latestMs: baseMs + 1000);
      seed
        ..message(1, 1, baseMs + 1000, guid: 'rename', itemType: 2)
        ..message(2, 1, baseMs + 2000, guid: 'older')
        ..message(3, 1, baseMs + 3000, guid: 'reply');
      await seed.into(db);
      expect(await db.write((tx) => chats.refreshLatest(tx, 1)), isTrue);
      final c = await chat1();
      expect(c.latestMessage?.guid, 'reply');
      expect(c.dbOnlyLatestMessageDate, at(baseMs + 3000));
    });

    test('a thread already showing its newest message is left alone (no write)', () async {
      await (Seed()
            ..chat(1, latestMessageId: 3, latestMs: baseMs + 3000)
            ..message(2, 1, baseMs + 2000)
            ..message(3, 1, baseMs + 3000))
          .into(db);
      expect(await db.write((tx) => chats.refreshLatest(tx, 1)), isFalse);
      expect(events, isEmpty);
    });

    test('deleted messages are not previewed', () async {
      await (Seed()
            ..chat(1, latestMessageId: 1, latestMs: baseMs + 1000)
            ..message(1, 1, baseMs + 1000, guid: 'rename', itemType: 2)
            ..message(2, 1, baseMs + 2000, guid: 'reply')
            ..message(3, 1, baseMs + 3000, guid: 'gone', deleted: true))
          .into(db);
      await db.write((tx) => chats.refreshLatest(tx, 1));
      expect((await chat1()).latestMessage?.guid, 'reply');
    });

    test('a thread with no messages keeps what it has', () async {
      await (Seed()
            ..chat(2)
            ..message(1, 2, baseMs, guid: 'elsewhere')
            ..chat(1, latestMessageId: 1, latestMs: baseMs))
          .into(db);
      expect(await db.write((tx) => chats.refreshLatest(tx, 1)), isFalse);
      expect((await chat1()).dbLatestMessage.targetId, 1);
    });

    test('a thread whose newest items are events previews its last real message', () async {
      await (Seed()
            ..chat(1, latestMessageId: 3, latestMs: baseMs + 3000)
            ..message(1, 1, baseMs + 1000, guid: 'text')
            ..message(2, 1, baseMs + 2000, guid: 'removed', itemType: 1)
            ..message(3, 1, baseMs + 3000, guid: 'unnamed', itemType: 2))
          .into(db);
      expect(await db.write((tx) => chats.refreshLatest(tx, 1)), isTrue);
      final c = await chat1();
      expect(c.latestMessage?.guid, 'text');
      expect(c.dbOnlyLatestMessageDate, at(baseMs + 1000));
    });

    test('a reaction newer than an event lists the thread', () async {
      await (Seed()
            ..chat(1, latestMessageId: 1, latestMs: baseMs + 1000)
            ..message(1, 1, baseMs + 1000, guid: 'text')
            ..message(2, 1, baseMs + 2000, guid: 'rename', itemType: 2)
            ..message(3, 1, baseMs + 3000, guid: 'reaction', reactionTo: 'text'))
          .into(db);
      await db.write((tx) => chats.refreshLatest(tx, 1));
      expect((await chat1()).latestMessage?.guid, 'reaction');
    });

    test('a thread holding only events lists nothing', () async {
      await (Seed()
            ..chat(1, latestMessageId: 2, latestMs: baseMs + 2000)
            ..message(1, 1, baseMs + 1000, guid: 'removed', itemType: 1)
            ..message(2, 1, baseMs + 2000, guid: 'unnamed', itemType: 2))
          .into(db);
      expect(await db.write((tx) => chats.refreshLatest(tx, 1)), isTrue);
      final c = await chat1();
      expect(c.latestMessage, isNull);
      expect(c.dbLatestMessage.targetId, 0);
      expect(c.dbOnlyLatestMessageDate, isNull);
    });

    test('newest is the last row of the timeline: a message delivered before it was created sorts there', () async {
      await (Seed()
            ..chat(1)
            ..message(1, 1, baseMs + 5000, deliveredMs: baseMs + 1000, guid: 'late-created')
            ..message(2, 1, baseMs + 3000, guid: 'bottom'))
          .into(db);
      await db.write((tx) => chats.refreshLatest(tx, 1));
      expect((await chat1()).latestMessage?.guid, 'bottom');
    });

    test('relistShownByEvents refreshes only chats listed by a status item', () async {
      await (Seed()
            ..chat(1, latestMessageId: 2, latestMs: baseMs + 2000)
            ..message(1, 1, baseMs + 1000, guid: 'text')
            ..message(2, 1, baseMs + 2000, guid: 'rename', itemType: 2)
            ..chat(2, latestMessageId: 3, latestMs: baseMs + 1000)
            ..message(3, 2, baseMs + 1000, guid: 'ok')
            ..message(4, 2, baseMs + 4000, guid: 'newer-but-not-relisted'))
          .into(db);
      expect(await db.write((tx) => chats.relistShownByEvents(tx, [1, 2])), [1]);
      expect((await chats.byId(1))!.latestMessage?.guid, 'text');
      expect((await chats.byId(2))!.latestMessage?.guid, 'ok');
    });

    test('relistShownByEvents finds its candidates in one statement, not two reads per chat', () async {
      final seed = Seed();
      for (var c = 1; c <= 20; c++) {
        seed
          ..chat(c, latestMessageId: c, latestMs: baseMs + c)
          ..message(c, c, baseMs + c, guid: 'text-$c');
      }
      await seed.into(db);
      final statements = await db.recordStatements(() => db.write((tx) => chats.relistShownByEvents(tx, [for (var c = 1; c <= 20; c++) c])));
      expect(statements.where((s) => s.$1.trimLeft().toUpperCase().startsWith('SELECT')), hasLength(1));
    });
  });

  group('latest pointer: from changed messages only (keepNewestOf)', () {
    late Map<String, Message> m;

    setUp(() async {
      final seed = Seed()
        ..chat(1)
        ..chat(9); // somewhere the "moved in" messages are stored
      m = {
        'rename': seed.message(1, 1, baseMs + 1000, guid: 'rename', itemType: 2),
        'older': seed.message(2, 9, baseMs + 2000, guid: 'older'),
        'reply': seed.message(3, 9, baseMs + 3000, guid: 'reply'),
        'later-rename': seed.message(4, 9, baseMs + 4000, guid: 'later-rename', itemType: 2),
        'gone': seed.message(5, 9, baseMs + 5000, guid: 'gone', deleted: true),
      };
      await seed.into(db);
    });

    Future<void> point(String guid) =>
        db.write((tx) => tx.execute('UPDATE chats SET latest_message_id = ?, latest_message_date_us = ? WHERE id = 1',
            [m[guid]!.id, m[guid]!.dateCreated!.microsecondsSinceEpoch]));

    Future<String?> latest() async => (await chats.byId(1))!.latestMessage?.guid;

    test('messages moved in that are newer become the preview', () async {
      await point('older');
      expect(await db.write((tx) => chats.keepNewest(tx, 1, [m['reply']!])), isTrue);
      expect(await latest(), 'reply');
      expect((await chats.byId(1))!.dbOnlyLatestMessageDate, at(baseMs + 3000));
    });

    test('messages moved in that are older leave the preview alone', () async {
      await point('reply');
      events.clear();
      expect(await db.write((tx) => chats.keepNewest(tx, 1, [m['older']!])), isFalse);
      expect(await latest(), 'reply');
      expect(events, isEmpty);
    });

    test('a status item moved in never becomes the preview', () async {
      await point('older');
      expect(await db.write((tx) => chats.keepNewest(tx, 1, [m['later-rename']!])), isFalse);
      expect(await latest(), 'older');
    });

    test('a deleted message moved in never becomes the preview', () async {
      await point('older');
      expect(await db.write((tx) => chats.keepNewest(tx, 1, [m['gone']!])), isFalse);
      expect(await latest(), 'older');
    });

    test('a thread listed by a status item takes an ordinary message even if older', () async {
      await point('rename');
      expect(await db.write((tx) => chats.keepNewest(tx, 1, [m['older']!])), isTrue);
      expect(await latest(), 'older');
    });

    test('a thread with no preview takes the newest ordinary message', () async {
      expect(await db.write((tx) => chats.keepNewest(tx, 1, [m['older']!, m['reply']!, m['rename']!])), isTrue);
      expect(await latest(), 'reply');
    });

    test('nothing moved in changes nothing', () async {
      await point('older');
      expect(await db.write((tx) => chats.keepNewest(tx, 1, const [])), isFalse);
      expect(await latest(), 'older');
    });

    test('a pointer at a message that is gone counts as no preview', () async {
      await db.write((tx) => tx.execute('UPDATE chats SET latest_message_id = 99, latest_message_date_us = ? WHERE id = 1',
          [at(baseMs + 9000).microsecondsSinceEpoch]));
      expect(await db.write((tx) => chats.keepNewest(tx, 1, [m['older']!])), isTrue);
      expect(await latest(), 'older');
    });
  });

  group('HandleRepo / AttachmentRepo writes', () {
    test('upsert by address/service keeps id, color (unless asked) and a ROWID the new copy lacks', () async {
      await (Seed()..handle(1, address: '+1001', originalRowId: 40)).into(db);
      await db.write((tx) => tx.execute("UPDATE handles SET color = 'red' WHERE id = 1"));

      final again = Handle(address: '+1001', service: 'iMessage', color: 'blue', formattedAddress: '+1 001');
      final sms = Handle(address: '+1001', service: 'SMS');
      await db.write((tx) => handles.upsert(tx, [again, sms]));
      expect(again.id, 1);
      final stored = (await handles.byId(1))!;
      expect(stored.color, 'red');
      expect(stored.originalROWID, 40);
      expect(stored.formattedAddress, '+1 001');
      expect(sms.id, isNot(1));

      await db.write((tx) => handles.upsert(tx, [Handle(address: '+1001', color: 'blue')], updateColor: true));
      expect((await handles.byId(1))!.color, 'blue');
    });

    test('insertMissing adds unknown handles and returns stored ones untouched, by unique key', () async {
      await (Seed()..handle(1, address: '+1001', originalRowId: 40)).into(db);
      final result = await db.write((tx) => handles.insertMissing(tx, [
            Handle(address: '+1001', originalROWID: 77),
            Handle(address: 'a@b.c', originalROWID: 78),
          ]));
      expect(result.keys, unorderedEquals(['+1001/iMessage', 'a@b.c/iMessage']));
      expect(result['+1001/iMessage']!.id, 1);
      expect(result['+1001/iMessage']!.originalROWID, 40);
      expect(result['a@b.c/iMessage']!.id, isNotNull);
      expect((await handles.byRowIds([78])).values.single.address, 'a@b.c');
    });

    test('adoptServerRowIds moves a reported ROWID to its handle and clears it from the old holder', () async {
      await (Seed()
            ..handle(1, address: '+1001', originalRowId: 5)
            ..handle(2, address: '+1002', originalRowId: 9))
          .into(db);
      final reported = (await handles.byId(2))!;
      await db.write((tx) => handles.adoptServerRowIds(tx, [(reported, 5)]));
      expect((await handles.byId(2))!.originalROWID, 5);
      expect((await handles.byId(1))!.originalROWID, isNull);
      expect((await handles.byRowIds([5]))[5]!.id, 2);
    });

    test('attachment upsert by guid keeps the id and links the message', () async {
      await (Seed()
            ..chat(1)
            ..message(1, 1, baseMs)
            ..message(2, 1, baseMs + 1)
            ..attachment(20, 1, guid: 'att'))
          .into(db);
      final moved = Attachment(guid: 'att', mimeType: 'image/png', width: 10)..message.targetId = 2;
      final added = Attachment(guid: 'att-new', id: 20)..message.targetId = 2;
      await db.write((tx) => attachments.upsert(tx, [moved, added]));
      expect(moved.id, 20);
      expect(added.id, isNot(20));
      expect((await attachments.forMessages([2]))[2]!.map((a) => a.guid), ['att', 'att-new']);
      expect((await attachments.byGuid('att'))!.width, 10);
    });
  });

  test('a repository write that throws leaves nothing behind', () async {
    await (Seed()..chat(1)).into(db);
    await expectLater(
      db.write((tx) async {
        await messages.upsert(tx, [newMessage('x', 1, baseMs)]);
        throw StateError('stop');
      }),
      throwsStateError,
    );
    expect(await messages.byGuid('x'), isNull);
    expect(events, isEmpty);
    expect(sortAtMicros(at(baseMs), null), at(baseMs).microsecondsSinceEpoch);
  });
}
