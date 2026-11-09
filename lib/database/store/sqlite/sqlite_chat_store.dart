import 'dart:async';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/chat_stats_repo.dart';
import 'package:bluebubbles/database/sqlite/contact_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/db_change_events.dart';
import 'package:bluebubbles/database/sqlite/handle_repo.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_messaging_store.dart';
import 'package:bluebubbles/helpers/types/helpers/service_twin_helpers.dart' show canonicalTwinFor, guidsToMarkRead, threadName;
import 'package:bluebubbles/services/ui/chat/chat_stats/chat_stats_models.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:collection/collection.dart';

/// ChatActions on SQLite. Every former ObjectBox write transaction is one
/// [Db.write]; address formatting and contact lookup stay in ChatActions.
mixin SqliteChatStore implements ChatStore, SqliteStorePart {
  @override
  Future<List<Chat>> markChatsRead(List<int> chatIds) {
    return db.write((tx) async {
      final chats = await ChatRepo(tx).byIds(chatIds);
      await ChatRepo(tx).setUnread(tx, chats.keys, false);
      for (final chat in chats.values) {
        chat.hasUnreadMessage = false;
      }
      return inIdOrder(chatIds, chats);
    });
  }

  @override
  Future<int?> saveChat(
    String guid,
    Chat inputChat,
    Map<String, bool> updateFlags, {
    int? latestMessageId,
    DateTime? latestMessageDate,
  }) {
    return db.write((tx) async {
      final repo = ChatRepo(tx);
      final existing = await repo.byGuid(guid);
      final chat = existing ?? inputChat;
      _applyChatUpdates(chat, inputChat, updateFlags);
      if (updateFlags['updateLatestMessage'] == true) {
        if (latestMessageId != null && latestMessageId > 0) {
          chat.dbLatestMessage.targetId = latestMessageId;
          if (latestMessageDate != null) chat.dbOnlyLatestMessageDate = latestMessageDate;
        } else {
          if (chat.dbOnlyLatestMessageDate != null) {
            Logger.info(
              '${chat.guid}: stored latest date cleared (was ${chat.dbOnlyLatestMessageDate!.toIso8601String()})',
              tag: 'ThreadCheck',
            );
          }
          chat.dbLatestMessage.targetId = 0;
          chat.dbOnlyLatestMessageDate = null;
        }
      }
      await repo.upsert(tx, [chat]);
      return chat.id;
    });
  }

  @override
  Future<void> deleteChat(int chatId, List<int> messageIds, List<int> handleIds) {
    return db.write((tx) async {
      await tx.execute('DELETE FROM chats WHERE id = ?', [chatId]);
      for (final chunk in messageIds.toSet().toList().slices(500)) {
        await tx.execute('DELETE FROM messages WHERE id IN (${sqlPlaceholders(chunk.length)})', chunk);
      }
      for (final chunk in handleIds.toSet().toList().slices(500)) {
        await tx.execute('DELETE FROM handles WHERE id IN (${sqlPlaceholders(chunk.length)})', chunk);
      }
    });
  }

  @override
  Future<void> softDeleteChat(String guid) {
    return db.write((tx) async {
      final chat = await ChatRepo(tx).byGuid(guid);
      if (chat == null) return;
      chat.dateDeleted = DateTime.now().toUtc();
      chat.hasUnreadMessage = false;
      await ChatRepo(tx).upsert(tx, [chat]);
    });
  }

  @override
  Future<void> unDeleteChat(String guid) {
    return db.write((tx) async {
      final chat = await ChatRepo(tx).byGuid(guid);
      if (chat == null) return;
      chat.dateDeleted = null;
      await ChatRepo(tx).upsert(tx, [chat]);
    });
  }

  @override
  Future<Map<String, dynamic>> addMessageToChat(
    Message inputMessage,
    List<Attachment> inputAttachments,
    Chat inputChat,
    Message inputLatest, {
    required bool checkForMessageText,
  }) {
    return db.write((tx) async {
      final messages = MessageRepo(tx);
      final handles = HandleRepo(tx);
      final chats = ChatRepo(tx);
      final attachments = AttachmentRepo(tx);

      final existing = await messages.byGuid(inputMessage.guid ?? '');
      if (existing != null) {
        inputMessage.id = existing.id;
        inputMessage.text ??= existing.text;
      }

      final hasSenderHandle = !(inputMessage.isFromMe ?? false) && (inputMessage.handleId ?? 0) != 0;
      Handle? handleToLink;
      int? reportedRowId;
      if (inputMessage.handle == null && hasSenderHandle) {
        handleToLink = (await handles.byRowIds([inputMessage.handleId!]))[inputMessage.handleId!];
        if (handleToLink == null) {
          final dbChat = await chats.byGuid(inputChat.guid);
          final chatHandles = dbChat?.handles.toList() ?? const <Handle>[];
          if (chatHandles.length == 1) {
            handleToLink = chatHandles.first;
            Logger.warn(
              'Linked message ${inputMessage.guid} to sole participant ${handleToLink.address} '
              '(originalROWID lookup for handleId=${inputMessage.handleId} failed)',
              tag: 'ChatActions',
            );
          } else {
            Logger.error(
              'Could not resolve handle for message ${inputMessage.guid} in chat ${inputChat.guid} '
              '(handleId=${inputMessage.handleId}, chatHandles=${chatHandles.length}) — '
              'notification will be skipped',
              tag: 'ChatActions',
            );
          }
        }
      } else if (inputMessage.handle != null) {
        reportedRowId = serverReportedRowId(inputMessage.handle!);
        handleToLink = await handles.byUniqueKey(inputMessage.handle!.address, inputMessage.handle!.service);
        if (handleToLink == null) {
          await handles.upsert(tx, [inputMessage.handle!], updateColor: true);
          handleToLink = inputMessage.handle;
        }
        if (reportedRowId != null) await handles.adoptServerRowIds(tx, [(handleToLink!, reportedRowId)]);
      }

      if (inputMessage.associatedMessageType != null && inputMessage.associatedMessageGuid != null) {
        final associated = await messages.byGuid(inputMessage.associatedMessageGuid!);
        if (associated != null) {
          associated.hasReactions = true;
          await messages.upsert(tx, [associated]);
        }
      } else if (!inputMessage.hasReactions && (await messages.reactionsFor([inputMessage.guid ?? ''])).isNotEmpty) {
        inputMessage.hasReactions = true;
      }

      final dbChat = await chats.byGuid(inputChat.guid);
      if (dbChat != null) inputMessage.chat.targetId = dbChat.id;

      int? messageId;
      try {
        await messages.upsert(tx, [inputMessage]);
        messageId = inputMessage.id;
      } catch (e, s) {
        if (!isUniqueViolation(e)) {
          Logger.error('[addMessageToChat] Failed to save message!', error: e, trace: s);
        }
        messageId = (await messages.byGuid(inputMessage.guid ?? ''))?.id;
        inputMessage.id = messageId;
      }

      if (messageId != null) {
        final dbMessage = await messages.byId(messageId);
        if (dbMessage != null) {
          var needsUpdate = false;
          if (shouldLinkSender(
            linked: dbMessage.handleRelation.target,
            resolved: handleToLink,
            fromPayload: hasSenderHandle && reportedRowId != null,
          )) {
            dbMessage.handleRelation.targetId = handleToLink!.id;
            needsUpdate = true;
          }
          if (inputAttachments.isNotEmpty) {
            for (final attachment in inputAttachments) {
              final stored = await attachments.byGuid(attachment.guid ?? '');
              if (stored != null) attachment.id = stored.id;
              attachment.message.targetId = dbMessage.id;
              try {
                await attachments.upsert(tx, [attachment]);
              } catch (e, s) {
                if (isUniqueViolation(e)) {
                  Logger.warn('[addMessageToChat] UniqueViolationException for attachment ${attachment.guid}');
                } else {
                  Logger.error('[addMessageToChat] Failed to save attachment!', error: e, trace: s);
                }
              }
            }
            needsUpdate = true;
          }
          if (needsUpdate) await messages.upsert(tx, [dbMessage]);
        }
      }

      var isNewer = false;
      if (messageId != null && checkForMessageText) {
        isNewer = inputMessage.dateCreated!.isAfter(inputLatest.dateCreated!) ||
            (inputMessage.guid != inputLatest.guid && inputMessage.dateCreated == inputLatest.dateCreated);
      }
      return <String, dynamic>{'messageId': messageId, 'isNewer': isNewer};
    });
  }

  @override
  Future<List<int>> supplementalMessageIds(List<String> messageGuids) async =>
      [for (final message in await MessageRepo(db).reactionsFor(messageGuids)) message.id!];

  @override
  Future<List<int>> syncLatestMessages(List<String> chatGuids, {required bool toggleUnread}) {
    return db.write((tx) async {
      final chats = ChatRepo(tx);
      final ids = <int>[];
      for (final guid in chatGuids.toSet()) {
        final chat = await chats.byGuid(guid);
        if (chat?.id == null) continue;
        ids.add(chat!.id!);
        if (!await chats.refreshLatest(tx, chat.id!)) continue;
        if (!toggleUnread) continue;
        final refreshed = await chats.byId(chat.id!);
        if (!(refreshed?.dbLatestMessage.target?.isFromMe ?? true)) {
          await chats.setUnread(tx, [chat.id!], true);
        }
      }
      return ids;
    });
  }

  @override
  Future<Handle?> handleByAddress(String address) async {
    final rows = await db.select('SELECT id FROM handles WHERE address = ? ORDER BY id LIMIT 1', [address]);
    return rows.isEmpty ? null : HandleRepo(db).byId(rows.single['id'] as int);
  }

  @override
  Future<({List<int> chatIds, List<int> brandNewHandleIds})> bulkSyncChats(
    List<Chat> inputChats,
    Map<String, Handle> inputHandles,
  ) {
    return db.write((tx) async {
      final handles = HandleRepo(tx);
      final chats = ChatRepo(tx);
      final existingHandles = <String, Handle>{};
      for (final input in inputHandles.values) {
        final existing = await handles.byUniqueKey(input.address, input.service);
        if (existing != null) existingHandles[input.uniqueAddressAndService] = existing;
      }
      final brandNewKeys = inputHandles.keys.where((key) => !existingHandles.containsKey(key)).toSet();
      final reported = <(Handle, int)>[];
      for (final input in inputHandles.values) {
        final rowId = serverReportedRowId(input);
        if (rowId != null) reported.add((input, rowId));
      }
      final handlesToSave = inputHandles.values.toList();
      await handles.upsert(tx, handlesToSave, updateColor: true);
      await handles.adoptServerRowIds(tx, reported);
      final validHandles = {for (final h in handlesToSave) h.uniqueAddressAndService: h};

      final chatsToSave = <Chat>[];
      final participantIds = <String, List<int>>{};
      for (final input in inputChats) {
        final existing = await chats.byGuid(input.guid);
        final chat = existing ?? input;
        if (existing != null) {
          if (!chat.lockChatName) chat.displayName = input.displayName;
          chat.mergeSpamFlag(input);
          chat.groupId = input.groupId ?? chat.groupId;
          chat.originalGroupId = input.originalGroupId ?? chat.originalGroupId;
          chat.legacyGroupIds = input.legacyGroupIds ?? chat.legacyGroupIds;
          chat.latestGroupTitle = input.latestGroupTitle ?? chat.latestGroupTitle;
        }
        participantIds[input.guid] = [
          for (final participant in input.participants)
            if (validHandles[participant.uniqueAddressAndService]?.id case final id?) id,
        ];
        chatsToSave.add(chat);
      }
      await chats.upsert(tx, chatsToSave);
      for (final chat in chatsToSave) {
        final ids = participantIds[chat.guid] ?? const <int>[];
        if (ids.isNotEmpty) await chats.setParticipants(tx, chat.id!, ids);
      }
      await chats.foldServiceTwins(tx, chatsToSave);
      return (
        chatIds: chatsToSave.map((e) => e.id!).toList(),
        brandNewHandleIds: [for (final h in handlesToSave) if (brandNewKeys.contains(h.uniqueAddressAndService)) h.id!],
      );
    });
  }

  @override
  Future<void> linkContactToHandle(ContactV2 contact, int handleId) {
    return db.write((tx) async {
      final handle = await HandleRepo(tx).byId(handleId);
      if (handle == null) return;
      final contacts = ContactRepo(tx);
      final stored = await contacts.byNativeId(contact.nativeContactId);
      final toSave = stored ?? contact;
      await contacts.upsert(tx, [toSave]);
      await contacts.setHandles(tx, toSave.id, {...toSave.handles.map((h) => h.id!), handleId});
    });
  }

  @override
  Future<List<int>> messagePageIds(
    int chatId,
    List<Handle> participants, {
    required int offset,
    required int limit,
    required bool includeDeleted,
  }) {
    return db.read((reader) async {
      final deleted = includeDeleted ? '' : 'AND date_deleted_us IS NULL ';
      final rows = await reader.select(
        'SELECT * FROM messages INDEXED BY messages_chat_time WHERE chat_id = ? '
        'AND date_created_us IS NOT NULL $deleted'
        'ORDER BY date_created_us DESC, id DESC LIMIT ? OFFSET ?',
        [chatId, limit, offset],
      );
      final messages = rows.map(messageFromRow).toList();
      await MessageRepo(reader).attachmentsFor(messages);
      final unresolved = <int>{
        for (final message in messages)
          if (message.isFromMe != true &&
              (message.handleId ?? 0) != 0 &&
              participants.every((h) => h.originalROWID != message.handleId) &&
              message.handleRelation.target == null)
            message.handleId!,
      };
      final storedByRowId = await HandleRepo(reader).byRowIds(unresolved);
      messages.removeWhere((message) {
        if (participants.isEmpty || message.isFromMe == true || (message.handleId ?? 0) == 0) return false;
        final handle = participants.firstWhereOrNull((h) => h.originalROWID == message.handleId) ??
            message.handleRelation.target ??
            storedByRowId[message.handleId];
        return handle == null && message.originalROWID != null;
      });
      return messages.map((e) => e.id!).toList();
    });
  }

  /// Keyset paging on (sort_at, id) through [MessageRepo]: its timeline
  /// query already leaves out reactions and senders this chat can't place
  /// (so [participants] and [loadedRows] are not needed).
  @override
  Future<MessagePage> olderMessagePage(
    int chatId,
    List<Handle> participants, {
    MessagePageCursor? after,
    required int loadedRows,
    required int limit,
  }) async {
    final repo = MessageRepo(db);
    final key = after?.key;
    final page = key == null ? await repo.newest([chatId], limit: limit) : await repo.olderThan([chatId], key, limit: limit);
    return (
      ids: [for (final m in page) m.id!],
      next: page.isEmpty ? after : MessagePageCursor.sqlite(MessageKey.of(page.last)),
    );
  }

  /// The keyset neighbours of the message's (sort_at, id) key, so ties and
  /// delivered-before-created messages land where the screen shows them.
  @override
  Future<MessagePage> messagePageAround(int chatId, List<Handle> participants, int aroundId, {required int limit}) async {
    final repo = MessageRepo(db);
    final target = (await repo.byIds([aroundId]))[aroundId];
    if (target == null) return (ids: <int>[], next: null);
    final page = await repo.around([chatId], MessageKey.of(target), before: limit, after: limit);
    return (
      ids: [for (final m in page) m.id!],
      next: page.isEmpty ? null : MessagePageCursor.sqlite(MessageKey.of(page.last)),
    );
  }

  @override
  Future<List<Message>> searchMessages(String term,
          {int? chatId, bool? isFromMe, int? senderRowId, DateTime? since, int limit = 50}) =>
      MessageRepo(db).search(term,
          chatIds: chatId == null ? null : [chatId],
          isFromMe: isFromMe,
          senderHandleId: senderRowId,
          since: since,
          limit: limit);

  @override
  Future<List<Chat>> chatsByGuids(List<String> guids) async {
    final found = <String, Chat>{};
    for (final guid in guids.toSet()) {
      final chat = await ChatRepo(db).byGuid(guid);
      if (chat != null) found[guid] = chat;
    }
    return [for (final guid in guids) ?found[guid]];
  }

  @override
  Future<List<Message>> linkMessages(int chatId) async {
    final rows = await db.select(
        'SELECT * FROM messages INDEXED BY messages_chat_time WHERE chat_id = ? AND date_deleted_us IS NULL '
        "AND payload_data_json IS NOT NULL AND balloon_bundle_id LIKE '%URLBalloonProvider%' "
        'ORDER BY date_created_us DESC, id DESC',
        [chatId]);
    return rows.map(messageFromRow).toList();
  }

  @override
  Future<List<Message>> bookmarkedMessages(int chatId) => MessageRepo(db).bookmarked(chatId);

  @override
  Future<int?> timelinePosition(int chatId, int messageId) async {
    final message = await MessageRepo(db).row(messageId);
    if (message == null || message.chat.targetId != chatId || message.dateDeleted != null) return null;
    return MessageRepo(db).newerCount([chatId], MessageKey.of(message));
  }

  @override
  Future<List<int>> participantIds(int chatId) async {
    final chat = await ChatRepo(db).byId(chatId);
    return chat == null ? <int>[] : chat.handles.map((e) => e.id!).toList();
  }

  @override
  Future<void> clearTranscript(int chatId) {
    return db.write((tx) async {
      final rows = await tx.select('SELECT id FROM messages WHERE chat_id = ?', [chatId]);
      final messages = await MessageRepo(tx).byIds(rows.map((row) => row['id'] as int));
      for (final message in messages.values) {
        message.dateDeleted = DateTime.now().toUtc();
      }
      await MessageRepo(tx).upsert(tx, messages.values.toList());
    });
  }

  @override
  Future<List<int>> chatPageIds({required int limit, required int offset, required List<int> ids}) async {
    if (ids.isNotEmpty) {
      final chats = (await ChatRepo(db).byIds(ids)).values.sortedBy<num>((chat) => chat.id!);
      return chats.skip(offset).take(limit).map((chat) => chat.id!).toList();
    }
    final chats = await ChatRepo(db).listPage(limit: offset + limit);
    return chats.skip(offset).map((chat) => chat.id!).toList();
  }
  /// Chat ids only grow (AUTOINCREMENT), so a chat is new when its id is above
  /// every id stored when the stream started or emitted since.
  @override
  Stream<List<Chat>> chatsWritten() {
    final controller = StreamController<List<Chat>>();
    StreamSubscription<List<Chat>>? sub;
    controller.onListen = () {
      final start = db.select('SELECT max(id) AS id FROM chats').then((rows) => rows.first['id'] as int? ?? 0);
      var newest = -1;
      sub = DbChangeEvents.main.on('chats').asyncMap((ids) async {
        if (newest < 0) newest = await start;
        final added = ids.where((id) => id > newest).toList();
        if (added.isEmpty) return const <Chat>[];
        newest = added.max;
        final chats = await ChatRepo(db).byIds(added);
        return chats.values.where((c) => c.dateDeleted == null).sortedBy<num>((c) => c.id!);
      }).where((chats) => chats.isNotEmpty).listen(controller.add, onError: controller.addError);
    };
    controller.onCancel = () => sub?.cancel();
    return controller.stream;
  }

  @override
  ChatStatsReader chatStats(Chat chat) => _SqliteChatStats(ChatStatsRepo(db), chat);

  @override
  Future<int> chatCount() async => (await db.select('SELECT count(*) AS n FROM chats')).first['n'] as int;

  @override
  Future<List<Chat>> threadedChats() async {
    final rows = await db.select('SELECT id FROM chats WHERE thread_key IS NOT NULL ORDER BY id');
    final ids = [for (final row in rows) row['id'] as int];
    return inIdOrder(ids, await ChatRepo(db).byIds(ids));
  }

  /// Ordered as the chat screen orders (sort_at, id), which ObjectBox's
  /// created-date query matches except for delivered-before-created ties.
  @override
  Future<Message?> newestMessageIn(int chatId, {bool listing = true}) async {
    final rows = await db.select(
        'SELECT * FROM messages INDEXED BY messages_chat_time WHERE chat_id = ? '
        'AND date_deleted_us IS NULL AND date_created_us IS NOT NULL '
        '${listing ? 'AND (item_type IS NULL OR item_type = 0) ' : ''}'
        'ORDER BY date_created_us DESC, id DESC LIMIT 1',
        [chatId]);
    if (rows.isEmpty) return null;
    final message = messageFromRow(rows.single);
    await MessageRepo(db).attachmentsFor([message]);
    return message;
  }

  @override
  Future<List<Chat>> threadChatsOf(Chat chat) async {
    final key = chat.threadKey;
    final chats = key == null || key.isEmpty ? <Chat>[] : await ChatRepo(db).threadCopies(key);
    return chats.any((c) => c.guid == chat.guid) ? chats : [chat, ...chats];
  }

  @override
  Future<List<String>> threadGuidsToMarkRead(String guid) async {
    final chat = await ChatRepo(db).byGuid(guid);
    final key = chat?.threadKey;
    if (key == null || key.isEmpty) return [guid];
    final rows = await db.select('SELECT guid FROM chats WHERE thread_key = ? ORDER BY id', [key]);
    return guidsToMarkRead(guid, [for (final row in rows) Chat(guid: row['guid'] as String, threadKey: key)]);
  }

  @override
  Future<String?> threadNameOf(Chat chat) async {
    final key = chat.threadKey;
    if (key == null || key.isEmpty || chat.id == null) return chat.currentName;
    final copies = await ChatRepo(db).threadCopies(key);
    if (copies.length < 2) return chat.currentName;
    final renamed = {for (final c in copies) c.latestGroupTitle}.whereType<String>().length > 1;
    final newestRename = renamed ? await MessageRepo(db).newestRename([chat.id!]) : null;
    return threadName(chat, copies, newestRename: newestRename);
  }

  @override
  Future<Chat?> canonicalTwinOf(Chat chat) async {
    final key = chat.threadKey;
    if (key == null || key.isEmpty) return null;
    return canonicalTwinFor(chat, await ChatRepo(db).threadCopies(key));
  }
}

void _applyChatUpdates(Chat chat, Chat input, Map<String, bool> flags) {
  if (flags['updateMuteType']!) chat.muteType = input.muteType;
  if (flags['updateMuteArgs']!) chat.muteArgs = input.muteArgs;
  if (flags['updateIsPinned']!) chat.isPinned = input.isPinned;
  if (flags['updatePinIndex']!) chat.pinIndex = input.pinIndex;
  if (flags['updateIsArchived']!) chat.isArchived = input.isArchived;
  if (flags['updateHasUnreadMessage']!) chat.hasUnreadMessage = input.hasUnreadMessage;
  if (flags['updateAutoSendReadReceipts']!) chat.autoSendReadReceipts = input.autoSendReadReceipts;
  if (flags['updateAutoSendTypingIndicators']!) chat.autoSendTypingIndicators = input.autoSendTypingIndicators;
  if (flags['updateCustomAvatarPath']!) chat.customAvatarPath = input.customAvatarPath;
  if (flags['updateCustomBackgroundPath']!) chat.customBackgroundPath = input.customBackgroundPath;
  if (flags['updateTextFieldText']!) chat.textFieldText = input.textFieldText;
  if (flags['updateTextFieldAttachments']!) chat.textFieldAttachments = input.textFieldAttachments;
  if (flags['updateDisplayName']!) chat.displayName = input.displayName;
  if (flags['updateDateDeleted']!) chat.dateDeleted = input.dateDeleted;
  if (flags['updateLockChatName']!) chat.lockChatName = input.lockChatName;
  if (flags['updateLockChatIcon']!) chat.lockChatIcon = input.lockChatIcon;
  if (flags['updateLastReadMessageGuid']!) chat.lastReadMessageGuid = input.lastReadMessageGuid;
  if (flags['updateCustomThemes'] == true) {
    chat.customThemeLight = input.customThemeLight;
    chat.customThemeDark = input.customThemeDark;
  }
  if (flags['updateWallpaperSettings'] == true) {
    chat.wallpaperType = input.wallpaperType;
    chat.dynamicWallpaperId = input.dynamicWallpaperId;
    chat.dynamicWallpaperConfig = input.dynamicWallpaperConfig;
  }
  if (flags['updateIsFilteredAsSpam'] == true) chat.isFilteredAsSpam = input.isFilteredAsSpam;
}

/// [ChatStatsReader] over ChatStatsRepo.
class _SqliteChatStats implements ChatStatsReader {
  _SqliteChatStats(this.repo, this.chat);

  final ChatStatsRepo repo;
  final Chat chat;

  @override
  Future<int> messageCountForTier() =>
      repo.messageCountForTier(chat.id!);

  @override
  Future<({int count, int latestMillis})> cacheKey() =>
      repo.cacheKey(chat.id!);

  @override
  Future<Map<int, List<int>>> timestampsByParticipant({int? sinceMillis}) =>
      repo.timestampsByParticipant(chat.id!, sinceMillis: sinceMillis);

  @override
  Future<int> attachmentMessageCount({int? sinceMillis}) =>
      repo.attachmentMessageCount(chat.id!, sinceMillis: sinceMillis);

  @override
  Future<int> unattributedCount({int? sinceMillis}) =>
      repo.unattributedCount(chat.id!, sinceMillis: sinceMillis);

  @override
  Future<int?> firstMessageMillis() =>
      repo.firstMessageMillis(chat.id!);

  @override
  Future<List<int>> readTimestamps({int? sinceMillis}) =>
      repo.readTimestamps(chat.id!, sinceMillis: sinceMillis);

  @override
  Future<double> textCoverage() =>
      repo.textCoverage(chat.id!);

  @override
  Future<List<String>> recentTexts({required bool fromMe, int? limit, int? participantId}) =>
      repo.recentTexts(chat.id!, fromMe: fromMe, limit: limit, participantId: participantId);

  @override
  Future<Map<int, List<int>>> textLengthsByParticipant({int? sinceMillis, int? limitPerParticipant}) =>
      repo.textLengthsByParticipant(chat.id!, sinceMillis: sinceMillis, limitPerParticipant: limitPerParticipant);

  @override
  Future<List<({String type, int participantId})>> reactions() =>
      repo.reactions(chat.id!);

  @override
  Future<List<String>> attachmentMimeTypes() =>
      repo.attachmentMimeTypes(chat.id!);

  @override
  Future<List<String>> expressiveSendStyleIds() =>
      repo.expressiveSendStyleIds(chat.id!);

  @override
  Future<int> editedCount({bool? fromMe, int? participantId}) =>
      repo.editedCount(chat.id!, fromMe: fromMe, participantId: participantId);

  @override
  Future<int> unsentCount({bool? fromMe, int? participantId}) =>
      repo.unsentCount(chat.id!, fromMe: fromMe, participantId: participantId);

  @override
  Future<int> sentCount() =>
      repo.sentCount(chat.id!);

  @override
  Future<int> receivedCount({int? participantId}) =>
      repo.receivedCount(chat.id!, participantId: participantId);

  @override
  Future<({int sent, int received, double? playedOfReceived})> audioStats() =>
      repo.audioStats(chat.id!);

  @override
  Future<List<GroupEventRecord>> groupEvents() =>
      repo.groupEvents(chat.id!);

  @override
  Future<({List<ReactionMatrixRow> reactionRows, Map<String, int> guidToSender})> reactionMatrixData({required int sinceMillis}) =>
      repo.reactionMatrixData(chat.id!, sinceMillis: sinceMillis);

  @override
  Future<List<int>> participantHandleIds({int? sinceMillis}) =>
      repo.participantHandleIds(chat.id!, sinceMillis: sinceMillis);
}
