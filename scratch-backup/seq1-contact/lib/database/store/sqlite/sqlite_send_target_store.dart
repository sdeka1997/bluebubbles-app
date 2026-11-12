import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_messaging_store.dart';

/// SendTargetResolver reads on SQLite repositories.
mixin SqliteSendTargetStore implements SendTargetStore, SqliteStorePart {
  @override
  Future<SendTargetContext> sendTargetContext(Chat thread, {String? anchorGuid, int recentLimit = 50}) {
    return db.snapshot((reader) async {
      final anchorChatGuid = anchorGuid == null ? null : (await MessageRepo(reader).byGuid(anchorGuid))?.appleChatGuid;
      final copies = <Chat>[];
      if (thread.threadKey?.isNotEmpty ?? false) {
        final rows = await reader.select(
          'SELECT id FROM chats WHERE thread_key = ? AND date_deleted_us IS NULL ORDER BY id',
          [thread.threadKey],
        );
        final ids = rows.map((row) => row['id'] as int).toList();
        final found = await ChatRepo(reader).byIds(ids);
        copies.addAll([for (final id in ids) ?found[id]]);
      }
      if (!copies.any((c) => c.guid == thread.guid)) copies.insert(0, thread);

      final recentRows = thread.id == null
          ? const <Map<String, Object?>>[]
          : await reader.select(
              'SELECT * FROM messages WHERE chat_id = ? ORDER BY date_created_us DESC, id DESC LIMIT ?',
              [thread.id, recentLimit],
            );
      final recent = recentRows.map(messageFromRow).toList();
      return SendTargetContext(copies: copies, recent: recent, anchorChatGuid: anchorChatGuid);
    });
  }
}
