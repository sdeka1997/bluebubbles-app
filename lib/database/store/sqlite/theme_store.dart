import 'dart:async';

import 'package:bluebubbles/database/sqlite/db.dart';

/// One saved theme as stored: its name, the two flags, and the serialized
/// ThemeData ([ThemeStruct.dbThemeData]).
typedef ThemeRow = ({String name, bool gradientBg, String googleFont, String data});

/// The app's themes on SQLite (stage S4). Themes are read while a frame is
/// being built and before the first one (main.dart picks the light and dark
/// theme before runApp), so reads must not wait: every row is loaded once
/// when the store opens and answered from memory. A write changes memory at
/// once and is saved in the background, in call order.
class ThemeStore {
  ThemeStore._(this._db, this._rows);

  /// Null: memory only.
  final Db? _db;
  final Map<String, ThemeRow> _rows;
  Future<void> _saving = Future.value();

  /// The store of this isolate; null until [open] (themes then fall back to
  /// the presets, as before a first launch).
  static ThemeStore? current;

  /// Loads every saved theme of [db].
  static Future<ThemeStore> open(Db db) async =>
      ThemeStore._(db, {for (final row in await _readAll(db)) row.name: row});

  /// A store that keeps themes in memory only (web, tests).
  static ThemeStore memory() => ThemeStore._(null, {});

  static Future<List<ThemeRow>> _readAll(DbReader db) async => [
        for (final r in await db.select('SELECT name, gradient_bg, google_font, data_json FROM themes ORDER BY rowid'))
          (
            name: r['name'] as String,
            gradientBg: (r['gradient_bg'] as int) != 0,
            googleFont: r['google_font'] as String,
            data: r['data_json'] as String,
          ),
      ];

  static Future<void> _put(WriteTx tx, ThemeRow row) => tx.execute(
      'INSERT INTO themes (name, gradient_bg, google_font, data_json) VALUES (?, ?, ?, ?) '
      'ON CONFLICT(name) DO UPDATE SET gradient_bg = excluded.gradient_bg, '
      'google_font = excluded.google_font, data_json = excluded.data_json',
      [row.name, row.gradientBg ? 1 : 0, row.googleFont, row.data]);

  bool get isEmpty => _rows.isEmpty;

  /// Every theme, in the order first saved.
  List<ThemeRow> all() => _rows.values.toList();

  ThemeRow? byName(String name) => _rows[name];

  /// Saves [row] over the theme of the same name. [replacing] is the name the
  /// theme had before a rename; that row goes.
  void put(ThemeRow row, {String? replacing}) {
    final renamed = replacing != null && replacing != row.name;
    if (!renamed && _rows[row.name] == row) return;
    if (renamed) _rows.remove(replacing);
    _rows[row.name] = row;
    _save((tx) async {
      if (renamed) await tx.execute('DELETE FROM themes WHERE name = ?', [replacing]);
      await _put(tx, row);
    });
  }

  void remove(String name) {
    if (_rows.remove(name) == null) return;
    _save((tx) => tx.execute('DELETE FROM themes WHERE name = ?', [name]));
  }

  void clear() {
    _rows.clear();
    _save((tx) => tx.execute('DELETE FROM themes'));
  }

  void _save(Future<void> Function(WriteTx tx) write) {
    final db = _db;
    if (db == null) return;
    _saving = _saving.then((_) => db.write(write)).catchError((Object e) {
      // Memory keeps the change; the next launch shows what was saved.
      print('BBSQL theme save failed: $e');
    });
  }

  /// Completes when every write so far is saved.
  Future<void> flush() => _saving;
}
