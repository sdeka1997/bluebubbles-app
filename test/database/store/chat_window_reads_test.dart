// S3 chat window (SQLITE-PLAN-2.md section 5): the reads the window needs
// besides the older page — the page newer than what it holds (scrolling back
// down after the newest rows were dropped), the replies of the messages it
// holds (reply counts, reply lines and "View thread" no longer rely on every
// newer message staying loaded), and the chat's newest sent / received message
// (keyboard shortcuts act on it wherever the window is).
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'store_fixture.dart';

void main() {
  forEachStore((fixture) {
    test('newer page: the rows just newer than a message, newest first, in screen order', () async {
      final chat = await fixture().chat('c');
      for (var i = 0; i < 60; i++) {
        await fixture().message('m$i', chat, t0 + (i ~/ 3) * 1000);
      }
      await fixture().message('r', chat, t0 + 59000, reactsTo: 'm10');
      final from = (await fixture().store.messageByGuid('m20'))!;

      final page = await fixture().store.newerMessagePage(chat.id!, chat.handles, from.id!, limit: 10);
      final rows = await fixture().store.messagesByIds(page);

      expect(rows.map((m) => m.guid), [for (var i = 30; i >= 21; i--) 'm$i']);
      final last = (await fixture().store.messageByGuid('m59'))!;
      expect(await fixture().store.newerMessagePage(chat.id!, chat.handles, last.id!, limit: 10), isEmpty);
    });
  }, only: {ActiveStore.sqlite});

  forEachStore((fixture) {
    test('replies of messages: every live reply of each originator, reactions and deleted left out', () async {
      final chat = await fixture().chat('c');
      await fixture().message('o1', chat, t0);
      await fixture().message('o2', chat, t0 + 1000);
      await fixture().message('a', chat, t0 + 2000, threadOriginator: 'o1');
      await fixture().message('b', chat, t0 + 3000, threadOriginator: 'o1');
      await fixture().message('c', chat, t0 + 4000, threadOriginator: 'o2');
      await fixture().message('gone', chat, t0 + 5000, threadOriginator: 'o1', deleted: true);
      await fixture().message('tap', chat, t0 + 6000, threadOriginator: 'o1', reactsTo: 'a');
      await fixture().message('other', chat, t0 + 7000, threadOriginator: 'elsewhere');

      final replies = await fixture().store.repliesOf(['o1', 'o2', 'none']);

      expect(replies.map((m) => m.guid).toSet(), {'a', 'b', 'c'});
    });

    test('newest sent and received: the chat newest of each, not reactions or deleted', () async {
      final them = await fixture().handle('+15550001', rowId: 1);
      final chat = await fixture().chat('c', handles: [them]);
      await fixture().message('in1', chat, t0, from: them);
      await fixture().message('out1', chat, t0 + 1000);
      await fixture().message('in2', chat, t0 + 2000, from: them);
      await fixture().message('out2', chat, t0 + 3000);
      await fixture().message('outGone', chat, t0 + 4000, deleted: true);
      await fixture().message('inTap', chat, t0 + 5000, from: them, reactsTo: 'out2');
      await fixture().message('outTap', chat, t0 + 6000, reactsTo: 'in2');

      expect((await fixture().store.newestTimelineMessage(chat.id!, fromMe: true))?.guid, 'out2');
      expect((await fixture().store.newestTimelineMessage(chat.id!, fromMe: false))?.guid, 'in2');
      expect((await fixture().store.newestTimelineMessage(chat.id!))?.guid, 'out2');
    });
  });
}
