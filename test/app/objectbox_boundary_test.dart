// Nothing but the entity files (whose ObjectBox annotations S5 step 3 removes)
// and the generated code touches ObjectBox; messages are reached through
// MessagingStore.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final objectBox = RegExp(r"package:objectbox/|\bDatabase\.(messages|chats|handles|attachments|contactsV2|store)\b|"
    r"\b(Message|Chat|Handle|Attachment|ContactV2)_\.|\bBox<(Message|Chat|Handle|Attachment|ContactV2)>");

const allowedDirs = [
  'lib/database/io/',
  'lib/database/html/',
  'lib/generated/',
];

const allowedFiles = <String>[];

void main() {
  test('only the entity files touch ObjectBox', () {
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
