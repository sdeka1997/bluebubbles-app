import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:bluebubbles/database/sqlite/relation_fill.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_messaging_store.dart';
import 'package:bluebubbles/utils/logger/logger.dart';

/// MessageActions on SQLite.
mixin SqliteMessageStore implements MessageStore, SqliteStorePart {
  @override
  Future<int> replaceMessage(String? oldGuid, Message incoming) {
    return db.write((tx) async {
      final existing = await MessageRepo(tx).byGuid(oldGuid ?? '');
      if (existing == null) {
        throw Exception("Cannot replace on a null existing message!!");
      }
      try {
        await MessageRepo(tx).replace(tx, oldGuid!, incoming);
      } catch (ex) {
        if (!isUniqueViolation(ex)) rethrow;
        Logger.warn('Failed to replace message! This is likely due to a unique constraint being violated: ${ex.toString()}');
      }
      return existing.id!;
    });
  }

  @override
  Future<void> deleteMessage(String guid) => db.write((tx) => MessageRepo(tx).delete(tx, [guid]));

  @override
  Future<void> softDeleteMessage(String guid) => db.write((tx) => MessageRepo(tx).softDelete(tx, guid));

  @override
  Future<void> restoreMessage(String guid) => db.write((tx) => MessageRepo(tx).restore(tx, guid));

  @override
  Future<int> saveMessage(Message inputMessage, {Chat? chat, required bool updateIsBookmarked}) {
    return db.write((tx) async {
      final existing = await _row(tx, 'guid = ?', [inputMessage.guid ?? '']);
      if (existing != null) {
        inputMessage.id = existing.id;
        inputMessage.text ??= existing.text;
        inputMessage.service ??= existing.service;
        // Preserve existing handleRelation if available
        if (existing.handleRelation.hasValue && !inputMessage.handleRelation.hasValue) {
          inputMessage.handleRelation.targetId = existing.handleRelation.targetId;
        }
      }

      // Only do handleId lookup if we don't already have a handleRelation
      if (inputMessage.handle == null && !inputMessage.handleRelation.hasValue && inputMessage.handleId != null) {
        final rows = await tx.select(
            'SELECT * FROM handles WHERE original_rowid = ? ORDER BY id LIMIT 1', [inputMessage.handleId]);
        final found = rows.isEmpty ? null : handleFromRow(rows.single);
        inputMessage.handle = found;
        if (found != null) inputMessage.handleRelation.targetId = found.id;
      }

      if (inputMessage.associatedMessageType != null && inputMessage.associatedMessageGuid != null) {
        await tx.execute('UPDATE messages SET has_reactions = 1 WHERE guid = ?', [inputMessage.associatedMessageGuid]);
      } else if (!inputMessage.hasReactions) {
        final reaction = await tx.select(
            'SELECT 1 FROM messages WHERE associated_message_guid = ? LIMIT 1', [inputMessage.guid ?? '']);
        if (reaction.isNotEmpty) inputMessage.hasReactions = true;
      }

      if (!updateIsBookmarked) {
        inputMessage.isBookmarked = existing?.isBookmarked ?? inputMessage.isBookmarked;
      }

      // Without [chat] the message is saved unlinked, as ObjectBox's put of
      // an unset ToOne stores no chat.
      if (chat != null) inputMessage.chat.targetId = chat.id;
      try {
        final row = messageToRow(inputMessage);
        if (existing != null) {
          await tx.update('messages', row);
        } else {
          // A new guid gets a new id: an id it arrived with is not this row's.
          inputMessage.id = await tx.insert('messages', row..['id'] = null);
        }
      } catch (e) {
        if (!isUniqueViolation(e)) rethrow;
      }
      return inputMessage.id!;
    });
  }

  Future<Message?> _row(DbReader reader, String where, List<Object?> args) async {
    final rows = await reader.select('SELECT * FROM messages WHERE $where ORDER BY id LIMIT 1', args);
    return rows.isEmpty ? null : messageFromRow(rows.single);
  }

  @override
  Future<int?> findMessageId({String? guid, String? associatedMessageGuid}) async {
    Message? result;
    if (guid != null) {
      result = await _row(db, 'guid = ?', [guid]);
    } else if (associatedMessageGuid != null) {
      result = await _row(db, 'associated_message_guid = ?', [associatedMessageGuid]);
    }
    return result?.id;
  }

  @override
  Future<List<int>> allMessageIds() async =>
      [for (final row in await db.select('SELECT id FROM messages ORDER BY id')) row['id'] as int];

  @override
  Future<List<Message>> messagesAssociatedWith(String guid) async {
    final rows = await db.select('SELECT * FROM messages WHERE associated_message_guid = ? ORDER BY id', [guid]);
    final messages = rows.map(messageFromRow).toList();
    await RelationFill(db).messages(messages);
    return messages;
  }

  @override
  Future<Message?> messageByGuid(String guid) => MessageRepo(db).byGuid(guid);

  @override
  Future<int> relinkMessagesToHandle(int serverHandleId, int localHandleId) {
    return db.write((tx) async {
      final rows = await tx.select(
          'UPDATE messages SET handle_relation_id = ? WHERE handle_id = ? AND is_from_me IS NOT 1 '
          'AND handle_relation_id IS NOT ? RETURNING id',
          [localHandleId, serverHandleId, localHandleId]);
      return rows.length;
    });
  }

  @override
  Future<Message?> messageById(int id) => MessageRepo(db).byId(id);

  @override
  Future<List<Message>> messagesCreatedAfter(int millisecondsSinceEpoch) =>
      MessageRepo(db).createdAfter(millisecondsSinceEpoch);

  @override
  Future<List<Message>> messagesByIds(List<int> ids) async => inIdOrder(ids, await MessageRepo(db).byIds(ids));
}

/// The attachments of [ids] with their messages filled.
Future<Map<int, Attachment>> attachmentsWithMessages(DbReader db, Iterable<int> ids) async {
  final result = <int, Attachment>{};
  final list = ids.toSet().toList();
  for (var i = 0; i < list.length; i += 500) {
    final chunk = list.sublist(i, i + 500 > list.length ? list.length : i + 500);
    for (final row in await db.select('SELECT * FROM attachments WHERE id IN (${sqlPlaceholders(chunk.length)})', chunk)) {
      result[row['id'] as int] = attachmentFromRow(row);
    }
  }
  await RelationFill(db).attachments(result.values);
  return result;
}
