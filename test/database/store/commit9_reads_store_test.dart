// Reads and writes the remaining model lookups move onto (switch plan commit
// 9), the same on ObjectBox and SQLite.
import 'package:flutter_test/flutter_test.dart';

import 'store_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  forEachStore((fixture) {
    test('a chat by its chat identifier, with participants', () async {
      final bob = await fixture().handle('bob@example.com');
      final chat = await fixture().chat('iMessage;-;bob@example.com', handles: [bob], identifier: 'bobexamplecom');
      await fixture().chat('iMessage;-;carol@example.com', identifier: 'carolexamplecom');
      final found = await fixture().store.chatByIdentifier('bobexamplecom');
      expect(found?.guid, chat.guid);
      expect(found!.handles.map((h) => h.address), ['bob@example.com']);
      expect(await fixture().store.chatByIdentifier('nobody'), isNull);
    });

    test("a chat's attachments with their message, deleted messages excluded", () async {
      final chat = await fixture().chat('c');
      final other = await fixture().chat('other');
      final m1 = await fixture().message('m1', chat, t0);
      final m2 = await fixture().message('m2', chat, t0 + 1000);
      final gone = await fixture().message('gone', chat, t0 + 2000, deleted: true);
      final elsewhere = await fixture().message('elsewhere', other, t0 + 3000);
      await fixture().attachment('a1', m1, mimeType: 'image/jpeg');
      await fixture().attachment('a2', m2, mimeType: 'application/pdf');
      await fixture().attachment('noMime', m2, edit: (a) => a.mimeType = null);
      await fixture().attachment('a3', gone, mimeType: 'image/png');
      await fixture().attachment('a4', elsewhere, mimeType: 'image/png');

      final found = await fixture().store.chatAttachments(chat.id!);
      expect(found.map((a) => a.guid).toSet(), {'a1', 'a2'});
      expect(found.firstWhere((a) => a.guid == 'a2').message.target?.guid, 'm2');
    });

    test('linked messages: a reaction gets the message it reacts to (with attachments), a group event its other person',
        () async {
      final chat = await fixture().chat('c');
      final bob = await fixture().handle('bob@example.com', rowId: 7);
      await fixture().contact('n1', 'Bob Builder', handles: [bob]);
      final target = await fixture().message('target', chat, t0);
      await fixture().attachment('pic', target);
      final reaction = await fixture().message('r', chat, t0 + 1000, reactsTo: 'target');
      final added = await fixture().message('added', chat, t0 + 2000,
          itemType: 1, edit: (m) => m..groupActionType = 0..otherHandle = 7);
      final plain = await fixture().message('plain', chat, t0 + 3000);

      final loaded = [
        (await fixture().store.messageById(reaction.id!))!,
        (await fixture().store.messageById(added.id!))!,
        (await fixture().store.messageById(plain.id!))!,
      ];
      await fixture().store.fillLinkedMessages(loaded);
      expect(loaded[0].reactionTarget?.guid, 'target');
      expect(loaded[0].reactionTarget!.dbAttachments.map((a) => a.guid), ['pic']);
      expect(loaded[1].otherParticipant?.address, 'bob@example.com');
      expect(loaded[1].otherParticipant!.displayName, 'Bob Builder');
      expect(loaded[2].reactionTarget, isNull);
      expect(loaded[2].otherParticipant, isNull);
    });

    test('every message read by id or guid comes with its linked rows', () async {
      final chat = await fixture().chat('c');
      await fixture().handle('bob@example.com', rowId: 7);
      await fixture().message('target', chat, t0);
      final reaction = await fixture().message('r', chat, t0 + 1000, reactsTo: 'target');
      final added = await fixture().message('added', chat, t0 + 2000,
          itemType: 1, edit: (m) => m..groupActionType = 0..otherHandle = 7);
      expect((await fixture().store.messageById(reaction.id!))!.reactionTarget?.guid, 'target');
      expect((await fixture().store.messageByGuid('r'))!.reactionTarget?.guid, 'target');
      final page = await fixture().store.messagesByIds([reaction.id!, added.id!]);
      expect(page.first.reactionTarget?.guid, 'target');
      expect(page.last.otherParticipant?.address, 'bob@example.com');
    });

    test('handles by address on one service, for Find My names', () async {
      await fixture().handle('mom@example.com');
      await fixture().handle('mom@example.com', service: 'SMS');
      await fixture().handle('dad@example.com');
      final found = await fixture().store.handlesByAddresses(['mom@example.com', 'nobody@example.com'], 'iMessage');
      expect(found.keys, ['mom@example.com']);
      expect(found['mom@example.com']!.service, 'iMessage');
      expect(await fixture().store.handlesByAddresses([], 'iMessage'), isEmpty);
    });

    test('deleting one handle leaves the others', () async {
      final bob = await fixture().handle('bob@example.com');
      final carol = await fixture().handle('carol@example.com');
      await fixture().store.deleteHandle(bob.id!);
      expect(await fixture().store.handleById(bob.id!), isNull);
      expect((await fixture().store.handleById(carol.id!))?.address, 'carol@example.com');
    });
  });
}
