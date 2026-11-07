import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/handle_repo.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
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

  /// One page of the chat list in the order today's list query loads it
  /// (ChatActions.getChatsAsync): not deleted, newest latest message first.
  /// [after] is the last chat of the previous page. Pins and folded twins are
  /// applied by ChatsService on top, as they are today.
  Future<List<Chat>> listPage({ChatListKey? after, int limit = 50}) {
    return db.snapshot((reader) async {
      final rows = <Map<String, Object?>>[];
      if (after?.latestMessageDateUs != null || after == null) {
        rows.addAll(await reader.select(
            after == null
                ? 'SELECT * FROM chats WHERE date_deleted_us IS NULL AND latest_message_date_us IS NOT NULL '
                    'ORDER BY latest_message_date_us DESC, id DESC LIMIT ?'
                : 'SELECT * FROM chats WHERE date_deleted_us IS NULL '
                    'AND (latest_message_date_us, id) < (?, ?) '
                    'ORDER BY latest_message_date_us DESC, id DESC LIMIT ?',
            [if (after != null) ...[after.latestMessageDateUs, after.id], limit]));
      }
      if (rows.length < limit) {
        // Undated chats last, as SQLite and ObjectBox both order nulls in a descending sort.
        rows.addAll(await reader.select(
            'SELECT * FROM chats WHERE date_deleted_us IS NULL AND latest_message_date_us IS NULL '
            'AND id < ? ORDER BY latest_message_date_us DESC, id DESC LIMIT ?',
            [after?.latestMessageDateUs == null && after != null ? after.id : _maxId, limit - rows.length]));
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

  /// Participants (one join per 500 chats) and latest messages (one id lookup).
  Future<void> _fill(List<Chat> chats) async {
    if (chats.isEmpty) return;
    final byId = {for (final c in chats) c.id!: c};
    final participantIds = <int, List<int>>{};
    for (final chunk in byId.keys.toList().slices(500)) {
      final rows = await db.select(
          'SELECT chat_id, handle_id FROM chat_handles WHERE chat_id IN (${sqlPlaceholders(chunk.length)})', chunk);
      for (final row in rows) {
        participantIds.putIfAbsent(row['chat_id'] as int, () => []).add(row['handle_id'] as int);
      }
    }
    final handles = await HandleRepo(db).byIds(participantIds.values.flattened);
    final latestIds = {for (final c in chats) if (c.dbLatestMessage.targetId != 0) c.dbLatestMessage.targetId};
    final latest = await MessageRepo(db).byIds(latestIds);
    for (final chat in chats) {
      final participants = (participantIds[chat.id] ?? const <int>[]).map((id) => handles[id]).whereType<Handle>().toList()
        ..sort((a, b) => a.id!.compareTo(b.id!));
      chat.handles.addAll(participants);
      chat.participants = participants;
      chat.latestMessage = latest[chat.dbLatestMessage.targetId];
    }
  }
}
