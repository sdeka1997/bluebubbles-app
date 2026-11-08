// MessageActions/MessageInterface and AttachmentActions/AttachmentInterface
// through MessagingStore (S2 switch plan, commits 4-5), every case on both
// stores, including the attachment query descriptors (SQL builder vs ObjectBox
// conditions).
import 'package:bluebubbles/env.dart';
import 'package:bluebubbles/services/backend/actions/attachment_actions.dart';
import 'package:bluebubbles/services/backend/actions/message_actions.dart';
import 'package:bluebubbles/services/backend/descriptors/attachment_query_descriptor.dart';
import 'package:bluebubbles/services/backend/interfaces/attachment_interface.dart';
import 'package:bluebubbles/services/backend/interfaces/message_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'store_fixture.dart';

Map<String, dynamic> msg(String guid, int msValue,
        {int handleId = 0, bool fromMe = false, String? reactsTo, String? text, int? rowId, bool bookmarked = false}) =>
    {
      'guid': guid,
      'text': text,
      'dateCreated': msValue,
      'isFromMe': fromMe,
      'handleId': handleId,
      'originalROWID': ?rowId,
      'isBookmarked': bookmarked,
      if (reactsTo != null) ...{'associatedMessageGuid': 'p:0/$reactsTo', 'associatedMessageType': 'love'},
    };

AttachmentQueryDescriptor where(List<(AttachmentQueryField, AttachmentQueryOperator, Object)> conditions,
        {AttachmentQueryLogic logic = AttachmentQueryLogic.and}) =>
    AttachmentQueryDescriptor(
      conditions: [for (final (f, o, v) in conditions) AttachmentQueryCondition(field: f, operator: o, value: v)],
      logic: logic,
    );

void main() {
  setUpAll(() => isIsolateOverride = true);
  tearDownAll(() => isIsolateOverride = false);

  forEachStore((fixture) {
    group('MessageActions', () {
      test('saveMessageAsync inserts, links the sender by ROWID and the chat; a re-save keeps id, text and bookmark',
          () async {
        final ana = await fixture().handle('ana@x.com', rowId: 7);
        final chat = await fixture().chat('c1', handles: [ana]);
        final id = await MessageActions.saveMessageAsync({
          'messageData': msg('m1', t0, handleId: 7, text: 'hi', bookmarked: true),
          'chatData': chat.toMap(),
          'updateIsBookmarked': true,
        });
        final again = await MessageActions.saveMessageAsync({
          'messageData': msg('m1', t0, handleId: 7, text: 'hi again'),
          'chatData': chat.toMap(),
          'updateIsBookmarked': false,
        });
        expect(again, id);
        final stored = (await fixture().store.messageById(id))!;
        expect((stored.text, stored.isBookmarked), ('hi again', true));
        expect(stored.handleRelation.target?.address, 'ana@x.com');
        expect(stored.chat.target?.guid, 'c1');
      });

      test('saveMessageAsync flags reactions both ways', () async {
        final chat = await fixture().chat('c1');
        await fixture().message('r0', chat, t0, reactsTo: 'm2', rowId: 1);
        await MessageActions.saveMessageAsync(
            {'messageData': msg('m1', t0), 'chatData': chat.toMap(), 'updateIsBookmarked': false});
        await MessageActions.saveMessageAsync(
            {'messageData': msg('r1', t0 + 1, reactsTo: 'm1'), 'chatData': chat.toMap(), 'updateIsBookmarked': false});
        final m2 = await MessageActions.saveMessageAsync(
            {'messageData': msg('m2', t0 + 2), 'chatData': chat.toMap(), 'updateIsBookmarked': false});
        expect((await fixture().store.messageByGuid('m1'))!.hasReactions, isTrue);
        expect((await fixture().store.messageById(m2))!.hasReactions, isTrue, reason: 'its reaction was stored first');
      });

      test('replaceMessage swaps the temp guid and takes the server dates and error; a missing one throws', () async {
        final chat = await fixture().chat('c1');
        final temp = await fixture().message('temp-1', chat, t0, text: 'hello');
        final id = await MessageActions.replaceMessage({
          'oldGuid': 'temp-1',
          'newMessageData': {...msg('real-1', t0, text: 'hello!'), 'dateDelivered': t0 + 5, 'error': 0},
        });
        expect(id, temp.id);
        final stored = (await fixture().store.messageById(id))!;
        expect((stored.guid, stored.text, stored.dateDelivered), ('real-1', 'hello!', ms(t0 + 5)));
        expect(stored.chat.target?.guid, 'c1', reason: 'replace keeps the chat');
        await expectLater(
            MessageActions.replaceMessage({'oldGuid': 'nope', 'newMessageData': msg('x', t0)}), throwsA(anything));
      });

      test('soft delete, restore and delete', () async {
        final chat = await fixture().chat('c1');
        final m = await fixture().message('m1', chat, t0);
        await MessageActions.softDeleteMessage({'guid': 'm1'});
        expect((await fixture().store.messageById(m.id!))!.dateDeleted, isNotNull);
        await MessageActions.restoreMessage({'guid': 'm1'});
        expect((await fixture().store.messageById(m.id!))!.dateDeleted, isNull);
        await MessageActions.deleteMessage({'guid': 'm1'});
        expect(await fixture().store.messageById(m.id!), isNull);
        await MessageActions.deleteMessage({'guid': 'never'});
      });

      test('findOneAsync by guid or associated guid; findAsync returns every message', () async {
        final chat = await fixture().chat('c1');
        final m = await fixture().message('m1', chat, t0);
        final r = await fixture().message('r1', chat, t0 + 1, reactsTo: 'm1');
        expect(await MessageActions.findOneAsync({'guid': 'm1'}), m.id);
        expect(await MessageActions.findOneAsync({'associatedMessageGuid': 'm1'}), r.id);
        expect(await MessageActions.findOneAsync({'guid': 'nope'}), isNull);
        expect(await MessageActions.findOneAsync({}), isNull);
        expect(await MessageActions.findAsync({}), unorderedEquals([m.id, r.id]));
      });

      test('fetchAssociatedMessagesAsync: normalized reactions plus the thread originator, by ROWID', () async {
        final chat = await fixture().chat('c1');
        await fixture().message('origin', chat, t0, rowId: 1);
        await fixture().message('m1', chat, t0 + 1, rowId: 5, threadOriginator: 'origin');
        await fixture().message('r1', chat, t0 + 2, reactsTo: 'm1', rowId: 9);
        await fixture().message('r2', chat, t0 + 3, reactsTo: 'm1', rowId: 7);
        final result = await MessageActions.fetchAssociatedMessagesAsync(
            {'messageGuid': 'm1', 'messageId': null, 'threadOriginatorGuid': 'origin'});
        final guids = [for (final m in result['associatedMessages'] as List) (m as Map)['guid']];
        expect(guids, ['origin', 'r2', 'r1']);
      });

      test('relinkMessagesToHandle links messages from the server handle, never mine', () async {
        final chat = await fixture().chat('c1');
        final ana = await fixture().handle('ana@x.com', rowId: 70);
        await fixture().message('a', chat, t0, handleId: 70);
        await fixture().message('b', chat, t0 + 1, handleId: 70);
        await fixture().message('mine', chat, t0 + 2);
        await fixture().message('other', chat, t0 + 3, handleId: 71);
        expect(await MessageActions.relinkMessagesToHandle({'handleId': 70, 'localHandleId': ana.id}), 2);
        expect(await MessageActions.relinkMessagesToHandle({'handleId': 70, 'localHandleId': ana.id}), 0);
        expect((await fixture().store.messageByGuid('a'))!.handleRelation.targetId, ana.id);
        expect((await fixture().store.messageByGuid('other'))!.handleRelation.targetId, 0);
      });

      test('MessageInterface returns the stored messages', () async {
        final chat = await fixture().chat('c1');
        await fixture().message('temp', chat, t0);
        final saved = await MessageInterface.saveMessageAsync(messageData: msg('m1', t0), updateIsBookmarked: false);
        expect(saved!.guid, 'm1');
        expect((await MessageInterface.replaceMessage(oldGuid: 'temp', newMessageData: msg('real', t0))).guid, 'real');
        expect((await MessageInterface.findOneAsync(guid: 'real'))!.chat.target?.guid, 'c1');
        expect((await MessageInterface.findAsync()).map((m) => m.guid), unorderedEquals(['m1', 'real']));
      });
    });

    group('AttachmentActions', () {
      test('saveAttachmentAsync: new; a re-save keeps id and message unless a message is given', () async {
        final chat = await fixture().chat('c1');
        final m1 = await fixture().message('m1', chat, t0);
        final m2 = await fixture().message('m2', chat, t0 + 1);
        final id = await AttachmentActions.saveAttachmentAsync({
          'attachmentData': {'guid': 'a1', 'mimeType': 'image/png', 'transferName': 'a.png'},
          'messageData': m1.toMap(),
        });
        expect(
            await AttachmentActions.saveAttachmentAsync(
                {'attachmentData': {'guid': 'a1', 'mimeType': 'image/png', 'totalBytes': 9}, 'messageData': null}),
            id);
        var stored = (await fixture().store.attachmentById(id))!;
        expect((stored.totalBytes, stored.message.target?.guid), (9, 'm1'));
        await AttachmentActions.saveAttachmentAsync(
            {'attachmentData': {'guid': 'a1', 'mimeType': 'image/png'}, 'messageData': m2.toMap()});
        stored = (await fixture().store.attachmentById(id))!;
        expect(stored.message.target?.guid, 'm2');
      });

      test('bulkSaveAttachmentsAsync keeps stored ids and message links; new ones are saved unlinked', () async {
        final chat = await fixture().chat('c1');
        final m1 = await fixture().message('m1', chat, t0);
        final a1 = await fixture().attachment('a1', m1);
        await AttachmentActions.bulkSaveAttachmentsAsync({
          'mapData': <Map<String, dynamic>, List<Map<String, dynamic>>>{
            m1.toMap(): [
              {'guid': 'a1', 'mimeType': 'image/png', 'totalBytes': 5},
              {'guid': 'a2', 'mimeType': 'image/gif'},
            ],
          },
        });
        // Today's behaviour on both stores: the map's message is not linked to
        // the attachments, so a2 is stored but no guid lookup (a link join) finds it.
        final ids = await AttachmentActions.findAttachmentsAsync({});
        expect(ids, [a1.id]);
        final first = (await fixture().store.attachmentById(a1.id!))!;
        expect((first.totalBytes, first.mimeType, first.message.target?.guid), (5, 'image/png', 'm1'));
        expect(await fixture().store.attachmentById(a1.id! + 1), isNotNull);
      });

      test('replaceAttachmentAsync moves the temp guid, or merges into a stored copy of the new one', () async {
        final chat = await fixture().chat('c1');
        final m1 = await fixture().message('m1', chat, t0);
        final temp = await fixture().attachment('temp-a', m1);
        final id = await AttachmentActions.replaceAttachmentAsync(
            {'oldGuid': 'temp-a', 'newAttachmentData': {'guid': 'real-a', 'mimeType': 'image/png', 'totalBytes': 3}});
        expect(id, temp.id);
        final stored = (await fixture().store.attachmentById(id))!;
        expect((stored.guid, stored.totalBytes, stored.message.target?.guid), ('real-a', 3, 'm1'));

        final temp2 = await fixture().attachment('temp-b', m1);
        final real2 = await fixture().attachment('real-b', m1);
        final merged = await AttachmentActions.replaceAttachmentAsync(
            {'oldGuid': 'temp-b', 'newAttachmentData': {'guid': 'real-b', 'mimeType': 'video/mp4', 'totalBytes': 4}});
        expect(merged, real2.id);
        expect(await fixture().store.attachmentById(temp2.id!), isNull);
        expect((await fixture().store.attachmentById(real2.id!))!.mimeType, 'video/mp4');

        await expectLater(
            AttachmentActions.replaceAttachmentAsync({'oldGuid': 'nope', 'newAttachmentData': {'guid': 'x'}}),
            throwsA(anything));
      });

      test('findOneAttachmentAsync and deleteAttachmentAsync', () async {
        final m1 = await fixture().message('m1', await fixture().chat('c1'), t0);
        final a = await fixture().attachment('a1', m1);
        expect(await AttachmentActions.findOneAttachmentAsync({'guid': 'a1'}), a.id);
        await AttachmentActions.deleteAttachmentAsync({'guid': 'a1'});
        expect(await AttachmentActions.findOneAttachmentAsync({'guid': 'a1'}), isNull);
      });

      test('lookups by guid and query only see attachments that belong to a message (ObjectBox link join)', () async {
        final m1 = await fixture().message('m1', await fixture().chat('c1'), t0);
        await fixture().attachment('linked', m1);
        final loose = await fixture().attachment('loose', null);
        expect(await AttachmentActions.findOneAttachmentAsync({'guid': 'loose'}), isNull);
        expect(await AttachmentActions.findAttachmentsAsync({}), hasLength(1));
        await expectLater(
            AttachmentActions.replaceAttachmentAsync({'oldGuid': 'loose', 'newAttachmentData': {'guid': 'x'}}),
            throwsA(anything));
        await AttachmentActions.deleteAttachmentAsync({'guid': 'loose'});
        expect(await fixture().store.attachmentById(loose.id!), isNull, reason: 'delete does not join');
      });

      test('findAttachmentsAsync: each query descriptor shape gives the same rows', () async {
        final m1 = await fixture().message('m1', await fixture().chat('c1'), t0);
        Future<void> add(String guid, String mime, int bytes, {bool outgoing = false}) async {
          await AttachmentActions.saveAttachmentAsync({
            'attachmentData': {'guid': guid, 'mimeType': mime, 'totalBytes': bytes, 'isOutgoing': outgoing},
            'messageData': m1.toMap(),
          });
        }

        await add('Img-1', 'image/png', 10);
        await add('img-2', 'image/JPEG', 20, outgoing: true);
        await add('vid_1', 'video/mp4', 30);
        await add('vid%2', 'video/quicktime', 40, outgoing: true);
        Future<List<String?>> find(AttachmentQueryDescriptor d) async => [
              for (final a in await fixture().store.attachmentsByIds(
                  await AttachmentActions.findAttachmentsAsync({'queryDescriptor': d.toMap()})))
                a.guid
            ]..sort();
        expect(await find(where([(AttachmentQueryField.guid, AttachmentQueryOperator.oneOf, ['IMG-1', 'vid_1', 'x'])])),
            ['Img-1', 'vid_1']);
        expect(await find(where([(AttachmentQueryField.guid, AttachmentQueryOperator.equals, 'IMG-2')])), ['img-2']);
        expect(await find(where([(AttachmentQueryField.mimeType, AttachmentQueryOperator.startsWith, 'IMAGE/')])),
            ['Img-1', 'img-2']);
        expect(await find(where([(AttachmentQueryField.guid, AttachmentQueryOperator.contains, '_')])), ['vid_1']);
        expect(await find(where([(AttachmentQueryField.guid, AttachmentQueryOperator.contains, '%')])), ['vid%2']);
        expect(await find(where([(AttachmentQueryField.mimeType, AttachmentQueryOperator.endsWith, 'jpeg')])), ['img-2']);
        expect(
            await find(where([
              (AttachmentQueryField.totalBytes, AttachmentQueryOperator.greaterThan, 15),
              (AttachmentQueryField.isOutgoing, AttachmentQueryOperator.equals, true),
            ])),
            ['img-2', 'vid%2']);
        expect(
            await find(where([
              (AttachmentQueryField.totalBytes, AttachmentQueryOperator.lessOrEqual, 10),
              (AttachmentQueryField.totalBytes, AttachmentQueryOperator.between, [35, 45]),
            ], logic: AttachmentQueryLogic.or)),
            ['Img-1', 'vid%2']);
        expect(await find(where([(AttachmentQueryField.totalBytes, AttachmentQueryOperator.notOneOf, [10, 20])])),
            ['vid%2', 'vid_1']);
        expect(await find(AttachmentQueryDescriptor(conditions: [])), hasLength(4));
      });

      test('AttachmentInterface returns the stored attachments with their message', () async {
        final chat = await fixture().chat('c1');
        final m1 = await fixture().message('m1', chat, t0);
        final saved = await AttachmentInterface.saveAttachmentAsync(
            attachmentData: {'guid': 'a1', 'mimeType': 'image/png'}, messageData: m1.toMap());
        expect(saved.message.target?.guid, 'm1');
        expect((await AttachmentInterface.findOneAttachmentAsync(guid: 'a1'))!.id, saved.id);
        final replaced = await AttachmentInterface.replaceAttachmentAsync(
            oldGuid: 'a1', newAttachmentData: {'guid': 'a2', 'mimeType': 'image/png'});
        expect((replaced.guid, replaced.message.target?.guid), ('a2', 'm1'));
        expect((await AttachmentInterface.findAttachmentsAsync()).map((a) => a.guid), ['a2']);
      });
    });
  });
}
