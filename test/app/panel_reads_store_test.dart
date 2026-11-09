// Reads the settings panels and pickers use (switch plan commit 8), the same on
// ObjectBox and SQLite.
import 'package:flutter_test/flutter_test.dart';

import '../database/store/store_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  forEachStore((fixture) {
    test('deleted chats, most recently deleted first', () async {
      await fixture().chat('live');
      await fixture().chat('old', deleted: DateTime.utc(2024, 1, 1));
      await fixture().chat('new', deleted: DateTime.utc(2025, 1, 1));

      expect((await fixture().store.deletedChats()).map((c) => c.guid), ['new', 'old']);
    });

    test('handles without a server row id, and the handle count', () async {
      await fixture().handle('a@x.com', rowId: 1);
      final b = await fixture().handle('b@x.com');
      await fixture().handle('c@x.com', rowId: 3);

      expect((await fixture().store.handlesWithoutRowId()).map((h) => h.id), [b.id]);
      expect(await fixture().store.handleCount(), 3);
    });
  });
}
