// Thread helpers read through MessagingStore (switch plan commit 8): the newest
// message a chat lists, a thread's copies, the chats to mark read and the
// thread's name.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../database/store/store_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  storeTests((fixture) {
    test('newest message a chat lists: no deleted ones, no status items unless asked', () async {
      final chat = await fixture().chat('c');
      await fixture().message('old', chat, t0);
      await fixture().message('new', chat, t0 + 1000);
      await fixture().message('rename', chat, t0 + 2000, itemType: 2);
      await fixture().message('gone', chat, t0 + 3000, deleted: true);
      final store = fixture().store;

      expect((await store.newestMessageIn(chat.id!))?.guid, 'new');
      expect((await store.newestMessageIn(chat.id!, listing: false))?.guid, 'rename');
      expect(await store.newestMessageIn((await fixture().chat('empty')).id!), isNull);
    });

    test('a thread\'s live copies, the chats to mark read, and its name', () async {
      final sms = await fixture().chat('SMS;-;+1', threadKey: 'k');
      final imsg = await fixture().chat('iMessage;-;+1', threadKey: 'k');
      await fixture().chat('gone', threadKey: 'k', deleted: DateTime.utc(2024));
      final alone = await fixture().chat('alone');
      final store = fixture().store;

      expect((await store.threadChatsOf(sms)).map((c) => c.guid).toSet(), {sms.guid, imsg.guid});
      expect((await store.threadChatsOf(alone)).map((c) => c.guid), [alone.guid]);
      expect((await store.threadGuidsToMarkRead(sms.guid)).toSet(), {sms.guid, imsg.guid, 'gone'});
      expect(await store.threadGuidsToMarkRead('missing'), ['missing']);
    });

    test('thread name: renamed copies that disagree follow the newest rename', () async {
      final a = await fixture().chat('a', threadKey: 'k', groupTitle: 'Old');
      await fixture().chat('b', threadKey: 'k', groupTitle: 'New');
      await fixture().message('r1', a, t0, itemType: 2, edit: (m) => m.groupTitle = 'Old');
      await fixture().message('r2', a, t0 + 1000, itemType: 2, edit: (m) => m.groupTitle = 'New');

      expect(await fixture().store.threadNameOf(a), 'New');
      expect(await fixture().store.threadNameOf(await fixture().chat('solo')), isNull);
    });
  });

  test('the thread helpers no longer read ObjectBox', () {
    for (final path in [
      'lib/helpers/types/helpers/chat_list_message.dart',
      'lib/helpers/types/helpers/service_twin_helpers.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('Database.')), reason: path);
    }
  });
}
