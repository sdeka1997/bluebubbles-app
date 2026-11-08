// Seeding helpers for the SQLite repository tests (not a test file itself).
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';

const baseMs = 1500000000000;

DateTime at(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

/// Collects rows and inserts them in one drift batch: tens of thousands of
/// rows in well under a second on the in-memory database.
class Seed {
  final _rows = <(String, Map<String, Object?>)>[];
  final _joins = <(String, List<Object?>)>[];

  void chat(int id, {String? guid, int? latestMessageId, int? latestMs, bool deleted = false, List<int> handles = const []}) {
    final chat = Chat(id: id, guid: guid ?? 'chat-$id', dateDeleted: deleted ? at(baseMs) : null)
      ..dbOnlyLatestMessageDate = latestMs == null ? null : at(latestMs);
    chat.dbLatestMessage.targetId = latestMessageId;
    _rows.add(('chats', chatToRow(chat)));
    for (final h in handles) {
      _joins.add(('INSERT INTO chat_handles (chat_id, handle_id) VALUES (?, ?)', [id, h]));
    }
  }

  void handle(int id, {required String address, String service = 'iMessage', int? originalRowId, List<int> contacts = const []}) {
    _rows.add((
      'handles',
      handleToRow(Handle(id: id, address: address, service: service, originalROWID: originalRowId)),
    ));
    for (final c in contacts) {
      _joins.add(('INSERT INTO contact_handles (contact_id, handle_id) VALUES (?, ?)', [c, id]));
    }
  }

  void contact(int id, String name) =>
      _rows.add(('contacts', contactToRow(ContactV2(id: id, displayName: name, nativeContactId: 'native-$id'))));

  /// A message of [chatId] created at [ms]; [guid] defaults to `m<id>`.
  Message message(
    int id,
    int chatId,
    int ms, {
    String? guid,
    int? deliveredMs,
    String? reactionTo,
    bool deleted = false,
    bool isFromMe = true,
    int? handleId,
    int? originalRowId,
    int? handleRelationId,
    String? threadOriginator,
    String? text,
    int? itemType,
  }) {
    final m = Message(
      id: id,
      guid: guid ?? 'm$id',
      dateCreated: at(ms),
      dateDelivered: deliveredMs == null ? null : at(deliveredMs),
      associatedMessageGuid: reactionTo,
      associatedMessageType: reactionTo == null ? null : 'love',
      dateDeleted: deleted ? at(ms) : null,
      isFromMe: isFromMe,
      handleId: handleId,
      originalROWID: originalRowId,
      threadOriginatorGuid: threadOriginator,
      text: text ?? 'text $id',
      itemType: itemType,
    );
    m.chat.targetId = chatId;
    m.handleRelation.targetId = handleRelationId;
    _rows.add(('messages', messageToRow(m)));
    return m;
  }

  void attachment(int id, int messageId, {String? guid}) {
    final a = Attachment(id: id, guid: guid ?? 'a$id', mimeType: 'image/jpeg');
    a.message.targetId = messageId;
    _rows.add(('attachments', attachmentToRow(a)));
  }

  /// Inserts everything collected so far, parents first.
  Future<void> into(Db db) async {
    const order = ['handles', 'contacts', 'chats', 'messages', 'attachments'];
    final rows = _rows.toList()..sort((a, b) => order.indexOf(a.$1).compareTo(order.indexOf(b.$1)));
    final joins = _joins.toList();
    _rows.clear();
    _joins.clear();
    await db.database.batch((b) {
      for (final (table, row) in rows) {
        b.customStatement(upsertSql(table, row.keys.toList()), row.values.toList());
      }
      for (final (sql, args) in joins) {
        b.customStatement(sql, args);
      }
    });
  }
}
