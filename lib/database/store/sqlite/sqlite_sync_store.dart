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
    final rows = await db.select('SELECT id FROM chats WHERE date_deleted_us IS NOT NULL ORDER BY date_deleted_us DESC, id DESC');
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
        handleIds);
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
      final folded = await repo.foldServiceTwins(tx, localChats);
      final current = await repo.all();
      final relistedIds = await repo.relistShownByEvents(tx, current.map((chat) => chat.id!));
      final relistedById = await repo.byIds(relistedIds);
      return ChatMetadataRefreshResult(
        changedChats: changed,
        foldedChats: folded,
        relistedChats: [for (final id in relistedIds) if (relistedById[id] != null) relistedById[id]!],
      );
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
}
