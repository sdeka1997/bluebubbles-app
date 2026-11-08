import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/relation_fill.dart';
import 'package:bluebubbles/database/sqlite/row_writes.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:collection/collection.dart';

/// A message's place in its chat's timeline: (sort_at_us, id), the order
/// [Message.sort] shows. Pages are found by key, never by count.
class MessageKey implements Comparable<MessageKey> {
  const MessageKey(this.sortAtUs, this.id);

  factory MessageKey.of(Message m) => MessageKey(sortAtMicros(m.dateCreated, m.dateDelivered), m.id!);

  final int sortAtUs;
  final int id;

  @override
  int compareTo(MessageKey other) => sortAtUs != other.sortAtUs ? sortAtUs.compareTo(other.sortAtUs) : id.compareTo(other.id);

  @override
  bool operator ==(Object other) => other is MessageKey && other.sortAtUs == sortAtUs && other.id == id;

  @override
  int get hashCode => Object.hash(sortAtUs, id);

  @override
  String toString() => 'MessageKey($sortAtUs, $id)';
}

/// Messages in SQLite. Every timeline method takes the chat ids of one thread
/// (the canonical chat plus twins not folded into it yet), returns newest first
/// and fills `dbAttachments`. Reactions are not timeline rows: [reactionsFor].
class MessageRepo {
  MessageRepo(this.db) : attachments = AttachmentRepo(db);

  final DbReader db;
  final AttachmentRepo attachments;

  /// Every timeline row of one chat, as the chat screen loads it today
  /// (ChatActions.getMessagesAsync): not deleted, with a date, and not from a
  /// sender this chat can't place (no handle on the phone matches the sender's
  /// server ROWID). Reactions are left out, so a page is always [limit] visible
  /// messages. The partial index holds exactly the rows the first two terms keep.
  static const _timeline = 'FROM messages m INDEXED BY messages_timeline '
      'WHERE m.chat_id = ? AND m.associated_message_guid IS NULL AND m.date_deleted_us IS NULL '
      'AND m.date_created_us IS NOT NULL AND $_senderKnown';

  /// The same rows including deleted ones (`includeDeleted`, e.g. Recently Deleted).
  static const _timelineWithDeleted = 'FROM messages m INDEXED BY messages_chat_time '
      'WHERE m.chat_id = ? AND m.associated_message_guid IS NULL '
      'AND m.date_created_us IS NOT NULL AND $_senderKnown';

  static const _senderKnown = '(m.is_from_me IS NOT 0 OR m.handle_id IS NULL OR m.handle_id = 0 '
      'OR m.original_rowid IS NULL OR m.handle_relation_id IS NOT NULL '
      'OR EXISTS (SELECT 1 FROM handles h WHERE h.original_rowid = m.handle_id) '
      'OR NOT EXISTS (SELECT 1 FROM chat_handles p WHERE p.chat_id = m.chat_id))';

  static const _desc = 'ORDER BY m.sort_at_us DESC, m.id DESC LIMIT ?';
  static const _asc = 'ORDER BY m.sort_at_us ASC, m.id ASC LIMIT ?';

  /// The newest [limit] messages: opening a chat, jumping to the bottom.
  Future<List<Message>> newest(List<int> chatIds, {int limit = 25, bool includeDeleted = false}) =>
      _page(chatIds, limit, includeDeleted, (from) => ('SELECT m.* $from $_desc', [limit]), descending: true);

  /// The [limit] messages just older than [key]: scrolling up.
  Future<List<Message>> olderThan(List<int> chatIds, MessageKey key, {int limit = 25, bool includeDeleted = false}) =>
      _page(chatIds, limit, includeDeleted,
          (from) => ('SELECT m.* $from AND (m.sort_at_us, m.id) < (?, ?) $_desc', [key.sortAtUs, key.id, limit]),
          descending: true);

  /// The [limit] messages just newer than [key]: scrolling back down. Newest first.
  Future<List<Message>> newerThan(List<int> chatIds, MessageKey key, {int limit = 25, bool includeDeleted = false}) async =>
      (await _page(chatIds, limit, includeDeleted,
              (from) => ('SELECT m.* $from AND (m.sort_at_us, m.id) > (?, ?) $_asc', [key.sortAtUs, key.id, limit]),
              descending: false))
          .reversed
          .toList();

  /// [before] older messages, the message at [key] (when it is a timeline row of
  /// [chatIds]) and [after] newer ones, newest first: jump to a message, search
  /// result, last unread.
  Future<List<Message>> around(List<int> chatIds, MessageKey key, {int before = 25, int after = 25, bool includeDeleted = false}) {
    return db.snapshot((reader) async {
      final repo = MessageRepo(reader);
      final newer = await repo.newerThan(chatIds, key, limit: after, includeDeleted: includeDeleted);
      final target = await repo._page(chatIds, 1, includeDeleted,
          (from) => ('SELECT m.* $from AND m.sort_at_us = ? AND m.id = ? $_desc', [key.sortAtUs, key.id, 1]),
          descending: true);
      final older = await repo.olderThan(chatIds, key, limit: before, includeDeleted: includeDeleted);
      return [...newer, ...target, ...older];
    });
  }

  /// One keyset query per chat id (each stays on the index; `chat_id IN (...)`
  /// would sort every older row of all of them), merged by key, deduplicated.
  Future<List<Message>> _page(List<int> chatIds, int limit, bool includeDeleted,
      (String, List<Object?>) Function(String from) query,
      {required bool descending}) {
    return db.snapshot((reader) async {
      final rows = <Map<String, Object?>>[];
      for (final chatId in chatIds.toSet()) {
        final (sql, args) = query(includeDeleted ? _timelineWithDeleted : _timeline);
        rows.addAll(await reader.select(sql, [chatId, ...args]));
      }
      final keyed = [for (final r in rows) (MessageKey(r['sort_at_us'] as int, r['id'] as int), r)]
        ..sort((a, b) => descending ? b.$1.compareTo(a.$1) : a.$1.compareTo(b.$1));
      final seen = <Object>{};
      final page = <Message>[];
      for (final (_, row) in keyed) {
        if (page.length == limit) break;
        if (!seen.add(row['guid'] ?? row['id']!)) continue;
        page.add(messageFromRow(row));
      }
      await MessageRepo(reader).attachmentsFor(page);
      return page;
    });
  }

  /// Reactions (and other associated messages) of [guids], ordered by server
  /// ROWID as today's supplemental query returns them.
  Future<List<Message>> reactionsFor(Iterable<String> guids) async {
    final result = <Message>[];
    for (final chunk in guids.toSet().toList().slices(500)) {
      final rows = await db.select(
          'SELECT * FROM messages WHERE associated_message_guid IN (${sqlPlaceholders(chunk.length)})', chunk);
      result.addAll(rows.map(messageFromRow));
    }
    await attachmentsFor(result);
    // In Dart: an ORDER BY here would sort in a temporary B-tree.
    return result
      ..sort((a, b) {
        final byRowId = (a.originalROWID ?? 0).compareTo(b.originalROWID ?? 0);
        return byRowId != 0 ? byRowId : a.id!.compareTo(b.id!);
      });
  }

  /// Fills every relation of [page] (RelationFill): attachments, chat with
  /// participants, sender with contacts.
  Future<void> attachmentsFor(List<Message> page) => RelationFill(db).messages(page);

  Future<Message?> byGuid(String guid) async {
    final rows = await db.select('SELECT * FROM messages WHERE guid = ?', [guid]);
    return _single(rows);
  }

  Future<Message?> byId(int id) async => (await byIds([id]))[id];

  Future<Map<int, Message>> byIds(Iterable<int> ids) async {
    final result = <int, Message>{};
    for (final chunk in ids.toSet().toList().slices(500)) {
      for (final row in await db.select('SELECT * FROM messages WHERE id IN (${sqlPlaceholders(chunk.length)})', chunk)) {
        result[row['id'] as int] = messageFromRow(row);
      }
    }
    await attachmentsFor(result.values.toList());
    return result;
  }

  /// A reply thread: the originator and every reply to it (not reactions, not
  /// deleted), oldest first, as the reply-thread popup shows them.
  Future<List<Message>> thread(String originatorGuid) {
    return db.snapshot((reader) async {
      final rows = await reader.select(
          'SELECT * FROM messages WHERE thread_originator_guid = ? '
          'AND associated_message_guid IS NULL AND date_deleted_us IS NULL',
          [originatorGuid]);
      final messages = rows.map(messageFromRow).toList();
      final originator = await MessageRepo(reader).byGuid(originatorGuid);
      if (originator != null) messages.add(originator);
      await MessageRepo(reader).attachmentsFor(messages);
      return messages..sort((a, b) => Message.sort(a, b, descending: false));
    });
  }

  /// Messages whose text contains [term], newest first, as the search screen
  /// shows them (SearchQueryHelper.findLocal on ObjectBox): ASCII letters match
  /// either case, other characters only themselves (`Message_.text.contains(
  /// caseSensitive: false)` and SQLite's LIKE fold the same way). No reactions,
  /// nothing deleted, only dated rows. Optional filters: [chatIds], [isFromMe],
  /// [senderHandleId] (the sender's server ROWID, `handle_id`) and [since].
  ///
  /// Terms of 3+ characters are found through messages_fts (trigram), which
  /// picks candidate rows that LIKE then checks; shorter terms, and terms with
  /// LIKE's own `%`, `_` or `\`, can't use it and scan messages as ObjectBox
  /// does for every search today.
  Future<List<Message>> search(String term,
      {List<int>? chatIds, bool? isFromMe, int? senderHandleId, DateTime? since, int limit = 50}) {
    return db.snapshot((reader) async {
      final useIndex = term.runes.length >= 3 && !term.contains(RegExp(r'[%_\\]'));
      final where = <String>[
        'm.associated_message_guid IS NULL',
        'm.date_deleted_us IS NULL',
        'm.date_created_us IS NOT NULL',
        if (chatIds != null) 'm.chat_id IN (${sqlPlaceholders(chatIds.length)})',
        if (isFromMe != null) 'm.is_from_me = ?',
        if (senderHandleId != null) 'm.handle_id = ?',
        if (since != null) 'm.date_created_us >= ?',
      ];
      final args = <Object?>[
        ...?chatIds,
        if (isFromMe != null) isFromMe ? 1 : 0,
        ?senderHandleId,
        if (since != null) since.millisecondsSinceEpoch * 1000,
        limit,
      ];
      // CROSS JOIN keeps the index as the outer loop: each candidate is then
      // one primary-key lookup, never a walk over a chat's whole history.
      final sql = useIndex
          ? 'SELECT m.* FROM messages_fts f CROSS JOIN messages m ON m.id = f.rowid WHERE f.text LIKE ? AND '
          : r"SELECT m.* FROM messages m WHERE m.text LIKE ? ESCAPE '\' AND ";
      final pattern = useIndex ? '%$term%' : '%${term.replaceAllMapped(RegExp(r'[%_\\]'), (c) => '\\${c[0]}')}%';
      final rows = await reader.select(
          '$sql${where.join(' AND ')} ORDER BY m.date_created_us DESC, m.id DESC LIMIT ?', [pattern, ...args]);
      final messages = rows.map(messageFromRow).toList();
      await MessageRepo(reader).attachmentsFor(messages);
      return messages;
    });
  }

  /// Every message whose sender has the server ROWID [serverHandleId]
  /// (`Message.handleId`), e.g. to link them to a repaired handle.
  Future<List<Message>> byServerHandleId(int serverHandleId) async {
    final messages = (await db.select('SELECT * FROM messages WHERE handle_id = ?', [serverHandleId])).map(messageFromRow).toList();
    await attachmentsFor(messages);
    return messages;
  }

  /// The newest group rename (`item_type` 2) stored in any of [chatIds], by
  /// creation date, deleted or not; null when there is none.
  Future<Message?> newestRename(List<int> chatIds) {
    return db.snapshot((reader) async {
      Message? newest;
      for (final chatId in chatIds.toSet()) {
        final rows = await reader.select(
            'SELECT * FROM messages INDEXED BY messages_renames WHERE chat_id = ? AND item_type = 2 '
            'ORDER BY date_created_us DESC, id DESC LIMIT 1',
            [chatId]);
        if (rows.isEmpty) continue;
        final m = messageFromRow(rows.single);
        final created = m.dateCreated?.microsecondsSinceEpoch ?? 0;
        final best = newest?.dateCreated?.microsecondsSinceEpoch ?? 0;
        if (newest == null || created > best || (created == best && m.id! > newest.id!)) newest = m;
      }
      if (newest != null) await MessageRepo(reader).attachmentsFor([newest]);
      return newest;
    });
  }

  /// The stored message [id], relations unfilled (latest-pointer checks).
  Future<Message?> row(int id) async {
    final rows = await db.select('SELECT * FROM messages WHERE id = ?', [id]);
    return rows.isEmpty ? null : messageFromRow(rows.single);
  }

  Future<Message?> _single(List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return null;
    final m = messageFromRow(rows.single);
    await attachmentsFor([m]);
    return m;
  }

  // Writes. Each takes the open [WriteTx] of the caller's Db.write, so a sync
  // batch or a fold is one transaction however many methods it calls.

  /// Inserts or updates [messages] by guid, keeping a stored message's id;
  /// `sort_at_us` follows the dates. Sets each message's id. Relations are
  /// written from `chat.targetId` / `handleRelation.targetId`.
  Future<List<Message>> upsert(WriteTx tx, List<Message> messages) async {
    await saveByKey(tx, 'messages', 'guid', messages,
        key: (m) => m.guid, setId: (m, id) => m.id = id, toRow: messageToRow);
    return messages;
  }

  /// Updates the stored message [oldGuid] from [incoming] as a send receipt,
  /// guid swap or edit does (MessageActions.replaceMessage): new guid and
  /// text, delivery/read/edit dates when given, error state always. Keeps the
  /// id, chat and sender. Returns the stored message, or null when none.
  Future<Message?> replace(WriteTx tx, String oldGuid, Message incoming) async {
    final existing = await MessageRepo(tx).byGuid(oldGuid);
    if (existing == null) return null;
    existing.guid = incoming.guid ?? existing.guid;
    if (incoming.text != null) existing.text = incoming.text;
    existing.service ??= incoming.service;
    existing.dateDelivered = incoming.dateDelivered ?? existing.dateDelivered;
    existing.isDelivered = incoming.isDelivered;
    existing.dateRead = incoming.dateRead ?? existing.dateRead;
    existing.dateEdited = incoming.dateEdited ?? existing.dateEdited;
    if (incoming.attributedBody.isNotEmpty) existing.attributedBody = incoming.attributedBody;
    if (incoming.messageSummaryInfo.isNotEmpty) existing.messageSummaryInfo = incoming.messageSummaryInfo;
    existing.payloadData = incoming.payloadData ?? existing.payloadData;
    existing.wasDeliveredQuietly = incoming.wasDeliveredQuietly || existing.wasDeliveredQuietly;
    existing.didNotifyRecipient = incoming.didNotifyRecipient || existing.didNotifyRecipient;
    existing.error = incoming.error;
    existing.errorMessage = incoming.errorMessage;
    await tx.update('messages', messageToRow(existing));
    return existing;
  }

  /// Hides the message [guid] (sets `date_deleted`). Returns whether it exists.
  Future<bool> softDelete(WriteTx tx, String guid, {DateTime? at}) async {
    final rows = await tx.select('UPDATE messages SET date_deleted_us = ? WHERE guid = ? RETURNING id',
        [(at ?? DateTime.now().toUtc()).microsecondsSinceEpoch, guid]);
    return rows.isNotEmpty;
  }

  /// Clears `date_deleted` of [guid]. Returns whether it was deleted.
  Future<bool> restore(WriteTx tx, String guid) async {
    final rows = await tx.select(
        'UPDATE messages SET date_deleted_us = NULL WHERE guid = ? AND date_deleted_us IS NOT NULL RETURNING id', [guid]);
    return rows.isNotEmpty;
  }

  /// Removes the messages [guids]. Their attachments stay, unlinked, as
  /// ObjectBox leaves them and the S1 copy stores them. Returns the removed ids.
  Future<List<int>> delete(WriteTx tx, Iterable<String> guids) async {
    final ids = <int>[];
    for (final chunk in guids.toSet().toList().slices(500)) {
      final rows = await tx.select('SELECT id FROM messages WHERE guid IN (${sqlPlaceholders(chunk.length)})', chunk);
      ids.addAll(rows.map((r) => r['id'] as int));
    }
    for (final chunk in ids.slices(500)) {
      final list = sqlPlaceholders(chunk.length);
      await tx.execute('UPDATE attachments SET message_id = NULL WHERE message_id IN ($list)', chunk);
      await tx.execute('DELETE FROM messages WHERE id IN ($list)', chunk);
    }
    return ids;
  }
}
