// Sync marker keys per store (SQLITE-PLAN-2 section 6, risk R5): SQLite builds
// read and write their own `sqlite*` incremental-sync markers, so the
// ObjectBox ones stay where the last ObjectBox build left them and a rollback
// re-syncs what it never saw. Not wired into the sync yet (slice B2).
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

  test('each store has its own keys; the ObjectBox ones are the existing settings keys', () {
    expect(SyncMarkerKeys.of(ActiveStore.objectBox).timestamp, 'lastIncrementalSync');
    expect(SyncMarkerKeys.of(ActiveStore.objectBox).rowId, 'lastIncrementalSyncRowId');
    expect(SyncMarkerKeys.of(ActiveStore.objectBox).catchUpTotal, 'incrementalCatchUpTotal');
    expect(SyncMarkerKeys.of(ActiveStore.sqlite).timestamp, 'sqliteLastIncrementalSync');
    expect(SyncMarkerKeys.of(ActiveStore.sqlite).rowId, 'sqliteLastIncrementalSyncRowId');
    expect(SyncMarkerKeys.of(ActiveStore.sqlite).catchUpTotal, 'sqliteIncrementalCatchUpTotal');
    expect(SyncMarkerKeys.of(ActiveStore.sqlite).all.toSet().intersection(SyncMarkerKeys.of(ActiveStore.objectBox).all.toSet()),
        isEmpty);
  });

  test('the sqlite keys are settings: saved by toMap, loaded by fromMap and updateFromMap-shaped maps', () {
    final s = withMarkers(sqTs: 111, sqRowId: 222, sqTotal: 333);
    expect(s.sqliteLastIncrementalSync.value, 111);
    expect(s.sqliteLastIncrementalSyncRowId.value, 222);
    expect(s.sqliteIncrementalCatchUpTotal.value, 333);
    expect(s.toMap(), containsPair('sqliteLastIncrementalSync', 111));
    expect(s.toMap(), containsPair('sqliteLastIncrementalSyncRowId', 222));
    expect(s.toMap(), containsPair('sqliteIncrementalCatchUpTotal', 333));
    expect(Settings.fromMap({}).sqliteLastIncrementalSync.value, 0);
  });

  test('ObjectBox builds read and write only the ObjectBox marker', () {
    final s = withMarkers(ts: 10, rowId: 20, total: 30, sqTs: 99, sqRowId: 98, sqTotal: 97);
    final m = SyncMarker.of(s, ActiveStore.objectBox);
    expect((m.timestamp, m.rowId, m.catchUpTotal), (10, 20, 30));
    m.timestamp = 11;
    m.rowId = 21;
    m.catchUpTotal = 0;
    expect((s.lastIncrementalSync.value, s.lastIncrementalSyncRowId.value, s.incrementalCatchUpTotal.value), (11, 21, 0));
    expect((s.sqliteLastIncrementalSync.value, s.sqliteLastIncrementalSyncRowId.value, s.sqliteIncrementalCatchUpTotal.value),
        (99, 98, 97));
  });

  test('SQLite builds write only the sqlite marker, leaving the ObjectBox one where the last ObjectBox build left it', () {
    final s = withMarkers(ts: 10, rowId: 20, total: 0, sqTs: 50, sqRowId: 60, sqTotal: 5);
    final m = SyncMarker.of(s, ActiveStore.sqlite);
    expect((m.timestamp, m.rowId, m.catchUpTotal), (50, 60, 5));
    m.timestamp = 51;
    m.rowId = 61;
    m.catchUpTotal = 0;
    expect((s.sqliteLastIncrementalSync.value, s.sqliteLastIncrementalSyncRowId.value, s.sqliteIncrementalCatchUpTotal.value),
        (51, 61, 0));
    expect((s.lastIncrementalSync.value, s.lastIncrementalSyncRowId.value), (10, 20), reason: 'rollback resumes from here');
    expect(m.keys.all, ['sqliteLastIncrementalSync', 'sqliteLastIncrementalSyncRowId', 'sqliteIncrementalCatchUpTotal']);
  });

  test('a first SQLite run starts from the ObjectBox marker: the copy holds everything ObjectBox had', () {
    final s = withMarkers(ts: 10, rowId: 20);
    final m = SyncMarker.of(s, ActiveStore.sqlite);
    expect((m.timestamp, m.rowId), (10, 20));
    expect(m.catchUpTotal, 0, reason: 'a catch-up in progress is not carried over; the sync recounts it');
    m.rowId = 25; // the sqlite marker is now set; the ObjectBox one is never read again
    s.lastIncrementalSyncRowId.value = 5;
    expect(m.rowId, 25);
    expect(m.timestamp, 10, reason: 'each key falls back on its own');
  });

  test('rollback drill, as markers: SQLite syncs past the ObjectBox marker, an ObjectBox build resumes from its own', () {
    final s = withMarkers(ts: 1000, rowId: 500);
    final sqlite = SyncMarker.of(s, ActiveStore.sqlite);
    sqlite.timestamp = 2000; // messages 501..700 arrive on the SQLite build
    sqlite.rowId = 700;
    final rolledBack = SyncMarker.of(s, ActiveStore.objectBox);
    expect((rolledBack.timestamp, rolledBack.rowId), (1000, 500), reason: 'ObjectBox re-syncs 501..700');
  });
}
