// Stage S4: themes on SQLite. Reads come from memory so a frame never waits;
// writes are saved in the background and survive a restart; an install whose
// file has no themes yet takes the old ObjectBox rows once.
import 'dart:io';

import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/store/sqlite/theme_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

ThemeRow row(String name, {String data = '{}', bool gradient = false}) =>
    (name: name, gradientBg: gradient, googleFont: 'Default', data: data);

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('theme_store');
    file = File('${dir.path}/bluebubbles.db');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<ThemeStore> reopen(Future<void> Function(ThemeStore store) before) async {
    final db = Db.file(file);
    final store = await ThemeStore.open(db);
    await before(store);
    await store.flush();
    await db.close();
    final again = Db.file(file);
    addTearDown(again.close);
    return ThemeStore.open(again);
  }

  test('a saved theme is read at once and is still there after a restart', () async {
    final db = Db.file(file);
    final store = await ThemeStore.open(db);
    store.put(row('Mine', data: '{"a":1}', gradient: true));
    expect(store.byName('Mine')?.data, '{"a":1}', reason: 'no wait for the write');
    await store.flush();
    await db.close();

    final again = Db.file(file);
    addTearDown(again.close);
    final reopened = await ThemeStore.open(again);
    expect(reopened.byName('Mine'), row('Mine', data: '{"a":1}', gradient: true));
  });

  test('saving a theme of the same name replaces it', () async {
    final store = await reopen((s) async {
      s.put(row('Mine', data: '1'));
      s.put(row('Mine', data: '2'));
    });
    expect(store.all(), [row('Mine', data: '2')]);
  });

  test('a rename leaves one theme, under the new name', () async {
    final store = await reopen((s) async {
      s.put(row('Old'));
      s.put(row('New'), replacing: 'Old');
    });
    expect(store.all().map((r) => r.name), ['New']);
  });

  test('a deleted theme stays deleted', () async {
    final store = await reopen((s) async {
      s.put(row('A'));
      s.put(row('B'));
      s.remove('A');
    });
    expect(store.all().map((r) => r.name), ['B']);
  });

  test('themes keep the order they were first saved in', () async {
    final store = await reopen((s) async {
      for (final name in ['Bright White', 'OLED Dark', 'Nord Theme']) {
        s.put(row(name));
      }
      s.put(row('Bright White', data: 'changed'));
    });
    expect(store.all().map((r) => r.name), ['Bright White', 'OLED Dark', 'Nord Theme']);
  });

  test('a v2 file (before themes) gets the themes table and keeps its rows', () async {
    final db = Db.file(file);
    await db.write((tx) => tx.execute("INSERT INTO storage_meta (key, value) VALUES ('storage_state', 'ready')"));
    await db.write((tx) => tx.execute('DROP TABLE themes'));
    await db.close();
    final raw = sqlite3.open(file.path);
    raw.execute('PRAGMA user_version = 2');
    raw.dispose();

    final again = Db.file(file);
    addTearDown(again.close);
    final store = await ThemeStore.open(again);
    store.put(row('Mine'));
    await store.flush();
    expect((await again.select('PRAGMA user_version')).single.values.single, 3);
    expect((await again.select("SELECT value FROM storage_meta WHERE key = 'storage_state'")).single['value'], 'ready');
    expect((await again.select('SELECT name FROM themes')).single['name'], 'Mine');
  });

  test('saving a theme exactly as stored writes nothing', () async {
    final db = Db.file(file);
    addTearDown(db.close);
    final store = await ThemeStore.open(db);
    store.put(row('Mine'));
    await store.flush();
    final writes = await db.recordStatements(() async {
      store.put(row('Mine'));
      await store.flush();
    });
    expect(writes, isEmpty);
  });

  test('clear removes every theme', () async {
    final store = await reopen((s) async {
      s.put(row('A'));
      s.clear();
    });
    expect(store.isEmpty, isTrue);
  });
}
