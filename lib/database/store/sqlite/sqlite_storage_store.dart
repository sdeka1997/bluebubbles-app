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
}
