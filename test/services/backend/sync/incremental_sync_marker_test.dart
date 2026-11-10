// The incremental-sync markers through SyncMarker: the sync reads and saves
// the `sqlite*` keys only, and the rollback drill: a sync leaves the keys of
// builds before SQLite where the last such build left them.
import 'package:bluebubbles/database/global/settings.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/env.dart';
import 'package:bluebubbles/services/backend/actions/sync_actions.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/backend/sync/incremental_sync_manager.dart';
import 'package:bluebubbles/services/backend/sync/sync_marker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../database/store/store_fixture.dart';

/// Records the keys it would persist instead of writing prefs.
class _Recording extends IncrementalSyncManager {
  _Recording({super.startRowId, super.startTimestamp}) : super(saveMarker: true);

  final saved = <String>[];

  @override
  Future<void> saveSettings(List<String> keys) async => saved.addAll(keys);
}

Settings _markers({int ts = 0, int rowId = 0, int total = 0, int sqTs = 0, int sqRowId = 0, int sqTotal = 0}) =>
    Settings.fromMap({
      'lastIncrementalSync': ts,
      'lastIncrementalSyncRowId': rowId,
      'incrementalCatchUpTotal': total,
      'sqliteLastIncrementalSync': sqTs,
      'sqliteLastIncrementalSyncRowId': sqRowId,
      'sqliteIncrementalCatchUpTotal': sqTotal,
    });

(int, int, int) _objectBox(Settings s) =>
    (s.lastIncrementalSync.value, s.lastIncrementalSyncRowId.value, s.incrementalCatchUpTotal.value);

(int, int, int) _sqlite(Settings s) =>
    (s.sqliteLastIncrementalSync.value, s.sqliteLastIncrementalSyncRowId.value, s.sqliteIncrementalCatchUpTotal.value);

void main() {
  late Settings settings;
  final dbs = <Db>[];

  void useSettings(Settings s) {
    settings = s;
    if (GetIt.I.isRegistered<SettingsService>()) GetIt.I.unregister<SettingsService>();
    GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = s);
  }

  void use() {
    final db = Db.memory();
    dbs.add(db);
    MessagingStore.use(MessagingStore(db));
  }

  tearDown(() async {
    MessagingStore.use(null);
    for (final db in dbs) {
      await db.close();
    }
    dbs.clear();
  });
  tearDownAll(() {
    if (GetIt.I.isRegistered<SettingsService>()) GetIt.I.unregister<SettingsService>();
  });

  {
    const own = _sqlite;
    const other = _objectBox;

    group('markers', () {
      setUp(use);

      test('a checkpoint saves the bookmark of this store only, and never moves it back', () async {
        useSettings(_markers(ts: 1, rowId: 50, sqTs: 1, sqRowId: 50));
        final mgr = _Recording(startRowId: 50);
        await mgr.saveCheckpoint(80);
        await mgr.saveCheckpoint(60);
        expect(own(settings).$2, 80);
        expect(other(settings).$2, 50);
        expect(mgr.saved, [SyncMarkerKeys.rowId]);
        expect(mgr.checkpointRowId, 60, reason: 'the in-memory checkpoint still moves');
      });

      test('the catch-up total is saved under this store\'s key', () async {
        useSettings(_markers());
        final mgr = _Recording(startRowId: 1);
        await mgr.saveCatchUpTotal(1234);
        expect(own(settings).$3, 1234);
        expect(other(settings).$3, 0);
        expect(mgr.saved, [SyncMarkerKeys.catchUpTotal]);
      });

      test('the end-of-sync markers: start time and the bookmark, never behind a checkpoint', () async {
        useSettings(_markers(ts: 5, rowId: 10, sqTs: 5, sqRowId: 10));
        final mgr = _Recording(startRowId: 10, startTimestamp: 5)
          ..syncStartedAt = 7777
          ..checkpointRowId = 300
          ..lastSyncedRowId = 250;
        await mgr.saveMarkers();
        expect((own(settings).$1, own(settings).$2), (7777, 300));
        expect((other(settings).$1, other(settings).$2), (5, 10));
        expect(mgr.saved, [SyncMarkerKeys.timestamp, SyncMarkerKeys.rowId]);
      });

      test('without a start timestamp the newest synced message time is the next start', () async {
        useSettings(_markers(rowId: 10, sqRowId: 10));
        final mgr = _Recording(startRowId: 10)
          ..syncStartedAt = 7777
          ..lastSyncedTimestamp = 4242;
        await mgr.saveMarkers();
        expect(own(settings).$1, 4242);
        expect(mgr.saved, [SyncMarkerKeys.timestamp], reason: 'no ROWID seen, no bookmark saved');
      });

      test('the background sync resumes from this store\'s marker', () {
        useSettings(_markers(ts: 10, rowId: 20, sqTs: 30, sqRowId: 40));
        final mgr = IncrementalSyncManager.resumingFrom(SyncMarker(settings));
        expect((mgr.startTimestamp, mgr.startRowId, mgr.saveMarker), (30, 40, true));
      });
    });
  }

  test('with no sqlite marker yet the sync starts where the build before SQLite stopped', () {
    use();
    useSettings(_markers(ts: 10, rowId: 20));
    final mgr = IncrementalSyncManager.resumingFrom(SyncMarker(settings));
    expect((mgr.startTimestamp, mgr.startRowId), (10, 20));
  });

  group('rollback drill', () {
    setUpAll(() => isIsolateOverride = true);
    tearDownAll(() => isIsolateOverride = false);

    test('a sync leaves the markers of builds before SQLite unchanged', () async {
      useSettings(_markers(ts: 1000, rowId: 500));
      use();

      // Messages 501..700 arrive.
      final mgr = _Recording(startRowId: 500, startTimestamp: 1000)..syncStartedAt = 2000;
      final result = await SyncActions.bulkSyncData({
        'messagesData': [
          {'guid': 'new-701', 'text': 'hi', 'dateCreated': t0 + 1, 'isFromMe': true, 'handleId': 0, 'itemType': 0,
            'chats': [{'guid': 'iMessage;-;ana@example.com', 'participants': [{'address': 'ana@example.com'}]}]},
        ],
      });
      expect(result['messageIds'], hasLength(1));
      await mgr.saveCheckpoint(700);
      mgr.lastSyncedRowId = 700;
      await mgr.saveMarkers();

      expect(_sqlite(settings), (2000, 700, 0));
      expect(_objectBox(settings), (1000, 500, 0), reason: 'a build before SQLite re-syncs 501..700');
      expect((await MessagingStore.current.messageByGuid('new-701'))?.text, 'hi');
    });
  });
}
