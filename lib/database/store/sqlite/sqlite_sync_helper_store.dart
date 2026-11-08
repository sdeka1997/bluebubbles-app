import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_messaging_store.dart';

/// sync_helpers.dart's attachment update on SQLite. The read, merge and upsert
/// are one Db.write, with no work outside the database inside the callback.
mixin SqliteSyncHelperStore implements SyncHelperStore, SqliteStorePart {
  @override
  Future<List<Attachment>> syncAttachments(List<Attachment> attachments) {
    final guids = attachments.map((attachment) => attachment.guid!).toList();
    return db.write((tx) async {
      final repo = AttachmentRepo(tx);
      final existing = <String, Attachment>{};
      for (final guid in guids) {
        final stored = await repo.byGuid(guid);
        if (stored != null) existing[guid] = stored;
      }

      final synced = <Attachment>[];
      for (final attachment in attachments) {
        final stored = existing[attachment.guid];
        final messageId = stored?.message.targetId;
        final merged = stored == null ? attachment : Attachment.merge(attachment, stored);
        merged.message.loadedFromSqlite(messageId, label: 'Attachment.message');
        synced.add(merged);
      }
      await repo.upsert(tx, synced);
      return synced;
    });
  }

  @override
  Future<List<Message>> syncMessages(Chat chat, List<Message> messages) {
    final guids = messages.map((message) => message.guid!).toList();
    return db.write((tx) async {
      final repo = MessageRepo(tx);
      final existing = <String, Message>{};
      for (final guid in guids) {
        final stored = await repo.byGuid(guid);
        if (stored != null) existing[guid] = stored;
      }

      final synced = <Message>[];
      for (final message in messages) {
        final stored = existing[message.guid];
        final merged = stored == null ? message : Message.merge(message, stored);
        merged.chat
          ..loadedFromSqlite(chat.id, label: 'Message.chat')
          ..fill(chat);
        synced.add(merged);
      }
      await repo.upsert(tx, synced);
      return synced;
    });
  }
}
