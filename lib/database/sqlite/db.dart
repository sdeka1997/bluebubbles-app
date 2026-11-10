import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bluebubbles/database/sqlite/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:flutter/foundation.dart';
import 'package:sqlite3/common.dart' show AllowedArgumentCount, CommonDatabase;

/// Rows changed by one committed [Db.write], by table name. Posted to the main
/// isolate as `IsolateEvent.dbChanged` (db_change_events.dart) so it re-reads
/// those ids.
class DbChanges {
  DbChanges(this.tables);

  /// The [toMap] payload back, or null when [map] holds no change.
  static DbChanges? tryFromMap(Object? map) {
    final tables = map is Map ? map['tables'] : null;
    if (tables is! Map) return null;
    final parsed = <String, Set<int>>{
      for (final MapEntry(:key, :value) in tables.entries)
        if (key is String && value is Iterable && value.isNotEmpty) key: value.whereType<int>().toSet(),
    };
    return parsed.isEmpty ? null : DbChanges(parsed);
  }

  factory DbChanges.fromMap(Map map) => tryFromMap(map) ?? DbChanges({});

  final Map<String, Set<int>> tables;

  /// Sendable between isolates: `{'tables': {table: [ids]}}`.
  Map<String, dynamic> toMap() => {
        'tables': {for (final MapEntry(:key, :value) in tables.entries) key: value.toList()},
      };

  bool get isEmpty => tables.isEmpty;

  @override
  String toString() => 'DbChanges(${tables.map((t, ids) => MapEntry(t, ids.length))})';
}

/// Runs SQL reads. [Db] reads outside any transaction (each statement on its
/// own); [Db.read] and [Db.write] hand out readers bound to their transaction.
abstract class DbReader {
  Future<List<Map<String, Object?>>> select(String sql, [List<Object?> args = const []]);

  /// Runs [fn] so that all of its reads see one snapshot of the file.
  Future<T> snapshot<T>(Future<T> Function(DbReader reader) fn);
}

/// The SQLite file as one isolate sees it: one connection ([AppDatabase]) per
/// isolate, reads at any time, writes serialised by SQLite's write lock.
///
/// A file's connection runs on a background isolate of its own, so a slow
/// statement never stalls the isolate that asked for it (on main, the one
/// that draws the screen). Statements are sent there and answered
/// asynchronously; the API is the same.
///
/// Every write goes through [write]: `BEGIN IMMEDIATE` takes the write lock up
/// front, so a second connection waits on `busy_timeout` instead of failing
/// with SQLITE_BUSY when its read turns into a write (drift's `transaction()`
/// sends a deferred `BEGIN`; see test/database/sqlite/write_contention_test.dart).
class Db implements DbReader {
  Db._(this.database, {this.inBackground = false});

  /// Opens [file]. With [inBackground] (the main isolate, which draws the
  /// screen) the connection runs on a background isolate of its own; a
  /// worker isolate keeps it on itself, where each statement costs no
  /// round trip.
  factory Db.file(File file, {bool inBackground = true}) => Db._(
      AppDatabase(inBackground
          ? NativeDatabase.createInBackground(file, setup: _setupConnection)
          : NativeDatabase(file, setup: _setupConnection)),
      inBackground: inBackground);

  /// An in-memory database on this isolate (tests).
  factory Db.memory() => Db._(AppDatabase(NativeDatabase.memory(setup: _setupConnection)));

  /// How long a write waits for another isolate's write (AppDatabase sets the
  /// same value again when it opens).
  static const busyTimeoutMs = 5000;

  final AppDatabase database;

  /// Whether the connection runs on a background isolate ([Db.file]).
  final bool inBackground;
  final _changes = StreamController<DbChanges>.broadcast(sync: true);
  List<(String, List<Object?>)>? _recorded;

  /// One event per committed [write] that changed rows; nothing for rollbacks.
  Stream<DbChanges> get changes => _changes.stream;

  static const _zoneKey = #bluebubblesDbTransaction;

  _Tx? get _currentTx {
    final tx = Zone.current[_zoneKey];
    return tx is _Tx && tx.db == this ? tx : null;
  }

  @override
  Future<List<Map<String, Object?>>> select(String sql, [List<Object?> args = const []]) {
    final tx = _currentTx;
    if (tx != null) return tx.select(sql, args);
    return _select(sql, args);
  }

  Future<List<Map<String, Object?>>> _select(String sql, List<Object?> args) async {
    _recorded?.add((sql, args));
    final rows = await _local(database.customSelect(sql, variables: args.map(_variable).toList()).get());
    return [for (final row in rows) row.data];
  }

  @override
  Future<T> snapshot<T>(Future<T> Function(DbReader reader) fn) => read(fn);

  /// Runs [fn] in a read transaction: one consistent snapshot, never blocks the
  /// writer. Inside a [write], runs in that write's transaction.
  Future<T> read<T>(Future<T> Function(DbReader reader) fn) async {
    final tx = _currentTx;
    if (tx != null) return fn(tx);
    return _local(database.transaction(() {
      final reader = _Tx(this);
      return runZoned(() => fn(reader), zoneValues: {_zoneKey: reader});
    }));
  }

  /// Runs [fn] in one write transaction: `BEGIN IMMEDIATE`, then `COMMIT`, or
  /// `ROLLBACK` if [fn] throws. If the write lock stays busy past `busy_timeout`,
  /// tries once more. A nested [write] joins the outer one.
  Future<T> write<T>(Future<T> Function(WriteTx tx) fn) async {
    final tx = _currentTx;
    if (tx is WriteTx) return fn(tx);
    if (tx != null) throw StateError('Db.write inside Db.read: start the write first');
    try {
      return await _writeOnce(fn);
    } on SqliteException catch (e) {
      if (!isBusy(e)) rethrow;
      return await _writeOnce(fn);
    }
  }

  Future<T> _writeOnce<T>(Future<T> Function(WriteTx tx) fn) {
    return _local(database.exclusively(() async {
      await _local(database.customStatement('BEGIN IMMEDIATE'));
      final tx = WriteTx._(this);
      await _takeChanges(); // drops rows seen since the last write (rolled back, or not ours)
      try {
        final result = await runZoned(() => fn(tx), zoneValues: {_zoneKey: tx});
        await _local(database.customStatement('COMMIT'));
        final changes = await _takeChanges();
        tx._marked.forEach((table, ids) => changes.tables.putIfAbsent(table, () => {}).addAll(ids));
        if (!changes.isEmpty) _changes.add(changes);
        return result;
      } catch (_) {
        try {
          await _local(database.customStatement('ROLLBACK'));
        } on SqliteException {
          // SQLite already rolled back (some errors end the transaction themselves).
        }
        rethrow;
      }
    }));
  }

  /// The rows SQLite's update hook saw on the connection since the last call.
  Future<DbChanges> _takeChanges() async {
    final rows = await _local(database.customSelect('SELECT $_takeChangesFunction() AS c').get());
    final tables = jsonDecode(rows.single.data['c'] as String) as Map<String, dynamic>;
    return DbChanges({for (final MapEntry(:key, :value) in tables.entries) key: (value as List).cast<int>().toSet()});
  }

  /// A statement that failed on the background isolate arrives wrapped in
  /// [DriftRemoteException]; callers catch the [SqliteException] itself
  /// ([isBusy], UNIQUE violations), as on a connection of this isolate.
  static Future<T> _local<T>(Future<T> statement) async {
    try {
      return await statement;
    } on DriftRemoteException catch (e) {
      final cause = e.remoteCause;
      if (cause is SqliteException) throw cause;
      rethrow;
    }
  }

  /// The statements [fn] ran through this Db, in order (for EXPLAIN tests).
  @visibleForTesting
  Future<List<(String, List<Object?>)>> recordStatements(Future<void> Function() fn) async {
    final recorded = _recorded = [];
    try {
      await fn();
    } finally {
      _recorded = null;
    }
    return recorded;
  }

  Future<void> close() async {
    await _changes.close();
    await database.close();
  }

  /// SQLITE_BUSY, including BUSY_SNAPSHOT (a stale read that tried to write).
  static bool isBusy(Object e) => e is SqliteException && e.resultCode == 5;
}

class _Tx implements DbReader {
  _Tx(this.db);

  final Db db;

  @override
  Future<List<Map<String, Object?>>> select(String sql, [List<Object?> args = const []]) => db._select(sql, args);

  @override
  Future<T> snapshot<T>(Future<T> Function(DbReader reader) fn) => fn(this);
}

/// The open write transaction of [Db.write].
class WriteTx extends _Tx {
  WriteTx._(super.db);

  final Map<String, Set<int>> _marked = {};

  Future<void> execute(String sql, [List<Object?> args = const []]) {
    db._recorded?.add((sql, args));
    return Db._local(db.database.customStatement(sql, args));
  }

  /// Inserts [row] and returns its id. A null `id` is left to SQLite.
  Future<int> insert(String table, Map<String, Object?> row) async {
    final columns = [for (final e in row.entries) if (e.key != 'id' || e.value != null) e.key];
    final rows = await select(
        'INSERT INTO $table (${columns.join(', ')}) VALUES (${List.filled(columns.length, '?').join(', ')}) RETURNING id',
        [for (final c in columns) row[c]]);
    return rows.single['id'] as int;
  }

  /// Writes every column of [row] over the stored row with the same `id`.
  Future<void> update(String table, Map<String, Object?> row) {
    final columns = row.keys.where((c) => c != 'id').toList();
    return execute('UPDATE $table SET ${columns.map((c) => '$c = ?').join(', ')} WHERE id = ?',
        [for (final c in columns) row[c], row['id']]);
  }

  /// Reports rows the update hook cannot see: tables WITHOUT ROWID (the join
  /// tables, reported by their parent id) and `DELETE FROM t` with no WHERE.
  void markChanged(String table, Iterable<int> ids) => _marked.putIfAbsent(table, () => {}).addAll(ids);
}

const _takeChangesFunction = 'bb_take_changes';

/// Runs right after sqlite3_open, before drift's first statement, on the
/// isolate that holds the connection. The busy timeout must be set here: drift
/// reads `user_version` before `beforeOpen`, and a connection opened while
/// another isolate opens or recovers the WAL otherwise fails at once
/// (SQLITE_BUSY_RECOVERY, 261) and stays failed.
///
/// SQLite's update hook (table, rowid) only reaches this isolate, so the rows
/// it reports are kept here and handed out by `bb_take_changes()` as JSON
/// (`{table: [ids]}`), emptied on each call. [Db.write] takes them right after
/// `BEGIN IMMEDIATE` (discarding older ones) and after `COMMIT`.
void _setupConnection(CommonDatabase raw) {
  raw.execute('PRAGMA busy_timeout = ${Db.busyTimeoutMs}');
  var pending = <String, Set<int>>{};
  raw.updatesSync.listen((update) => pending.putIfAbsent(update.tableName, () => {}).add(update.rowId));
  raw.createFunction(
    functionName: _takeChangesFunction,
    argumentCount: const AllowedArgumentCount(0),
    function: (_) {
      final taken = pending;
      pending = {};
      return jsonEncode({for (final MapEntry(:key, :value) in taken.entries) key: value.toList()});
    },
  );
}

Variable<Object> _variable(Object? value) => switch (value) {
  null => const Variable<Object>(null),
  final int v => Variable.withInt(v),
  final String v => Variable.withString(v),
  final bool v => Variable.withBool(v),
  final double v => Variable.withReal(v),
  final Uint8List v => Variable.withBlob(v),
  _ => throw ArgumentError.value(value, 'value', 'unsupported SQL argument type'),
};
