import 'package:bluebubbles/database/global/settings.dart';
import 'package:get/get.dart';

/// The settings keys of the incremental-sync markers: the timestamp and Apple
/// ROWID the next sync starts from, and the size of a catch-up in progress.
///
/// They are not the keys builds before SQLite used (`lastIncrementalSync*`,
/// `incrementalCatchUpTotal`): those stay where the last such build left them,
/// so a rollback to one re-syncs everything it never saw (SQLITE-PLAN-2 R5).
class SyncMarkerKeys {
  static const timestamp = 'sqliteLastIncrementalSync';
  static const rowId = 'sqliteLastIncrementalSyncRowId';
  static const catchUpTotal = 'sqliteIncrementalCatchUpTotal';

  /// For `Settings.saveManyAsync`.
  static const all = [timestamp, rowId, catchUpTotal];
}

/// The markers in [settings]; what the sync reads and writes.
///
/// An unset (0) timestamp or ROWID reads the pre-SQLite one: the first sync
/// after the move to SQLite started where the ObjectBox build stopped. A
/// catch-up total is never carried over. Only the [SyncMarkerKeys] are written.
class SyncMarker {
  SyncMarker(this.settings);

  final Settings settings;

  int get timestamp => _read(settings.sqliteLastIncrementalSync, settings.lastIncrementalSync);
  set timestamp(int value) => settings.sqliteLastIncrementalSync.value = value;

  int get rowId => _read(settings.sqliteLastIncrementalSyncRowId, settings.lastIncrementalSyncRowId);
  set rowId(int value) => settings.sqliteLastIncrementalSyncRowId.value = value;

  int get catchUpTotal => settings.sqliteIncrementalCatchUpTotal.value;
  set catchUpTotal(int value) => settings.sqliteIncrementalCatchUpTotal.value = value;

  int _read(RxInt own, RxInt beforeSqlite) => own.value != 0 ? own.value : beforeSqlite.value;
}
