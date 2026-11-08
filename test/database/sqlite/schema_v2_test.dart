// Schema v2: real foreign keys (drift_dev 2.31 silently dropped every
// `references(...)` in v1), the messages_fts trigram index kept by triggers,
// and the v1 -> v2 migration of a file as stage S1 left it on the phone.
import 'dart:io';

import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

Future<List<Map<String, Object?>>> rows(Db db, String sql) => db.select(sql);

/// `PRAGMA foreign_key_list(table)` as (from, table, to, on_delete).
Future<Set<(String, String, String, String)>> foreignKeys(Db db, String table) async => {
      for (final r in await db.select('PRAGMA foreign_key_list($table)'))
        (r['from'] as String, r['table'] as String, r['to'] as String, r['on_delete'] as String),
    };

/// Every table, index and trigger by name, with its SQL.
Future<Map<String, String>> schema(Db db) async => {
      for (final r in await db.select(
          "SELECT name, sql FROM sqlite_master WHERE sql IS NOT NULL AND name NOT LIKE 'messages_fts_%' "
          "AND name != 'sqlite_sequence'"))
        r['name'] as String: (r['sql'] as String).replaceAll(RegExp(r'\s+'), ' '),
    };

Future<List<int>> ftsIds(Db db, String term) async =>
    [for (final r in await db.select('SELECT rowid FROM messages_fts WHERE text LIKE ? ORDER BY rowid', ['%$term%'])) r['rowid'] as int];

/// A file exactly as stage S1 wrote it on the phone (drift schema v1, check v3,
/// verified), with rows that v1 could hold and v2's foreign keys cannot.
File writeS1File(Directory dir) {
  final file = File('${dir.path}/bluebubbles.db');
  final db = raw.sqlite3.open(file.path);
  try {
    db.execute(File('test/database/sqlite/fixtures/schema_v1.sql').readAsStringSync());
    db.execute('PRAGMA user_version = 1');
    db.execute('''
      INSERT INTO handles (id, address, unique_address_and_service, service) VALUES (1, '+1555', '+1555/iMessage', 'iMessage');
      INSERT INTO contacts (id, display_name, native_contact_id, addresses_json, is_native) VALUES (1, 'A', 'n1', '[]', 1);
      INSERT INTO contact_handles VALUES (1, 1), (1, 77);
      INSERT INTO chats (id, guid, latest_message_id) VALUES (1, 'c1', 3);
      INSERT INTO chat_handles VALUES (1, 1), (9, 1);
      INSERT INTO custom_groups (id, name, sort_order, show_unread_badge) VALUES (1, 'G', 0, 0);
      INSERT INTO custom_group_chats VALUES (1, 1), (1, 8);
      INSERT INTO messages (id, guid, text, sort_at_us, has_attachments, has_reactions, error, chat_id, handle_relation_id,
          has_apple_payload_data, was_delivered_quietly, did_notify_recipient, is_bookmarked, is_delivered, has_effect_played)
        VALUES (1, 'm1', 'Hello World', 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0),
               (2, 'm2', 'orphaned pointers', 2, 0, 0, 0, 5, 6, 0, 0, 0, 0, 0, 0),
               (3, 'm3', 'third one', 3, 0, 0, 0, 1, NULL, 0, 0, 0, 0, 0, 0);
      INSERT INTO attachments (id, guid, message_id, has_live_photo, is_downloaded) VALUES (1, 'a1', 1, 0, 0), (2, 'a2', 404, 0, 0);
      INSERT INTO storage_meta VALUES ('check_version', '3'), ('copy_state', 'verified'), ('schema_version', '1');
      INSERT INTO copy_checkpoints VALUES ('messages', 3, 3);
    ''');
  } finally {
    db.dispose();
  }
  return file;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('bb_schema_v2_'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('fresh file', () {
    late Db db;
    setUp(() => db = Db.memory());
    tearDown(() => db.close());

    test('opens at schema v2 with foreign keys on', () async {
      expect(db.database.schemaVersion, 2);
      expect((await rows(db, 'PRAGMA foreign_keys')).single.values.single, 1);
    });

    test('every child and join table has its foreign keys (PRAGMA foreign_key_list)', () async {
      final printed = <String>[];
      for (final table in ['messages', 'attachments', 'chat_handles', 'contact_handles', 'custom_group_chats', 'chats']) {
        printed.add('$table: ${(await foreignKeys(db, table)).toList()}');
      }
      // ignore: avoid_print
      print('FK proof\n${printed.join('\n')}');
      expect(await foreignKeys(db, 'messages'), {
        ('chat_id', 'chats', 'id', 'SET NULL'),
        ('handle_relation_id', 'handles', 'id', 'SET NULL'),
      });
      expect(await foreignKeys(db, 'attachments'), {('message_id', 'messages', 'id', 'SET NULL')});
      expect(await foreignKeys(db, 'chat_handles'), {('chat_id', 'chats', 'id', 'CASCADE'), ('handle_id', 'handles', 'id', 'CASCADE')});
      expect(await foreignKeys(db, 'contact_handles'),
          {('contact_id', 'contacts', 'id', 'CASCADE'), ('handle_id', 'handles', 'id', 'CASCADE')});
      expect(await foreignKeys(db, 'custom_group_chats'),
          {('group_id', 'custom_groups', 'id', 'CASCADE'), ('chat_id', 'chats', 'id', 'CASCADE')});
      // chats.latest_message_id points at a message of the chat: a cycle, no key.
      expect(await foreignKeys(db, 'chats'), isEmpty);
    });

    test('deletes cascade to join rows and unlink (as ObjectBox leaves them) messages and attachments', () async {
      await db.write((tx) async {
        await tx.execute("INSERT INTO handles (id, address, unique_address_and_service, service) VALUES (1, 'a', 'a/i', 'i'), (2, 'b', 'b/i', 'i')");
        await tx.execute("INSERT INTO contacts (id, display_name, native_contact_id, addresses_json, is_native) VALUES (1, 'A', 'n1', '[]', 1)");
        await tx.execute("INSERT INTO chats (id, guid) VALUES (1, 'c1'), (2, 'c2')");
        await tx.execute('INSERT INTO chat_handles VALUES (1, 1), (1, 2), (2, 2)');
        await tx.execute('INSERT INTO contact_handles VALUES (1, 1), (1, 2)');
        await tx.execute("INSERT INTO custom_groups (id, name, sort_order, show_unread_badge) VALUES (1, 'G', 0, 0)");
        await tx.execute('INSERT INTO custom_group_chats VALUES (1, 1), (1, 2)');
        await tx.execute('INSERT INTO messages (id, guid, sort_at_us, has_attachments, has_reactions, error, chat_id, handle_relation_id, '
            'has_apple_payload_data, was_delivered_quietly, did_notify_recipient, is_bookmarked, is_delivered, has_effect_played) '
            "VALUES (1, 'm1', 1, 1, 0, 0, 1, 2, 0, 0, 0, 0, 0, 0)");
        await tx.execute("INSERT INTO attachments (id, guid, message_id, has_live_photo, is_downloaded) VALUES (1, 'a1', 1, 0, 0)");
      });

      await db.write((tx) => tx.execute('DELETE FROM handles WHERE id = 2'));
      expect(await rows(db, 'SELECT chat_id, handle_id FROM chat_handles ORDER BY 1, 2'), [{'chat_id': 1, 'handle_id': 1}]);
      expect(await rows(db, 'SELECT handle_id FROM contact_handles'), [{'handle_id': 1}]);
      expect((await rows(db, 'SELECT handle_relation_id FROM messages')).single['handle_relation_id'], isNull);

      await db.write((tx) => tx.execute('DELETE FROM chats WHERE id = 1'));
      expect(await rows(db, 'SELECT chat_id FROM custom_group_chats'), [{'chat_id': 2}]);
      expect(await rows(db, 'SELECT count(*) AS n FROM chat_handles'), [{'n': 0}]);
      expect(await rows(db, 'SELECT id, chat_id FROM messages'), [{'id': 1, 'chat_id': null}], reason: 'the message stays');

      await db.write((tx) => tx.execute('DELETE FROM messages WHERE id = 1'));
      expect(await rows(db, 'SELECT id, message_id FROM attachments'), [{'id': 1, 'message_id': null}], reason: 'the attachment stays');

      await db.write((tx) => tx.execute('DELETE FROM custom_groups WHERE id = 1'));
      expect(await rows(db, 'SELECT count(*) AS n FROM custom_group_chats'), [{'n': 0}]);
    });

    test('a row pointing at a missing parent is refused', () async {
      expect(
          () => db.write((tx) => tx.execute('INSERT INTO messages (id, guid, sort_at_us, has_attachments, has_reactions, error, chat_id, '
              'has_apple_payload_data, was_delivered_quietly, did_notify_recipient, is_bookmarked, is_delivered, has_effect_played) '
              "VALUES (1, 'm1', 1, 0, 0, 0, 42, 0, 0, 0, 0, 0, 0)")),
          throwsA(isA<Exception>().having((e) => '$e', 'message', contains('FOREIGN KEY'))));
      expect(() => db.write((tx) => tx.execute('INSERT INTO chat_handles VALUES (5, 5)')), throwsA(isA<Exception>()));
    });

    test('messages_fts is a trigram index kept in step with messages by triggers', () async {
      final ddl = (await rows(db, "SELECT sql FROM sqlite_master WHERE name = 'messages_fts'")).single['sql'] as String;
      expect(ddl, allOf(contains('fts5'), contains("tokenize='trigram'"), contains("content='messages'")));
      expect([for (final r in await rows(db, "SELECT name FROM sqlite_master WHERE type = 'trigger' ORDER BY name")) r['name']],
          ['messages_fts_ad', 'messages_fts_ai', 'messages_fts_au']);

      Future<void> insert(int id, String? text, {String? subject}) => db.write((tx) => tx.execute(
          'INSERT INTO messages (id, guid, text, subject, sort_at_us, has_attachments, has_reactions, error, has_apple_payload_data, '
          'was_delivered_quietly, did_notify_recipient, is_bookmarked, is_delivered, has_effect_played) '
          'VALUES (?, ?, ?, ?, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0)',
          [id, 'm$id', text, subject]));
      await insert(1, 'Dinner at eight?');
      await insert(2, 'see you at DINNER');
      await insert(3, null, subject: 'dinner plans');
      expect(await ftsIds(db, 'dinner'), [1, 2]);
      expect([for (final r in await rows(db, "SELECT rowid FROM messages_fts WHERE subject LIKE '%dinner%'")) r['rowid']], [3]);

      await db.write((tx) => tx.execute("UPDATE messages SET text = 'lunch instead' WHERE id = 1"));
      expect(await ftsIds(db, 'dinner'), [2]);
      expect(await ftsIds(db, 'lunch'), [1]);
      // An upsert rewrites every column; the index follows.
      await db.write((tx) => tx.execute("INSERT INTO messages (id, guid, sort_at_us, has_attachments, has_reactions, error, "
          "has_apple_payload_data, was_delivered_quietly, did_notify_recipient, is_bookmarked, is_delivered, has_effect_played, text) "
          "VALUES (2, 'm2', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'brunch') ON CONFLICT(id) DO UPDATE SET text = excluded.text"));
      expect(await ftsIds(db, 'dinner'), isEmpty);
      await db.write((tx) => tx.execute('DELETE FROM messages WHERE id = 2'));
      expect(await ftsIds(db, 'brunch'), isEmpty);
      // FTS5's own check of the index against the messages table.
      await db.write((tx) => tx.execute("INSERT INTO messages_fts (messages_fts, rank) VALUES ('integrity-check', 1)"));
    });
  });

  group('v1 -> v2 migration of an S1 file', () {
    test('rebuilds the tables with foreign keys, keeps every row, clears dangling pointers, fills messages_fts', () async {
      final file = writeS1File(dir);
      final fresh = Db.memory();
      addTearDown(fresh.close);

      final db = Db.file(file);
      addTearDown(db.close);
      expect((await rows(db, 'PRAGMA user_version')).single.values.single, 2);
      expect(await schema(db), await schema(fresh), reason: 'a migrated file has exactly the schema of a new one');
      for (final table in ['messages', 'attachments', 'chat_handles', 'contact_handles', 'custom_group_chats']) {
        expect(await foreignKeys(db, table), await foreignKeys(fresh, table), reason: table);
      }

      // Rows kept; pointers at rows that don't exist cleared or dropped, as the keys would have.
      expect(await rows(db, 'SELECT id, chat_id, handle_relation_id FROM messages ORDER BY id'), [
        {'id': 1, 'chat_id': 1, 'handle_relation_id': 1},
        {'id': 2, 'chat_id': null, 'handle_relation_id': null},
        {'id': 3, 'chat_id': 1, 'handle_relation_id': null},
      ]);
      expect(await rows(db, 'SELECT id, message_id FROM attachments ORDER BY id'), [{'id': 1, 'message_id': 1}, {'id': 2, 'message_id': null}]);
      expect(await rows(db, 'SELECT * FROM chat_handles'), [{'chat_id': 1, 'handle_id': 1}]);
      expect(await rows(db, 'SELECT * FROM contact_handles'), [{'contact_id': 1, 'handle_id': 1}]);
      expect(await rows(db, 'SELECT * FROM custom_group_chats'), [{'group_id': 1, 'chat_id': 1}]);
      expect((await rows(db, 'SELECT latest_message_id FROM chats')).single['latest_message_id'], 3);
      expect(await rows(db, 'PRAGMA foreign_key_check'), isEmpty);
      expect((await rows(db, 'PRAGMA integrity_check')).single.values.single, 'ok');

      // The S1 bookkeeping is untouched; the index holds the existing text.
      final meta = {for (final r in await rows(db, 'SELECT key, value FROM storage_meta')) r['key']: r['value']};
      expect(meta, containsPair('copy_state', 'verified'));
      expect(meta, containsPair('check_version', '3'));
      expect(meta, containsPair('fts_state', 'ready'));
      expect(await rows(db, 'SELECT * FROM copy_checkpoints'), [{'entity': 'messages', 'last_source_id': 3, 'rows_copied': 3}]);
      expect(await ftsIds(db, 'world'), [1]);
      expect(await ftsIds(db, 'ird on'), [3]);
      await db.write((tx) => tx.execute("INSERT INTO messages_fts (messages_fts, rank) VALUES ('integrity-check', 1)"));
    });

    test('a migrated file keeps working with the keys on: cascades and the index triggers', () async {
      final db = Db.file(writeS1File(dir));
      addTearDown(db.close);
      await db.write((tx) => tx.execute('DELETE FROM chats WHERE id = 1'));
      expect(await rows(db, 'SELECT count(*) AS n FROM chat_handles'), [{'n': 0}]);
      expect(await rows(db, 'SELECT count(*) AS n FROM messages WHERE chat_id IS NULL'), [{'n': 3}]);
      await db.write((tx) => tx.execute("UPDATE messages SET text = 'Goodbye' WHERE id = 1"));
      expect(await ftsIds(db, 'world'), isEmpty);
      expect(await ftsIds(db, 'goodb'), [1]);
    });
  });
}
