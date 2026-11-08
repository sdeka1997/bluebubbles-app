import 'dart:io';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/app_database.dart';
import 'package:bluebubbles/database/sqlite/objectbox_sqlite_copy.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';

// The copy reads a real ObjectBox store. Host tests need the ObjectBox C
// library: lib/libobjectbox.dylib (macOS, git-ignored) or a system install.

DateTime _ms(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

class Fixture {
  Fixture(this.directory) : store = Store(getObjectBoxModel(), directory: directory.path);

  final Directory directory;
  Store store;

  late Chat alice;
  late Chat group;
  late Handle aliceHandle;
  late Handle bobHandle;
  late Message latestGroupMessage;

  /// Every entity, relations, null booleans, JSON fields, a hard-deleted row,
  /// a soft-deleted message, reactions, and old history saved after newer messages.
  void seed() {
    final handles = store.box<Handle>();
    aliceHandle = Handle(address: '+15550001', service: 'iMessage', originalROWID: 1);
    bobHandle = Handle(address: 'bob@example.com', service: 'iMessage', originalROWID: 2, color: '#123');
    final gone = Handle(address: 'gone', originalROWID: 3);
    handles.putMany([aliceHandle, bobHandle, gone]);

    final contact = ContactV2(displayName: 'Alice', nativeContactId: 'n1', addresses: const ['+15550001'])
      ..phoneNumbers = const [ContactPhone(number: '+15550001', label: 'mobile')];
    contact.handles.add(aliceHandle);
    store.box<ContactV2>().put(contact);

    alice = Chat(guid: 'iMessage;-;+15550001', chatIdentifier: '+15550001', isArchived: null, isPinned: null)
      ..legacyGroupIds = null;
    alice.handles.add(aliceHandle);
    group = Chat(guid: 'iMessage;+;chat1', displayName: 'Group', textFieldAttachments: const ['/a.png'])
      ..legacyGroupIds = const ['g-old'];
    group.handles.addAll([aliceHandle, bobHandle]);
    store.box<Chat>().putMany([alice, group]);

    final customGroup = CustomGroup(name: 'Family', sortOrder: 1, showUnreadBadge: false);
    customGroup.chats.add(group);
    store.box<CustomGroup>().put(customGroup);

    final messages = store.box<Message>();
    final batch = <Message>[];
    for (var i = 0; i < 60; i++) {
      final m = Message(
        guid: 'm$i',
        text: 'text $i',
        dateCreated: _ms(1700000000000 + i * 1000),
        // Some Macs report delivery before creation; sort_at must take the earlier one.
        dateDelivered: i % 7 == 0 ? _ms(1700000000000 + i * 1000 - 500) : null,
        isFromMe: i % 3 == 0 ? null : i.isEven,
        hasDdResults: i % 5 == 0 ? null : false,
        metadata: i % 4 == 0 ? {'k': i, 'list': [1, 'a']} : null,
        dateDeleted: i == 10 ? _ms(1700000099000) : null,
      );
      m.chat.target = i.isEven ? alice : group;
      m.handleRelation.target = i.isEven ? aliceHandle : bobHandle;
      batch.add(m);
    }
    messages.putMany(batch);
    // Reactions point at an earlier message.
    final reaction = Message(guid: 'r1', associatedMessageGuid: 'm2', associatedMessageType: 'love', dateCreated: _ms(1700000100000));
    reaction.chat.target = alice;
    messages.put(reaction);
    // Old history saved after the newest messages (a late re-download).
    final late = Message(guid: 'old-1', text: 'from 2017', dateCreated: _ms(1500000000000));
    late.chat.target = group;
    messages.put(late);
    // A message pointing at a chat and handle that no longer exist.
    final orphan = Message(guid: 'orphan', dateCreated: _ms(1700000200000));
    orphan.chat.targetId = 9999;
    orphan.handleRelation.target = gone;
    messages.put(orphan);
    handles.remove(gone.id!);
    // A hard-deleted message leaves a gap in the ids.
    messages.remove(batch[20].id!);

    latestGroupMessage = batch[59];
    alice.dbLatestMessage.target = reaction;
    alice.dbOnlyLatestMessageDate = reaction.dateCreated;
    group.dbLatestMessage.target = latestGroupMessage;
    store.box<Chat>().putMany([alice, group]);

    final attachment = Attachment(guid: 'a1', mimeType: 'image/png', isOutgoing: null, metadata: {'w': 1}, exif: {'x': 'y'});
    attachment.message.target = batch[3];
    store.box<Attachment>().put(attachment);
  }

  void close() => store.close();
}

Future<Map<String, List<Map<String, Object?>>>> dumpTables(AppDatabase database) async {
  final result = <String, List<Map<String, Object?>>>{};
  for (final table in copiedTables) {
    final rows = await database.customSelect('SELECT * FROM $table ORDER BY 1, 2').get();
    result[table] = rows.map((r) => r.data).toList();
  }
  return result;
}

Future<int> count(AppDatabase database, String table) async =>
    (await database.customSelect('SELECT count(*) AS c FROM $table').getSingle()).read<int>('c');

Future<List<int>> ftsIds(AppDatabase database, String term) async => [
      for (final r in await database
          .customSelect("SELECT rowid FROM messages_fts WHERE text LIKE '%$term%' ORDER BY rowid")
          .get())
        r.read<int>('rowid'),
    ];

Future<List<String>> ftsTriggerNames(AppDatabase database) async => [
      for (final r in await database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'trigger' AND name LIKE 'messages_fts_%' ORDER BY name")
          .get())
        r.read<String>('name'),
    ];

/// FTS5's own check that messages_fts holds exactly the indexed text of messages.
Future<void> expectFtsConsistent(AppDatabase database) =>
    database.customStatement("INSERT INTO messages_fts (messages_fts, rank) VALUES ('integrity-check', 1)");

void main() {
  // The resume test holds a clean copy and a resumed one open side by side.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory directory;
  late Fixture fixture;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('bb_copy_');
    fixture = Fixture(Directory('${directory.path}/objectbox'))..seed();
  });

  tearDown(() {
    if (!fixture.store.isClosed()) fixture.close();
    directory.deleteSync(recursive: true);
  });

  test('copies every entity and relation, keeps ids, converts ms to us, and verifies', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final copy = ObjectBoxSqliteCopy(source: fixture.store, target: database, batchSize: 7);

    final report = await copy.run();
    expect(report.completed, isTrue);
    final verify = await copy.verify();
    expect(verify.ok, isTrue, reason: verify.toString());

    expect(await count(database, 'messages'), fixture.store.box<Message>().count());
    expect(await count(database, 'handles'), 2);
    expect(await count(database, 'chats'), 2);
    expect(await count(database, 'chat_handles'), 3);
    expect(await count(database, 'contact_handles'), 1);
    expect(await count(database, 'custom_group_chats'), 1);
    expect(await count(database, 'attachments'), 1);

    final m7 = fixture.store.box<Message>().query(Message_.guid.equals('m7')).build().findFirst()!;
    final row = (await database.customSelect('SELECT * FROM messages WHERE id = ${m7.id}').getSingle()).data;
    expect(row['date_created_us'], m7.dateCreated!.millisecondsSinceEpoch * 1000);
    expect(row['sort_at_us'], m7.dateDelivered!.millisecondsSinceEpoch * 1000);
    expect(row['chat_id'], fixture.group.id);
    expect(row['is_from_me'], 0);
    final m3 = (await database.customSelect("SELECT is_from_me FROM messages WHERE guid = 'm3'").getSingle()).data;
    expect(m3['is_from_me'], isNull);
    final orphan = (await database.customSelect("SELECT chat_id, handle_relation_id FROM messages WHERE guid = 'orphan'").getSingle()).data;
    expect(orphan, {'chat_id': null, 'handle_relation_id': null});
    final chat = (await database.customSelect('SELECT latest_message_id FROM chats WHERE id = ${fixture.group.id}').getSingle()).data;
    expect(chat['latest_message_id'], fixture.latestGroupMessage.id);

    final meta = await readStorageMeta(database);
    expect(meta['copy_state'], 'verified');
    expect(meta['verify_result'], contains('"ok":true'));
  });

  test('fills messages_fts once after the bulk insert and keeps it maintained afterwards', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final lines = <String>[];
    final copy = ObjectBoxSqliteCopy(source: fixture.store, target: database, batchSize: 7, log: lines.add);
    await copy.run();
    expect((await copy.verify()).ok, isTrue);

    expect((await readStorageMeta(database))['fts_state'], 'ready');
    expect(await ftsTriggerNames(database), ['messages_fts_ad', 'messages_fts_ai', 'messages_fts_au']);
    await expectFtsConsistent(database);
    final m7 = fixture.store.box<Message>().query(Message_.guid.equals('m7')).build().findFirst()!;
    expect(await ftsIds(database, 'text 7'), [m7.id]);
    expect(await ftsIds(database, 'from 2017'), hasLength(1));
    expect(lines.where((l) => l.startsWith('BBSQL fts rebuilt')), hasLength(1));

    // A top-up run goes through the triggers.
    final newer = Message(guid: 'new-fts', text: 'freshly searchable', dateCreated: _ms(1800000000000));
    newer.chat.target = fixture.alice;
    fixture.store.box<Message>().put(newer);
    await ObjectBoxSqliteCopy(source: fixture.store, target: database, batchSize: 7).run();
    expect(await ftsIds(database, 'freshly'), [newer.id]);
    await expectFtsConsistent(database);
  });

  test('a copy killed mid-way has no index triggers yet; the resumed copy builds the index', () async {
    final file = File('${directory.path}/bluebubbles.db');
    var database = AppDatabase.file(file);
    await ObjectBoxSqliteCopy(source: fixture.store, target: database, batchSize: 4, stopAfterBatches: 3).run();
    expect((await readStorageMeta(database))['fts_state'], 'building');
    expect(await ftsTriggerNames(database), isEmpty, reason: 'the bulk insert does no per-row index work');
    await database.close();

    database = AppDatabase.file(file);
    addTearDown(database.close);
    final resumed = ObjectBoxSqliteCopy(source: fixture.store, target: database, batchSize: 4);
    expect((await resumed.run()).completed, isTrue);
    expect((await resumed.verify()).ok, isTrue);
    expect((await readStorageMeta(database))['fts_state'], 'ready');
    expect(await ftsTriggerNames(database), hasLength(3));
    await expectFtsConsistent(database);
    expect(await ftsIds(database, 'text 59'), hasLength(1));
  });

  test('never writes to the ObjectBox store', () async {
    fixture.close();
    final dataFile = File('${fixture.directory.path}/data.mdb');
    final before = sha256.convert(dataFile.readAsBytesSync());
    fixture.store = Store(getObjectBoxModel(), directory: fixture.directory.path);
    final database = AppDatabase.inMemory();
    addTearDown(database.close);

    final copy = ObjectBoxSqliteCopy(source: fixture.store, target: database, batchSize: 5);
    await copy.run();
    expect((await copy.verify()).ok, isTrue);
    fixture.close();

    expect(sha256.convert(dataFile.readAsBytesSync()), before);
    for (final file in Directory('lib/database/sqlite').listSync().whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.endsWith('.g.dart')) continue;
      final source = file.readAsStringSync();
      for (final write in ['.put(', '.putMany(', '.putAsync(', '.remove(', '.removeMany(', '.removeAll(', 'TxMode.write']) {
        expect(source.contains(write), isFalse, reason: '${file.path} calls $write');
      }
    }
  });

  test('a copy killed after a few batches resumes to the same result as an uninterrupted one', () async {
    final clean = AppDatabase.inMemory();
    addTearDown(clean.close);
    await ObjectBoxSqliteCopy(source: fixture.store, target: clean, batchSize: 4).run();

    final file = File('${directory.path}/bluebubbles.db');
    var database = AppDatabase.file(file);
    final first = await ObjectBoxSqliteCopy(source: fixture.store, target: database, batchSize: 4, stopAfterBatches: 5).run();
    expect(first.completed, isFalse);
    expect(await count(database, 'messages'), lessThan(fixture.store.box<Message>().count()));
    await database.close();

    database = AppDatabase.file(file);
    addTearDown(database.close);
    final resumed = ObjectBoxSqliteCopy(source: fixture.store, target: database, batchSize: 4);
    final second = await resumed.run();
    expect(second.completed, isTrue);
    expect((await resumed.verify()).ok, isTrue);

    expect(await dumpTables(database), await dumpTables(clean));
  });

  test('running again after a verified copy only tops up new rows and re-verifies', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final copy = ObjectBoxSqliteCopy(source: fixture.store, target: database, batchSize: 10);
    await copy.run();
    expect((await copy.verify()).ok, isTrue);

    final newer = Message(guid: 'new-1', text: 'new', dateCreated: _ms(1800000000000));
    newer.chat.target = fixture.alice;
    fixture.store.box<Message>().put(newer);
    fixture.alice.dbLatestMessage.target = newer;
    fixture.store.box<Chat>().put(fixture.alice);

    final again = ObjectBoxSqliteCopy(source: fixture.store, target: database, batchSize: 10);
    final report = await again.run();
    expect(report.mode, CopyMode.incremental);
    expect(report.rows['messages'], 1);
    final verify = await again.verify();
    expect(verify.ok, isTrue, reason: verify.toString());
    final chat = (await database.customSelect('SELECT latest_message_id FROM chats WHERE id = ${fixture.alice.id}').getSingle()).data;
    expect(chat['latest_message_id'], newer.id);
  });

  test('a latest message saved after the message pass does not break the counts', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final copy = ObjectBoxSqliteCopy(source: fixture.store, target: database, batchSize: 10);
    await copy.run();
    // As if the app saved a newer latest message between the message pass and the
    // latest-pointer refresh: the refresh copies it above the checkpoint.
    final newer = Message(guid: 'between', dateCreated: _ms(1800000000000));
    newer.chat.target = fixture.group;
    fixture.store.box<Message>().put(newer);
    fixture.group.dbLatestMessage.target = newer;
    fixture.store.box<Chat>().put(fixture.group);
    await database.customStatement(
        "INSERT INTO messages (id, guid, sort_at_us, chat_id, has_attachments, has_reactions, error, has_apple_payload_data, "
        "was_delivered_quietly, did_notify_recipient, is_bookmarked, is_delivered, has_effect_played) "
        "VALUES (${newer.id}, 'between', 0, ${fixture.group.id}, 0, 0, 0, 0, 0, 0, 0, 0, 0)");

    final verify = await copy.verify();
    expect(verify.countsMatch, isTrue, reason: verify.toString());
  });

  test('verification catches a mismatched field and a missing row', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final copy = ObjectBoxSqliteCopy(source: fixture.store, target: database, batchSize: 10);
    await copy.run();

    await database.customStatement("UPDATE messages SET is_from_me = 1 - coalesce(is_from_me, 0) WHERE id = ${fixture.latestGroupMessage.id}");
    final mismatch = await copy.verify();
    expect(mismatch.ok, isFalse);
    expect(mismatch.mismatches.single, contains('messages ${fixture.latestGroupMessage.id} is_from_me'));
    expect((await readStorageMeta(database))['copy_state'], 'verify_failed');

    // Counts matched, so the next run re-copies just the differing rows.
    final repair = ObjectBoxSqliteCopy(source: fixture.store, target: database, batchSize: 10);
    expect((await repair.run()).mode, CopyMode.incremental);
    expect((await repair.verify()).ok, isTrue);

    await database.customStatement("DELETE FROM attachments");
    final missing = await repair.verify();
    expect(missing.ok, isFalse);
    expect(missing.counts['attachments'], [1, 0]);
    // Missing rows: the next run starts over.
    final restart = ObjectBoxSqliteCopy(source: fixture.store, target: database, batchSize: 10);
    expect((await restart.run()).mode, CopyMode.full);
    expect((await restart.verify()).ok, isTrue);
  });
}
