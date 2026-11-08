// Every SQL statement each repository method runs is planned on an index:
// no full table scan, no temporary B-tree sort. Checked on the statements the
// methods actually send (Db.recordStatements), without and with ANALYZE stats
// (the phone's copied file has none today).
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/chat_stats_repo.dart';
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/contact_repo.dart';
import 'package:bluebubbles/database/sqlite/custom_group_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/handle_repo.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:bluebubbles/database/sqlite/sync_batch_writer.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';

import 'sqlite_seed.dart';

/// The plan lines of every statement [fn] runs through [db].
Future<List<(String, List<String>)>> plansOf(Db db, Future<void> Function() fn) async {
  final statements = await db.recordStatements(fn);
  return [
    for (final (sql, args) in statements)
      (sql, [for (final row in await db.database.customSelect('EXPLAIN QUERY PLAN $sql', variables: [
        for (final a in args)
          switch (a) {
            null => const Variable<Object>(null),
            final int v => Variable.withInt(v),
            final bool v => Variable.withBool(v),
            _ => Variable.withString(a as String),
          },
      ]).get()) row.read<String>('detail')]),
  ];
}

/// [expected] index names, each used by some statement of the method; nothing
/// scans a table or sorts in a temporary B-tree.
void expectIndexed(List<(String, List<String>)> plans, Set<String> expected) {
  expect(plans, isNotEmpty);
  final details = plans.expand((p) => p.$2).toList();
  for (final (sql, lines) in plans) {
    for (final line in lines) {
      expect(line, isNot(contains('TEMP B-TREE')), reason: '$sql\n$lines');
      // An ordered walk of the intended index with a LIMIT is fine; a table scan is not.
      expect(RegExp(r'^SCAN \w+$').hasMatch(line), isFalse, reason: '$sql\n$lines');
      if (line.startsWith('SCAN')) expect(line, matches(r'USING (COVERING )?INDEX'), reason: '$sql\n$lines');
    }
  }
  for (final index in expected) {
    expect(details.any((d) => d.contains(index)), isTrue, reason: 'expected $index in\n${details.join('\n')}');
  }
}

/// A read of a whole small table on purpose (contacts, custom groups: one row
/// per address-book card or settings entry; ObjectBox reads them whole today).
/// It may scan only [tables]: the table itself and, with ANALYZE stats, the
/// small tables it fills from (an IN list of most of their ids is cheaper as a
/// scan). Nothing sorts in a temporary B-tree.
void expectWholeTable(List<(String, List<String>)> plans, Set<String> tables) {
  for (final (sql, lines) in plans) {
    for (final line in lines) {
      expect(line, isNot(contains('TEMP B-TREE')), reason: '$sql\n$lines');
      final scanned = RegExp(r'^SCAN (\w+)').firstMatch(line)?.group(1);
      if (scanned != null) expect(tables, contains(scanned), reason: '$sql\n$lines');
    }
  }
}

void main() {
  late Db db;
  late MessageRepo messages;
  late ChatRepo chats;
  late HandleRepo handles;
  late AttachmentRepo attachments;

  Future<void> seedSkewed() async {
    // Phone proportions (702,952 messages, 33,372 attachments ~ 5%, 900 handles,
    // 600 contacts) scaled down: one large chat, many small, 15% reactions.
    final seed = Seed();
    for (var h = 1; h <= 900; h++) {
      if (h <= 600) seed.contact(h, 'Contact $h');
      seed.handle(h, address: '+1${h.toString().padLeft(6, '0')}', originalRowId: h + 4, contacts: h <= 600 ? [h] : const []);
    }
    for (var c = 1; c <= 200; c++) {
      seed.chat(c, latestMs: c == 3 ? null : baseMs + c * 1000, latestMessageId: c, handles: [c, 200 + c]);
    }
    for (var i = 1; i <= 6000; i++) {
      seed.message(i, i % 3 == 0 ? 1 : 1 + i % 200, baseMs + i * 1000,
          reactionTo: i % 7 == 0 ? 'm${i - 1}' : null,
          isFromMe: i.isEven,
          handleId: 5 + i % 1000,
          originalRowId: i,
          threadOriginator: i % 500 == 0 ? 'm1' : null);
      if (i % 20 == 0) seed.attachment(i, i);
    }
    await seed.into(db);
    for (var g = 1; g <= 10; g++) {
      await db.write((tx) => CustomGroupRepo(db).create(tx, 'Group $g', [for (var c = g; c <= 200; c += 10) 'chat-$c']));
    }
  }

  for (final analyzed in [false, true]) {
    group(analyzed ? 'with ANALYZE stats' : 'without stats (as on the phone)', () {
      setUp(() async {
        db = Db.memory();
        messages = MessageRepo(db);
        chats = ChatRepo(db);
        handles = HandleRepo(db);
        attachments = AttachmentRepo(db);
        await seedSkewed();
        if (analyzed) await db.database.customStatement('ANALYZE');
      });
      tearDown(() => db.close());

      const key = MessageKey(baseMs * 1000 + 1500 * 1000000, 1500);
      const timelineIndex = 'messages_timeline (chat_id=?';
      const withDeletedIndex = 'messages_chat_time (chat_id=?';
      const senderLookups = {'handles_rowid (original_rowid=?)', 'SEARCH p USING PRIMARY KEY (chat_id=?)'};

      test('MessageRepo.newest -> messages_timeline', () async {
        expectIndexed(await plansOf(db, () => messages.newest([1, 2])), {timelineIndex, ...senderLookups});
      });

      test('MessageRepo.newest(includeDeleted) -> messages_chat_time', () async {
        expectIndexed(await plansOf(db, () => messages.newest([1], includeDeleted: true)), {withDeletedIndex});
      });

      test('MessageRepo.olderThan -> messages_timeline range on (sort_at, id)', () async {
        expectIndexed(await plansOf(db, () => messages.olderThan([1, 2], key)), {'messages_timeline (chat_id=? AND sort_at_us<?)'});
      });

      test('MessageRepo.newerThan -> messages_timeline range on (sort_at, id)', () async {
        expectIndexed(await plansOf(db, () => messages.newerThan([1], key)), {'messages_timeline (chat_id=? AND sort_at_us>?)'});
      });

      test('MessageRepo.around -> messages_timeline (older, exact, newer)', () async {
        expectIndexed(await plansOf(db, () => messages.around([1], key)), {
          'messages_timeline (chat_id=? AND sort_at_us<?)',
          'messages_timeline (chat_id=? AND sort_at_us>?)',
          'messages_timeline (chat_id=? AND sort_at_us=? AND id=?',
        });
      });

      test('MessageRepo.reactionsFor -> messages_assoc', () async {
        expectIndexed(await plansOf(db, () => messages.reactionsFor(['m1', 'm2', 'm3'])), {'messages_assoc (associated_message_guid=?)'});
      });

      test('MessageRepo.attachmentsFor -> attachments_message', () async {
        final page = await messages.newest([1]);
        expectIndexed(await plansOf(db, () => messages.attachmentsFor(page)), {'attachments_message (message_id=?)'});
      });

      test('MessageRepo.byGuid -> unique guid index; byId -> primary key', () async {
        expectIndexed(await plansOf(db, () => messages.byGuid('m15')), {'sqlite_autoindex_messages_1 (guid=?)'});
        expectIndexed(await plansOf(db, () => messages.byId(15)), {'messages USING INTEGER PRIMARY KEY (rowid=?)'});
      });

      test('MessageRepo.thread -> messages_thread', () async {
        expectIndexed(await plansOf(db, () => messages.thread('m1')), {'messages_thread (thread_originator_guid=?)'});
      });

      test('MessageRepo.search (3+ characters) -> messages_fts trigram LIKE, rows by primary key', () async {
        for (final chatIds in [null, [1, 2]]) {
          final plans = await plansOf(db, () => messages.search('text 15', chatIds: chatIds, isFromMe: true, since: at(baseMs)));
          final search = plans.first;
          expect(search.$1, contains('messages_fts'));
          // The matches are sorted by date after the index finds them (as ObjectBox
          // sorts its scan): a temporary B-tree over the matching rows only.
          expect(search.$2.first, matches(r'^SCAN f VIRTUAL TABLE INDEX 0:L'), reason: search.$2.join('\n'));
          expect(search.$2, contains('SEARCH m USING INTEGER PRIMARY KEY (rowid=?)'), reason: search.$2.join('\n'));
          expect(search.$2.where((l) => RegExp(r'^SCAN m\b|^SCAN messages\b').hasMatch(l)), isEmpty, reason: search.$2.join('\n'));
          expectIndexed(plans.skip(1).toList(), {'attachments_message (message_id=?)'});
        }
      });

      test('MessageRepo.search under 3 characters or with LIKE wildcards scans messages, as ObjectBox does for every search', () async {
        for (final term in ['te', 'x', '1_5', '5%']) {
          final plans = await plansOf(db, () => messages.search(term));
          expect(plans.first.$1, isNot(contains('messages_fts')), reason: term);
          // Every not-deleted, non-reaction row (the partial timeline index holds exactly those).
          expect(plans.first.$2, contains(matches(r'^SCAN m( USING INDEX messages_timeline)?$')), reason: term);
        }
      });

      test('MessageRepo.byServerHandleId -> messages_handle_id', () async {
        expectIndexed(await plansOf(db, () => messages.byServerHandleId(9)), {'messages_handle_id (handle_id=?)'});
      });

      test('MessageRepo.newestRename -> messages_renames, walked backwards per chat', () async {
        expectIndexed(await plansOf(db, () => messages.newestRename([1, 2])), {'messages_renames (chat_id=?)'});
      });

      test('ChatStatsRepo: every query on one chat via messages_timeline / messages_chat_time; attachments by message', () async {
        final stats = ChatStatsRepo(db);
        final plans = await plansOf(db, () async {
          await stats.totalMessages(1);
          await stats.sentCount(1);
          await stats.receivedCount(1, participantId: 5);
          await stats.unattributedCount(1, sinceMillis: baseMs);
          await stats.timestampsByParticipant(1, sinceMillis: baseMs);
          await stats.readTimestamps(1);
          await stats.attachmentMessageCount(1);
          await stats.editedCount(1, fromMe: false, participantId: 5);
          await stats.unsentCount(1, fromMe: true);
          await stats.recentTexts(1, fromMe: false, limit: 5, participantId: 5);
          await stats.textLengthsByParticipant(1, limitPerParticipant: 3);
          await stats.textCoverage(1);
          await stats.reactions(1);
          await stats.attachmentMimeTypes(1);
          await stats.expressiveSendStyleIds(1);
          await stats.audioStats(1);
          await stats.groupEvents(1);
          await stats.reactionMatrixData(1, sinceMillis: baseMs);
          await stats.firstMessageMillis(1);
          await stats.cacheKey(1);
        });
        expect(plans.length, greaterThanOrEqualTo(20));
        for (final (sql, lines) in plans) {
          final detail = lines.join('\n');
          expect(detail, anyOf(contains('messages_timeline (chat_id=?)'), contains('messages_chat_time (chat_id=?)')), reason: '$sql\n$detail');
          for (final line in lines) {
            expect(RegExp(r'^SCAN \w+$').hasMatch(line), isFalse, reason: '$sql\n$detail');
            // One chat's rows sorted by date (newest texts, oldest first message):
            // only statements that ORDER BY may sort, and only that chat's rows.
            if (line.contains('TEMP B-TREE')) expect(sql, contains('ORDER BY'), reason: '$sql\n$detail');
          }
          if (sql.contains('JOIN attachments')) expect(detail, contains('attachments_message (message_id=?)'), reason: '$sql\n$detail');
        }
      });

      test('ChatRepo.byId / byGuid -> primary key / unique guid, participants by chat_handles key', () async {
        expectIndexed(await plansOf(db, () => chats.byId(1)), {
          'chats USING INTEGER PRIMARY KEY (rowid=?)',
          'chat_handles USING PRIMARY KEY (chat_id=?)',
          'handles USING INTEGER PRIMARY KEY (rowid=?)',
          'contact_handles_handle (handle_id=?)',
        });
        expectIndexed(await plansOf(db, () => chats.byGuid('chat-1')), {'sqlite_autoindex_chats_1 (guid=?)'});
      });

      test('ChatRepo.listPage -> chats_list, first page and next pages', () async {
        expectIndexed(await plansOf(db, () => chats.listPage(limit: 10)), {'chats_list'});
        expectIndexed(await plansOf(db, () => chats.listPage(after: const ChatListKey(baseMs * 1000 + 30000000, 30), limit: 10)),
            {'chats_list (latest_message_date_us<?)'});
        expectIndexed(await plansOf(db, () => chats.listPage(after: const ChatListKey(null, 40))),
            {'chats_list (latest_message_date_us=? AND id<?)'});
      });

      test('HandleRepo.byId -> primary key; byUniqueKey -> handles_address; contacts -> contact_handles_handle', () async {
        expectIndexed(await plansOf(db, () => handles.byId(1)),
            {'handles USING INTEGER PRIMARY KEY (rowid=?)', 'contact_handles_handle (handle_id=?)'});
        expectIndexed(await plansOf(db, () => handles.byUniqueKey('+1001', 'iMessage')), {'handles_address (address=? AND service=?)'});
      });

      test('AttachmentRepo.byGuid -> unique guid index; forMessages -> attachments_message', () async {
        expectIndexed(await plansOf(db, () => attachments.byGuid('a15')), {'sqlite_autoindex_attachments_1 (guid=?)'});
        expectIndexed(await plansOf(db, () => attachments.forMessages([15, 30])), {'attachments_message (message_id=?)'});
      });

      group('ContactRepo / CustomGroupRepo', () {
        late ContactRepo contacts;
        late CustomGroupRepo groups;
        setUp(() {
          contacts = ContactRepo(db);
          groups = CustomGroupRepo(db);
        });

        test('ContactRepo.byId / byIds -> primary key; handles via contact_handles key', () async {
          expectIndexed(await plansOf(db, () => contacts.byIds([1, 2])), {
            'contacts USING INTEGER PRIMARY KEY (rowid=?)',
            'contact_handles USING PRIMARY KEY (contact_id=?)',
            'handles USING INTEGER PRIMARY KEY (rowid=?)',
          });
        });

        test('ContactRepo.byNativeId -> unique native id index', () async {
          expectIndexed(await plansOf(db, () => contacts.byNativeId('native-5')), {'sqlite_autoindex_contacts_1 (native_contact_id=?)'});
        });

        test('ContactRepo.forHandles -> contact_handles_handle', () async {
          expectIndexed(await plansOf(db, () => contacts.forHandles([1, 2, 3])), {'contact_handles_handle (handle_id=?)'});
        });

        test('ContactRepo.nativeIds -> covering unique index, no table read', () async {
          expectWholeTable(await plansOf(db, () => contacts.nativeIds()), {'contacts'});
          expect((await plansOf(db, () => contacts.nativeIds())).single.$2.single, contains('COVERING INDEX'));
        });

        test('ContactRepo.all / byAddress read the whole contacts table, as today, and never sort in SQL', () async {
          expectWholeTable(await plansOf(db, () => contacts.all()), {'contacts', 'contact_handles', 'handles'});
          expectWholeTable(await plansOf(db, () => contacts.byAddress('+1000005')), {'contacts'});
        });

        test('ContactRepo writes -> unique native id; setHandles / deleteByNativeIds -> keys', () async {
          expectIndexed(
              await plansOf(db, () => db.write((tx) => contacts.upsert(tx, [ContactV2(displayName: 'x', nativeContactId: 'native-5')]))),
              {'sqlite_autoindex_contacts_1 (native_contact_id=?)'});
          expectIndexed(await plansOf(db, () => db.write((tx) => contacts.setHandles(tx, 5, [5, 6]))),
              {'contact_handles USING PRIMARY KEY (contact_id=?)', 'handles USING INTEGER PRIMARY KEY (rowid=?)'});
          expectIndexed(await plansOf(db, () => db.write((tx) => contacts.deleteByNativeIds(tx, ['native-7']))),
              {'sqlite_autoindex_contacts_1 (native_contact_id=?)', 'contact_handles USING PRIMARY KEY (contact_id=?)'});
        });

        test('CustomGroupRepo.byId -> primary key; chats via custom_group_chats key', () async {
          expectIndexed(await plansOf(db, () => groups.byId(1)), {
            'custom_groups USING INTEGER PRIMARY KEY (rowid=?)',
            'custom_group_chats USING PRIMARY KEY (group_id=?)',
            'chats USING INTEGER PRIMARY KEY (rowid=?)',
          });
        });

        test('CustomGroupRepo.all reads the whole (tiny) groups table; idsForChat -> custom_group_chats_chat', () async {
          // Every group's chats are filled like ChatRepo pages (participants, latest
          // message, its attachments); with stats, the seed's 300 attachments make an
          // IN list of 200 latest-message ids cheaper as a scan.
          expectWholeTable(await plansOf(db, () => groups.all()),
              {'custom_groups', 'custom_group_chats', 'chats', 'chat_handles', 'handles', 'messages', 'attachments'});
          expectIndexed(await plansOf(db, () => groups.idsForChat(5)), {'custom_group_chats_chat (chat_id=?)'});
        });

        test('CustomGroupRepo writes -> keys and unique chat guid', () async {
          expectIndexed(await plansOf(db, () => db.write((tx) => groups.create(tx, 'New', ['chat-1', 'chat-2']))),
              {'custom_group_chats USING PRIMARY KEY (group_id=?)', 'sqlite_autoindex_chats_1 (guid=?)'});
          expectIndexed(await plansOf(db, () => db.write((tx) => groups.delete(tx, 2))),
              {'custom_group_chats USING PRIMARY KEY (group_id=?)', 'custom_groups USING INTEGER PRIMARY KEY (rowid=?)'});
        });
      });
      group('writes: every lookup a write makes is on an index', () {
        Message incoming(String guid, int chatId) =>
            Message(guid: guid, dateCreated: at(baseMs + 9999000), isFromMe: true)..chat.targetId = chatId;

        test('MessageRepo.upsert -> unique guid index, then by primary key', () async {
          expectIndexed(await plansOf(db, () => db.write((tx) => messages.upsert(tx, [incoming('m15', 1), incoming('fresh', 2)]))),
              {'sqlite_autoindex_messages_1 (guid=?)'});
        });

        test('MessageRepo.replace / softDelete / restore -> unique guid index', () async {
          expectIndexed(await plansOf(db, () => db.write((tx) => messages.replace(tx, 'm15', incoming('m15b', 1)))),
              {'sqlite_autoindex_messages_1 (guid=?)', 'messages USING INTEGER PRIMARY KEY (rowid=?)'});
          expectIndexed(await plansOf(db, () => db.write((tx) => messages.softDelete(tx, 'm16'))), {'sqlite_autoindex_messages_1 (guid=?)'});
          expectIndexed(await plansOf(db, () => db.write((tx) => messages.restore(tx, 'm16'))), {'sqlite_autoindex_messages_1 (guid=?)'});
        });

        test('MessageRepo.delete -> unique guid index; attachments detached via attachments_message', () async {
          expectIndexed(await plansOf(db, () => db.write((tx) => messages.delete(tx, ['m20', 'm40']))),
              {'sqlite_autoindex_messages_1 (guid=?)', 'attachments_message (message_id=?)'});
        });

        test('ChatRepo.upsert -> unique guid index; setParticipants / setUnread -> primary keys', () async {
          expectIndexed(await plansOf(db, () => db.write((tx) => chats.upsert(tx, [Chat(guid: 'chat-5'), Chat(guid: 'new')]))),
              {'sqlite_autoindex_chats_1 (guid=?)'});
          expectIndexed(await plansOf(db, () => db.write((tx) => chats.setParticipants(tx, 5, [1, 2]))),
              {'chat_handles USING PRIMARY KEY (chat_id=?)', 'handles USING INTEGER PRIMARY KEY (rowid=?)'});
          expectIndexed(await plansOf(db, () => db.write((tx) => chats.setUnread(tx, [1, 2], true))),
              {'chats USING INTEGER PRIMARY KEY (rowid=?)'});
        });

        test('ChatRepo.refreshLatest -> newest row of the chat on messages_chat_time, walked backwards', () async {
          expectIndexed(await plansOf(db, () => db.write((tx) => chats.refreshLatest(tx, 1))),
              {'messages_chat_time (chat_id=?)', 'chats USING INTEGER PRIMARY KEY (rowid=?)'});
        });

        test('ChatRepo.keepNewest / relistShownByEvents -> primary keys only (never the chat history)', () async {
          final added = (await messages.byIds([5999])).values.toList();
          final plans = await plansOf(db, () => db.write((tx) => chats.keepNewest(tx, 1, added)));
          expectIndexed(plans, {'chats USING INTEGER PRIMARY KEY (rowid=?)', 'messages USING INTEGER PRIMARY KEY (rowid=?)'});
          expect(plans.expand((p) => p.$2).where((d) => d.contains('messages_chat_time') || d.contains('messages_timeline')), isEmpty);
          expectIndexed(await plansOf(db, () => db.write((tx) => chats.relistShownByEvents(tx, [1, 2]))),
              {'chats USING INTEGER PRIMARY KEY (rowid=?)'});
        });

        test('ChatRepo.foldServiceTwins: messages move on messages_chat_time; chats (with participants) read whole, as getAll today', () async {
          await db.write((tx) => tx.execute("UPDATE chats SET chat_identifier = 'same' WHERE id IN (7, 8)"));
          final plans = await plansOf(db, () => db.write((tx) => chats.foldServiceTwins(tx, const [])));
          expect(plans.where((p) => p.$1.startsWith('UPDATE messages')), isNotEmpty, reason: 'chat 8 folds into 7');
          for (final (sql, lines) in plans) {
            for (final line in lines) {
              expect(line, isNot(contains('TEMP B-TREE')), reason: '$sql\n$lines');
              final scanned = RegExp(r'^SCAN (\w+)$').firstMatch(line)?.group(1);
              if (scanned != null) expect(['chats', 'chat_handles', 'handles', 'contact_handles'], contains(scanned), reason: '$sql\n$lines');
            }
            if (sql.startsWith('UPDATE messages')) expect(lines.join(), contains('messages_chat_time (chat_id=?)'));
          }
        });
        test('SqliteSyncBatch.write: messages and attachments always keyed; only the fold reads chats (and their participants) whole', () async {
          final prepared = await SqliteSyncBatch.prepare({
            'messagesData': [
              for (final i in [5, 6, 7000])
                {
                  'guid': 'm$i',
                  'dateCreated': baseMs + i * 1000,
                  'isFromMe': false,
                  'handleId': 9,
                  'handle': {'address': '+1000005', 'service': 'iMessage', 'originalROWID': 9},
                  'associatedMessageGuid': 'p:0/m1',
                  'associatedMessageType': 'love',
                  'chats': [
                    {'guid': 'chat-5', 'chatIdentifier': '+1000005', 'participants': [{'address': '+1000005', 'service': 'iMessage'}]},
                  ],
                  'attachments': [{'guid': 'a$i', 'mimeType': 'image/jpeg'}],
                },
            ],
          });
          final plans = await plansOf(db, () => SqliteSyncBatch.write(db, prepared));
          for (final (sql, lines) in plans) {
            for (final line in lines) {
              final scanned = RegExp(r'^SCAN (\w+)$').firstMatch(line)?.group(1);
              if (scanned != null) {
                expect(['chats', 'chat_handles', 'handles', 'contact_handles'], contains(scanned), reason: '$sql\n$lines');
                if (scanned == 'chats') expect(sql, startsWith('SELECT * FROM chats'), reason: 'only foldServiceTwins\n$lines');
              }
            }
          }
          expect(plans.where((p) => p.$1.startsWith('SELECT * FROM chats') && p.$2.contains('SCAN chats')), hasLength(1));
        });

        test('HandleRepo.upsert / insertMissing -> unique address+service index', () async {
          expectIndexed(
              await plansOf(db, () => db.write((tx) => handles.upsert(tx, [Handle(address: '+1000001'), Handle(address: 'x@y.z')]))),
              {'sqlite_autoindex_handles_1 (unique_address_and_service=?)'});
          expectIndexed(await plansOf(db, () => db.write((tx) => handles.insertMissing(tx, [Handle(address: '+1000002')]))),
              {'sqlite_autoindex_handles_1 (unique_address_and_service=?)'});
        });

        test('HandleRepo.byRowIds / adoptServerRowIds -> handles_rowid', () async {
          expectIndexed(await plansOf(db, () => handles.byRowIds([5, 6])), {'handles_rowid (original_rowid=?)'});
          final h = (await handles.byId(3))!;
          expectIndexed(await plansOf(db, () => db.write((tx) => handles.adoptServerRowIds(tx, [(h, 5)]))),
              {'handles_rowid (original_rowid=?)'});
        });

        test('AttachmentRepo.upsert -> unique guid index', () async {
          expectIndexed(
              await plansOf(db, () => db.write((tx) => attachments.upsert(tx, [Attachment(guid: 'a20'), Attachment(guid: 'new')]))),
              {'sqlite_autoindex_attachments_1 (guid=?)'});
        });
      });
    });
  }
}
