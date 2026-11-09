import 'package:bluebubbles/database/global/settings.dart';
import 'package:get/get.dart';

/// The local store a build runs on.
enum ActiveStore { objectBox, sqlite }

/// The settings keys of the incremental-sync markers of a store: the
/// timestamp and Apple ROWID the next sync starts from, and the size of a
/// catch-up in progress. SQLite builds keep their own (SQLITE-PLAN-2 R5) so a
/// rollback to an ObjectBox build re-syncs from where that build stopped.
class SyncMarkerKeys {
  const SyncMarkerKeys._(this.timestamp, this.rowId, this.catchUpTotal);

  static const objectBox = SyncMarkerKeys._('lastIncrementalSync', 'lastIncrementalSyncRowId', 'incrementalCatchUpTotal');
  static const sqlite =
      SyncMarkerKeys._('sqliteLastIncrementalSync', 'sqliteLastIncrementalSyncRowId', 'sqliteIncrementalCatchUpTotal');

  static SyncMarkerKeys of(ActiveStore store) => switch (store) {
        ActiveStore.objectBox => objectBox,
        ActiveStore.sqlite => sqlite,
      };

  final String timestamp;
  final String rowId;
  final String catchUpTotal;

  /// For `Settings.saveManyAsync`.
  List<String> get all => [timestamp, rowId, catchUpTotal];
}

/// The markers of [store] in [settings]; what the sync reads and writes in
/// place of `lastIncrementalSync*` / `incrementalCatchUpTotal`.
///
/// On SQLite an unset (0) timestamp or ROWID reads the ObjectBox one: the
/// first SQLite run after a copy starts where ObjectBox stopped, which is right
/// because the copy holds everything ObjectBox had (a fresh copy resets these to
/// 0, resetSqliteMarkers). A catch-up total is never carried over.
class SyncMarker {
  SyncMarker.of(this.settings, this.store);

  final Settings settings;
  final ActiveStore store;

  SyncMarkerKeys get keys => SyncMarkerKeys.of(store);

  bool get _sqlite => store == ActiveStore.sqlite;

  int get timestamp => _read(settings.sqliteLastIncrementalSync, settings.lastIncrementalSync);
  set timestamp(int value) => (_sqlite ? settings.sqliteLastIncrementalSync : settings.lastIncrementalSync).value = value;

  int get rowId => _read(settings.sqliteLastIncrementalSyncRowId, settings.lastIncrementalSyncRowId);
  set rowId(int value) => (_sqlite ? settings.sqliteLastIncrementalSyncRowId : settings.lastIncrementalSyncRowId).value = value;

  int get catchUpTotal => (_sqlite ? settings.sqliteIncrementalCatchUpTotal : settings.incrementalCatchUpTotal).value;
  set catchUpTotal(int value) =>
      (_sqlite ? settings.sqliteIncrementalCatchUpTotal : settings.incrementalCatchUpTotal).value = value;

  int _read(RxInt sqlite, RxInt objectBox) {
    if (!_sqlite) return objectBox.value;
    return sqlite.value != 0 ? sqlite.value : objectBox.value;
  }
}
