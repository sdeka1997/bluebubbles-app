import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_messaging_store.dart';

/// StorageActions on SQLite repositories.
mixin SqliteStorageStore implements StorageStore, SqliteStorePart {
  @override
  Future<Set<String>> storageAttachmentGuids({String? chatGuid, int? beforeMillis}) {
    return AttachmentRepo(db).storageGuids(chatGuid: chatGuid, beforeMillis: beforeMillis);
  }

  @override
  Future<void> resetStorageAttachments(List<String> guids) {
    if (guids.isEmpty) return Future.value();
    return db.write((tx) => AttachmentRepo(tx).resetDownloadMetadata(tx, guids));
  }

  @override
  Future<void> clearMessagingData() => db.write((tx) async {
        // Parents last: the join tables and messages' keys reference them.
        for (final table in [
          'custom_group_chats',
          'custom_groups',
          'attachments',
          'messages',
          'contact_handles',
          'contacts',
          'chat_handles',
          'chats',
          'handles',
        ]) {
          await tx.execute('DELETE FROM $table');
        }
      });
}
