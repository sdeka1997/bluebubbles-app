import 'dart:convert';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/app_database.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;

/// Tables the copy fills, parents before children.
const copiedTables = <String>[
  'handles',
  'contacts',
  'contact_handles',
  'chats',
  'chat_handles',
  'custom_groups',
  'custom_group_chats',
  'messages',
  'attachments',
];

enum CopyMode { full, incremental, none }

class CopyReport {
  CopyReport({required this.mode, required this.completed, required this.rows, required this.elapsed});

  final CopyMode mode;
  final bool completed;

  /// Rows copied this run per entity table (new rows; not refreshes).
  final Map<String, int> rows;
  final Duration elapsed;
}

class VerifyResult {
  VerifyResult({required this.counts, required this.mismatches, required this.sampled, required this.elapsed});

  /// Per table: [ObjectBox count, SQLite count].
  final Map<String, List<int>> counts;

  /// `table id column` of every differing field (no values: they can be message text).
  final List<String> mismatches;
  final int sampled;
  final Duration elapsed;

  bool get countsMatch => counts.values.every((pair) => pair[0] == pair[1]);

  /// The large tables hold every row they should; only these force a fresh copy.
  bool get rowsComplete => ['messages', 'attachments'].every((t) => counts[t] == null || counts[t]![0] == counts[t]![1]);
  bool get ok => countsMatch && mismatches.isEmpty;

  Map<String, Object?> toJson() => {
    'ok': ok,
    'counts': counts,
    'mismatches': mismatches.take(50).toList(),
    'mismatchCount': mismatches.length,
    'sampled': sampled,
    'ms': elapsed.inMilliseconds,
  };

  @override
  String toString() => jsonEncode(toJson());
}

Future<Map<String, String?>> readStorageMeta(AppDatabase database) async {
  final rows = await database.customSelect('SELECT key, value FROM storage_meta').get();
  return {for (final row in rows) row.read<String>('key'): row.read<String?>('value')};
}

/// Copies the linked messaging set from ObjectBox into SQLite, then checks it.
///
/// ObjectBox is only read (`getMany`, `getAll`, `findIds`, `count`, `contains`);
/// nothing in this file writes to it. Rows keep their ObjectBox ids, so the copy
/// is idempotent: entities go in ascending id batches, each batch commits with its
/// checkpoint, and a run killed mid-way resumes from the checkpoints. Every run
/// ends by reconciling with ObjectBox as it is now (rows deleted there are deleted
/// here, small tables and each chat's latest message are re-copied), so a verified
/// copy can be topped up cheaply on later launches.
class ObjectBoxSqliteCopy {
  ObjectBoxSqliteCopy({
    required this.source,
    required this.target,
    this.batchSize = 1000,
    this.stopAfterBatches,
    this.log,
    this.progressEvery = 20000,
  });

  final Store source;
  final AppDatabase target;
  final int batchSize;

  /// Test hook: stop (as if killed) after this many batches.
  final int? stopAfterBatches;
  final void Function(String line)? log;
  final int progressEvery;

  /// Verification failures after which the copy stops retrying on its own.
  static const maxVerifyFailures = 2;

  int _batches = 0;

  /// Chats and handles in SQLite, as of the last small-table copy.
  Set<int> _copiedChatIds = {};
  Set<int> _copiedHandleIds = {};
  int _messagesCopiedUpTo = 0;

  Box<Message> get _messages => source.box<Message>();
  Box<Chat> get _chats => source.box<Chat>();
  Box<Handle> get _handles => source.box<Handle>();
  Box<Attachment> get _attachments => source.box<Attachment>();
  Box<ContactV2> get _contacts => source.box<ContactV2>();
  Box<CustomGroup> get _groups => source.box<CustomGroup>();

  Future<CopyReport> run() async {
    final clock = Stopwatch()..start();
    final meta = await readStorageMeta(target);
    final state = meta['copy_state'];
    final failures = int.tryParse(meta['verify_failures'] ?? '') ?? 0;
    if (state == 'verify_failed' && failures >= maxVerifyFailures) {
      log?.call('BBSQL skip: verification failed $failures times, not retrying');
      return CopyReport(mode: CopyMode.none, completed: false, rows: const {}, elapsed: clock.elapsed);
    }
    // A failed check whose message and attachment counts matched only had differing
    // rows (usually ones the app changed between copy and check, which every run
    // re-reads anyway): re-copy those. Missing rows mean start over.
    final repair = state == 'verify_failed' && meta['verify_rows_complete'] == 'true';
    final mode = state == 'verified' || repair ? CopyMode.incremental : CopyMode.full;
    if (state == 'verify_failed' && !repair) await _reset();
    // A full copy inserts every message: the search index is filled once at the
    // end instead of row by row (SQLITE-PLAN-2 section 6, step 6).
    if (mode == CopyMode.full) await target.transaction(() => suspendFts(target.customStatement));
    await _setMeta({'copy_state': 'copying', 'schema_version': '${target.schemaVersion}'});

    final rows = <String, int>{};
    // Deletions first: a message deleted in ObjectBox and saved again under a new
    // id keeps its guid, which is unique here too.
    await _deleteMissing('attachments', _allIds(_attachments));
    await _deleteMissing('messages', _allIds(_messages), childFk: ('attachments', 'message_id'));

    rows.addAll(await _copySmallTables());
    if (repair) await _recopyMismatched(meta['verify_mismatch_ids']);

    for (final table in ['messages', 'attachments']) {
      final copied = await _copyById(table);
      if (copied == null) return _stopped(mode, rows, clock);
      rows[table] = copied;
    }

    // The app keeps writing while the copy runs; the rows it changes most (each
    // chat's latest message, read and delivery state) are taken fresh last.
    await _copySmallTables();
    await _refreshLatestMessages();
    if ((await readStorageMeta(target))['fts_state'] != 'ready') {
      final ftsClock = Stopwatch()..start();
      await target.transaction(() => rebuildFts(target.customStatement));
      log?.call('BBSQL fts rebuilt ms=${ftsClock.elapsedMilliseconds}');
    }
    await _setMeta({'copy_state': 'copied', 'copied_at': DateTime.now().toUtc().toIso8601String()});
    return CopyReport(mode: mode, completed: true, rows: rows, elapsed: clock.elapsed);
  }

  Future<void> _recopyMismatched(String? json) async {
    if (json == null) return;
    final byTable = (jsonDecode(json) as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as List).cast<int>()));
    final messages = _messages.getMany(byTable['messages'] ?? const []).whereType<Message>();
    final attachments = _attachments.getMany(byTable['attachments'] ?? const []).whereType<Attachment>();
    await _ensureParents(messages);
    final messageRows = messages.map(_expectedMessageRow).toList();
    final attachmentRows = attachments.map(_expectedAttachmentRow).toList();
    await target.batch((b) {
      _upsertAll(b, 'messages', messageRows);
      _upsertAll(b, 'attachments', attachmentRows);
    });
  }

  CopyReport _stopped(CopyMode mode, Map<String, int> rows, Stopwatch clock) =>
      CopyReport(mode: mode, completed: false, rows: rows, elapsed: clock.elapsed);

  bool get _shouldStop => stopAfterBatches != null && _batches >= stopAfterBatches!;

  Future<void> _reset() => resetTarget(target);

  /// Empties every copied table, the checkpoints and the copy's own state, so the
  /// next run is a fresh full copy.
  static Future<void> resetTarget(AppDatabase target) async {
    await target.transaction(() async {
      // No per-row index deletes: the next full copy fills the index anew.
      await suspendFts(target.customStatement);
      for (final table in copiedTables.reversed) {
        await target.customStatement('DELETE FROM $table');
      }
      await target.customStatement('DELETE FROM copy_checkpoints');
      await target.customStatement(
          "DELETE FROM storage_meta WHERE key IN ('copy_state', 'verify_failures', 'verify_result', "
          "'verify_rows_complete', 'verify_mismatch_ids', 'verified_at', 'copied_at')");
    });
  }

  Future<void> _setMeta(Map<String, String?> values) async {
    await target.batch((b) {
      for (final entry in values.entries) {
        b.customStatement('INSERT OR REPLACE INTO storage_meta (key, value) VALUES (?, ?)', [entry.key, entry.value]);
      }
    });
  }

  static List<int> _allIds<T>(Box<T> box) {
    final query = box.query().build();
    try {
      return query.findIds();
    } finally {
      query.close();
    }
  }

  Future<int> _checkpoint(String entity) async {
    final row = await target
        .customSelect('SELECT last_source_id FROM copy_checkpoints WHERE entity = ?', variables: [drift.Variable(entity)])
        .getSingleOrNull();
    return row?.read<int>('last_source_id') ?? 0;
  }

  /// Read in pages: a row object per message at once would be tens of MB on the phone.
  Future<List<int>> _sqliteIds(String table) async {
    final ids = <int>[];
    while (true) {
      final page = await target
          .customSelect('SELECT id FROM $table WHERE id > ? ORDER BY id LIMIT 20000',
              variables: [drift.Variable(ids.isEmpty ? 0 : ids.last)])
          .get();
      ids.addAll(page.map((r) => r.read<int>('id')));
      if (page.length < 20000) return ids;
    }
  }

  /// Deletes rows whose ObjectBox row is gone. [childFk] rows pointing at them
  /// are detached first, as ObjectBox leaves them dangling rather than deleting them.
  Future<void> _deleteMissing(String table, List<int> sourceIds, {(String, String)? childFk}) async {
    final present = (sourceIds.toList()..sort());
    final gone = <int>[];
    var i = 0;
    for (final id in await _sqliteIds(table)) {
      while (i < present.length && present[i] < id) {
        i++;
      }
      if (i >= present.length || present[i] != id) gone.add(id);
    }
    if (gone.isEmpty) return;
    for (final chunk in gone.slices(500)) {
      final list = chunk.join(',');
      await target.batch((b) {
        if (childFk != null) b.customStatement('UPDATE ${childFk.$1} SET ${childFk.$2} = NULL WHERE ${childFk.$2} IN ($list)');
        b.customStatement('DELETE FROM $table WHERE id IN ($list)');
      });
    }
    log?.call('BBSQL removed ${gone.length} $table rows deleted in ObjectBox');
  }

  /// Handles, contacts, chats and custom groups with their join tables: a few
  /// thousand rows, re-copied whole on every run so edits there are picked up.
  Future<Map<String, int>> _copySmallTables() async {
    final handles = _handles.getAll();
    final handleIds = handles.map((h) => h.id!).toSet();
    final contacts = _contacts.getAll();
    final chats = _chats.getAll();
    final chatIds = chats.map((c) => c.id!).toSet();
    final groups = _groups.getAll();
    _copiedChatIds = chatIds;
    _copiedHandleIds = handleIds;

    final before = {
      for (final table in ['handles', 'contacts', 'chats', 'custom_groups']) table: (await _sqliteIds(table)).toSet(),
    };
    await _deleteMissing('handles', handleIds.toList());
    await _deleteMissing('contacts', contacts.map((c) => c.id).toList());
    await _deleteMissing('chats', chatIds.toList(), childFk: ('messages', 'chat_id'));
    await _deleteMissing('custom_groups', groups.map((g) => g.id!).toList());

    await target.batch((b) {
      _upsertAll(b, 'handles', handles.map(handleToRow));
      _upsertAll(b, 'contacts', contacts.map(contactToRow));
      b.customStatement('DELETE FROM contact_handles');
      for (final contact in contacts) {
        for (final handleId in _validTargets(contact.handles.map((h) => h.id), handleIds)) {
          b.customStatement('INSERT INTO contact_handles (contact_id, handle_id) VALUES (?, ?)', [contact.id, handleId]);
        }
      }
      _upsertAll(b, 'chats', chats.map(chatToRow));
      b.customStatement('DELETE FROM chat_handles');
      for (final chat in chats) {
        for (final handleId in _validTargets(chat.handles.map((h) => h.id), handleIds)) {
          b.customStatement('INSERT INTO chat_handles (chat_id, handle_id) VALUES (?, ?)', [chat.id, handleId]);
        }
      }
      _upsertAll(b, 'custom_groups', groups.map(customGroupToRow));
      b.customStatement('DELETE FROM custom_group_chats');
      for (final group in groups) {
        for (final chatId in _validTargets(group.chats.map((c) => c.id), chatIds)) {
          b.customStatement('INSERT INTO custom_group_chats (group_id, chat_id) VALUES (?, ?)', [group.id, chatId]);
        }
      }
    });
    return {
      'handles': handleIds.difference(before['handles']!).length,
      'contacts': contacts.where((c) => !before['contacts']!.contains(c.id)).length,
      'chats': chatIds.difference(before['chats']!).length,
      'custom_groups': groups.where((g) => !before['custom_groups']!.contains(g.id)).length,
    };
  }

  Iterable<int> _validTargets(Iterable<int?> ids, Set<int> existing) =>
      ids.whereType<int>().where(existing.contains).toSet();

  void _upsertAll(drift.Batch b, String table, Iterable<Map<String, Object?>> rows) {
    String? sql;
    for (final row in rows) {
      sql ??= upsertSql(table, row.keys.toList());
      b.customStatement(sql, row.values.toList());
    }
  }

  /// The row as SQLite should hold it: [toRow] of the ObjectBox object, with
  /// relations to rows that no longer exist in ObjectBox cleared (ObjectBox
  /// keeps such dangling ids; a foreign key cannot).
  Map<String, Object?> _expectedMessageRow(Message m) {
    final row = messageToRow(m);
    final chatId = row['chat_id'] as int?;
    if (chatId != null && !_copiedChatIds.contains(chatId) && !_chats.contains(chatId)) row['chat_id'] = null;
    final handleId = row['handle_relation_id'] as int?;
    if (handleId != null && !_copiedHandleIds.contains(handleId) && !_handles.contains(handleId)) {
      row['handle_relation_id'] = null;
    }
    return row;
  }

  Map<String, Object?> _expectedAttachmentRow(Attachment a) {
    final row = attachmentToRow(a);
    if (row['message_id'] != null && !_messages.contains(row['message_id'] as int)) row['message_id'] = null;
    return row;
  }

  Map<String, Object?> _expectedRow(String table, Object entity) =>
      table == 'messages' ? _expectedMessageRow(entity as Message) : _expectedAttachmentRow(entity as Attachment);

  /// Copies ObjectBox ids above the checkpoint in ascending batches; returns the
  /// rows copied, or null when stopped by [stopAfterBatches].
  Future<int?> _copyById(String table) async {
    final box = table == 'messages' ? _messages : _attachments;
    final from = await _checkpoint(table);
    if (table == 'messages') _messagesCopiedUpTo = from;
    final ids = (_allIds(box).where((id) => id > from).toList())..sort();
    final clock = Stopwatch()..start();
    var copied = 0;
    var nextProgress = progressEvery;
    final existing = await target
        .customSelect('SELECT rows_copied FROM copy_checkpoints WHERE entity = ?', variables: [drift.Variable(table)])
        .getSingleOrNull();
    var total = existing?.read<int>('rows_copied') ?? 0;
    for (final chunk in ids.slices(batchSize)) {
      if (_shouldStop) return null;
      final entities = (table == 'messages' ? _messages.getMany(chunk) : _attachments.getMany(chunk)).whereType<Object>();
      if (table == 'messages') {
        await _ensureParents(entities.cast<Message>());
      } else if (entities.cast<Attachment>().any((a) => a.message.targetId > _messagesCopiedUpTo)) {
        // An attachment saved with a message newer than the message pass: copy that first.
        await _copyById('messages');
      }
      final rows = entities.map((e) => _expectedRow(table, e)).toList();
      total += rows.length;
      await target.batch((b) {
        _upsertAll(b, table, rows);
        b.customStatement(
          'INSERT OR REPLACE INTO copy_checkpoints (entity, last_source_id, rows_copied) VALUES (?, ?, ?)',
          [table, chunk.last, total],
        );
      });
      _batches++;
      if (table == 'messages') _messagesCopiedUpTo = chunk.last;
      copied += rows.length;
      if (copied >= nextProgress) {
        log?.call('BBSQL progress $table $copied/${ids.length} ${clock.elapsedMilliseconds}ms');
        nextProgress += progressEvery;
      }
      // Let the isolate's event loop breathe between batches.
      await Future<void>.delayed(Duration.zero);
    }
    return copied;
  }

  /// Chats and handles created in ObjectBox after the small tables were copied
  /// must reach SQLite before messages that point at them (foreign keys).
  Future<void> _ensureParents(Iterable<Message> messages) async {
    final missing = messages.any((m) =>
        (m.chat.targetId != 0 && !_copiedChatIds.contains(m.chat.targetId) && _chats.contains(m.chat.targetId)) ||
        (m.handleRelation.targetId != 0 &&
            !_copiedHandleIds.contains(m.handleRelation.targetId) &&
            _handles.contains(m.handleRelation.targetId)));
    if (missing) await _copySmallTables();
  }

  Future<void> _refreshLatestMessages() async {
    final ids = _chats.getAll().map((c) => c.dbLatestMessage.targetId).where((id) => id != 0).toSet().toList();
    final messages = _messages.getMany(ids).whereType<Message>().toList();
    await _ensureParents(messages);
    final rows = messages.map(_expectedMessageRow).toList();
    await target.batch((b) => _upsertAll(b, 'messages', rows));
  }

  Future<List<Map<String, Object?>>> _sqliteRows(String table, List<int> ids) async {
    final result = <Map<String, Object?>>[];
    for (final chunk in ids.slices(500)) {
      final rows = await target.customSelect('SELECT * FROM $table WHERE id IN (${chunk.join(',')})').get();
      result.addAll(rows.map((r) => r.data));
    }
    return result;
  }

  Future<int> _sqliteCount(String table, {int? upTo}) async =>
      (await target.customSelect('SELECT count(*) AS c FROM $table${upTo == null ? '' : ' WHERE id <= $upTo'}').getSingle())
          .read<int>('c');

  /// Every 997th id plus the first and last, in ascending id order.
  static List<int> sampleIds(List<int> sortedIds) => [
    for (var i = 0; i < sortedIds.length; i++)
      if (i % 997 == 0 || i == sortedIds.length - 1) sortedIds[i],
  ];

  /// Compares the copy with ObjectBox: per-table and join counts, then field by
  /// field for every chat, handle, contact and group, a deterministic sample of
  /// messages and attachments, and each chat's latest message. Each SQLite row is
  /// also read back through its fromRow mapper, so a lossy read fails too.
  Future<VerifyResult> verify() async {
    final clock = Stopwatch()..start();
    final counts = <String, List<int>>{};
    final mismatches = <String>[];
    final mismatchIds = <String, Set<int>>{};
    var sampled = 0;

    void compare(String table, Map<String, Object?> expected, Map<String, Object?>? actual,
        Map<String, Object?> Function(Map<String, Object?>) reread) {
      sampled++;
      final id = expected['id'];
      if (actual == null) {
        mismatches.add('$table $id missing');
        mismatchIds.putIfAbsent(table, () => {}).add(id as int);
        return;
      }
      final roundTrip = reread(actual);
      for (final column in expected.keys) {
        if (!const DeepCollectionEquality().equals(expected[column], actual[column]) ||
            !const DeepCollectionEquality().equals(expected[column], roundTrip[column])) {
          mismatches.add('$table $id $column');
          mismatchIds.putIfAbsent(table, () => {}).add(id as int);
        }
      }
    }

    Future<void> compareAll<T>(String table, List<T> entities, Map<String, Object?> Function(T) toRow,
        Map<String, Object?> Function(Map<String, Object?>) reread) async {
      final expected = entities.map(toRow).toList();
      final actual = {
        for (final row in await _sqliteRows(table, expected.map((r) => r['id'] as int).toList())) row['id']: row,
      };
      for (final row in expected) {
        compare(table, row, actual[row['id']], reread);
      }
    }

    final handles = _handles.getAll();
    final handleIds = handles.map((h) => h.id!).toSet();
    final chats = _chats.getAll();
    final chatIds = chats.map((c) => c.id!).toSet();
    final contacts = _contacts.getAll();
    final groups = _groups.getAll();
    _copiedChatIds = chatIds;
    _copiedHandleIds = handleIds;
    counts['handles'] = [handles.length, await _sqliteCount('handles')];
    counts['contacts'] = [contacts.length, await _sqliteCount('contacts')];
    counts['chats'] = [chats.length, await _sqliteCount('chats')];
    counts['custom_groups'] = [groups.length, await _sqliteCount('custom_groups')];
    counts['chat_handles'] = [
      chats.fold(0, (n, c) => n + _validTargets(c.handles.map((h) => h.id), handleIds).length),
      await _sqliteCount('chat_handles'),
    ];
    counts['contact_handles'] = [
      contacts.fold(0, (n, c) => n + _validTargets(c.handles.map((h) => h.id), handleIds).length),
      await _sqliteCount('contact_handles'),
    ];
    counts['custom_group_chats'] = [
      groups.fold(0, (n, g) => n + _validTargets(g.chats.map((c) => c.id), chatIds).length),
      await _sqliteCount('custom_group_chats'),
    ];

    await compareAll('handles', handles, handleToRow, (r) => handleToRow(handleFromRow(r)));
    await compareAll('contacts', contacts, contactToRow, (r) => contactToRow(contactFromRow(r)));
    await compareAll('chats', chats, chatToRow, (r) => chatToRow(chatFromRow(r)));
    await compareAll('custom_groups', groups, customGroupToRow, (r) => customGroupToRow(customGroupFromRow(r)));

    // Rows the app saved after the copy finished are not expected yet: compare
    // counts up to the highest id the copy took.
    for (final table in ['messages', 'attachments']) {
      final ids = _allIds(table == 'messages' ? _messages : _attachments)..sort();
      final copiedUpTo = await _checkpoint(table);
      counts[table] = [ids.where((id) => id <= copiedUpTo).length, await _sqliteCount(table, upTo: copiedUpTo)];
      var sample = sampleIds(ids.where((id) => id <= copiedUpTo).toList());
      if (table == 'messages') {
        sample = {...sample, ...chats.map((c) => c.dbLatestMessage.targetId).where((id) => id != 0 && id <= copiedUpTo)}
            .toList();
      }
      if (table == 'messages') {
        await compareAll('messages', _messages.getMany(sample).whereType<Message>().toList(), _expectedMessageRow,
            (r) => messageToRow(messageFromRow(r)));
      } else {
        await compareAll('attachments', _attachments.getMany(sample).whereType<Attachment>().toList(),
            _expectedAttachmentRow, (r) => attachmentToRow(attachmentFromRow(r)));
      }
    }

    // Latest-message pointers: every pointer ObjectBox can resolve resolves here.
    for (final chat in chats) {
      final id = chat.dbLatestMessage.targetId;
      if (id == 0 || !_messages.contains(id)) continue;
      final row = await target
          .customSelect('SELECT 1 FROM messages WHERE id = ?', variables: [drift.Variable(id)])
          .getSingleOrNull();
      if (row == null) mismatches.add('chats ${chat.id} latest_message_id unresolved');
    }

    final result = VerifyResult(counts: counts, mismatches: mismatches, sampled: sampled, elapsed: clock.elapsed);
    final meta = await readStorageMeta(target);
    final failures = int.tryParse(meta['verify_failures'] ?? '') ?? 0;
    await _setMeta({
      'copy_state': result.ok ? 'verified' : 'verify_failed',
      'verify_failures': result.ok ? '0' : '${failures + 1}',
      'verified_at': DateTime.now().toUtc().toIso8601String(),
      'verify_result': jsonEncode(result.toJson()),
      'verify_rows_complete': '${result.rowsComplete}',
      'verify_mismatch_ids': jsonEncode(mismatchIds.map((k, v) => MapEntry(k, v.toList()))),
    });
    return result;
  }
}
