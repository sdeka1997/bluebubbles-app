// Contact refreshes find the chats to redraw through MessagingStore (S2 switch
// plan, commit 7): only live chats that include an updated handle, on both
// stores, and ContactServiceV2 no longer reads ObjectBox itself.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../database/store/store_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  forEachStore((fixture) {
    test('live chats with any of the given participants', () async {
      final bob = await fixture().handle('bob@x.com', rowId: 1);
      final amy = await fixture().handle('amy@x.com', rowId: 2);
      final cat = await fixture().handle('cat@x.com', rowId: 3);
      final withBob = await fixture().chat('bob', handles: [bob]);
      final group = await fixture().chat('group', handles: [amy, cat]);
      await fixture().chat('cat', handles: [cat]);
      await fixture().chat('gone', handles: [bob], deleted: DateTime(2024));

      final store = fixture().store;
      expect((await store.liveChatsWithParticipants([bob.id!, amy.id!])).map((c) => c.guid).toSet(),
          {withBob.guid, group.guid});
      expect(await store.liveChatsWithParticipants([]), isEmpty);
    });
  });

  test('ContactServiceV2 reads only through MessagingStore', () {
    final source = File('lib/services/ui/contact_service_v2.dart').readAsStringSync();
    expect(source, isNot(contains('Database.')));
  });
}
