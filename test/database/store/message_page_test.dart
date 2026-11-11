// S5 step 5: a page of a chat's timeline is one read. The store returns the
// messages themselves (attachments, linked messages and reactions filled), so
// no caller re-reads them by id or fetches the reactions in a second pass.
import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'store_fixture.dart';

void main() {
  storeTests((fixture) {
    test('an older page comes back with its reactions on it', () async {
      final chat = await fixture().chat('c');
      for (var i = 0; i < 10; i++) {
        await fixture().message('m$i', chat, t0 + i * 1000);
      }
      await fixture().message('r9', chat, t0 + 9 * 1000 + 1, reactsTo: 'm9');
      await fixture().message('r3', chat, t0 + 3 * 1000 + 1, reactsTo: 'm3');

      final page = await fixture().store.olderMessagePage(chat.id!, limit: 25);

      expect(page.messages.map((m) => m.guid), [for (var i = 9; i >= 0; i--) 'm$i']);
      final byGuid = {for (final m in page.messages) m.guid: m};
      expect(byGuid['m9']!.associatedMessages.map((m) => m.guid), ['r9']);
      expect(byGuid['m3']!.associatedMessages.map((m) => m.guid), ['r3']);
      expect(byGuid['m5']!.associatedMessages, isEmpty);
    });

    test('a page around a message comes back with its reactions on it', () async {
      final chat = await fixture().chat('c');
      final shown = <Message>[];
      for (var i = 0; i < 10; i++) {
        shown.add(await fixture().message('m$i', chat, t0 + i * 1000));
      }
      await fixture().message('r5', chat, t0 + 5 * 1000 + 1, reactsTo: 'm5');

      final page = await fixture().store.messagePageAround(chat.id!, shown[5].id!, limit: 2);

      expect(page.messages.map((m) => m.guid), ['m7', 'm6', 'm5', 'm4', 'm3']);
      expect(page.messages[2].associatedMessages.map((m) => m.guid), ['r5']);
    });

    test('limit 0 reads the whole chat (export), with reactions', () async {
      final chat = await fixture().chat('c');
      for (var i = 0; i < 40; i++) {
        await fixture().message('m$i', chat, t0 + i * 1000);
      }
      await fixture().message('r1', chat, t0 + 1000 + 1, reactsTo: 'm1');

      final all = await fixture().store.chatMessages(chat.id!, chat.handles.toList(), offset: 0, limit: 0, includeDeleted: true);

      expect(all.where((m) => m.associatedMessageGuid == null), hasLength(40));
      expect(all.firstWhere((m) => m.guid == 'm1').associatedMessages.map((m) => m.guid), ['r1']);
    });

    test('a page reads each message row once: none is re-read by id', () async {
      final chat = await fixture().chat('c');
      for (var i = 0; i < 30; i++) {
        await fixture().message('m$i', chat, t0 + i * 1000);
        if (i.isEven) await fixture().message('r$i', chat, t0 + i * 1000 + 1, reactsTo: 'm$i');
      }

      final statements = await fixture().db.recordStatements(() async {
        await fixture().store.olderMessagePage(chat.id!, limit: 25);
      });

      final rereads = statements.where((s) => s.$1.contains('FROM messages WHERE id IN')).toList();
      expect(rereads, isEmpty, reason: rereads.map((s) => s.$1).join('\n'));
    });
  });
}
