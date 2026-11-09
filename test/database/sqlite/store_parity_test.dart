// ObjectBox and SQLite give the same answers on one fixture: the copy of a
// real ObjectBox store, read through today's ObjectBox queries and through the
// SQLite repositories. Search (SearchQueryHelper.findLocal vs MessageRepo.search,
// including 1-2 character terms and LIKE metacharacters) and every chat-stats
// query (ChatStatsQueries vs ChatStatsRepo).
import 'dart:io';

import 'package:bluebubbles/app/layouts/conversation_list/pages/search/search_query_helper.dart';
import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/chat_stats_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:bluebubbles/database/sqlite/objectbox_sqlite_copy.dart';
import 'package:bluebubbles/services/ui/chat/chat_stats/chat_stats_queries.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime _ms(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

const _texts = [
  'Hello World', 'hello there', 'HELLO!!!', 'Café OK', 'CAFÉ', 'ÉCOLE', 'école', 'Straße', 'STRASSE', 'İstanbul',
  'ΣΊΣΥΦΟΣ', 'σίσυφος', 'a_b c', 'axb', 'a%b', '50% off', r'x\y', 'emoji 😀 here', '😀', 'third bird', 'ab', 'AB', 'a',
  'naïve', 'the end', 'tab\there', 'line\nbreak',
];

void main() {
  late Directory dir;
  late Store store;
  late Db db;
  late Chat alice;
  late Chat groupChat;
  late Handle aliceHandle;
  late Handle bobHandle;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('bb_parity_');
    store = Store(getObjectBoxModel(), directory: '${dir.path}/objectbox');
    Database.messages = store.box<Message>();
    Database.attachments = store.box<Attachment>();

    aliceHandle = Handle(address: '+1555', service: 'iMessage', originalROWID: 11);
    bobHandle = Handle(address: 'bob@x', service: 'iMessage', originalROWID: 12);
    final carol = Handle(address: 'carol@x', service: 'iMessage', originalROWID: 13);
    store.box<Handle>().putMany([aliceHandle, bobHandle, carol]);
    alice = Chat(guid: 'iMessage;-;+1555')..handles.add(aliceHandle);
    groupChat = Chat(guid: 'iMessage;+;g1')..handles.addAll([aliceHandle, bobHandle, carol]);
    store.box<Chat>().putMany([alice, groupChat]);

    var t = 1600000000000;
    final messages = <Message>[];
    Message add(Chat chat, {String? text, bool? fromMe = false, Handle? from, String? guid, String? assoc, String? assocType,
        bool deleted = false, bool noDate = false, int itemType = 0, String? groupTitle, DateTime? read, DateTime? played,
        DateTime? edited, String? effect, bool attachments = false, List<MessageSummaryInfo>? summary, int? itemTypeOverride}) {
      t += 60000;
      final m = Message(
        guid: guid ?? 'g${messages.length}',
        text: text,
        dateCreated: noDate ? null : _ms(t),
        isFromMe: fromMe,
        handleId: fromMe == true ? 0 : (from?.originalROWID ?? 0),
        associatedMessageGuid: assoc,
        associatedMessageType: assocType,
        dateDeleted: deleted ? _ms(t + 1) : null,
        itemType: itemType,
        groupTitle: groupTitle,
        dateRead: read,
        datePlayed: played,
        dateEdited: edited,
        expressiveSendStyleId: effect,
        hasAttachments: attachments,
        messageSummaryInfo: summary ?? const [],
      );
      m.chat.target = chat;
      if (from != null) m.handleRelation.target = from;
      messages.add(m);
      return m;
    }

    for (final (i, text) in _texts.indexed) {
      add(i.isEven ? alice : groupChat, text: text, fromMe: i % 3 == 0, from: i % 3 == 0 ? null : (i.isEven ? aliceHandle : bobHandle));
    }
    // More matches than one page (50).
    for (var i = 0; i < 70; i++) {
      add(i.isEven ? alice : groupChat, text: 'common phrase $i', fromMe: i % 4 == 0, from: i % 4 == 0 ? null : carol);
    }
    // Never results: reaction, deleted, no date.
    add(alice, text: 'hello reaction', assoc: 'g0', assocType: 'love', from: aliceHandle);
    add(alice, text: 'hello deleted', deleted: true, from: aliceHandle);
    add(alice, text: 'hello undated', noDate: true, from: aliceHandle);
    // Stats inputs: renames, groupChat events, reactions, reads, plays, edits, unsends, effects, audio.
    add(groupChat, itemType: 2, groupTitle: 'First name', fromMe: true);
    add(groupChat, itemType: 2, groupTitle: 'Second name', from: bobHandle);
    add(groupChat, itemType: 1, from: aliceHandle);
    add(groupChat, itemType: 3, fromMe: true, deleted: true);
    add(groupChat, text: 'loved', assoc: 'g2', assocType: 'love', fromMe: true);
    add(groupChat, text: 'disliked', assoc: 'g4', assocType: 'dislike', from: carol);
    add(groupChat, assoc: 'g4', assocType: '-love', from: bobHandle);
    add(alice, text: 'read one', fromMe: true, read: _ms(t + 5000));
    add(alice, text: 'played', from: aliceHandle, played: _ms(t + 9000), attachments: true);
    add(groupChat, text: 'edited', from: bobHandle, edited: _ms(t + 1000));
    add(groupChat, text: 'unsent', from: bobHandle, edited: _ms(t + 2000),
        summary: [MessageSummaryInfo(retractedParts: [0], editedContent: {}, originalTextRange: {}, editedParts: [])]);
    add(groupChat, text: 'unsent mine', fromMe: true, edited: _ms(t + 3000),
        summary: [MessageSummaryInfo(retractedParts: [0], editedContent: {}, originalTextRange: {}, editedParts: [])]);
    add(groupChat, text: 'boom', fromMe: true, effect: 'com.apple.MobileSMS.expressivesend.impact');
    add(groupChat, text: 'unknown sender', fromMe: false);
    final voiceMine = add(groupChat, fromMe: true, attachments: true);
    final voiceTheirs = add(groupChat, from: carol, attachments: true);
    final photo = add(groupChat, from: bobHandle, attachments: true);
    store.box<Message>().putMany(messages);
    store.box<Attachment>().putMany([
      Attachment(guid: 'at1', mimeType: 'audio/amr')..message.target = voiceMine,
      Attachment(guid: 'at2', mimeType: 'audio/x-m4a')..message.target = voiceTheirs,
      Attachment(guid: 'at3', mimeType: 'image/jpeg')..message.target = photo,
      Attachment(guid: 'at4', mimeType: 'Audio/odd')..message.target = photo,
      Attachment(guid: 'at5')..message.target = photo,
    ]);
    groupChat.dbLatestMessage.target = messages.last;
    store.box<Chat>().put(groupChat);

    db = Db.memory();
    final copy = ObjectBoxSqliteCopy(source: store, target: db.database, batchSize: 17);
    expect((await copy.run()).completed, isTrue);
    expect((await copy.verify()).ok, isTrue);
  });

  tearDownAll(() async {
    await db.close();
    store.close();
    dir.deleteSync(recursive: true);
  });

  group('search: MessageRepo.search finds what SearchQueryHelper.findLocal finds, in the same order', () {
    final terms = [..._texts.map((t) => t.substring(0, t.length.clamp(1, 4))), 'hello', 'HeLLo', 'common', 'common phrase 1',
      'é', 'É', 'café', 'CAFÉ', 'école', 'ÉCOLE', 'ss', 'ß', 'istanbul', 'İst', 'σίσ', 'ΣΊΣ', '_', '%', 'a_b', 'a%b', '50%',
      r'\', r'x\y', '😀', 'b', 'B', ' ', 'ird', 'o w', 'nothing at all', "it's", '\t', '\n'];

    Future<void> same(String term, {Chat? chat, Handle? handle, bool fromMe = false, bool notFromMe = false, DateTime? since}) async {
      final expected = (await SearchQueryHelper.findLocal(term: term, selectedChat: chat, selectedHandle: handle,
              isFromMe: fromMe, isNotFromMe: notFromMe, sinceDate: since))
          .map((m) => m.guid)
          .toList();
      final actual = (await MessageRepo(db).search(term,
              chatIds: chat == null ? null : [chat.id!],
              isFromMe: fromMe ? true : (notFromMe ? false : null),
              senderHandleId: fromMe || notFromMe ? null : handle?.originalROWID,
              since: since))
          .map((m) => m.guid)
          .toList();
      expect(actual, expected, reason: 'term "$term" chat=${chat?.id} handle=${handle?.id} fromMe=$fromMe notFromMe=$notFromMe');
    }

    test('every term, no filter (incl. 1-2 characters, accents, LIKE metacharacters, a full page)', () async {
      var nonEmpty = 0;
      for (final term in terms.toSet()) {
        await same(term);
        if ((await SearchQueryHelper.findLocal(term: term, selectedChat: null, selectedHandle: null, isFromMe: false,
                isNotFromMe: false, sinceDate: null))
            .isNotEmpty) {
          nonEmpty++;
        }
      }
      expect(nonEmpty, greaterThan(30), reason: 'the fixture exercises real matches');
      expect((await MessageRepo(db).search('common')).length, 50);
    });

    test('with each filter: chat, sender, from me, not from me, since', () async {
      for (final term in ['hello', 'common', 'e', 'ab', 'phrase 3']) {
        await same(term, chat: groupChat);
        await same(term, chat: alice);
        await same(term, handle: bobHandle);
        await same(term, fromMe: true);
        await same(term, notFromMe: true);
        await same(term, since: _ms(1600000000000 + 60000 * 60));
        await same(term, chat: groupChat, fromMe: true, since: _ms(1600000000000 + 60000 * 40));
      }
    });

    test('results carry their attachments', () async {
      final played = (await MessageRepo(db).search('played')).single;
      expect(played.dbAttachments, isEmpty);
      final page = await MessageRepo(db).search('common');
      expect(page.every((m) => m.id != null && m.chat.targetId != 0), isTrue);
    });
  });

  group('lookups', () {
    test('byServerHandleId: every message whose sender ROWID matches, as Message_.handleId.equals', () async {
      final q = store.box<Message>().query(Message_.handleId.equals(12)).build();
      final expected = q.find().map((m) => m.guid).toSet();
      q.close();
      final actual = (await MessageRepo(db).byServerHandleId(12)).map((m) => m.guid).toSet();
      expect(actual, expected);
      expect(actual, isNotEmpty);
    });

    test('newestRename: the newest item_type 2 of the chats, as threadNameFor / _newestStoredNameChange', () async {
      expect((await MessageRepo(db).newestRename([groupChat.id!]))?.groupTitle, 'Second name');
      expect((await MessageRepo(db).newestRename([alice.id!, groupChat.id!]))?.groupTitle, 'Second name');
      expect(await MessageRepo(db).newestRename([alice.id!]), isNull);
    });
  });

  group('chat stats: ChatStatsRepo equals ChatStatsQueries', () {
    late ChatStatsRepo repo;
    setUp(() => repo = ChatStatsRepo(db));

    test('counts, participants, timestamps, texts, reactions, events, attachments, cache key', () async {
      const since = 1600000000000 + 60000 * 50;
      for (final chat in [alice, groupChat]) {
        final id = chat.id!;
        final reason = 'chat $id';
        expect(await repo.totalMessages(id), ChatStatsQueries.totalMessages(chat), reason: reason);
        expect(await repo.messageCountForTier(id), ChatStatsQueries.messageCountForTier(chat), reason: reason);
        expect(await repo.sentCount(id), ChatStatsQueries.sentCount(chat), reason: reason);
        expect(await repo.receivedCount(id), ChatStatsQueries.receivedCount(chat), reason: reason);
        expect(await repo.receivedCount(id, participantId: bobHandle.id), ChatStatsQueries.receivedCount(chat, participantId: bobHandle.id));
        for (final s in [null, since]) {
          expect(await repo.unattributedCount(id, sinceMillis: s), unattributedIntent(store, chat, sinceMillis: s), reason: reason);
          expect((await repo.participantHandleIds(id, sinceMillis: s))..sort(),
              ChatStatsQueries.participantHandleIds(chat, sinceMillis: s)..sort());
          expect(await repo.timestampsByParticipant(id, sinceMillis: s), ChatStatsQueries.timestampsByParticipant(chat, sinceMillis: s));
          expect(await repo.readTimestamps(id, sinceMillis: s), ChatStatsQueries.readTimestamps(chat, sinceMillis: s));
          expect(await repo.attachmentMessageCount(id, sinceMillis: s), ChatStatsQueries.attachmentMessageCount(chat, sinceMillis: s));
          for (final limit in [null, 3]) {
            expect(await repo.textLengthsByParticipant(id, sinceMillis: s, limitPerParticipant: limit),
                ChatStatsQueries.textLengthsByParticipant(chat, sinceMillis: s, limitPerParticipant: limit));
          }
        }
        for (final fromMe in [null, true, false]) {
          for (final p in [null, bobHandle.id]) {
            expect(await repo.editedCount(id, fromMe: fromMe, participantId: p),
                ChatStatsQueries.editedCount(chat, fromMe: fromMe, participantId: p), reason: '$reason edited $fromMe $p');
            expect(await repo.unsentCount(id, fromMe: fromMe, participantId: p),
                ChatStatsQueries.unsentCount(chat, fromMe: fromMe, participantId: p), reason: '$reason unsent $fromMe $p');
          }
        }
        for (final fromMe in [true, false]) {
          for (final limit in [null, 5]) {
            for (final p in [null, carolId(store)]) {
              expect(await repo.recentTexts(id, fromMe: fromMe, limit: limit, participantId: p),
                  ChatStatsQueries.recentTexts(chat, fromMe: fromMe, limit: limit, participantId: p));
            }
          }
        }
        expect(await repo.textCoverage(id), ChatStatsQueries.textCoverage(chat));
        expect(await repo.reactions(id), unorderedEquals(ChatStatsQueries.reactions(chat)));
        expect(await repo.attachmentMimeTypes(id), unorderedEquals(ChatStatsQueries.attachmentMimeTypes(chat)));
        expect(await repo.expressiveSendStyleIds(id), unorderedEquals(ChatStatsQueries.expressiveSendStyleIds(chat)));
        final audio = await repo.audioStats(id);
        final audioToday = ChatStatsQueries.audioStats(chat);
        expect((audio.sent, audio.received, audio.playedOfReceived), (audioToday.sent, audioToday.received, audioToday.playedOfReceived));
        expect([for (final e in await repo.groupEvents(id)) (e.itemType, e.groupActionType, e.groupTitle, e.dateMillis, e.senderId)],
            [for (final e in ChatStatsQueries.groupEvents(chat)) (e.itemType, e.groupActionType, e.groupTitle, e.dateMillis, e.senderId)]);
        final matrix = await repo.reactionMatrixData(id, sinceMillis: since);
        final matrixToday = ChatStatsQueries.reactionMatrixData(chat, sinceMillis: since);
        expect(matrix.guidToSender, matrixToday.guidToSender);
        expect([for (final r in matrix.reactionRows) (r.targetGuid, r.reactorId, r.type)],
            unorderedEquals([for (final r in matrixToday.reactionRows) (r.targetGuid, r.reactorId, r.type)]));
        expect(await repo.firstMessageMillis(id), ChatStatsQueries.firstMessageMillis(chat));
        final key = await repo.cacheKey(id);
        final keyToday = ChatStatsQueries.cacheKey(chat);
        expect((key.count, key.latestMillis), (keyToday.count, keyToday.latestMillis));
      }
      // The fixture exercises each query.
      expect(ChatStatsQueries.unsentCount(groupChat), 2);
      expect(ChatStatsQueries.audioStats(groupChat).received, 1);
      expect(ChatStatsQueries.groupEvents(groupChat), hasLength(3));
      // ObjectBox stores an unset ToOne as 0, which `handleRelation.isNull()`
      // never matches, so today's query finds no unlinked sender at all; the
      // repository counts what the query documents (see unattributedIntent).
      expect(ChatStatsQueries.unattributedCount(groupChat), 0);
      expect(await repo.unattributedCount(groupChat.id!), 1);
    });
  });
}

/// What `ChatStatsQueries.unattributedCount` documents: real incoming messages
/// of [chat] whose sender was never linked to a handle.
int unattributedIntent(Store store, Chat chat, {int? sinceMillis}) {
  final q = (store.box<Message>().query(ChatStatsQueries.realMessages(sinceMillis: sinceMillis).and(Message_.isFromMe.equals(false)))
        ..link(Message_.chat, Chat_.id.equals(chat.id!)))
      .build();
  try {
    return q.find().where((m) => m.handleRelation.targetId == 0).length;
  } finally {
    q.close();
  }
}

int carolId(Store store) => store.box<Handle>().getAll().firstWhere((h) => h.address == 'carol@x').id!;
