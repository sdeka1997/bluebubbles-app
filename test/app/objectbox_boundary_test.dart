// ObjectBox is gone (stage S5): nothing in lib uses its package, boxes or
// query fields again.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final objectBox = RegExp(r"package:objectbox/|\bDatabase\.(messages|chats|handles|attachments|contactsV2|store)\b|"
    r"\b(Message|Chat|Handle|Attachment|ContactV2)_\.|\bBox<(Message|Chat|Handle|Attachment|ContactV2)>");


void main() {
  test('nothing uses ObjectBox', () {
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = f.path.replaceAll('\\', '/');
      if (!path.endsWith('.dart')) continue;
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
