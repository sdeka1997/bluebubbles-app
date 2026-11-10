// SyncActions.bulkSyncData / SyncInterface.bulkSyncData through MessagingStore
// (S2 switch plan, commit 5): the sync_batch_test cases, plus
// the R6 transaction-boundary tests (risk 1 of the plan): batches started
// concurrently end as they would run one after the other.
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/env.dart';
import 'package:bluebubbles/services/backend/actions/sync_actions.dart';
import 'package:bluebubbles/services/backend/interfaces/sync_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'store_fixture.dart';

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

final ana = person('ana@example.com', rowId: 7);
final bo = person('bo@example.com', rowId: 8);
final dm = chatMap('iMessage;-;ana@example.com', [ana]);
final trip = chatMap('iMessage;+;chat99', [ana, bo], name: 'Trip');
final sms = chatMap('SMS;-;ana@example.com', [person('ana@example.com', service: 'SMS')], identifier: 'ana@example.com');

Map<String, dynamic> firstBatch() => {
      'messagesData': [
        msgMap('g1', t0 + 1000, chat: trip, from: ana, handleId: 7, attachments: ['att1', 'att2']),
        msgMap('g2', t0 + 2000, chat: trip),
        msgMap('d1', t0 + 1500, chat: dm, from: ana),
        msgMap('r1', t0 + 3000, chat: trip, from: bo, reactsTo: 'g1'),
        msgMap('rename', t0 + 4000, chat: trip, itemType: 2),
      ],
    };

Map<String, dynamic> secondBatch() => {
      'messagesData': [
        msgMap('g3', t0 + 6000, chat: trip, from: bo, attachments: ['att3']),
        msgMap('r2', t0 + 6500, chat: trip, from: ana, reactsTo: 'g1'),
        msgMap('d2', t0 + 7000, chat: dm),
        msgMap('g2', t0 + 2000, chat: trip, deliveredMs: t0 + 2500),
      ],
    };

Map<String, dynamic> twinBatch() => {
      'messagesData': [msgMap('s1', t0 + 8000, chat: sms)],
    };

const _guids = ['g1', 'g2', 'g3', 'd1', 'd2', 'r1', 'r2', 'rename', 's1', 'x1', 'old1', 'old2', 'old3', 'new1'];
const _chats = ['iMessage;+;chat99', 'iMessage;-;ana@example.com', 'SMS;-;ana@example.com'];

/// What a store holds, without local ids: compared across stores and runs.
Future<Map<String, Object?>> snapshot(MessagingStore store) async {
  final handles = await store.handlesByIds(await store.allHandleIds());
  final out = <String, Object?>{
    'handles': [for (final h in handles) '${h.address}/${h.service}/${h.originalROWID}']..sort(),
    'messages': (await store.allMessageIds()).length,
    'attachments': (await store.findAttachmentIds(null)).length,
  };
  for (final guid in _guids) {
    final m = await store.messageByGuid(guid);
    if (m == null) continue;
    out[guid] = (
      chat: m.chat.target?.guid,
      sender: m.handleRelation.target?.address,
      reactions: m.hasReactions,
      attachments: m.hasAttachments,
      delivered: m.dateDelivered?.millisecondsSinceEpoch,
      appleChat: m.appleChatGuid,
    ).toString();
  }
  for (final guid in _chats) {
    final c = await store.chatByGuid(guid);
    if (c == null) continue;
    out[guid] = (
      people: [for (final h in c.handles) h.address]..sort(),
      latest: c.dbLatestMessage.target?.guid,
      name: c.displayName,
    ).toString();
  }
  return out;
}

void main() {
  setUpAll(() => isIsolateOverride = true);
  tearDownAll(() => isIsolateOverride = false);

  storeTests((fixture) {
    MessagingStore store() => fixture().store;

    group('SyncActions.bulkSyncData', () {
      test('a batch saves handles, chats, participants, messages, attachments and pointers', () async {
        final result = await SyncActions.bulkSyncData(firstBatch());

        final g = (await store().chatByGuid('iMessage;+;chat99'))!;
        expect([for (final h in g.handles) h.address], unorderedEquals(['ana@example.com', 'bo@example.com']));
        expect(g.displayName, 'Trip');
        expect(g.dbLatestMessage.target?.guid, 'r1', reason: 'a rename never lists; the reaction is the newest ordinary item');
        final d = (await store().chatByGuid('iMessage;-;ana@example.com'))!;
        expect(d.dbLatestMessage.target?.guid, 'd1');

        final g1 = (await store().messageByGuid('g1'))!;
        expect(g1.chat.targetId, g.id);
        expect((g1.hasReactions, g1.hasAttachments), (true, true));
        final ids = {for (final h in g.handles) h.address: h.id};
        expect(g1.handleRelation.targetId, ids['ana@example.com']);
        expect((await store().messageByGuid('r1'))!.handleRelation.targetId, ids['bo@example.com']);
        expect((await store().messageByGuid('g2'))!.handleRelation.targetId, 0, reason: 'from me');
        expect((await store().handleById(ids['ana@example.com']!))!.formattedAddress, 'ana@example.com');
        expect(await store().findAttachmentIds(null), hasLength(2));

        expect(result['messageIds'], hasLength(5));
        expect((result['chatIds'] as List).toSet(), {g.id, d.id});
      });

      test('re-running a batch is idempotent: same rows, same ids, no pointer moves', () async {
        final first = await SyncActions.bulkSyncData(firstBatch());
        final before = await snapshot(store());
        final again = await SyncActions.bulkSyncData(firstBatch());
        expect(await snapshot(store()), before);
        expect(again['messageIds'], first['messageIds']);
        expect(again['chatIds'], isEmpty);
      });

      test('late-saved old history keeps the latest pointer on the newest message', () async {
        await SyncActions.bulkSyncData(firstBatch());
        final old = await SyncActions.bulkSyncData({
          'messagesData': [msgMap('old1', t0 - 900000, chat: trip, from: ana), msgMap('old2', t0 - 800000, chat: trip)],
        });
        expect((await store().chatByGuid('iMessage;+;chat99'))!.dbLatestMessage.target?.guid, 'r1');
        expect(old['chatIds'], isEmpty);

        await SyncActions.bulkSyncData({
          'messagesData': [msgMap('old3', t0 - 700000, chat: trip), msgMap('new1', t0 + 9000, chat: trip, from: bo)],
        });
        expect((await store().chatByGuid('iMessage;+;chat99'))!.dbLatestMessage.target?.guid, 'new1');
      });

      test('a stored message is merged, not replaced: receipts arrive, sender and chat stay', () async {
        await SyncActions.bulkSyncData(firstBatch());
        final id = (await store().messageByGuid('g1'))!.id;
        await SyncActions.bulkSyncData({
          'messagesData': [
            msgMap('g1', t0 + 1000, chat: trip, deliveredMs: t0 + 2500)..remove('handle'),
          ],
        });
        final g1 = (await store().messageByGuid('g1'))!;
        expect(g1.id, id);
        expect(g1.dateDelivered, ms(t0 + 2500));
        expect(g1.handleRelation.target?.address, 'ana@example.com');
        expect(g1.chat.target?.guid, 'iMessage;+;chat99');
      });

      test('a top-level chat owns every message; senders resolve by server ROWID too', () async {
        await SyncActions.bulkSyncData({'chatData': dm, 'messagesData': [msgMap('x1', t0, handleId: 7)]});
        final x1 = (await store().messageByGuid('x1'))!;
        expect(x1.chat.target?.guid, dm['guid']);
        expect(x1.handleRelation.target?.address, 'ana@example.com');
      });

      test('a twin chat in the batch is folded into its thread in the same write', () async {
        await SyncActions.bulkSyncData({'messagesData': [msgMap('d1', t0 + 1500, chat: dm, from: ana)]});
        await SyncActions.bulkSyncData(twinBatch());
        final thread = (await store().chatByGuid(dm['guid'] as String))!;
        final s1 = (await store().messageByGuid('s1'))!;
        expect(s1.chat.targetId, thread.id, reason: 'saved straight into the thread');
        expect(s1.appleChatGuid, 'SMS;-;ana@example.com');
        expect(thread.dbLatestMessage.target?.guid, 's1');
      });

      test('a batch that fails part way writes no chat, message or attachment', () async {
        final batch = firstBatch();
        (batch['messagesData'] as List).add(msgMap('bad', t0, chat: trip)..remove('guid'));
        await expectLater(SyncActions.bulkSyncData(batch), throwsA(anything));
        expect(await store().allMessageIds(), isEmpty);
        expect(await store().findAttachmentIds(null), isEmpty);
        expect(await store().chatByGuid('iMessage;+;chat99'), isNull);
        // The batch's handles are written in the batch's one Db.write too.
        expect(await store().allHandleIds(), isEmpty);
      });

      test('SyncInterface.bulkSyncData hands back the saved messages and moved chats', () async {
        final result = await SyncInterface.bulkSyncData(messagesData: (firstBatch()['messagesData'] as List).cast());
        expect(result.messages.map((m) => m.guid), ['g1', 'g2', 'd1', 'r1', 'rename']);
        expect(result.chats.map((c) => c.guid).toSet(), {'iMessage;+;chat99', 'iMessage;-;ana@example.com'});
      });
    });

    group('R6: batches started together end as run one after the other', () {
      test('two overlapping batches', () async {
        await SyncActions.bulkSyncData(firstBatch());
        await SyncActions.bulkSyncData(secondBatch());
        final sequential = await snapshot(store());

        await fixture().reset();
        await Future.wait([SyncActions.bulkSyncData(firstBatch()), SyncActions.bulkSyncData(secondBatch())]);
        expect(await snapshot(store()), sequential);

        await fixture().reset();
        await Future.wait([SyncActions.bulkSyncData(secondBatch()), SyncActions.bulkSyncData(firstBatch())]);
        expect(await snapshot(store()), sequential, reason: 'whichever batch commits first');
      });

      test('a twin batch racing another batch of its thread', () async {
        await SyncActions.bulkSyncData(firstBatch());
        await SyncActions.bulkSyncData(twinBatch());
        await SyncActions.bulkSyncData(secondBatch());
        final sequential = await snapshot(store());
        expect(sequential['s1'], contains('chat: iMessage;-;ana@example.com'));

        await fixture().reset();
        await SyncActions.bulkSyncData(firstBatch());
        await Future.wait([SyncActions.bulkSyncData(twinBatch()), SyncActions.bulkSyncData(secondBatch())]);
        expect(await snapshot(store()), sequential);
      });

      test('five batches at once: no duplicate handle, chat or message', () async {
        await Future.wait([
          for (var i = 0; i < 5; i++) SyncActions.bulkSyncData(i.isEven ? firstBatch() : secondBatch()),
        ]);
        final snap = await snapshot(store());
        expect(snap['handles'], ['ana@example.com/iMessage/7', 'bo@example.com/iMessage/8']);
        expect(snap['messages'], 8);
        expect(snap['attachments'], 3);
        expect(snap['iMessage;+;chat99'], contains('latest: r2'));
        expect(snap['iMessage;-;ana@example.com'], contains('latest: d2'));
      });
    });
  });
}
