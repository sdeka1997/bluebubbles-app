import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
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
    // In Dart: an ORDER BY here would sort in a temporary B-tree.
    return result
      ..sort((a, b) {
        final byRowId = (a.originalROWID ?? 0).compareTo(b.originalROWID ?? 0);
        return byRowId != 0 ? byRowId : a.id!.compareTo(b.id!);
      });
  }

  /// Fills `dbAttachments` of [page] with one query on attachments_message.
  Future<Map<int, List<Attachment>>> attachmentsFor(List<Message> page) async {
    final byMessage = await attachments.forMessages(page.map((m) => m.id!));
    for (final m in page) {
      m.dbAttachments.addAll(byMessage[m.id] ?? const []);
    }
    return byMessage;
  }

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

  Future<Message?> _single(List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return null;
    final m = messageFromRow(rows.single);
    await attachmentsFor([m]);
    return m;
  }
}
