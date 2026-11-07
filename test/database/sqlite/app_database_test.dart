import 'dart:io';

import 'package:bluebubbles/database/sqlite/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

const requiredStageOneTables = <String>{
  'chats',
  'messages',
  'legacy_handles',
  'chat_participants',
  'message_attachments',
  'storage_meta',
  'copy_checkpoints',
};

Future<int> pragmaInt(AppDatabase database, String pragma) async {
  final row = await database.customSelect('PRAGMA $pragma').getSingle();
  return row.data.values.single as int;
}

Future<Set<String>> tableNames(AppDatabase database) async {
  final rows = await database.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

void main() {
  test('in-memory database opens at schema v1 with foreign keys and required tables', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);

    expect(database.schemaVersion, 1);
    expect(await pragmaInt(database, 'foreign_keys'), 1);
    expect(await tableNames(database), containsAll(requiredStageOneTables));
  });

  test('file database opens in WAL mode', () async {
    final directory = await Directory.systemTemp.createTemp('bluebubbles_sqlite_test_');
    addTearDown(() => directory.delete(recursive: true));
    final database = AppDatabase.file(File('${directory.path}/messages.sqlite'));
    addTearDown(database.close);

    final row = await database.customSelect('PRAGMA journal_mode').getSingle();
    expect(row.data.values.single.toString().toLowerCase(), 'wal');
  });
}
