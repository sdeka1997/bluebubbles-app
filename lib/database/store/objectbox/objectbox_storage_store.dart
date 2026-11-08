import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';

/// StorageActions' ObjectBox query and reset transaction, moved verbatim.
mixin ObjectBoxStorageStore implements StorageStore {
  @override
  Future<Set<String>> storageAttachmentGuids({String? chatGuid, int? beforeMillis}) async {
    final qb = Database.attachments.query();
    final mq = qb.link(
      Attachment_.message,
      beforeMillis != null ? Message_.dateCreated.lessThan(beforeMillis) : null,
    );
    if (chatGuid != null) mq.link(Message_.chat, Chat_.guid.equals(chatGuid));
    final q = qb.build();
    try {
      return q.property(Attachment_.guid).find(replaceNullWith: '').toSet();
    } finally {
      q.close();
    }
  }

  @override
  Future<void> resetStorageAttachments(List<String> guids) async {
    if (guids.isEmpty) return;
    Database.runInTransaction(TxMode.write, () {
      for (final guid in guids) {
        final query = Database.attachments.query(Attachment_.guid.equals(guid)).build();
        final row = query.findFirst();
        query.close();
        if (row == null) continue;
        row.isDownloaded = false;
        row.metadata
          ?..remove('_orientation_processed')
          ..remove('_orientation')
          ..remove('_raw_width')
          ..remove('_raw_height');
        row.height = null;
        row.width = null;
        row.exif = null;
        Database.attachments.put(row);
      }
    });
  }
}
