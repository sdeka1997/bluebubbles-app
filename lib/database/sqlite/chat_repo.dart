import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/service_twin_helpers.dart'
    show assignThreadKeys, canonicalTwinFor, carryOverThreadSettings;
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/relation_fill.dart';
import 'package:bluebubbles/database/sqlite/row_writes.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:collection/collection.dart';

/// Where a chat list page ends: (latest_message_date_us, id) of its last chat.
/// Chats with no latest message date come after all dated ones, by id.
class ChatListKey {
  const ChatListKey(this.latestMessageDateUs, this.id);

  factory ChatListKey.of(Chat c) => ChatListKey(c.dbOnlyLatestMessageDate?.microsecondsSinceEpoch, c.id!);

  final int? latestMessageDateUs;
  final int id;

  @override
  String toString() => 'ChatListKey($latestMessageDateUs, $id)';
}

/// Chats in SQLite, each with its participants in `handles` (and `participants`),
/// their contacts, and the latest message in [Chat.latestMessage].
class ChatRepo {
  ChatRepo(this.db);

  final DbReader db;

  Future<Chat?> byId(int id) => _one('SELECT * FROM chats WHERE id = ?', [id]);

  Future<Chat?> byGuid(String guid) => _one('SELECT * FROM chats WHERE guid = ?', [guid]);

  Future<Chat?> byIdentifier(String identifier) =>
      _one('SELECT * FROM chats WHERE chat_identifier = ? ORDER BY id LIMIT 1', [identifier]);

  Future<Map<int, Chat>> byIds(Iterable<int> ids) {
    return db.snapshot((reader) async {
      final chats = <Chat>[];
      for (final chunk in ids.toSet().toList().slices(500)) {
        final rows = await reader.select('SELECT * FROM chats WHERE id IN (${sqlPlaceholders(chunk.length)})', chunk);
        chats.addAll(rows.map(chatFromRow));
      }
      await ChatRepo(reader)._fill(chats);
      return {for (final c in chats) c.id!: c};
    });
  }

  /// [chat]'s thread key as stored: a Chat held in memory can predate the
  /// regroup that changed it.
  Future<String?> storedThreadKey(Chat chat) async {
    if (chat.id == null) return chat.threadKey;
    final rows = await db.select('SELECT thread_key FROM chats WHERE id = ?', [chat.id]);
    return rows.isEmpty ? chat.threadKey : rows.single['thread_key'] as String?;
  }

  /// The live copies of [threadKey], with relations filled.
  Future<List<Chat>> threadCopies(String threadKey) async {
    final rows = await db.select('SELECT id FROM chats WHERE thread_key = ? AND date_deleted_us IS NULL ORDER BY id', [
      threadKey,
    ]);
    final ids = rows.map((row) => row['id'] as int).toList();
    final found = await byIds(ids);
    return [
      for (final id in ids)
        if (found[id] != null) found[id]!,
    ];
  }

  /// Links [handleId] to empty one-to-one chats whose GUID names [address],
  /// matching the legacy contact sync fallback.
  Future<void> linkEmptyOneToOneByAddress(WriteTx tx, String address, int handleId) async {
    final rows = await tx.select(
      'SELECT c.id FROM chats c WHERE instr(c.guid, ?) > 0 '
      'AND NOT EXISTS (SELECT 1 FROM chat_handles ch WHERE ch.chat_id = c.id)',
      [';-;$address'],
    );
    for (final row in rows) {
      final chatId = row['id'] as int;
      await tx.execute('INSERT INTO chat_handles (chat_id, handle_id) VALUES (?, ?)', [chatId, handleId]);
      tx.markChanged('chat_handles', [chatId]);
    }
  }

  /// One page of the chat list in the order today's list query loads it
  /// (ChatActions.getChatsAsync): not deleted, newest latest message first.
  /// [after] is the last chat of the previous page. Pins and folded twins are
  /// applied by ChatsService on top, as they are today.
  Future<List<Chat>> listPage({ChatListKey? after, int limit = 50}) {
    return db.snapshot((reader) async {
      final rows = <Map<String, Object?>>[];
      if (after?.latestMessageDateUs != null || after == null) {
        rows.addAll(
          await reader.select(
            after == null
                ? 'SELECT * FROM chats WHERE date_deleted_us IS NULL AND latest_message_date_us IS NOT NULL '
                      'ORDER BY latest_message_date_us DESC, id DESC LIMIT ?'
                : 'SELECT * FROM chats WHERE date_deleted_us IS NULL '
                      'AND (latest_message_date_us, id) < (?, ?) '
                      'ORDER BY latest_message_date_us DESC, id DESC LIMIT ?',
            [
              if (after != null) ...[after.latestMessageDateUs, after.id],
              limit,
            ],
          ),
        );
      }
      if (rows.length < limit) {
        // Undated chats last, as SQLite and ObjectBox both order nulls in a descending sort.
        rows.addAll(
          await reader.select(
            'SELECT * FROM chats WHERE date_deleted_us IS NULL AND latest_message_date_us IS NULL '
            'AND id < ? ORDER BY latest_message_date_us DESC, id DESC LIMIT ?',
            [after?.latestMessageDateUs == null && after != null ? after.id : _maxId, limit - rows.length],
          ),
        );
      }
      final chats = rows.map(chatFromRow).toList();
      await ChatRepo(reader)._fill(chats);
      return chats;
    });
  }

  static const _maxId = 0x7fffffffffffffff;

  Future<Chat?> _one(String sql, List<Object?> args) {
    return db.snapshot((reader) async {
      final rows = await reader.select(sql, args);
      if (rows.isEmpty) return null;
      final chat = chatFromRow(rows.single);
      await ChatRepo(reader)._fill([chat]);
      return chat;
    });
  }

  /// Every relation (RelationFill): participants with their contacts and,
  /// with [latest], the latest message with its attachments and sender.
  Future<void> _fill(List<Chat> chats, {bool latest = true}) => RelationFill(db, latest: latest).chats(chats);

  // Writes. Each takes the open [WriteTx] of the caller's Db.write.

  /// Inserts or updates [chats] by guid, keeping a stored chat's id. Every
  /// column is written from the object (as ObjectBox's `put`), so callers
  /// merge into the stored chat first. Participants: [setParticipants].
  /// Saves [chats] by guid. The thread key is [regroupThreads]'s and the latest
  /// pointer the database's; neither is written from memory; only a new chat keeps the date it arrived with, to
  /// order it until its first message is stored.
  Future<List<Chat>> upsert(WriteTx tx, List<Chat> chats) async {
    Map<String, Object?> toRow(Chat c) {
      final row = chatToRow(c)
        ..remove('latest_message_id')
        ..remove('thread_key');
      if (c.id != null) row.remove('latest_message_date_us');
      return row;
    }

    await saveByKey(tx, 'chats', 'guid', chats, key: (c) => c.guid, setId: (c, id) => c.id = id, toRow: toRow);
    return chats;
  }

  /// Makes [handleIds] the participants of [chatId] (ids with no stored
  /// handle are skipped). Reported as a change of the chat in `chat_handles`.
  Future<void> setParticipants(WriteTx tx, int chatId, Iterable<int> handleIds) async {
    await tx.execute('DELETE FROM chat_handles WHERE chat_id = ?', [chatId]);
    for (final handleId in handleIds.toSet()) {
      await tx.execute('INSERT INTO chat_handles (chat_id, handle_id) SELECT ?, id FROM handles WHERE id = ?', [
        chatId,
        handleId,
      ]);
    }
    tx.markChanged('chat_handles', [chatId]);
  }

  Future<void> setUnread(WriteTx tx, Iterable<int> chatIds, bool unread) async {
    for (final chunk in chatIds.toSet().toList().slices(500)) {
      await tx.execute('UPDATE chats SET has_unread_message = ? WHERE id IN (${sqlPlaceholders(chunk.length)})', [
        unread,
        ...chunk,
      ]);
    }
  }

  Future<void> setLastReadMessageGuid(WriteTx tx, int chatId, String? guid) =>
      tx.execute('UPDATE chats SET last_read_message_guid = ? WHERE id = ?', [guid, chatId]);

  // The latest pointer (chats.latest_message_id / latest_message_date_us) is
  // the database's: latestPointerTriggers (app_database.dart) keep it.

  /// The stored pointer of each of [chatIds], to tell which ones a write moved.
  Future<Map<int, (int?, int?)>> pointers(Iterable<int> chatIds) async {
    final result = <int, (int?, int?)>{};
    for (final chunk in chatIds.toSet().toList().slices(500)) {
      final rows = await db.select(
        'SELECT id, latest_message_id, latest_message_date_us FROM chats WHERE id IN (${sqlPlaceholders(chunk.length)})',
        chunk,
      );
      for (final row in rows) {
        result[row['id'] as int] = (row['latest_message_id'] as int?, row['latest_message_date_us'] as int?);
      }
    }
    return result;
  }

  /// (latest_message_id, latest_message_date) of [chatId], or null when there is no such chat.
  Future<(int?, DateTime?)?> _pointer(DbReader reader, int chatId) async {
    final rows = await reader.select('SELECT latest_message_id, latest_message_date_us FROM chats WHERE id = ?', [
      chatId,
    ]);
    if (rows.isEmpty) return null;
    final us = rows.single['latest_message_date_us'] as int?;
    return (rows.single['latest_message_id'] as int?, us == null ? null : DateTime.fromMicrosecondsSinceEpoch(us));
  }

  /// Runs [regroupThreads] when the write changed what thread grouping reads
  /// (regroupPendingTriggers in app_database.dart). Db.write calls it before
  /// every commit; a write that needs the result sooner calls it itself.
  Future<Map<String, Chat>> regroupIfPending(WriteTx tx) async {
    if ((await tx.select("SELECT 1 FROM storage_meta WHERE key = 'regroup_pending'")).isEmpty) return {};
    final folded = await regroupThreads(tx);
    await tx.execute("DELETE FROM storage_meta WHERE key = 'regroup_pending'");
    return folded;
  }

  /// Regroups every chat (the only writer of `thread_key`); the database then
  /// files their messages (threadFilingTriggers). Each chat of a thread that
  /// changed which is folded into another carries its pin, mute, archive and
  /// custom name over to the thread. Returns each such chat's guid mapped to
  /// its thread, one instance per thread, with its pointer as stored.
  Future<Map<String, Chat>> regroupThreads(WriteTx tx) async {
    final all = (await tx.select('SELECT * FROM chats')).map(chatFromRow).toList();
    await ChatRepo(tx)._fill(all, latest: false);
    final regrouped = assignThreadKeys(all);
    for (final chat in regrouped) {
      await tx.execute('UPDATE chats SET thread_key = ? WHERE id = ?', [chat.threadKey, chat.id]);
    }
    final inThread = all.where((c) => c.threadKey?.isNotEmpty ?? false).groupListsBy((c) => c.threadKey!);
    // A thread's first chat can change when a chat joins it, so every chat in
    // a changed thread is checked, not only the ones whose key changed.
    final touched = <String, Chat>{};
    for (final chat in regrouped) {
      touched[chat.guid] = chat;
      for (final c in inThread[chat.threadKey] ?? const <Chat>[]) {
        touched.putIfAbsent(c.guid, () => c);
      }
    }
    final folded = <String, Chat>{};
    for (final twin in touched.values) {
      final canonical = canonicalTwinFor(twin, inThread[twin.threadKey] ?? const []);
      if (canonical == null) continue;
      folded[twin.guid] = canonical;
      if (carryOverThreadSettings(canonical, [twin])) {
        await tx.execute(
          'UPDATE chats SET is_pinned = ?, pin_index = ?, mute_type = ?, mute_args = ?, is_archived = ?, '
          'display_name = ?, lock_chat_name = ? WHERE id = ?',
          [
            canonical.isPinned,
            canonical.pinIndex,
            canonical.muteType,
            canonical.muteArgs,
            canonical.isArchived,
            canonical.displayName,
            canonical.lockChatName,
            canonical.id,
          ],
        );
      }
    }
    for (final canonical in folded.values.toSet()) {
      final (id, date) = (await _pointer(tx, canonical.id!))!;
      canonical.dbLatestMessage.targetId = id;
      canonical.dbOnlyLatestMessageDate = date;
    }
    return folded;
  }

  /// [chatIds] and every chat sharing a thread with one of them.
  Future<Set<int>> withThreadMates(Iterable<int> chatIds) async {
    final result = chatIds.toSet();
    for (final chunk in result.toList().slices(500)) {
      final rows = await db.select(
        'SELECT t.id FROM chats c JOIN chats t ON t.thread_key = c.thread_key '
        'WHERE c.id IN (${sqlPlaceholders(chunk.length)})',
        chunk,
      );
      result.addAll(rows.map((r) => r['id'] as int));
    }
    return result;
  }

  Future<List<Chat>> all() async {
    final ids = [for (final row in await db.select('SELECT id FROM chats ORDER BY id')) row['id'] as int];
    final chats = await byIds(ids);
    return [
      for (final id in ids)
        if (chats[id] != null) chats[id]!,
    ];
  }

  Future<void> setHandleIds(WriteTx tx, Map<int, List<int>> handleIdsByChat) async {
    for (final entry in handleIdsByChat.entries) {
      await tx.execute('DELETE FROM chat_handles WHERE chat_id = ?', [entry.key]);
      for (final handleId in entry.value.toSet()) {
        await tx.execute('INSERT INTO chat_handles (chat_id, handle_id) VALUES (?, ?)', [entry.key, handleId]);
      }
      tx.markChanged('chat_handles', [entry.key]);
    }
  }
}
