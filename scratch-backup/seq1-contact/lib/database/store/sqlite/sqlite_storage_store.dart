import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_messaging_store.dart';

/// StorageActions on SQLite repositories.
mixin SqliteStorageStore implements StorageStore, SqliteStorePart {
  @override
  Future<Set<String>> storageAttachmentGuids({String? chatGuid, int? beforeMillis}) async {
    final where = <String>['a.message_id IS NOT NULL'];
    final args = <Object?>[];
    if (beforeMillis != null) {
      where.add('m.date_created_us < ?');
      args.add(beforeMillis * 1000);
    }
    if (chatGuid != null) {
      where.add('c.guid = ?');
      args.add(chatGuid);
    }
    final rows = await db.select(
      'SELECT a.guid FROM attachments a JOIN messages m ON m.id = a.message_id '
      'JOIN chats c ON c.id = m.chat_id WHERE ${where.join(' AND ')}',
      args,
    );
    return rows.map((row) => row['guid'] as String? ?? '').toSet();
  }

  @override
  Future<void> resetStorageAttachments(List<String> guids) {
    if (guids.isEmpty) return Future.value();
    return db.write((tx) async {
      for (final guid in guids) {
        final rows = await tx.select('SELECT * FROM attachments WHERE guid = ?', [guid]);
        if (rows.isEmpty) continue;
        final row = attachmentFromRow(rows.single)
          ..isDownloaded = false
          ..height = null
          ..width = null
          ..exif = null;
        row.metadata?.removeWhere((key, _) => const {
              '_orientation_processed',
              '_orientation',
              '_raw_width',
              '_raw_height',
            }.contains(key));
        await tx.update('attachments', attachmentToRow(row));
      }
    });
  }
}
