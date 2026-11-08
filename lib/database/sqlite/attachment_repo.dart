import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/relation_fill.dart';
import 'package:bluebubbles/database/sqlite/row_writes.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:collection/collection.dart';

/// `?, ?, ?` for an `IN (...)` of [n] values.
String sqlPlaceholders(int n) => List.filled(n, '?').join(', ');

/// Attachments in SQLite. [byGuid] fills `message` (RelationFill); [forMessages]
/// is the building block of MessageRepo's fill and leaves it to the caller.
class AttachmentRepo {
  AttachmentRepo(this.db);

  final DbReader db;

  Future<Attachment?> byGuid(String guid) async {
    final rows = await db.select('SELECT * FROM attachments WHERE guid = ?', [guid]);
    if (rows.isEmpty) return null;
    final attachment = attachmentFromRow(rows.single);
    await RelationFill(db).attachments([attachment]);
    return attachment;
  }

  /// The attachments of each message id, in id order. One `IN` query per 500 ids
  /// on attachments_message.
  Future<Map<int, List<Attachment>>> forMessages(Iterable<int> messageIds) async {
    final ids = messageIds.toSet().toList();
    final result = <int, List<Attachment>>{};
    for (final chunk in ids.slices(500)) {
      final rows = await db.select('SELECT * FROM attachments WHERE message_id IN (${sqlPlaceholders(chunk.length)})', chunk);
      for (final row in rows) {
        result.putIfAbsent(row['message_id'] as int, () => []).add(attachmentFromRow(row));
      }
    }
    for (final list in result.values) {
      list.sort((a, b) => a.id!.compareTo(b.id!));
    }
    return result;
  }

  /// Inserts or updates [attachments] by guid, keeping a stored attachment's
  /// id; the owner is `message.targetId`. Sets each attachment's id.
  Future<List<Attachment>> upsert(WriteTx tx, List<Attachment> attachments) async {
    await saveByKey(tx, 'attachments', 'guid', attachments,
        key: (a) => a.guid, setId: (a, id) => a.id = id, toRow: attachmentToRow);
    return attachments;
  }
}
