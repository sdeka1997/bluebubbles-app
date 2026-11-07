import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/handle_repo.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:bluebubbles/helpers/types/extensions/extensions.dart' show serverErrorMessage;
import 'package:bluebubbles/services/backend/actions/sync_actions.dart' show payloadSenderKey;
import 'package:collection/collection.dart';

/// One sync batch with everything that needs async work outside the database
/// (address formatting) already done; [SqliteSyncBatch.write] only touches
/// the database.
class PreparedSyncBatch {
  PreparedSyncBatch._(this.chatData, this.messagesData, this.chatDataByGuid, this.handles, this.reportedRowIds);

  final Map<String, dynamic>? chatData;
  final List<Map<String, dynamic>> messagesData;
  final Map<String, Map<String, dynamic>> chatDataByGuid;

  /// Every participant and sender of the batch, once per address/service, formatted.
  final List<Handle> handles;

  /// Apple ROWIDs the server reported, by `uniqueAddressAndService`.
  final Map<String, int> reportedRowIds;
}

/// `SyncActions.bulkSyncData` on SQLite: the same payload, the same merge and
/// wiring rules, in ONE [Db.write] per batch (handles included, which
/// ObjectBox saves in a transaction of their own). Nothing inside the write
/// does HTTP or file I/O.
class SqliteSyncBatch {
  static Future<Map<String, dynamic>> bulkSyncData(Db db, dynamic data) async => write(db, await prepare(data));

  /// Collects the batch's handles and chats and formats addresses (async, so
  /// outside the write).
  static Future<PreparedSyncBatch> prepare(dynamic data) async {
    final chatData = data['chatData'] as Map<String, dynamic>?;
    final messagesData = (data['messagesData'] as List).cast<Map<String, dynamic>>();

    final handleMaps = <String, Map<String, dynamic>>{};
    final reportedRowIds = <String, int>{};
    void collect(List<dynamic>? participants) {
      for (final raw in (participants ?? const []).whereType<Map>()) {
        final h = raw.cast<String, dynamic>();
        final key = _handleKey(h);
        handleMaps[key] ??= h;
        final rowId = serverReportedRowId(Handle.fromMap(h));
        if (rowId != null) reportedRowIds[key] = rowId;
      }
    }

    final chatDataByGuid = <String, Map<String, dynamic>>{};
    if (chatData != null) {
      collect(chatData['participants'] as List?);
      chatDataByGuid[chatData['guid'] as String] = chatData;
    }
    for (final msgData in messagesData) {
      collect([msgData['handle']]);
      for (final raw in (msgData['chats'] as List? ?? const []).whereType<Map>()) {
        final c = raw.cast<String, dynamic>();
        collect(c['participants'] as List?);
        final guid = c['guid'] as String?;
        if (guid != null) chatDataByGuid[guid] ??= c;
      }
    }

    final handles = handleMaps.values.map(Handle.fromMap).toList();
    for (final h in handles) {
      await h.updateFormattedAddress();
    }
    return PreparedSyncBatch._(chatData, messagesData, chatDataByGuid, handles, reportedRowIds);
  }

  /// Writes [batch] in one transaction. Returns `messageIds` (every saved
  /// message) and `chatIds` (chats whose latest pointer moved).
  static Future<Map<String, dynamic>> write(Db db, PreparedSyncBatch batch) => db.write((tx) async {
        final handleRepo = HandleRepo(tx);
        final handlesMap = await handleRepo.insertMissing(tx, batch.handles);
        await handleRepo.adoptServerRowIds(tx, [
          for (final e in batch.reportedRowIds.entries)
            if (handlesMap[e.key]?.id != null) (handlesMap[e.key]!, e.value),
        ]);

        final chatsMap = await _chats(tx, batch, handlesMap);
        final (saved, byGuid) = await _messages(tx, batch, chatsMap, handlesMap);
        await _attachments(tx, batch, byGuid);

        final savedByChat = saved.groupListsBy((m) => m.chat.targetId);
        final chatIds = <int>[];
        for (final chatId in {for (final c in chatsMap.values) if (c.id != null) c.id!}) {
          if (await ChatRepo(tx).keepNewest(tx, chatId, savedByChat[chatId] ?? const [])) chatIds.add(chatId);
        }
        return {'messageIds': saved.map((m) => m.id!).toList(), 'chatIds': chatIds};
      });

  static String _handleKey(Map<String, dynamic> h) => '${h['address'] ?? ''}/${h['service'] ?? 'iMessage'}';

  /// `_syncChatsInTx`: merges into stored chats, links participants, folds twins.
  static Future<Map<String, Chat>> _chats(WriteTx tx, PreparedSyncBatch batch, Map<String, Handle> handlesMap) async {
    if (batch.chatDataByGuid.isEmpty) return {};
    final inputs = batch.chatDataByGuid.values.map(Chat.fromMap).toList();
    final stored = await _byKey(tx, 'chats', 'guid', inputs.map((c) => c.guid), chatFromRow, (c) => c.guid);

    final toSave = <Chat>[];
    final participants = <String, List<int>>{};
    for (final input in inputs) {
      final existing = stored[input.guid];
      final chat = existing ?? input;
      if (existing != null) {
        if (input.displayName != null && input.displayName!.isNotEmpty) chat.displayName = input.displayName;
        chat.chatIdentifier ??= input.chatIdentifier;
        chat.groupId = input.groupId ?? chat.groupId;
        chat.originalGroupId = input.originalGroupId ?? chat.originalGroupId;
        chat.legacyGroupIds = input.legacyGroupIds ?? chat.legacyGroupIds;
        chat.latestGroupTitle = input.latestGroupTitle ?? chat.latestGroupTitle;
        chat.style ??= input.style;
        if (input.isArchived == true) chat.isArchived = true;
        chat.mergeSpamFlag(input);
      }
      participants[input.guid] = [
        for (final p in ((batch.chatDataByGuid[input.guid]!['participants'] as List?) ?? const []).whereType<Map>())
          if (handlesMap[_handleKey(p.cast<String, dynamic>())]?.id case final int id) id,
      ];
      toSave.add(chat);
    }

    final chats = ChatRepo(tx);
    await chats.upsert(tx, toSave);
    for (final chat in toSave) {
      final ids = participants[chat.guid]!;
      if (ids.isNotEmpty) await chats.setParticipants(tx, chat.id!, ids);
    }
    return {for (final c in toSave) c.guid: c, ...await chats.foldServiceTwins(tx, toSave)};
  }

  /// `_syncMessagesInTx`: merges into stored messages, wires chat and sender,
  /// sets `has_reactions` on the messages reacted to.
  static Future<(List<Message>, Map<String, Message>)> _messages(
      WriteTx tx, PreparedSyncBatch batch, Map<String, Chat> chatsMap, Map<String, Handle> handlesMap) async {
    final data = batch.messagesData;
    if (data.isEmpty) return (<Message>[], <String, Message>{});
    final inputs = data.map((m) {
      final msg = Message.fromMap(m);
      if (msg.error > 0) msg.errorMessage = serverErrorMessage(msg.error);
      return msg;
    }).toList();
    final stored = await _byKey(tx, 'messages', 'guid', inputs.map((m) => m.guid!), messageFromRow, (m) => m.guid!);
    final handles = HandleRepo(tx);
    final linked = await handles.byIds({for (final m in stored.values) if (m.handleRelation.targetId != 0) m.handleRelation.targetId});
    final byRowId = await handles.byRowIds({for (final m in inputs) if ((m.handleId ?? 0) > 0) m.handleId!});
    final singleChat = batch.chatData == null ? null : chatsMap[batch.chatData!['guid'] as String?];

    final toSave = <Message>[];
    for (final (i, input) in inputs.indexed) {
      final msgData = data[i];
      final existing = stored[input.guid];
      final msg = existing != null ? Message.merge(existing, input) : input;

      var chat = singleChat;
      if (chat == null) {
        for (final raw in (msgData['chats'] as List? ?? const []).whereType<Map>()) {
          chat = chatsMap[raw['guid'] as String?];
          if (chat != null) break;
        }
      }
      if (chat != null) msg.chat.targetId = chat.id;

      final payloadHandle = handlesMap[payloadSenderKey(msgData)];
      final current = msg.handleRelation.targetId == 0 ? null : linked[msg.handleRelation.targetId];
      if (payloadHandle?.id != null && shouldLinkSender(linked: current, resolved: payloadHandle, fromPayload: true)) {
        msg.handleRelation.targetId = payloadHandle!.id;
        msg.handle = payloadHandle;
      } else if (msg.handleRelation.targetId == 0 && (msg.handleId ?? 0) > 0) {
        final h = byRowId[msg.handleId];
        if (h != null) {
          msg.handleRelation.targetId = h.id;
          msg.handle = h;
        }
      } else if (current != null && msg.handle == null) {
        msg.handle = current;
      }
      toSave.add(msg);
    }
    await MessageRepo(tx).upsert(tx, toSave);
    final byGuid = {for (final m in toSave) if (m.guid != null) m.guid!: m};

    final reactedGuids = {
      for (final m in toSave)
        if ((m.associatedMessageGuid ?? '').isNotEmpty) m.associatedMessageGuid!,
    };
    final reacted = <int>{};
    for (final guid in reactedGuids) {
      final inBatch = byGuid[guid];
      if (inBatch != null) {
        if (!inBatch.hasReactions) reacted.add(inBatch.id!);
        inBatch.hasReactions = true;
      }
    }
    final rows = await _rowsByKey(tx, 'messages', 'guid', reactedGuids.whereNot(byGuid.containsKey));
    for (final r in rows) {
      if ((r['has_reactions'] as int? ?? 0) == 0) reacted.add(r['id'] as int);
    }
    await _setFlag(tx, 'has_reactions', reacted);
    return (toSave, byGuid);
  }

  /// `_syncAttachmentsInTx`: links each attachment to its message (a stored
  /// attachment is kept as stored otherwise) and sets `has_attachments`.
  static Future<void> _attachments(WriteTx tx, PreparedSyncBatch batch, Map<String, Message> byGuid) async {
    final maps = <Map<String, dynamic>>[];
    final owner = <String, String>{};
    for (final msgData in batch.messagesData) {
      final msgGuid = msgData['guid'] as String?;
      if (msgGuid == null) continue;
      for (final raw in (msgData['attachments'] as List? ?? const []).whereType<Map>()) {
        final a = raw.cast<String, dynamic>();
        final guid = a['guid'] as String?;
        if (guid == null || owner.containsKey(guid)) continue;
        maps.add(a);
        owner[guid] = msgGuid;
      }
    }
    if (maps.isEmpty) return;
    final inputs = maps.map(Attachment.fromMap).toList();
    final stored = await _byKey(tx, 'attachments', 'guid', inputs.map((a) => a.guid!), attachmentFromRow, (a) => a.guid!);
    final toSave = <Attachment>[];
    final flagged = <int>{};
    for (final input in inputs) {
      final a = stored[input.guid] ?? input;
      final msg = byGuid[owner[input.guid]];
      if (msg?.id != null) {
        a.message.targetId = msg!.id;
        if (!msg.hasAttachments) {
          msg.hasAttachments = true;
          flagged.add(msg.id!);
        }
      }
      toSave.add(a);
    }
    await AttachmentRepo(tx).upsert(tx, toSave);
    await _setFlag(tx, 'has_attachments', flagged);
  }

  static Future<void> _setFlag(WriteTx tx, String column, Set<int> ids) async {
    for (final chunk in ids.toList().slices(500)) {
      await tx.execute('UPDATE messages SET $column = 1 WHERE id IN (${sqlPlaceholders(chunk.length)})', chunk);
    }
  }

  static Future<List<Map<String, Object?>>> _rowsByKey(WriteTx tx, String table, String column, Iterable<String> keys) async {
    final rows = <Map<String, Object?>>[];
    for (final chunk in keys.toSet().toList().slices(500)) {
      rows.addAll(await tx.select('SELECT * FROM $table WHERE $column IN (${sqlPlaceholders(chunk.length)})', chunk));
    }
    return rows;
  }

  static Future<Map<String, T>> _byKey<T>(WriteTx tx, String table, String column, Iterable<String> keys,
      T Function(Map<String, Object?> row) fromRow, String Function(T item) key) async {
    final items = (await _rowsByKey(tx, table, column, keys)).map(fromRow);
    return {for (final item in items) key(item): item};
  }
}
