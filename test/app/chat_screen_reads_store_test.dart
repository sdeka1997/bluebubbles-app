// Message reads the chat screens use (switch plan commit 8), the same on
// ObjectBox and SQLite: the links section, bookmarks, and how far down the
// timeline a message sits (jump to a reply or the last read message).
import 'package:flutter_test/flutter_test.dart';

import '../database/store/store_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  forEachStore((fixture) {
    test('link previews of a chat, newest first', () async {
      final chat = await fixture().chat('c');
      final other = await fixture().chat('other');
      void link(m) => m
        ..balloonBundleId = 'com.apple.messages.URLBalloonProvider'
        ..dbPayloadData = '{"type": 0}';
      await fixture().message('l1', chat, t0, edit: link);
      await fixture().message('l2', chat, t0 + 2000, edit: link);
      await fixture().message('noPayload', chat, t0 + 3000,
          edit: (m) => m.balloonBundleId = 'com.apple.messages.URLBalloonProvider');
      await fixture().message('gone', chat, t0 + 4000, deleted: true, edit: link);
      await fixture().message('plain', chat, t0 + 5000);
      await fixture().message('elsewhere', other, t0 + 6000, edit: link);

      expect((await fixture().store.linkMessages(chat.id!)).map((m) => m.guid), ['l2', 'l1']);
    });

    test('bookmarked messages of a chat, newest first, with attachments', () async {
      final chat = await fixture().chat('c');
      final b1 = await fixture().message('b1', chat, t0, edit: (m) => m.isBookmarked = true);
      await fixture().message('b2', chat, t0 + 1000, edit: (m) => m.isBookmarked = true);
      await fixture().message('plain', chat, t0 + 2000);
      await fixture().attachment('a1', b1);

      final found = await fixture().store.bookmarkedMessages(chat.id!);
      expect(found.map((m) => m.guid), ['b2', 'b1']);
      expect(found.last.dbAttachments.map((a) => a.guid), ['a1']);
    });

    test('a message\'s position counts the live timeline messages newer than it', () async {
      final chat = await fixture().chat('c');
      for (var i = 0; i < 10; i++) {
        await fixture().message('m$i', chat, t0 + i * 1000);
      }
      await fixture().message('gone', chat, t0 + 20000, deleted: true);
      final m3 = (await fixture().store.messageByGuid('m3'))!;

      expect(await fixture().store.timelinePosition(chat.id!, m3.id!), 6);
    });
  });
}
