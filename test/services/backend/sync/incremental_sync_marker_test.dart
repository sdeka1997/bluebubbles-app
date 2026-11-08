// The incremental-sync markers through SyncMarker (S2 switch plan, commit 6):
// the sync reads and saves the markers of the active store, the ObjectBox
// keys on ObjectBox and the `sqlite*` keys on SQLite, and the rollback drill:
// a sync on SQLite leaves the ObjectBox marker (and the ObjectBox store) where
// the last ObjectBox build left them.
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

  void use(ActiveStore kind) {
    final db = Db.memory();
    dbs.add(db);
    MessagingStore.use(MessagingStore.forStore(kind, db: db));
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

  test('ObjectBox is the active store until startup selects SQLite: the sync uses the ObjectBox marker', () {
    MessagingStore.use(null);
    useSettings(_markers(ts: 10, rowId: 20, total: 30, sqTs: 99, sqRowId: 98));
    final m = _Recording(startRowId: 1).marker;
    expect(m.store, ActiveStore.objectBox);
    expect((m.timestamp, m.rowId, m.catchUpTotal), (10, 20, 30));
  });

  for (final kind in ActiveStore.values) {
    final own = kind == ActiveStore.objectBox ? _objectBox : _sqlite;
    final other = kind == ActiveStore.objectBox ? _sqlite : _objectBox;
    final keys = SyncMarkerKeys.of(kind);

    group(kind.name, () {
      setUp(() => use(kind));

      test('a checkpoint saves the bookmark of this store only, and never moves it back', () async {
        useSettings(_markers(ts: 1, rowId: 50, sqTs: 1, sqRowId: 50));
        final mgr = _Recording(startRowId: 50);
        await mgr.saveCheckpoint(80);
        await mgr.saveCheckpoint(60);
        expect(own(settings).$2, 80);
        expect(other(settings).$2, 50);
        expect(mgr.saved, [keys.rowId]);
        expect(mgr.checkpointRowId, 60, reason: 'the in-memory checkpoint still moves');
      });

      test('the catch-up total is saved under this store\'s key', () async {
        useSettings(_markers());
        final mgr = _Recording(startRowId: 1);
        await mgr.saveCatchUpTotal(1234);
        expect(own(settings).$3, 1234);
        expect(other(settings).$3, 0);
        expect(mgr.saved, [keys.catchUpTotal]);
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
        expect(mgr.saved, [keys.timestamp, keys.rowId]);
      });

      test('without a start timestamp the newest synced message time is the next start', () async {
        useSettings(_markers(rowId: 10, sqRowId: 10));
        final mgr = _Recording(startRowId: 10)
          ..syncStartedAt = 7777
          ..lastSyncedTimestamp = 4242;
        await mgr.saveMarkers();
        expect(own(settings).$1, 4242);
        expect(mgr.saved, [keys.timestamp], reason: 'no ROWID seen, no bookmark saved');
      });

      test('the background sync resumes from this store\'s marker', () {
        useSettings(_markers(ts: 10, rowId: 20, sqTs: 30, sqRowId: 40));
        final mgr = IncrementalSyncManager.resumingFrom(SyncMarker.of(settings, kind));
        expect((mgr.startTimestamp, mgr.startRowId, mgr.saveMarker),
            kind == ActiveStore.objectBox ? (10, 20, true) : (30, 40, true));
      });
    });
  }

  test('a first SQLite sync starts where ObjectBox stopped (the copy holds everything ObjectBox had)', () {
    use(ActiveStore.sqlite);
    useSettings(_markers(ts: 10, rowId: 20));
    final mgr = IncrementalSyncManager.resumingFrom(SyncMarker.of(settings, ActiveStore.sqlite));
    expect((mgr.startTimestamp, mgr.startRowId), (10, 20));
  });

  group('rollback drill', () {
    setUpAll(() => isIsolateOverride = true);
    tearDownAll(() {
      isIsolateOverride = false;
      closeObjectBox();
    });

    test('a sync on SQLite leaves the ObjectBox marker and the ObjectBox store unchanged', () async {
      final obx = objectBoxFixture();
      final kept = await obx.message('kept', await obx.chat('iMessage;-;ana@example.com'), t0);
      useSettings(_markers(ts: 1000, rowId: 500));
      use(ActiveStore.sqlite);

      // Messages 501..700 arrive on the SQLite build.
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
      expect(_objectBox(settings), (1000, 500, 0), reason: 'an ObjectBox build re-syncs 501..700');
      expect(await obx.store.allMessageIds(), [kept.id], reason: 'the sync wrote only to SQLite');
      expect((await MessagingStore.current.messageByGuid('new-701'))?.text, 'hi');

      // The rolled-back ObjectBox build resumes from its own marker.
      MessagingStore.use(obx.store);
      final rolledBack = IncrementalSyncManager.resumingFrom(SyncMarker.of(settings, MessagingStore.current.kind));
      expect((rolledBack.startTimestamp, rolledBack.startRowId), (1000, 500));
    });
  });
}
