import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/attachment_query_sql.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_message_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_messaging_store.dart';
import 'package:bluebubbles/services/backend/descriptors/attachment_query_descriptor.dart';

/// AttachmentActions on SQLite.
mixin SqliteAttachmentStore implements AttachmentStore, SqliteStorePart {
  /// The attachments the ObjectBox lookups find: they query with
  /// `.link(Attachment_.message)`, an inner join, so an attachment that
  /// belongs to no message is never found by guid.
  static const _linked = 'message_id IS NOT NULL';

  Future<Attachment?> _byGuid(DbReader reader, String guid) async {
    final rows = await reader.select('SELECT * FROM attachments WHERE guid = ? AND $_linked', [guid]);
    return rows.isEmpty ? null : attachmentFromRow(rows.single);
  }

  /// ObjectBox's put: overwrites the row with the attachment's id, else inserts.
  Future<int> _put(WriteTx tx, Attachment a) async {
    final row = attachmentToRow(a);
    if (a.id != null && (await tx.select('SELECT 1 FROM attachments WHERE id = ?', [a.id])).isNotEmpty) {
      await tx.update('attachments', row);
      return a.id!;
    }
    return tx.insert('attachments', row..['id'] = null);
  }

  @override
  Future<int> saveAttachment(Attachment attachment, {Message? message}) {
    return db.write((tx) async {
      final existing = await _byGuid(tx, attachment.guid!);
      if (existing != null) {
        attachment.id = existing.id;
        // Always preserve the existing message relationship unless explicitly overridden
        if (existing.message.hasValue) attachment.message.targetId = existing.message.targetId;
      }
      if (message?.id != null) attachment.message.targetId = message!.id;
      try {
        attachment.id = await _put(tx, attachment);
      } catch (e) {
        if (!isUniqueViolation(e)) rethrow;
      }
      return attachment.id!;
    });
  }

  @override
  Future<void> saveAttachments(List<Attachment> attachments) {
    return db.write((tx) async {
      for (final a in attachments) {
        final existing = await _byGuid(tx, a.guid!);
        if (existing == null) continue;
        a.id = existing.id;
        // Preserve the existing message relationship to prevent it from being cleared by put
        if (existing.message.hasValue && !a.message.hasValue) a.message.targetId = existing.message.targetId;
      }
      try {
        for (final a in attachments) {
          a.id = await _put(tx, a);
        }
      } catch (e) {
        // ObjectBox's putMany stops at the first duplicate guid; so does this.
        if (!isUniqueViolation(e)) rethrow;
      }
    });
  }

  @override
  Future<int> replaceAttachment(String oldGuid, Attachment newAttachment) {
    return db.write((tx) async {
      final existing = await _byGuid(tx, oldGuid);
      if (existing == null) {
        throw Exception("Old GUID ($oldGuid) does not exist!");
      }
      // Another path may have stored newAttachment.guid already: merge into it
      // and drop the temp-guid row (see the ObjectBox implementation).
      final conflicting = await _byGuid(tx, newAttachment.guid!);
      final target = conflicting != null && conflicting.id != existing.id ? conflicting : existing;
      if (!identical(target, existing)) {
        await tx.execute('DELETE FROM attachments WHERE id = ?', [existing.id]);
      }
      target.guid = newAttachment.guid;
      target.originalROWID = newAttachment.originalROWID;
      target.uti = newAttachment.uti;
      target.mimeType = newAttachment.mimeType ?? target.mimeType;
      target.isOutgoing = newAttachment.isOutgoing;
      target.transferName = newAttachment.transferName;
      target.totalBytes = newAttachment.totalBytes;
      target.bytes = newAttachment.bytes;
      target.webUrl = newAttachment.webUrl;
      target.hasLivePhoto = newAttachment.hasLivePhoto;
      await tx.update('attachments', attachmentToRow(target));

      newAttachment.id = target.id;
      newAttachment.width = target.width;
      newAttachment.height = target.height;
      newAttachment.metadata = target.metadata;
      return newAttachment.id!;
    });
  }

  @override
  Future<int?> findAttachmentId(String guid) async => (await _byGuid(db, guid))?.id;

  @override
  Future<List<int>> findAttachmentIds(AttachmentQueryDescriptor? query) async {
    final where = query == null ? null : attachmentWhere(query);
    final rows = await db.select(
        'SELECT id FROM attachments WHERE $_linked${where == null ? '' : ' AND (${where.$1})'} ORDER BY id',
        where?.$2 ?? const []);
    return [for (final row in rows) row['id'] as int];
  }

  @override
  Future<void> deleteAttachment(String guid) =>
      db.write((tx) => tx.execute('DELETE FROM attachments WHERE guid = ?', [guid]));

  @override
  Future<Attachment?> attachmentById(int id) async => (await attachmentsWithMessages(db, [id]))[id];

  @override
  Future<List<Attachment>> attachmentsByIds(List<int> ids) async => inIdOrder(ids, await attachmentsWithMessages(db, ids));

  @override
  Future<List<Attachment>> attachmentsOfMessage(int? messageId, List<String> guids) async {
    final repo = AttachmentRepo(db);
    if (messageId != null) {
      final found = (await repo.forMessages([messageId]))[messageId] ?? const <Attachment>[];
      if (found.isNotEmpty) return found;
    }
    return [for (final guid in guids.toSet()) ?await repo.byGuid(guid)];
  }
}
