import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Conversation list and conversation view code that may not hide anything by deleting it:
/// Apple devices are the source of truth, so Archive is the only way to hide on Android.
/// Deletion still arrives from Apple through the services, and Settings → Developer Tools
/// keeps its troubleshooting delete.
const _deleteCalls = ['softDeleteChat', 'recoverablyDeleteChat', 'deleteSelectedChats', 'softDeleteMessage'];

void main() {
  test('no conversation list or conversation view surface deletes a conversation or message', () {
    final offenders = <String>[];
    for (final dir in ['lib/app/layouts/conversation_list', 'lib/app/layouts/conversation_view']) {
      for (final file in Directory(dir).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (_deleteCalls.any(lines[i].contains)) offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('no conversation menu asks to delete a chat from this device', () {
    final offenders = <String>[];
    for (final dir in ['lib/app/layouts/conversation_list', 'lib/app/layouts/conversation_view']) {
      for (final file in Directory(dir).listSync(recursive: true).whereType<File>()) {
        if (file.path.endsWith('.dart') && file.readAsStringSync().contains('This chat will be deleted')) {
          offenders.add(file.path);
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
