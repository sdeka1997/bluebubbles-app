// Relations become explicit (S2 switch plan, commit 3; risk 4). Entities read
// from SQLite carry their relation ids from the row; repositories fill the
// related objects. A relation read before it is filled throws (debug), and
// every repository read returns entities whose reachable relations are all
// filled. On ObjectBox the relations behave as before.
import 'dart:io';

import 'package:bluebubbles/database/io/relations.dart' as rel;
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/contact_repo.dart';
import 'package:bluebubbles/database/sqlite/custom_group_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/handle_repo.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sqlite_seed.dart';

/// Every relation reachable from [roots] (except the two never filled on
/// SQLite: Chat.messages, Chat.customGroups) is filled, and reading it does
/// not throw. Returns how many relations it visited.
int expectFilled(Iterable<Object> roots) {
  final seen = Set<Object>.identity();
  var visited = 0;
  void one(String what, rel.ToOne r, Object? Function() read, void Function(Object) walk) {
    visited++;
    expect(r.isFilled, isTrue, reason: '$what not filled');
    final t = read();
    if (r.targetId != 0) expect(t, isNotNull, reason: '$what ${r.targetId} not resolved');
    if (t != null) walk(t);
  }

  void many(String what, rel.ToMany r, void Function(Object) walk) {
    visited++;
    expect(r.isFilled, isTrue, reason: '$what not filled');
    for (final e in r.toList()) {
      walk(e as Object);
    }
  }

  void walk(Object e) {
    if (!seen.add(e)) return;
    switch (e) {
      case final Message m:
        one('Message ${m.id}.chat', m.chat as rel.ToOne, () => m.chat.target, walk);
        one('Message ${m.id}.handleRelation', m.handleRelation as rel.ToOne, () => m.handleRelation.target, walk);
        many('Message ${m.id}.dbAttachments', m.dbAttachments as rel.ToMany, walk);
      case final Chat c:
        one('Chat ${c.id}.dbLatestMessage', c.dbLatestMessage as rel.ToOne, () => c.dbLatestMessage.target, walk);
        many('Chat ${c.id}.handles', c.handles as rel.ToMany, walk);
        expect(c.latestMessage, same(c.dbLatestMessage.target));
      case final Handle h:
        many('Handle ${h.id}.contactsV2', h.contactsV2 as rel.ToMany, walk);
      case final ContactV2 c:
        many('ContactV2 ${c.id}.handles', c.handles as rel.ToMany, walk);
      case final Attachment a:
        one('Attachment ${a.id}.message', a.message as rel.ToOne, () => a.message.target, walk);
      case final CustomGroup g:
        many('CustomGroup ${g.id}.chats', g.chats as rel.ToMany, walk);
    }
  }

  roots.forEach(walk);
  return visited;
}

void main() {
  group('Rel / RelList read from SQLite', () {
    Map<String, Object?> row(Message m) => messageToRow(m)..['id'] = 5;

    test('reading an unfilled relation throws (debug assert), naming it', () {
      final m = messageFromRow(row(Message(guid: 'g', dateCreated: at(baseMs))..chat.targetId = 3));
      expect(m.chat.targetId, 3, reason: 'the id is there without a fill');
      expect(m.chat.hasValue, isTrue);
      expect(() => m.chat.target, throwsA(isA<AssertionError>().having((e) => e.message, 'message', contains('Message.chat'))));
      expect(() => m.dbAttachments.length, throwsA(isA<AssertionError>()));
      expect(() => m.dbAttachments.isEmpty, throwsA(isA<AssertionError>()));
      expect(() => m.dbAttachments.toList(), throwsA(isA<AssertionError>()));
      expect(() => [for (final a in m.dbAttachments) a], throwsA(isA<AssertionError>()));

      final c = chatFromRow(chatToRow(Chat(id: 1, guid: 'c')));
      expect(() => c.handles.isNotEmpty, throwsA(isA<AssertionError>().having((e) => e.message, 'message', contains('Chat.handles'))));
      expect(() => c.messages.length, throwsA(isA<AssertionError>().having((e) => e.message, 'message', contains('Chat.messages'))));
      expect(() => c.customGroups.length, throwsA(isA<AssertionError>()));
      expect(() => handleFromRow(handleToRow(Handle(id: 1, address: 'a'))).contactsV2.length, throwsA(isA<AssertionError>()));
      expect(() => contactFromRow(contactToRow(ContactV2(id: 1, displayName: 'x', nativeContactId: 'n'))).handles.length,
          throwsA(isA<AssertionError>()));
      expect(() => customGroupFromRow(customGroupToRow(CustomGroup(id: 1, name: 'g'))).chats.length,
          throwsA(isA<AssertionError>()));
      final a = attachmentFromRow(attachmentToRow(Attachment(id: 1, guid: 'a')..message.targetId = 5));
      expect(() => a.message.target, throwsA(isA<AssertionError>()));
    });

    test('a relation with no stored id needs no fill; filling or setting it makes it readable', () {
      final m = messageFromRow(row(Message(guid: 'g', dateCreated: at(baseMs))));
      expect(m.chat.hasValue, isFalse);
      expect(m.chat.target, isNull);
      expect(m.chat.targetId, 0);

      final withChat = messageFromRow(row(Message(guid: 'g', dateCreated: at(baseMs))..chat.targetId = 3));
      final chat = Chat(id: 3, guid: 'c');
      withChat.chat.fill(chat);
      expect(withChat.chat.target, same(chat));
      withChat.chat.targetId = 4;
      expect(() => withChat.chat.target, throwsA(isA<AssertionError>()), reason: 'a new id is unfilled again');
      withChat.chat.target = chat;
      expect((withChat.chat.targetId, withChat.chat.target), (3, chat));
      withChat.chat.target = null;
      expect((withChat.chat.targetId, withChat.chat.hasValue), (0, false));

      m.dbAttachments.fill(const []);
      expect(m.dbAttachments, isEmpty);
      m.dbAttachments.add(Attachment(id: 9, guid: 'x'));
      expect(m.dbAttachments.single.id, 9);
    });

    test('row mappers map relation ids directly, and back', () {
      final m = Message(guid: 'g', dateCreated: at(baseMs));
      m.chat.targetId = 3;
      m.handleRelation.targetId = 4;
      final read = messageFromRow(row(m));
      expect((read.chat.targetId, read.handleRelation.targetId), (3, 4));
      expect(messageToRow(read)['chat_id'], 3);
      expect(messageToRow(read)['handle_relation_id'], 4);
      final chat = chatFromRow(chatToRow(Chat(id: 1, guid: 'c')..dbLatestMessage.targetId = 7));
      expect(chat.dbLatestMessage.targetId, 7);
      expect(chatToRow(chat)['latest_message_id'], 7);
      final a = attachmentFromRow(attachmentToRow(Attachment(id: 1, guid: 'a')..message.targetId = 5));
      expect((a.message.targetId, attachmentToRow(a)['message_id']), (5, 5));
    });
  });

  group('ObjectBox keeps its relations', () {
    late Directory dir;
    late Store store;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('bb_rel_ob_');
      store = Store(getObjectBoxModel(), directory: dir.path);
    });
    tearDown(() {
      store.close();
      dir.deleteSync(recursive: true);
    });

    test('the entity fields are the Rel/RelList look-alikes and ObjectBox lazy-loads and saves them as before', () {
      final handle = Handle(address: '+1', service: 'iMessage');
      final contact = ContactV2(displayName: 'A', nativeContactId: 'n')..handles.add(handle);
      store.box<ContactV2>().put(contact);
      final chat = Chat(guid: 'c')..handles.add(handle);
      store.box<Chat>().put(chat);
      final m = Message(guid: 'm', text: 'hi', dateCreated: at(baseMs));
      m.chat.target = chat;
      m.handleRelation.target = handle;
      store.box<Message>().put(m);
      final a = Attachment(guid: 'a');
      a.message.target = m;
      store.box<Attachment>().put(a);
      chat.dbLatestMessage.target = m;
      store.box<Chat>().put(chat);
      final group = CustomGroup(name: 'G')..chats.add(chat);
      store.box<CustomGroup>().put(group);

      final readMessage = store.box<Message>().get(m.id!)!;
      expect(readMessage.chat, isA<rel.Rel<Chat>>());
      expect(readMessage.dbAttachments, isA<rel.RelList<Attachment>>());
      expect((readMessage.chat as rel.ToOne).isFilled, isTrue);
      expect(readMessage.chat.target!.guid, 'c');
      expect(readMessage.handleRelation.target!.address, '+1');
      expect(readMessage.dbAttachments.single.guid, 'a');
      final readChat = store.box<Chat>().get(chat.id!)!;
      expect(readChat.handles.single.address, '+1');
      expect(readChat.handles.single.contactsV2.single.displayName, 'A');
      expect(readChat.dbLatestMessage.target!.guid, 'm');
      expect(readChat.messages.single.guid, 'm');
      expect(readChat.customGroups.single.name, 'G');
      expect(store.box<Attachment>().get(a.id!)!.message.target!.guid, 'm');
      expect(store.box<CustomGroup>().get(group.id!)!.chats.single.guid, 'c');
      expect(store.box<ContactV2>().get(contact.id)!.handles.single.address, '+1');

      // ToMany edits still save through ObjectBox.
      readChat.handles.removeAt(0);
      store.box<Chat>().put(readChat);
      expect(store.box<Chat>().get(chat.id!)!.handles, isEmpty);
      // Message_ relation queries still work (generated code unchanged).
      expect(store.box<Message>().query(Message_.chat.equals(chat.id!)).build().count(), 1);
    });
  });

  group('every repository read fills every reachable relation', () {
    late Db db;
    setUp(() async {
      db = Db.memory();
      final seed = Seed()
        ..contact(1, 'Alice')
        ..contact(2, 'Bob')
        ..handle(1, address: '+1', contacts: [1])
        ..handle(2, address: '+2', contacts: [1, 2])
        ..handle(3, address: '+3')
        ..chat(1, latestMessageId: 4, latestMs: baseMs + 4, handles: [1, 2])
        ..chat(2, latestMessageId: 6, latestMs: baseMs + 6, handles: [3])
        ..chat(3);
      for (var i = 1; i <= 6; i++) {
        seed.message(i, i <= 4 ? 1 : 2, baseMs + i,
            isFromMe: i.isEven, handleRelationId: i.isEven ? null : (i <= 4 ? 2 : 3), threadOriginator: i == 3 ? 'm1' : null,
            text: 'hello $i', handleId: i.isEven ? null : 20 + i, itemType: i == 5 ? 2 : null);
      }
      seed.message(7, 1, baseMs + 7, reactionTo: 'm1', handleRelationId: 1);
      seed
        ..attachment(1, 1)
        ..attachment(2, 1)
        ..attachment(3, 5);
      await seed.into(db);
      await db.write((tx) async {
        await tx.execute("INSERT INTO custom_groups (id, name, sort_order, show_unread_badge) VALUES (1, 'G', 0, 1)");
        await tx.execute('INSERT INTO custom_group_chats (group_id, chat_id) VALUES (1, 1), (1, 2)');
      });
    });
    tearDown(() => db.close());

    test('MessageRepo', () async {
      final repo = MessageRepo(db);
      final newest = await repo.newest([1]);
      expect(newest, isNotEmpty);
      expect(expectFilled(newest), greaterThan(10));
      expect(newest.firstWhere((m) => m.id == 1).dbAttachments.map((a) => a.id), [1, 2]);
      expect(newest.firstWhere((m) => m.id == 1).handleRelation.target!.contactsV2.map((c) => c.displayName), ['Alice', 'Bob']);
      expect(newest.first.chat.target!.handles.map((h) => h.id), [1, 2]);
      expect(identical(newest[0].chat.target, newest[1].chat.target), isTrue, reason: 'one object per row');
      final key = MessageKey.of(newest.last);
      expectFilled(await repo.olderThan([1], key));
      expectFilled(await repo.newerThan([1], key));
      expectFilled(await repo.around([1], MessageKey.of(newest[1])));
      expectFilled(await repo.reactionsFor(['m1']));
      expectFilled([(await repo.byGuid('m3'))!]);
      expectFilled((await repo.byIds([1, 5])).values);
      expectFilled([(await repo.byId(5))!]);
      expectFilled(await repo.thread('m1'));
      expectFilled(await repo.search('hello'));
      expectFilled(await repo.search('he'));
      expectFilled(await repo.byServerHandleId(21));
      expectFilled([(await repo.newestRename([2]))!]);
    });

    test('ChatRepo: participants with contacts, latest message with its chat being this chat', () async {
      final repo = ChatRepo(db);
      final page = await repo.listPage();
      expect(page.map((c) => c.id), [2, 1, 3]);
      expectFilled(page);
      final one = page.firstWhere((c) => c.id == 1);
      expect(one.dbLatestMessage.target!.chat.target, same(one));
      expect(one.participants.map((h) => h.id), [1, 2]);
      expect(page.firstWhere((c) => c.id == 3).dbLatestMessage.target, isNull);
      expectFilled([(await repo.byId(1))!, (await repo.byGuid('chat-2'))!]);
      expectFilled((await repo.byIds([1, 2, 3])).values);
    });

    test('HandleRepo, ContactRepo, CustomGroupRepo, AttachmentRepo', () async {
      final handles = HandleRepo(db);
      expectFilled((await handles.byIds([1, 2, 3])).values);
      expectFilled([(await handles.byId(2))!, (await handles.byUniqueKey('+2', 'iMessage'))!]);
      expect((await handles.byId(2))!.contactsV2.map((c) => c.id), [1, 2]);
      final contacts = ContactRepo(db);
      final all = await contacts.all();
      expectFilled(all);
      expect(all.first.handles.map((h) => h.id), [1, 2]);
      expectFilled([(await contacts.byId(2))!, (await contacts.byNativeId('native-1'))!]);
      expectFilled(await contacts.forHandles([2]));
      final groups = CustomGroupRepo(db);
      final g = (await groups.all()).single;
      expectFilled([g]);
      expect(g.chats.map((c) => c.id), [1, 2]);
      expectFilled([(await groups.byId(1))!]);
      final a = (await AttachmentRepo(db).byGuid('a3'))!;
      expectFilled([a]);
      expect(a.message.target!.id, 5);
    });
  });
}
