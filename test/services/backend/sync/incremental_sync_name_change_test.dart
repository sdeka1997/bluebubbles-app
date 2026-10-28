import 'package:bluebubbles/services/backend/sync/incremental_sync_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldApplyNameChange', () {
    test('an old rename synced after a newer one keeps the newer name', () {
      // Messages in iCloud backfills the 2026-03-11 rename after the 06-19 one is stored.
      expect(shouldApplyNameChange(DateTime(2026, 3, 11), DateTime(2026, 6, 19)), isFalse);
    });

    test('the rename already stored does not apply again', () {
      expect(shouldApplyNameChange(DateTime(2026, 6, 19), DateTime(2026, 6, 19)), isFalse);
    });

    test('a newer rename applies', () {
      expect(shouldApplyNameChange(DateTime(2026, 6, 19), DateTime(2026, 3, 31)), isTrue);
    });

    test('a rename applies when none is stored for the chat', () {
      expect(shouldApplyNameChange(DateTime(2026, 3, 11), null), isTrue);
    });
  });
}
