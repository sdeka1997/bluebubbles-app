// Switch plan item 10 (commit 9): ObjectBox's messaging boxes and query fields
// are used only by the ObjectBox layer, the copy into SQLite and the startup
// check that judges the copy against ObjectBox. Everything else reaches
// messages through MessagingStore, so the store startup selects is the one used.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final objectBox = RegExp(r"package:objectbox/|\bDatabase\.(messages|chats|handles|attachments|contactsV2|store)\b|"
    r"\b(Message|Chat|Handle|Attachment|ContactV2)_\.|\bBox<(Message|Chat|Handle|Attachment|ContactV2)>");

const allowedDirs = [
  'lib/database/io/',
  'lib/database/html/',
  'lib/database/store/objectbox/',
  'lib/database/migrations/',
  'lib/generated/',
];

const allowedFiles = [
  'lib/database/database.dart',
  'lib/database/sqlite/objectbox_sqlite_copy.dart',
  'lib/database/sqlite/sqlite_copy_check.dart',
  'lib/database/sqlite/storage_state.dart',
];

void main() {
  test('only the ObjectBox layer, the copy and the startup check touch the messaging boxes', () {
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = f.path.replaceAll('\\', '/');
      if (!path.endsWith('.dart') || allowedDirs.any(path.startsWith) || allowedFiles.contains(path)) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('//')) continue;
        if (objectBox.hasMatch(line)) hits.add('$path:${i + 1}: $line');
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}
