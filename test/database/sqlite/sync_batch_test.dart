// The incremental-sync batch on SQLite (SQLITE-PLAN-2 S2 test 3, risk R6): what
// SyncActions.bulkSyncData writes per batch (handles, chats with participants,
// folded twins, messages wired to chat and sender, reactions and attachment
// flags, attachments, latest pointers), written in ONE Db.write. Address
// formatting happens before the write, as today.
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/handle_repo.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:bluebubbles/database/sqlite/sync_batch_writer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sqlite_seed.dart';

Map<String, dynamic> person(String address, {int? rowId, String service = 'iMessage'}) =>
    {'address': address, 'service': service, 'originalROWID': ?rowId};

Map<String, dynamic> chatMap(String guid, List<Map<String, dynamic>> participants, {String? identifier, String? name}) => {
      'guid': guid,
      'chatIdentifier': identifier ?? guid.split(';').last,
      'participants': participants,
      'displayName': ?name,
      'style': participants.length > 1 ? 43 : 45,
    };

Map<String, dynamic> msgMap(
  String guid,
  int ms, {
  Map<String, dynamic>? chat,
  Map<String, dynamic>? from,
  int? handleId,
  String? reactsTo,
  List<String> attachments = const [],
  int itemType = 0,
  int? deliveredMs,
}) =>
    {
      'guid': guid,
      'text': 'text of $guid',
      'dateCreated': ms,
      'dateDelivered': ?deliveredMs,
      'isFromMe': from == null,
      'handle': ?from,
      'handleId': handleId ?? 0,
      'itemType': itemType,
      if (reactsTo != null) ...{'associatedMessageGuid': 'p:0/$reactsTo', 'associatedMessageType': 'love'},
      if (chat != null) 'chats': [chat],
      'attachments': [for (final a in attachments) {'guid': a, 'mimeType': 'image/jpeg', 'transferName': '$a.jpg'}],
    };

Future<Map<String, int>> counts(Db db) async => {
      for (final t in ['handles', 'chats', 'chat_handles', 'messages', 'attachments'])
        t: (await db.select('SELECT count(*) AS c FROM $t')).single['c'] as int,
    };

Future<List<Map<String, Object?>>> dump(Db db, String table) => db.select('SELECT * FROM $table ORDER BY 1, 2');

void main() {
  late Db db;
  late List<DbChanges> events;
  late MessageRepo messages;
  late ChatRepo chats;

  setUp(() {
    db = Db.memory();
    events = [];
    db.changes.listen(events.add);
    messages = MessageRepo(db);
    chats = ChatRepo(db);
  });
  tearDown(() => db.close());

  final ana = person('ana@example.com', rowId: 7);
  final bo = person('bo@example.com', rowId: 8);
  final dm = chatMap('iMessage;-;ana@example.com', [ana]);
  final group = chatMap('iMessage;+;chat99', [ana, bo], name: 'Trip');

  Map<String, dynamic> firstBatch() => {
        'messagesData': [
          msgMap('g1', baseMs + 1000, chat: group, from: ana, handleId: 7, attachments: ['att1', 'att2']),
          msgMap('g2', baseMs + 2000, chat: group),
          msgMap('d1', baseMs + 1500, chat: dm, from: ana),
          msgMap('r1', baseMs + 3000, chat: group, from: bo, reactsTo: 'g1'),
          msgMap('rename', baseMs + 4000, chat: group, itemType: 2),
        ],
      };

  test('a batch is written in one transaction: handles, chats, participants, messages, attachments, pointers', () async {
    final result = await SqliteSyncBatch.bulkSyncData(db, firstBatch());

    expect(events, hasLength(1), reason: 'one Db.write per batch');
    expect(events.single.tables.keys, containsAll(['handles', 'chats', 'chat_handles', 'messages', 'attachments']));
    expect(await counts(db), {'handles': 2, 'chats': 2, 'chat_handles': 3, 'messages': 5, 'attachments': 2});

    final g = (await chats.byGuid('iMessage;+;chat99'))!;
    expect(g.participants.map((h) => h.address), unorderedEquals(['ana@example.com', 'bo@example.com']));
    expect(g.displayName, 'Trip');
    expect(g.latestMessage?.guid, 'r1', reason: 'a rename never lists; the reaction is the newest ordinary item');
    expect((await chats.byGuid('iMessage;-;ana@example.com'))!.latestMessage?.guid, 'd1');

    final g1 = (await messages.byGuid('g1'))!;
    expect(g1.chat.targetId, g.id);
    expect(g1.hasReactions, isTrue);
    expect(g1.hasAttachments, isTrue);
    expect(g1.dbAttachments.map((a) => a.guid), ['att1', 'att2']);
    final ids = {for (final h in g.participants) h.address: h.id};
    expect(g1.handleRelation.targetId, ids['ana@example.com']);
    expect((await messages.byGuid('r1'))!.handleRelation.targetId, ids['bo@example.com']);
    expect((await messages.byGuid('g2'))!.handleRelation.targetId, 0, reason: 'from me');
    expect((await HandleRepo(db).byId(ids['ana@example.com']!))!.formattedAddress, 'ana@example.com',
        reason: 'formatted before the write');

    expect(result['messageIds'], hasLength(5));
    expect((result['chatIds'] as List).toSet(), {g.id, (await chats.byGuid('iMessage;-;ana@example.com'))!.id});
  });

  test('re-running a batch is idempotent: same rows, same ids, same pointers', () async {
    await SqliteSyncBatch.bulkSyncData(db, firstBatch());
    final before = {for (final t in ['handles', 'chats', 'chat_handles', 'messages', 'attachments']) t: await dump(db, t)};
    final again = await SqliteSyncBatch.bulkSyncData(db, firstBatch());
    final after = {for (final t in ['handles', 'chats', 'chat_handles', 'messages', 'attachments']) t: await dump(db, t)};
    expect(after, before);
    expect(again['chatIds'], isEmpty, reason: 'no pointer moved');
    expect(events, hasLength(2));
  });

  test('a batch of late-saved old history keeps the latest pointer on the newest message', () async {
    await SqliteSyncBatch.bulkSyncData(db, firstBatch());
    final old = await SqliteSyncBatch.bulkSyncData(db, {
      'messagesData': [
        msgMap('old1', baseMs - 900000, chat: group, from: ana),
        msgMap('old2', baseMs - 800000, chat: group),
      ],
    });
    expect((await chats.byGuid('iMessage;+;chat99'))!.latestMessage?.guid, 'r1');
    expect(old['chatIds'], isEmpty);
    expect((await messages.olderThan([(await chats.byGuid('iMessage;+;chat99'))!.id!], MessageKey.of((await messages.byGuid('g1'))!)))
            .map((m) => m.guid),
        ['old2', 'old1']);

    // Old history and one newer message in one batch: the newer one wins.
    await SqliteSyncBatch.bulkSyncData(db, {
      'messagesData': [
        msgMap('old3', baseMs - 700000, chat: group),
        msgMap('new1', baseMs + 9000, chat: group, from: bo),
      ],
    });
    expect((await chats.byGuid('iMessage;+;chat99'))!.latestMessage?.guid, 'new1');
  });

  test('a stored message is merged, not replaced: receipts arrive, the sender and chat stay', () async {
    await SqliteSyncBatch.bulkSyncData(db, firstBatch());
    final id = (await messages.byGuid('g2'))!.id;
    await SqliteSyncBatch.bulkSyncData(db, {
      'messagesData': [msgMap('g2', baseMs + 2000, chat: group, deliveredMs: baseMs + 2500)..['dateRead'] = baseMs + 2600],
    });
    final g2 = (await messages.byGuid('g2'))!;
    expect(g2.id, id);
    expect(g2.dateDelivered, at(baseMs + 2500));
    expect(g2.dateRead, at(baseMs + 2600));
    expect(g2.chat.targetId, (await chats.byGuid('iMessage;+;chat99'))!.id);
  });

  test('a top-level chat owns every message of the batch; senders resolve by server ROWID too', () async {
    await SqliteSyncBatch.bulkSyncData(db, {
      'chatData': dm,
      'messagesData': [
        msgMap('x1', baseMs, handleId: 7), // no embedded chat, no handle map: ROWID 7 is ana
      ],
    });
    final x1 = (await messages.byGuid('x1'))!;
    expect(x1.chat.targetId, (await chats.byGuid(dm['guid'] as String))!.id);
    expect(x1.handleRelation.targetId, (await HandleRepo(db).byUniqueKey('ana@example.com', 'iMessage'))!.id);
  });

  test('a twin chat in the batch is folded into its thread in the same transaction', () async {
    final sms = chatMap('SMS;-;ana@example.com', [person('ana@example.com', service: 'SMS')], identifier: 'ana@example.com');
    await SqliteSyncBatch.bulkSyncData(db, {
      'messagesData': [msgMap('d1', baseMs + 1500, chat: dm, from: ana)],
    });
    events.clear();
    await SqliteSyncBatch.bulkSyncData(db, {
      'messagesData': [msgMap('s1', baseMs + 5000, chat: sms)],
    });
    expect(events, hasLength(1));
    final thread = (await chats.byGuid(dm['guid'] as String))!;
    final s1 = (await messages.byGuid('s1'))!;
    expect(s1.chat.targetId, thread.id, reason: 'saved straight into the thread');
    expect(s1.appleChatGuid, 'SMS;-;ana@example.com');
    expect(thread.latestMessage?.guid, 's1');
  });

  test('a batch that fails part way writes nothing at all', () async {
    final batch = firstBatch();
    (batch['messagesData'] as List).add(msgMap('bad', baseMs, chat: group)..remove('guid'));
    await expectLater(SqliteSyncBatch.bulkSyncData(db, batch), throwsA(anything));
    expect(await counts(db), {'handles': 0, 'chats': 0, 'chat_handles': 0, 'messages': 0, 'attachments': 0});
    expect(events, isEmpty);
  });

  test('prepare does the address formatting; write only touches the database', () async {
    final prepared = await SqliteSyncBatch.prepare(firstBatch());
    expect(prepared.handles.map((h) => h.formattedAddress), everyElement(isNotNull));
    final statements = await db.recordStatements(() => SqliteSyncBatch.write(db, prepared));
    expect(statements, isNotEmpty);
    expect(events, hasLength(1));
  });
}
