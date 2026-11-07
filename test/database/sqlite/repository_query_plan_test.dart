// Every SQL statement each repository method runs is planned on an index:
// no full table scan, no temporary B-tree sort. Checked on the statements the
// methods actually send (Db.recordStatements), without and with ANALYZE stats
// (the phone's copied file has none today).
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/handle_repo.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';

import 'sqlite_seed.dart';

/// The plan lines of every statement [fn] runs through [db].
Future<List<(String, List<String>)>> plansOf(Db db, Future<void> Function() fn) async {
  final statements = await db.recordStatements(fn);
  return [
    for (final (sql, args) in statements)
      (sql, [for (final row in await db.database.customSelect('EXPLAIN QUERY PLAN $sql', variables: [
        for (final a in args) a is int ? Variable.withInt(a) : Variable.withString(a as String),
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
      if (line.startsWith('SCAN')) expect(line, contains('USING INDEX'), reason: '$sql\n$lines');
    }
  }
  for (final index in expected) {
    expect(details.any((d) => d.contains(index)), isTrue, reason: 'expected $index in\n${details.join('\n')}');
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
    });
  }
}
