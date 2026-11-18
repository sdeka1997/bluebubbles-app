// The database keeps messages.has_attachments in step with the attachment
// rows pointing at a message (attachmentFlagTriggers), on every write path.
import 'dart:io';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;

import 'sqlite_seed.dart';

void main() {
  late Db db;
  setUp(() async {
    db = Db.memory();
    await (Seed()
          ..chat(1)
          ..message(1, 1, baseMs + 1000, guid: 'photo')
          ..message(2, 1, baseMs + 2000, guid: 'text'))
        .into(db);
  });
  tearDown(() => db.close());

  Future<bool> flagged(int id) async =>
      (await db.select('SELECT has_attachments FROM messages WHERE id = ?', [id])).single['has_attachments'] == 1;

  Future<int> attach(String guid, int? messageId) => db.write((tx) {
        final a = Attachment(guid: guid, mimeType: 'image/jpeg');
        a.message.targetId = messageId;
        return tx.insert('attachments', attachmentToRow(a)..['id'] = null);
      });

  test('an attachment saved outside a sync batch flags its message', () async {
    expect(await flagged(1), isFalse);
    await attach('a1', 1);
    expect(await flagged(1), isTrue);
    expect(await flagged(2), isFalse);
  });

  test('deleting the last attachment clears the flag; one left keeps it', () async {
    final a1 = await attach('a1', 1);
    final a2 = await attach('a2', 1);
    await db.write((tx) => tx.execute('DELETE FROM attachments WHERE id = ?', [a1]));
    expect(await flagged(1), isTrue);
    await db.write((tx) => tx.execute('DELETE FROM attachments WHERE id = ?', [a2]));
    expect(await flagged(1), isFalse);
  });

  test('an attachment moved to another message moves the flag', () async {
    final a1 = await attach('a1', 1);
    await db.write((tx) => tx.execute('UPDATE attachments SET message_id = 2 WHERE id = ?', [a1]));
    expect(await flagged(1), isFalse);
    expect(await flagged(2), isTrue);
  });

  test('a message written from memory cannot clear or invent the flag', () async {
    await attach('a1', 1);
    await db.write((tx) => tx.execute('UPDATE messages SET has_attachments = 0 WHERE id = 1'));
    await db.write((tx) => tx.execute('UPDATE messages SET has_attachments = 1 WHERE id = 2'));
    expect(await flagged(1), isTrue);
    expect(await flagged(2), isFalse);
  });

  test('a message saved after its attachment is flagged', () async {
    await attach('early', null);
    await db.write((tx) async {
      final m = Message(guid: 'late', dateCreated: DateTime.fromMillisecondsSinceEpoch(baseMs + 3000), isFromMe: true);
      m.chat.targetId = 1;
      await tx.insert('messages', messageToRow(m)..['id'] = 3);
      await tx.execute("UPDATE attachments SET message_id = 3 WHERE guid = 'early'");
    });
    expect(await flagged(3), isTrue);
  });

  test('v7 -> v8 upgrade flags every message from its attachments and installs the rule', () async {
    final dir = await Directory.systemTemp.createTemp('bb_v8_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/bluebubbles.db');
    final seedDb = Db.file(file);
    await (Seed()
          ..chat(1)
          ..message(1, 1, baseMs + 1000, guid: 'sent-photo')
          ..message(2, 1, baseMs + 2000, guid: 'plain'))
        .into(seedDb);
    await seedDb.close();
    final r = raw.sqlite3.open(file.path);
    for (final name in [
      'attachments_flag_insert',
      'attachments_flag_delete',
      'attachments_flag_update',
      'messages_flag_attachments',
      'messages_flag_attachments_insert',
      'messages_flag_reactions',
      'messages_flag_reactions_insert',
      'messages_reacted_insert',
      'messages_reacted_delete',
      'messages_reacted_update',
    ]) {
      r.execute('DROP TRIGGER $name');
    }
    // What a v7 build left: a photo sent from the phone, never flagged.
    r.execute("INSERT INTO attachments (guid, message_id, is_outgoing, has_live_photo, is_downloaded) "
        "VALUES ('att', 1, 1, 0, 1)");
    r.execute('UPDATE messages SET has_attachments = 0');
    r.execute('PRAGMA user_version = 7');
    r.dispose();

    final upgraded = Db.file(file);
    addTearDown(upgraded.close);
    expect((await upgraded.select('PRAGMA user_version')).single.values.single, 8);
    final rows = await upgraded.select('SELECT guid, has_attachments FROM messages ORDER BY id');
    expect(rows, [
      {'guid': 'sent-photo', 'has_attachments': 1},
      {'guid': 'plain', 'has_attachments': 0},
    ]);
    await upgraded.write((tx) => tx.execute("DELETE FROM attachments WHERE guid = 'att'"));
    expect((await upgraded.select('SELECT has_attachments FROM messages WHERE id = 1')).single['has_attachments'], 0);
  });

  group('has_reactions', () {
    Future<bool> reacted(String guid) async =>
        (await db.select('SELECT has_reactions FROM messages WHERE guid = ?', [guid])).single['has_reactions'] == 1;

    Future<void> react(int id, String guid, String target) => db.write((tx) {
          final m = Message(guid: guid, associatedMessageGuid: target, associatedMessageType: 'love',
              dateCreated: DateTime.fromMillisecondsSinceEpoch(baseMs + id * 1000), isFromMe: true);
          m.chat.targetId = 1;
          return tx.insert('messages', messageToRow(m)..['id'] = id);
        });

    test('a reaction flags its message; removing the last one clears it', () async {
      await react(10, 'r1', 'text');
      await react(11, 'r2', 'text');
      expect(await reacted('text'), isTrue);
      await db.write((tx) => tx.execute('DELETE FROM messages WHERE id = 10'));
      expect(await reacted('text'), isTrue);
      await db.write((tx) => tx.execute('DELETE FROM messages WHERE id = 11'));
      expect(await reacted('text'), isFalse);
    });

    test('a reaction stored before its message flags the message when it arrives', () async {
      await react(10, 'r1', 'later');
      await db.write((tx) {
        final m = Message(guid: 'later', dateCreated: DateTime.fromMillisecondsSinceEpoch(baseMs + 9000));
        m.chat.targetId = 1;
        return tx.insert('messages', messageToRow(m)..['id'] = 20);
      });
      expect(await reacted('later'), isTrue);
    });

    test('a message written from memory cannot clear or invent the flag', () async {
      await react(10, 'r1', 'text');
      await db.write((tx) => tx.execute("UPDATE messages SET has_reactions = 0 WHERE guid = 'text'"));
      await db.write((tx) => tx.execute("UPDATE messages SET has_reactions = 1 WHERE guid = 'photo'"));
      expect(await reacted('text'), isTrue);
      expect(await reacted('photo'), isFalse);
    });
  });
}
