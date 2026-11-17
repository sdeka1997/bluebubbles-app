import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:bluebubbles/database/sqlite/sync_batch_writer.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_messaging_store.dart';
import 'package:bluebubbles/helpers/types/helpers/chat_metadata_helpers.dart';
import 'package:bluebubbles/helpers/types/helpers/service_twin_helpers.dart'
    show canonicalTwinFor, updateGroupIdsFromRemote;

/// SyncActions.bulkSyncData on SQLite: SqliteSyncBatch, the whole batch
/// (handles included) in one Db.write, address formatting before it.
mixin SqliteSyncStore implements SyncStore, SqliteStorePart {
  @override
  Future<Map<String, dynamic>> syncBatch(dynamic data) => SqliteSyncBatch.bulkSyncData(db, data);

  @override
  Future<Chat?> chatById(int id) => ChatRepo(db).byId(id);

  @override
  Future<Chat?> chatByGuid(String guid) => ChatRepo(db).byGuid(guid);

  @override
  Future<Chat?> chatByIdentifier(String identifier) => ChatRepo(db).byIdentifier(identifier);

  @override
  Future<List<Chat>> chatsByIds(List<int> ids) async => inIdOrder(ids, await ChatRepo(db).byIds(ids));

  @override
  Future<List<Chat>> allChats() => ChatRepo(db).all();

  @override
  Future<List<Chat>> deletedChats() async {
    final rows = await db.select(
      'SELECT id FROM chats WHERE date_deleted_us IS NOT NULL ORDER BY date_deleted_us DESC, id DESC',
    );
    final ids = [for (final row in rows) row['id'] as int];
    return inIdOrder(ids, await ChatRepo(db).byIds(ids));
  }

  @override
  Future<List<Chat>> liveChatsWithParticipants(List<int> handleIds) async {
    if (handleIds.isEmpty) return const [];
    final rows = await db.select(
      'SELECT DISTINCT c.id FROM chat_handles ch JOIN chats c ON c.id = ch.chat_id '
      'WHERE c.date_deleted_us IS NULL AND ch.handle_id IN (${List.filled(handleIds.length, '?').join(', ')}) '
      'ORDER BY c.id',
      handleIds,
    );
    final ids = [for (final row in rows) row['id'] as int];
    return inIdOrder(ids, await ChatRepo(db).byIds(ids));
  }

  @override
  Future<void> setChatHandleIds(Map<int, List<int>> handleIdsByChat) =>
      db.write((tx) => ChatRepo(tx).setHandleIds(tx, handleIdsByChat));

  @override
  Future<ChatMetadataRefreshResult> refreshChatMetadata(List<Map<String, dynamic>> remoteChats) {
    return db.write((tx) async {
      final repo = ChatRepo(tx);
      final localChats = await repo.all();
      final changed = {
        ...updateGroupIdsFromRemote(localChats, remoteChats),
        ...updateSpamFlagsFromRemote(localChats, remoteChats),
      }.toList();
      if (changed.isNotEmpty) await repo.upsert(tx, changed);
      final folded = await repo.regroupIfPending(tx);
      return ChatMetadataRefreshResult(changedChats: changed, foldedChats: folded);
    });
  }

  @override
  Future<DateTime?> newestStoredNameChange(String chatGuid) async {
    final repo = ChatRepo(db);
    final local = await repo.byGuid(chatGuid);
    if (local == null) return null;
    final all = await repo.all();
    final canonical = canonicalTwinFor(local, all.where((chat) => chat.threadKey == local.threadKey));
    final newest = await MessageRepo(db).newestRename({local.id!, canonical?.id ?? local.id!}.toList());
    return newest?.dateCreated;
  }

  @override
  Future<List<String>> chatsAwaitingOriginRepair() async {
    if ((await db.select("SELECT 1 FROM storage_meta WHERE key = 'origin_repair_pending'")).isEmpty) return const [];
    final rows = await db.select('SELECT guid FROM chats WHERE thread_key IN '
        '(SELECT thread_key FROM chats WHERE thread_key IS NOT NULL GROUP BY thread_key HAVING count(*) > 1) ORDER BY id');
    return [for (final row in rows) row['guid'] as String];
  }

  @override
  Future<int> recordAppleChat(String chatGuid, List<String> messageGuids) {
    if (messageGuids.isEmpty) return Future.value(0);
    return db.write((tx) async {
      var changed = 0;
      for (var i = 0; i < messageGuids.length; i += 500) {
        final chunk = messageGuids.sublist(i, i + 500 > messageGuids.length ? messageGuids.length : i + 500);
        final marks = List.filled(chunk.length, '?').join(', ');
        final stale = await tx.select(
          'SELECT count(*) AS n FROM messages WHERE guid IN ($marks) AND apple_chat_guid IS NOT ?',
          [...chunk, chatGuid],
        );
        changed += stale.single['n'] as int;
        await tx.execute(
          'UPDATE messages SET apple_chat_guid = ? WHERE guid IN ($marks) AND apple_chat_guid IS NOT ?',
          [chatGuid, ...chunk, chatGuid],
        );
      }
      return changed;
    });
  }

  @override
  Future<void> finishOriginRepair() =>
      db.write((tx) => tx.execute("DELETE FROM storage_meta WHERE key = 'origin_repair_pending'"));
}
