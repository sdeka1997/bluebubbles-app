// Switch plan commit 9: outside the ObjectBox layer nothing reaches the boxes
// through the model classes' own lookups and saves; everything goes through
// MessagingStore, so the store startup selects is the one that is used.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final legacy = RegExp(r'\b(Chat\.findOne|Chat\.getMessages|Message\.findOne|Handle\.findOne|Handle\.find|Handle\.delete|'
    r'Handle\.bulkSave)\(|\.clearTranscript\(\)|\.getAttachmentsAsync\(|\b(message|msg|m)\.save\((chat:|updateIsBookmarked:|\))');

const objectBoxLayer = ['lib/database/io/', 'lib/database/html/', 'lib/database/store/objectbox/', 'lib/database/migrations/'];

void main() {
  test('no file outside the ObjectBox layer uses the model lookups or saves', () {
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = f.path.replaceAll('\\', '/');
      if (!path.endsWith('.dart') || objectBoxLayer.any(path.startsWith) || path.startsWith('lib/generated/')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('//') || line.startsWith('///')) continue;
        if (legacy.hasMatch(line)) {
          hits.add('$path:${i + 1}: $line');
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  // A model method callers use (setPlayedDate, updateDefaultPhone...) must not
  // save through ObjectBox behind their back: only save() itself may.
  test('model helpers save through MessagingStore, not save()', () {
    final call = RegExp(r'(^|[^.\w])save\(\s*\)|\bthis\.save\(');
    final member = RegExp(r'^  \S.*\(.*[{>]\s*$|^  \S.*\b(\w+)\(\{?[^)]*$');
    final hits = <String>[];
    for (final path in ['lib/database/io/message.dart', 'lib/database/io/handle.dart', 'lib/database/io/chat.dart']) {
      final lines = File(path).readAsLinesSync();
      var inSave = false;
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (member.hasMatch(line)) inSave = RegExp(r'^  \w+\?? save\(').hasMatch(line);
        if (!inSave && call.hasMatch(line) && !line.trim().startsWith('//')) hits.add('$path:${i + 1}: ${line.trim()}');
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}
