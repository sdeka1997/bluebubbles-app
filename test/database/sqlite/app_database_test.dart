import 'dart:io';

import 'package:bluebubbles/database/sqlite/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// The whole linked messaging set plus copy bookkeeping (schema v1, kept in v2).
const requiredStageOneTables = <String>{
  'chats',
  'messages',
  'handles',
  'chat_handles',
  'attachments',
  'contacts',
  'contact_handles',
  'custom_groups',
  'custom_group_chats',
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

Future<Map<String, String>> indexSql(AppDatabase database) async {
  final rows = await database
      .customSelect("SELECT name, sql FROM sqlite_master WHERE type = 'index' AND sql IS NOT NULL")
      .get();
  return {for (final row in rows) row.read<String>('name'): row.read<String>('sql')};
}

Future<List<String>> columnNames(AppDatabase database, String table) async {
  final rows = await database.customSelect('PRAGMA table_info($table)').get();
  return rows.map((row) => row.read<String>('name')).toList();
}

void main() {
  test('in-memory database opens at schema v2 with foreign keys and required tables', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);

    expect(database.schemaVersion, 3);
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

  test('every persisted ObjectBox property of the messaging set has a column', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);

    // Counts from lib/generated/objectbox-model.json, minus ToMany relations,
    // plus messages.sort_at_us.
    // Message and Attachment persist `metadata` twice (FlexBuffer + dbMetadata JSON
    // of the same map); SQLite keeps one metadata_json column for it.
    expect((await columnNames(database, 'messages')).length, 46);
    expect(await columnNames(database, 'messages'), containsAll(['sort_at_us', 'chat_id', 'handle_relation_id', 'text']));
    expect((await columnNames(database, 'chats')).length, 35);
    expect(await columnNames(database, 'chats'), contains('latest_message_id'));
    expect((await columnNames(database, 'handles')).length, 10);
    expect((await columnNames(database, 'attachments')).length, 16);
    expect((await columnNames(database, 'contacts')).length, 15);
    expect((await columnNames(database, 'custom_groups')).length, 4);
  });

  test('the chat timeline is served by (chat_id, sort_at_us, id) indexes, one partial', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);

    final indexes = await indexSql(database);
    expect(indexes['messages_chat_time'], contains('(chat_id, sort_at_us, id)'));
    expect(indexes['messages_timeline'], contains('(chat_id, sort_at_us, id)'));
    expect(indexes['messages_timeline'], contains('WHERE associated_message_guid IS NULL AND date_deleted_us IS NULL'));
    expect(indexes.keys, containsAll(['messages_assoc', 'attachments_message', 'chats_list', 'chat_handles_handle']));
  });

  test('a chat may point at its latest message before that message is copied', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);

    await database.customStatement("INSERT INTO chats (id, guid, latest_message_id) VALUES (1, 'c1', 99)");
    final row = await database.customSelect('SELECT latest_message_id FROM chats WHERE id = 1').getSingle();
    expect(row.read<int>('latest_message_id'), 99);
  });
}
