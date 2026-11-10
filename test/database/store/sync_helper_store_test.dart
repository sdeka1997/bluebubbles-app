// sync_helpers.dart through MessagingStore (S2 switch plan, commit 5): each
// helper is one Db.write. The same batch started concurrently must end in a state reachable
// by running the two batches sequentially in either order.
import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'store_fixture.dart';

void main() {
  storeTests((fixture) {
    test('metadata refresh folds service copies and relists chats shown by status events', () async {
      final canonical = await fixture().chat('SMS;-;+155****1111');
      final twin = await fixture().chat('RCS;-;+155****1111');
      final moved = await fixture().message('moved', twin, t0 + 20);

      final relisted = await fixture().chat('iMessage;-;relisted');
      final ordinary = await fixture().message('ordinary', relisted, t0);
      final status = await fixture().message('status', relisted, t0 + 10, itemType: 2);
      await fixture().setLatest(relisted, status);

      final result = await fixture().store.refreshChatMetadata([
        {'guid': canonical.guid, 'groupId': 'G1'},
        {'guid': twin.guid, 'groupId': 'G1', 'isFilteredAsSpam': true},
      ]);

      expect(result.changedChats.map((chat) => chat.guid), unorderedEquals([canonical.guid, twin.guid]));
      expect(result.foldedChats[twin.guid]?.id, canonical.id);
      expect(result.relistedChats.map((chat) => chat.guid), [relisted.guid]);
      expect((await fixture().store.messageByGuid(moved.guid!))!.chat.targetId, canonical.id);
      expect((await fixture().store.chatById(relisted.id!))!.dbLatestMessage.targetId, ordinary.id);
    });

    test('handle-sync reads, clears and rebuilds chat links through the facade', () async {
      final ana = await fixture().handle('ana@example.com', rowId: 7);
      final chat = await fixture().chat('iMessage;-;ana@example.com', handles: [ana]);

      expect((await fixture().store.allHandles()).map((h) => h.originalROWID), [7]);
      expect((await fixture().store.allChats()).single.handles.map((h) => h.originalROWID), [7]);

      await fixture().store.clearHandles();
      expect(await fixture().store.allHandles(), isEmpty);
      final restored = Handle(address: ana.address, service: ana.service, originalROWID: 7);
      final ids = await fixture().store.saveHandles([restored], matchOnOriginalROWID: false);
      await fixture().store.setChatHandleIds({chat.id!: ids});

      expect((await fixture().store.chatById(chat.id!))!.handles.map((h) => h.originalROWID), [7]);
    });

    test('newest stored name change includes the canonical service twin', () async {
      final canonical = await fixture().chat('SMS;+;canonical', threadKey: 'thread');
      final copy = await fixture().chat('iMessage;+;copy', threadKey: 'thread');
      await fixture().message('old-rename', copy, t0, itemType: 2);
      final newest = await fixture().message('new-rename', canonical, t0 + 10, itemType: 2);

      expect(await fixture().store.newestStoredNameChange(copy.guid), newest.dateCreated);
    });

    test('syncAttachments inserts new rows and merges stored rows without losing their owner', () async {
      final chat = await fixture().chat('iMessage;-;a@example.com');
      final owner = await fixture().message('m1', chat, t0);
      final stored = await fixture().attachment('a1', owner, mimeType: 'image/jpeg');
      stored.totalBytes = 40;
      await fixture().store.saveAttachment(stored, message: owner);

      final incoming = Attachment(
        guid: 'a1',
        mimeType: 'image/png',
        transferName: 'new.png',
        isOutgoing: false,
      );
      final fresh = Attachment(
        guid: 'a2',
        mimeType: 'text/plain',
        transferName: 'a2.txt',
        isOutgoing: false,
      );

      final synced = await fixture().store.syncAttachments([incoming, fresh]);

      expect(synced.map((a) => a.guid), ['a1', 'a2']);
      expect(synced.first.id, stored.id);
      expect(synced.first.mimeType, 'image/png', reason: 'new server fields take precedence');
      expect(synced.first.totalBytes, 40, reason: 'fields absent from the server copy survive');
      expect(synced.first.message.targetId, owner.id, reason: 'the stored owner survives');
      expect((await fixture().store.attachmentById(stored.id!))!.message.targetId, owner.id);
      expect(synced.last.id, isNotNull);
      expect((await fixture().store.attachmentById(synced.last.id!))!.guid, 'a2');
    });

    test('syncMessages inserts and merges messages and links every result to the requested chat', () async {
      final oldChat = await fixture().chat('iMessage;-;old@example.com');
      final chat = await fixture().chat('iMessage;-;new@example.com');
      final stored = await fixture().message('m1', oldChat, t0, text: 'old text', rowId: 41);
      final incoming = Message(
        guid: 'm1',
        text: 'new text',
        dateCreated: ms(t0 + 10),
        isFromMe: true,
        originalROWID: 42,
      );
      final fresh = Message(
        guid: 'm2',
        text: 'fresh',
        dateCreated: ms(t0 + 20),
        isFromMe: true,
        originalROWID: 43,
      );

      final synced = await fixture().store.syncMessages(chat, [incoming, fresh]);

      expect(synced.map((m) => m.guid), ['m1', 'm2']);
      expect(synced.first.id, stored.id);
      expect(synced.first.text, 'new text', reason: 'new server fields take precedence');
      expect(synced.first.originalROWID, 42, reason: 'fields already present on the server copy survive');
      expect(synced.every((m) => m.chat.targetId == chat.id), isTrue);
      expect((await fixture().store.messageByGuid('m1'))!.chat.targetId, chat.id);
      expect((await fixture().store.messageByGuid('m2'))!.chat.targetId, chat.id);
    });
  });
}
