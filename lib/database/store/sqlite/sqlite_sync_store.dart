import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/sync_batch_writer.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_messaging_store.dart';

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
  Future<List<Chat>> chatsByIds(List<int> ids) async => inIdOrder(ids, await ChatRepo(db).byIds(ids));
}
