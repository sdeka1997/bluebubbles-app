// The server panel's local counts come from MessagingStore (switch plan
// commit 8).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../database/store/store_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  storeTests((fixture) {
    test('live messages and chats, handles, and attachments by kind', () async {
      final bob = await fixture().handle('bob@x.com', rowId: 1);
      final chat = await fixture().chat('c', handles: [bob]);
      await fixture().chat('gone', deleted: DateTime.utc(2024));
      final m = await fixture().message('m', chat, t0);
      await fixture().message('m2', chat, t0 + 1000);
      await fixture().message('deleted', chat, t0 + 2000, deleted: true);
      await fixture().attachment('img', m, mimeType: 'image/png');
      await fixture().attachment('vid', m, mimeType: 'video/mp4');
      await fixture().attachment('loc', m, mimeType: 'text/x-vlocation');
      await fixture().attachment('pdf', m, mimeType: 'application/pdf');

      expect(await fixture().store.localCounts(), {
        'messages': 2,
        'chats': 1,
        'handles': 1,
        'attachments': 4,
        'images': 1,
        'videos': 1,
        'locations': 1,
      });
    });
  });

  test('the server panel reads only through MessagingStore', () {
    final source = File('lib/app/layouts/settings/pages/server/server_management_panel.dart').readAsStringSync();
    expect(source, isNot(contains('Database.runInTransaction')));
    expect(source, isNot(contains('Database.messages')));
  });
}
