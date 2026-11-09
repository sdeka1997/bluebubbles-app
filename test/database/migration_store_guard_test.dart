import 'dart:io';

import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/services/backend/sync/sync_marker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migrations that edit the ObjectBox messaging boxes never run once messages live in SQLite', () {
    for (var v = 2; v <= Database.version; v++) {
      final touchesMessaging = Database.objectBoxMessagingMigrations.contains(v);
      expect(Database.migrationRuns(v, ActiveStore.objectBox), isTrue, reason: 'v$v on ObjectBox');
      expect(Database.migrationRuns(v, ActiveStore.sqlite), !touchesMessaging, reason: 'v$v on SQLite');
    }
  });

  test('every migration step that reads or writes a messaging box is listed as ObjectBox-only', () {
    final source = File('lib/database/database.dart').readAsStringSync();
    final body = source.substring(source.indexOf('static Future<void> _performDatabaseMigrations'));
    final steps = RegExp(r'case (\d+):([\s\S]*?)(?=\n\s*(?:// .*\n\s*)*case \d+:|\n      }\n)').allMatches(body);
    expect(steps.length, greaterThanOrEqualTo(Database.version - 1));
    final messaging = RegExp(r'Database\.(messages|chats|handles|attachments|contactsV2|customGroups)\b|'
        r'ChatLatestMessageMigration|MessageHandleRelationshipMigration');
    for (final step in steps) {
      final v = int.parse(step.group(1)!);
      expect(Database.objectBoxMessagingMigrations.contains(v), messaging.hasMatch(step.group(2)!), reason: 'case $v');
    }
  });
}
