// Risk R1 (SQLITE-PLAN-2): drift's transaction() sends a deferred BEGIN, and a
// second isolate then fails at once with SQLITE_BUSY instead of waiting. Every
// SQLite write in the app goes through Db.write (BEGIN IMMEDIATE), so no
// repository or write helper may open a drift transaction, batch or raw
// statement of its own.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `lib/database/sqlite/` files allowed to talk to drift directly: Db itself,
/// the schema, and the copy with its startup state machine (one isolate,
/// ObjectBox to a file no one else opens until it is ready, under a lock).
const _allowed = {
  'db.dart',
  'app_database.dart',
  'app_database.g.dart',
  'objectbox_sqlite_copy.dart',
  'sqlite_copy_check.dart',
  'storage_state.dart',
  'sqlite_chat_repository.dart',
};

final _forbidden = RegExp(r'\.transaction\(|\.batch\(|\.customStatement\(|\.customInsert\(|\.customUpdate\(|\.into\(');

List<String> violations(Directory dir) => [
      for (final file in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.dart')))
        if (!_allowed.contains(file.uri.pathSegments.last))
          for (final (i, line) in file.readAsLinesSync().indexed)
            if (!line.trimLeft().startsWith('//') && _forbidden.hasMatch(line)) '${file.path}:${i + 1}: ${line.trim()}',
    ];

void main() {
  test('no SQLite repository writes outside Db.write', () {
    expect(violations(Directory('lib/database/sqlite')), isEmpty);
  });

  test('the check catches a repository that opens its own transaction', () {
    final dir = Directory.systemTemp.createTempSync('bb_write_lint_');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/bad_repo.dart').writeAsStringSync('Future<void> f(dynamic db) => db.database.transaction(() async {});\n');
    File('${dir.path}/db.dart').writeAsStringSync('Future<void> f(dynamic db) => db.transaction(() async {});\n');
    expect(violations(dir), [contains('bad_repo.dart:1')]);
  });
}
