// The incremental-sync markers (SQLITE-PLAN-2 section 6, risk R5): the app
// reads and writes its own `sqlite*` keys, so the keys builds before SQLite
// used stay where the last such build left them and a rollback to one
// re-syncs what it never saw.
import 'package:bluebubbles/database/global/settings.dart';
import 'package:bluebubbles/services/backend/sync/sync_marker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Settings withMarkers({int ts = 0, int rowId = 0, int total = 0, int sqTs = 0, int sqRowId = 0, int sqTotal = 0}) =>
      Settings.fromMap({
        'lastIncrementalSync': ts,
        'lastIncrementalSyncRowId': rowId,
        'incrementalCatchUpTotal': total,
        'sqliteLastIncrementalSync': sqTs,
        'sqliteLastIncrementalSyncRowId': sqRowId,
        'sqliteIncrementalCatchUpTotal': sqTotal,
      });

  test('the keys are the sqlite ones, none shared with builds before SQLite', () {
    expect(SyncMarkerKeys.all, ['sqliteLastIncrementalSync', 'sqliteLastIncrementalSyncRowId', 'sqliteIncrementalCatchUpTotal']);
    expect(SyncMarkerKeys.all.toSet().intersection({'lastIncrementalSync', 'lastIncrementalSyncRowId', 'incrementalCatchUpTotal'}),
        isEmpty);
  });

  test('the sqlite keys are settings: saved by toMap, loaded by fromMap', () {
    final s = withMarkers(sqTs: 111, sqRowId: 222, sqTotal: 333);
    expect(s.sqliteLastIncrementalSync.value, 111);
    expect(s.sqliteLastIncrementalSyncRowId.value, 222);
    expect(s.sqliteIncrementalCatchUpTotal.value, 333);
    expect(s.toMap(), containsPair('sqliteLastIncrementalSync', 111));
    expect(s.toMap(), containsPair('sqliteLastIncrementalSyncRowId', 222));
    expect(s.toMap(), containsPair('sqliteIncrementalCatchUpTotal', 333));
    expect(Settings.fromMap({}).sqliteLastIncrementalSync.value, 0);
  });

  test('writes go to the sqlite keys only, leaving the old ones where a rollback resumes', () {
    final s = withMarkers(ts: 10, rowId: 20, total: 0, sqTs: 50, sqRowId: 60, sqTotal: 5);
    final m = SyncMarker(s);
    expect((m.timestamp, m.rowId, m.catchUpTotal), (50, 60, 5));
    m.timestamp = 51;
    m.rowId = 61;
    m.catchUpTotal = 0;
    expect((s.sqliteLastIncrementalSync.value, s.sqliteLastIncrementalSyncRowId.value, s.sqliteIncrementalCatchUpTotal.value),
        (51, 61, 0));
    expect((s.lastIncrementalSync.value, s.lastIncrementalSyncRowId.value), (10, 20), reason: 'rollback resumes from here');
  });

  test('an unset sqlite marker reads the old one, each key on its own; a catch-up total is not carried over', () {
    final s = withMarkers(ts: 10, rowId: 20, total: 30);
    final m = SyncMarker(s);
    expect((m.timestamp, m.rowId), (10, 20));
    expect(m.catchUpTotal, 0);
    m.rowId = 25;
    s.lastIncrementalSyncRowId.value = 5;
    expect(m.rowId, 25);
    expect(m.timestamp, 10);
  });
}
