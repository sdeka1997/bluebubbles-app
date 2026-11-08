import 'package:bluebubbles/services/backend/sync/incremental_sync_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isStaleRowIdBookmark', () {
    test('a bookmark past the newest server message came from a previous chat.db', () {
      // Saved against the old database; the replacement's newest ROWID is 113.
      expect(isStaleRowIdBookmark(801519, 113), isTrue);
    });

    test('a bookmark at the newest server message is just caught up', () {
      expect(isStaleRowIdBookmark(113, 113), isFalse);
    });

    test('a bookmark below the newest server message is valid', () {
      expect(isStaleRowIdBookmark(100, 113), isFalse);
    });

    test('an empty server database proves nothing', () {
      expect(isStaleRowIdBookmark(801519, null), isFalse);
    });
  });
}
