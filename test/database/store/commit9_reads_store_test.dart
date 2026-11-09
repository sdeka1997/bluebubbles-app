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

    test('deleting one handle leaves the others', () async {
      final bob = await fixture().handle('bob@example.com');
      final carol = await fixture().handle('carol@example.com');
      await fixture().store.deleteHandle(bob.id!);
      expect(await fixture().store.handleById(bob.id!), isNull);
      expect((await fixture().store.handleById(carol.id!))?.address, 'carol@example.com');
    });
  });
}
