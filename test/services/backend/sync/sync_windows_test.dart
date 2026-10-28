import 'package:bluebubbles/services/backend/sync/sync_windows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextSyncWindow', () {
    test('covers the next batch of ROWIDs after the cursor', () {
      expect(nextSyncWindow(cursor: 1000, batchSize: 1000), (after: 1000, upTo: 2000));
    });

    test('stops at the requested end ROWID', () {
      expect(nextSyncWindow(cursor: 1000, batchSize: 1000, endRowId: 1500), (after: 1000, upTo: 1500));
    });
  });

  group('syncWindowsDone', () {
    test('done once every message counted at the start has been seen', () {
      expect(syncWindowsDone(seen: 3000, total: 3000, cursor: 4000, emptyRun: 0), isTrue);
      expect(syncWindowsDone(seen: 2999, total: 3000, cursor: 4000, emptyRun: 0), isFalse);
    });

    test('done at the requested end ROWID', () {
      expect(syncWindowsDone(seen: 10, total: 3000, cursor: 1500, emptyRun: 0, endRowId: 1500), isTrue);
    });

    test('a long run of empty windows hands over to offset paging', () {
      expect(syncWindowsDone(seen: 10, total: 3000, cursor: 90000, emptyRun: maxEmptySyncWindows), isTrue);
      expect(syncWindowsDone(seen: 10, total: 3000, cursor: 90000, emptyRun: maxEmptySyncWindows - 1), isFalse);
    });
  });

  group('syncBookmark', () {
    test('never moves backwards past a saved checkpoint', () {
      // Pages are sorted by date, so the highest ROWID seen can be below the
      // window already checkpointed.
      expect(syncBookmark(checkpoint: 5000, lastSyncedRowId: 4200), 5000);
    });

    test('moves forward to the highest ROWID synced', () {
      expect(syncBookmark(checkpoint: 5000, lastSyncedRowId: 5100), 5100);
      expect(syncBookmark(checkpoint: null, lastSyncedRowId: 4200), 4200);
      expect(syncBookmark(checkpoint: 5000, lastSyncedRowId: null), 5000);
    });
  });
}
