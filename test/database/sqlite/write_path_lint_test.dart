// Risk R1 (SQLITE-PLAN-2): drift's transaction() sends a deferred BEGIN, and a
// second isolate then fails at once with SQLITE_BUSY instead of waiting. Every
// SQLite write in the app goes through Db.write (BEGIN IMMEDIATE), so no
// repository or write helper may open a drift transaction, batch or raw
// statement of its own.
//
// Risk R6 (S2 switch plan): a Db.write holds the write lock across its awaits,
// so a callback may only await the database. No HTTP, file or directory call,
// and no address formatting (it awaits the platform) inside a Db.write
// callback, in the repositories, the MessagingStore implementations, the
// Actions and the sync managers.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `lib/database/sqlite/` files allowed to talk to drift directly: Db itself
/// and the schema.
const _allowed = {
  'db.dart',
  'app_database.dart',
  'app_database.g.dart',
};

/// Where SQLite writes happen or will (switch plan commits 4-6): no drift
/// write of their own anywhere, nothing but the database inside Db.write.
const _writeDirs = [
  'lib/database/sqlite',
  'lib/database/store',
  'lib/services/backend/actions',
  'lib/services/backend/interfaces',
  'lib/services/backend/sync',
];

final _forbidden = RegExp(r'\.transaction\(|\.batch\(|\.customStatement\(|\.customInsert\(|\.customUpdate\(|\.into\(');

/// Calls that leave the database: HTTP, files, directories, platform address
/// formatting.
final _outside = RegExp(r'\bhttp\b|\bHttp\w*|\bFile\(|\bDirectory\(|updateFormattedAddress|\bdio\b|Future\.delayed');

Iterable<File> _dartFiles(Directory dir) =>
    dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

List<String> violations(Directory dir) => [
      for (final file in _dartFiles(dir))
        if (!_allowed.contains(file.uri.pathSegments.last))
          for (final (i, line) in file.readAsLinesSync().indexed)
            if (!line.trimLeft().startsWith('//') && _forbidden.hasMatch(line)) '${file.path}:${i + 1}: ${line.trim()}',
    ];

/// The source of each `.write((tx) ...)` callback in [source], with the line it
/// starts on: from the opening parenthesis to its match.
List<(int, String)> writeCallbacks(String source) {
  final out = <(int, String)>[];
  for (final m in RegExp(r'\.write\(\s*\(\w+\)').allMatches(source)) {
    final open = source.indexOf('(', m.start);
    var depth = 0;
    var end = open;
    for (; end < source.length; end++) {
      final c = source[end];
      if (c == '(') depth++;
      if (c == ')' && --depth == 0) break;
    }
    out.add(('\n'.allMatches(source.substring(0, m.start)).length + 1, source.substring(open, end + 1)));
  }
  return out;
}

List<String> outsideCalls(Directory dir) => [
      for (final file in _dartFiles(dir))
        for (final (line, body) in writeCallbacks(file.readAsStringSync()))
          for (final (i, text) in body.split('\n').indexed)
            if (!text.trimLeft().startsWith('//') && _outside.hasMatch(text))
              '${file.path}:${line + i}: ${text.trim()}',
    ];

void main() {
  test('no SQLite writes outside Db.write', () {
    for (final dir in _writeDirs) {
      expect(violations(Directory(dir)), isEmpty, reason: dir);
    }
  });

  test('nothing but the database inside a Db.write callback', () {
    final callbacks = [
      for (final dir in _writeDirs)
        for (final file in _dartFiles(Directory(dir))) ...writeCallbacks(file.readAsStringSync()),
    ];
    expect(callbacks.length, greaterThan(15), reason: 'the check sees the write callbacks');
    for (final dir in _writeDirs) {
      expect(outsideCalls(Directory(dir)), isEmpty, reason: dir);
    }
  });

  test('the check catches a repository that opens its own transaction', () {
    final dir = Directory.systemTemp.createTempSync('bb_write_lint_');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/bad_repo.dart').writeAsStringSync('Future<void> f(dynamic db) => db.database.transaction(() async {});\n');
    File('${dir.path}/db.dart').writeAsStringSync('Future<void> f(dynamic db) => db.transaction(() async {});\n');
    Directory('${dir.path}/actions').createSync();
    File('${dir.path}/actions/bad_action.dart').writeAsStringSync('Future<void> g(dynamic d) => d.batch((b) {});\n');
    expect(violations(dir), unorderedEquals([contains('bad_repo.dart:1'), contains('bad_action.dart:1')]));
  });

  test('the check catches HTTP, file and formatting calls inside a write callback, not outside it', () {
    final dir = Directory.systemTemp.createTempSync('bb_write_lint_');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/store.dart').writeAsStringSync('''
Future<void> ok(dynamic db, dynamic h) async {
  await h.updateFormattedAddress();
  await db.write((tx) async {
    await tx.execute('UPDATE handles SET color = ?', ['red']);
  });
}

Future<void> bad(dynamic db, dynamic h) => db.write((tx) async {
      await File('x').readAsString();
      await h.updateFormattedAddress();
      await HttpSvc.ping();
    });
''');
    expect(outsideCalls(dir), [contains('store.dart:9:'), contains('store.dart:10:'), contains('store.dart:11:')]);
  });
}
