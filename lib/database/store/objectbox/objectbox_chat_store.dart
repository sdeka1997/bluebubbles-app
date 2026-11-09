import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/objectbox/objectbox_thread_store_helpers.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/helpers/types/helpers/service_twin_helpers.dart' show canonicalTwinFor, guidsToMarkRead, threadName;
import 'package:bluebubbles/services/ui/chat/chat_stats/chat_stats_models.dart';
import 'package:bluebubbles/services/ui/chat/chat_stats/chat_stats_queries.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

/// ChatActions' ObjectBox code, moved behind [ChatStore].
mixin ObjectBoxChatStore implements ChatStore {
  @override
  Future<List<Chat>> markChatsRead(List<int> chatIds) async {
    final chats = Database.chats.getMany(chatIds).whereType<Chat>().toList();
    for (final c in chats) {
      c.hasUnreadMessage = false;
    }
    Database.runInTransaction(TxMode.write, () {
      Database.chats.putMany(chats);
    });
    return chats;
  }

  @override
  Future<int?> saveChat(
    String guid,
    Chat inputChat,
    Map<String, bool> updateFlags, {
    int? latestMessageId,
    DateTime? latestMessageDate,
  }) async {
    return Database.runInTransaction(TxMode.write, () {
      final chatBox = Database.chats;
      final query = chatBox.query(Chat_.guid.equals(guid)).build();
      final existing = query.findFirst();
      query.close();

      final chat = existing ?? inputChat;
      if (existing == null) chat.id = inputChat.id;
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
          chat.dbLatestMessage.target = null;
          chat.dbOnlyLatestMessageDate = null;
        }
      }

      try {
        chat.id = chatBox.put(chat);
      } on UniqueViolationException catch (_) {}
      return chat.id;
    });
  }

  @override
  Future<void> deleteChat(int chatId, List<int> messageIds, List<int> handleIds) async {
    Database.runInTransaction(TxMode.write, () {
      final chatBox = Database.chats;
      final messageBox = Database.messages;
      final handleBox = Database.handles;
      chatBox.remove(chatId);
      messageBox.removeMany(messageIds);
      if (handleIds.isNotEmpty) handleBox.removeMany(handleIds);
    });
  }

  @override
  Future<void> softDeleteChat(String guid) async {
    Database.runInTransaction(TxMode.write, () {
      final chatBox = Database.chats;
      final query = chatBox.query(Chat_.guid.equals(guid)).build()..limit = 1;
      final chat = query.findFirst();
      query.close();
      if (chat != null) {
        chat.dateDeleted = DateTime.now().toUtc();
        chat.hasUnreadMessage = false;
        chatBox.put(chat);
      }
    });
  }

  @override
  Future<void> unDeleteChat(String guid) async {
    Database.runInTransaction(TxMode.write, () {
      final chatBox = Database.chats;
      final query = chatBox.query(Chat_.guid.equals(guid)).build()..limit = 1;
      final chat = query.findFirst();
      query.close();
      if (chat != null) {
        chat.dateDeleted = null;
        chatBox.put(chat);
      }
    });
  }

  @override
  Future<Map<String, dynamic>> addMessageToChat(
    Message inputMessage,
    List<Attachment> inputAttachments,
    Chat inputChat,
    Message inputLatest, {
    required bool checkForMessageText,
  }) async {
    return Database.runInTransaction(TxMode.write, () {
      final messageBox = Database.messages;
      final attachmentBox = Database.attachments;
      final handleBox = Database.handles;
      final chatBox = Database.chats;

      final msgQuery = messageBox.query(Message_.guid.equals(inputMessage.guid ?? '')).build()..limit = 1;
      final existing = msgQuery.findFirst();
      msgQuery.close();
      if (existing != null) {
        inputMessage.id = existing.id;
        inputMessage.text ??= existing.text;
      }

      final hasSenderHandle = !(inputMessage.isFromMe ?? false) && (inputMessage.handleId ?? 0) != 0;
      Handle? handleToLink;
      int? reportedRowId;
      if (inputMessage.handle == null && hasSenderHandle) {
        final handleQuery = handleBox.query(Handle_.originalROWID.equals(inputMessage.handleId!)).build()..limit = 1;
        handleToLink = handleQuery.findFirst();
        handleQuery.close();
        if (handleToLink == null) {
          final chatQuery = chatBox.query(Chat_.guid.equals(inputChat.guid)).build()..limit = 1;
          final dbChat = chatQuery.findFirst();
          chatQuery.close();
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
        final existingHandleQuery = handleBox
            .query(Handle_.uniqueAddressAndService.equals(inputMessage.handle!.uniqueAddressAndService))
            .build()
          ..limit = 1;
        final existingHandle = existingHandleQuery.findFirst();
        existingHandleQuery.close();
        if (existingHandle != null) {
          handleToLink = existingHandle;
        } else {
          final handleId = handleBox.put(inputMessage.handle!);
          inputMessage.handle!.id = handleId;
          handleToLink = inputMessage.handle;
        }
        if (reportedRowId != null) adoptServerRowIdsInBox(handleBox, [(handleToLink!, reportedRowId)]);
      }

      if (inputMessage.associatedMessageType != null && inputMessage.associatedMessageGuid != null) {
        final query = messageBox.query(Message_.guid.equals(inputMessage.associatedMessageGuid!)).build()..limit = 1;
        final associated = query.findFirst();
        query.close();
        if (associated != null) {
          associated.hasReactions = true;
          messageBox.put(associated);
        }
      } else if (!inputMessage.hasReactions) {
        final query = messageBox.query(Message_.associatedMessageGuid.equals(inputMessage.guid ?? '')).build()..limit = 1;
        final reaction = query.findFirst();
        query.close();
        if (reaction != null) inputMessage.hasReactions = true;
      }

      final chatQuery = chatBox.query(Chat_.guid.equals(inputChat.guid)).build()..limit = 1;
      final dbChat = chatQuery.findFirst();
      chatQuery.close();
      if (dbChat != null) inputMessage.chat.target = dbChat;

      int? messageId;
      try {
        messageId = messageBox.put(inputMessage);
        inputMessage.id = messageId;
      } on UniqueViolationException catch (_) {
        final query = messageBox.query(Message_.guid.equals(inputMessage.guid ?? '')).build()..limit = 1;
        final retry = query.findFirst();
        query.close();
        inputMessage.id = retry?.id;
        messageId = retry?.id;
      } catch (e, s) {
        Logger.error('[addMessageToChat] Failed to save message!', error: e, trace: s);
      }

      if (messageId != null) {
        final dbMessage = messageBox.get(messageId);
        if (dbMessage != null) {
          var needsUpdate = false;
          if (shouldLinkSender(
            linked: dbMessage.handleRelation.target,
            resolved: handleToLink,
            fromPayload: hasSenderHandle && reportedRowId != null,
          )) {
            dbMessage.handleRelation.target = handleToLink;
            needsUpdate = true;
          }
          if (inputAttachments.isNotEmpty) {
            for (final attachment in inputAttachments) {
              final query = attachmentBox.query(Attachment_.guid.equals(attachment.guid ?? '')).build()..limit = 1;
              final existingAttach = query.findFirst();
              query.close();
              if (existingAttach != null) attachment.id = existingAttach.id;
              attachment.message.target = dbMessage;
              try {
                attachmentBox.put(attachment);
              } on UniqueViolationException catch (_) {
                Logger.warn('[addMessageToChat] UniqueViolationException for attachment ${attachment.guid}');
              } catch (e, s) {
                Logger.error('[addMessageToChat] Failed to save attachment!', error: e, trace: s);
              }
            }
            dbMessage.dbAttachments.addAll(inputAttachments.where((a) => a.id != null));
            dbMessage.dbAttachments.applyToDb();
            needsUpdate = true;
          }
          if (needsUpdate) messageBox.put(dbMessage);
        }
      }

      var isNewer = false;
      if ((messageId != null || kIsWeb) && checkForMessageText) {
        isNewer = inputMessage.dateCreated!.isAfter(inputLatest.dateCreated!) ||
            (inputMessage.guid != inputLatest.guid && inputMessage.dateCreated == inputLatest.dateCreated);
      }
      return <String, dynamic>{'messageId': messageId, 'isNewer': isNewer};
    });
  }

  @override
  Future<List<int>> supplementalMessageIds(List<String> messageGuids) async {
    return Database.runInTransaction(TxMode.read, () {
      final query = (Database.messages.query(Message_.associatedMessageGuid.oneOf(messageGuids))
            ..order(Message_.originalROWID))
          .build();
      final reactions = query.find();
      query.close();
      return reactions.map((e) => e.id!).toList();
    });
  }

  @override
  Future<List<int>> syncLatestMessages(List<String> chatGuids, {required bool toggleUnread}) async {
    return Database.runInTransaction(TxMode.write, () {
      final chatBox = Database.chats;
      final messageBox = Database.messages;
      final query = chatBox.query(Chat_.guid.oneOf(chatGuids)).build();
      final chats = query.find();
      query.close();
      if (chats.isEmpty) return <int>[];

      final updated = <Chat>[];
      for (final chat in chats) {
        final latestQuery = (messageBox.query(Message_.dateCreated.notNull().and(listsThreadCondition))
              ..link(Message_.chat, Chat_.id.equals(chat.id!))
              ..order(Message_.dateCreated, flags: Order.descending))
            .build()
          ..limit = 1;
        final latest = latestQuery.find().firstOrNull;
        latestQuery.close();
        if (latest?.handle == null && latest?.handleId != null && latest?.handleId != 0) {
          final handleQuery = Database.handles.query(Handle_.originalROWID.equals(latest!.handleId!)).build()..limit = 1;
          latest.handle = handleQuery.findFirst();
          handleQuery.close();
        }
        if (_tryUpdateLastMessage(chat, latest, toggleUnread)) updated.add(chat);
      }
      if (updated.isNotEmpty) chatBox.putMany(updated, mode: PutMode.update);
      return chats.map((e) => e.id!).toList();
    });
  }

  @override
  Future<Handle?> handleByAddress(String address) async {
    final query = Database.handles.query(Handle_.address.equals(address)).build()..limit = 1;
    final handle = query.findFirst();
    query.close();
    return handle;
  }

  @override
  Future<({List<int> chatIds, List<int> brandNewHandleIds})> bulkSyncChats(
    List<Chat> inputChats,
    Map<String, Handle> inputHandles,
  ) async {
    return Database.runInTransaction(TxMode.write, () {
      final chatBox = Database.chats;
      final handleBox = Database.handles;
      final inputAddresses = inputHandles.keys.toList();
      final existingQuery = handleBox.query(Handle_.uniqueAddressAndService.oneOf(inputAddresses)).build();
      final existingHandles = existingQuery.find();
      existingQuery.close();
      final existingByKey = {for (final h in existingHandles) h.uniqueAddressAndService: h};
      final handlesToSave = <Handle>[];
      final brandNewHandleIds = <int>[];
      final reported = <(Handle, int)>[];
      for (final input in inputHandles.values) {
        final rowId = serverReportedRowId(input);
        if (rowId != null) reported.add((input, rowId));
        final existing = existingByKey[input.uniqueAddressAndService];
        if (existing != null) {
          input.id = existing.id;
          input.originalROWID ??= existing.originalROWID;
        }
        handlesToSave.add(input);
      }
      handleBox.putMany(handlesToSave);
      for (final h in handlesToSave) {
        if (!existingByKey.containsKey(h.uniqueAddressAndService)) brandNewHandleIds.add(h.id!);
      }
      adoptServerRowIdsInBox(handleBox, reported);
      final validHandles = {for (final h in handlesToSave) h.uniqueAddressAndService: h};

      final inputGuids = inputChats.map((e) => e.guid).toList();
      final chatsQuery = chatBox.query(Chat_.guid.oneOf(inputGuids)).build();
      final existingChats = chatsQuery.find();
      chatsQuery.close();
      final existingChatsByGuid = {for (final c in existingChats) c.guid: c};
      final chatsToSave = <Chat>[];
      final chatHandles = <String, List<Handle>>{};
      for (final input in inputChats) {
        final existing = existingChatsByGuid[input.guid];
        final chat = existing ?? input;
        if (existing != null) {
          if (!chat.lockChatName) chat.displayName = input.displayName;
          chat.mergeSpamFlag(input);
          chat.groupId = input.groupId ?? chat.groupId;
          chat.originalGroupId = input.originalGroupId ?? chat.originalGroupId;
          chat.legacyGroupIds = input.legacyGroupIds ?? chat.legacyGroupIds;
          chat.latestGroupTitle = input.latestGroupTitle ?? chat.latestGroupTitle;
        }
        chatHandles[input.guid] = [
          for (final participant in input.participants)
            if (validHandles[participant.uniqueAddressAndService] case final h?) h,
        ];
        chatsToSave.add(chat);
      }
      chatBox.putMany(chatsToSave);
      for (final chat in chatsToSave) {
        final handles = chatHandles[chat.guid];
        if (handles != null && handles.isNotEmpty) {
          final fresh = chatBox.get(chat.id!);
          if (fresh != null) {
            fresh.handles.clear();
            fresh.handles.addAll(handles);
            fresh.handles.applyToDb();
          }
        }
      }
      foldServiceTwinsObjectBox(chatsToSave);
      return (chatIds: chatsToSave.map((e) => e.id!).toList(), brandNewHandleIds: brandNewHandleIds);
    });
  }

  @override
  Future<void> linkContactToHandle(ContactV2 contact, int handleId) async {
    Database.runInTransaction(TxMode.write, () {
      final handle = Database.handles.get(handleId);
      if (handle == null) return;
      contact.handles.add(handle);
      Database.contactsV2.put(contact);
    });
  }

  @override
  Future<List<int>> messagePageIds(
    int chatId,
    List<Handle> participants, {
    required int offset,
    required int limit,
    required bool includeDeleted,
  }) async {
    return Database.runInTransaction(TxMode.read,
        () => _messagePage(chatId, participants, offset: offset, limit: limit, includeDeleted: includeDeleted).ids);
  }

  /// Today's search-result query: [limit] messages created before and after
  /// the target's created date, with the target itself.
  @override
  Future<MessagePage> messagePageAround(int chatId, List<Handle> participants, int aroundId, {required int limit}) async {
    final ids = Database.runInTransaction(TxMode.read, () {
      final target = Database.messages.get(aroundId);
      final created = target?.dateCreated?.millisecondsSinceEpoch;
      if (target == null || created == null) return <int>[];
      final live = Message_.dateDeleted.isNull().and(Message_.dateCreated.notNull());
      final before = (Database.messages.query(Message_.dateCreated.lessThan(created).and(live))
            ..link(Message_.chat, Chat_.id.equals(chatId))
            ..order(Message_.dateCreated, flags: Order.descending))
          .build()
        ..limit = limit;
      final after = (Database.messages.query(Message_.dateCreated.greaterThan(created).and(live))
            ..link(Message_.chat, Chat_.id.equals(chatId))
            ..order(Message_.dateCreated))
          .build()
        ..limit = limit;
      try {
        final messages = [...after.find(), target, ...before.find()]..sort(Message.sort);
        return _placeable(messages, participants).map((e) => e.id!).toList();
      } finally {
        before.close();
        after.close();
      }
    });
    return (ids: ids, next: const MessagePageCursor.objectBox());
  }

  @override
  Future<MessagePage> olderMessagePage(
    int chatId,
    List<Handle> participants, {
    MessagePageCursor? after,
    required int loadedRows,
    required int limit,
  }) async {
    final page = Database.runInTransaction(
      TxMode.read,
      () => _messagePage(chatId, participants, offset: after == null ? 0 : loadedRows, limit: limit, includeDeleted: false),
    );
    return (ids: page.ids, next: page.rows == 0 ? after : const MessagePageCursor.objectBox());
  }

  /// Today's chat-screen query: [limit] rows of [chatId] from [offset], newest
  /// created first, reactions included; [rows] counts them before
  /// [_placeable] drops any.
  ({List<int> ids, int rows}) _messagePage(
    int chatId,
    List<Handle> participants, {
    required int offset,
    required int limit,
    required bool includeDeleted,
  }) {
    final query = (Database.messages.query(includeDeleted
            ? Message_.dateCreated.notNull().and(Message_.dateDeleted.isNull().or(Message_.dateDeleted.notNull()))
            : Message_.dateDeleted.isNull().and(Message_.dateCreated.notNull()))
          ..link(Message_.chat, Chat_.id.equals(chatId))
          ..order(Message_.dateCreated, flags: Order.descending))
        .build()
      ..limit = limit
      ..offset = offset;
    final messages = query.find();
    query.close();
    return (ids: _placeable(messages, participants).map((e) => e.id!).toList(), rows: messages.length);
  }

  /// [messages] without those from a sender this chat can't place.
  List<Message> _placeable(List<Message> messages, List<Handle> participants) {
    final result = [...messages];
    for (var i = 0; i < result.length; i++) {
      final message = result[i];
      if (participants.isNotEmpty && !message.isFromMe! && message.handleId != null && message.handleId != 0) {
        final handle = participants.firstWhereOrNull((e) => e.originalROWID == message.handleId) ?? message.getHandle();
        if (handle == null && message.originalROWID != null) {
          result.removeAt(i--);
        }
      }
    }
    return result;
  }

  @override
  Future<List<Message>> searchMessages(String term,
      {int? chatId, bool? isFromMe, int? senderRowId, DateTime? since, int limit = 50}) async {
    var condition = Message_.text
        .contains(term, caseSensitive: false)
        .and(Message_.associatedMessageGuid.isNull())
        .and(Message_.dateDeleted.isNull())
        .and(Message_.dateCreated.notNull());
    if (isFromMe != null) condition = condition.and(Message_.isFromMe.equals(isFromMe));
    if (senderRowId != null) condition = condition.and(Message_.handleId.equals(senderRowId));
    if (since != null) condition = condition.and(Message_.dateCreated.greaterOrEqual(since.millisecondsSinceEpoch));

    final builder = Database.messages.query(condition);
    if (chatId != null) builder.link(Message_.chat, Chat_.id.equals(chatId));
    final query = (builder..order(Message_.dateCreated, flags: Order.descending)).build()..limit = limit;
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  @override
  Future<List<Chat>> chatsByGuids(List<String> guids) async {
    final query = Database.chats.query(Chat_.guid.oneOf(guids)).build();
    try {
      final byGuid = {for (final chat in query.find()) chat.guid: chat};
      return [for (final guid in guids) ?byGuid[guid]];
    } finally {
      query.close();
    }
  }

  @override
  Future<List<Message>> linkMessages(int chatId) async {
    final query = (Database.messages.query(Message_.dateDeleted.isNull() &
            Message_.dbPayloadData.notNull() &
            Message_.balloonBundleId.contains("URLBalloonProvider"))
          ..link(Message_.chat, Chat_.id.equals(chatId))
          ..order(Message_.dateCreated, flags: Order.descending))
        .build();
    try {
      return await query.findAsync();
    } finally {
      query.close();
    }
  }

  @override
  Future<List<Message>> bookmarkedMessages(int chatId) async {
    final query = (Database.messages.query(Message_.isBookmarked.equals(true))
          ..link(Message_.chat, Chat_.id.equals(chatId))
          ..order(Message_.dateCreated, flags: Order.descending))
        .build();
    try {
      final messages = query.find();
      for (final m in messages) {
        m.dbAttachments.length;
      }
      return messages;
    } finally {
      query.close();
    }
  }

  /// Today's count: the index among the chat's live rows, newest created first,
  /// as ObjectBox's page-by-position scrolling reaches them.
  @override
  Future<int?> timelinePosition(int chatId, int messageId) async {
    final query = (Database.messages.query(Message_.dateDeleted.isNull().and(Message_.dateCreated.notNull()))
          ..link(Message_.chat, Chat_.id.equals(chatId))
          ..order(Message_.dateCreated, flags: Order.descending))
        .build();
    try {
      final pos = (await query.findIdsAsync()).indexOf(messageId);
      return pos < 0 ? null : pos;
    } finally {
      query.close();
    }
  }

  @override
  Future<List<int>> participantIds(int chatId) async {
    return Database.runInTransaction(TxMode.read, () {
      final query = Database.chats.query(Chat_.id.equals(chatId)).build();
      final chat = query.findFirst();
      query.close();
      return chat == null ? <int>[] : chat.handles.map((e) => e.id!).toList();
    });
  }

  @override
  Future<List<Attachment>> chatAttachments(int chatId) async {
    final messageQuery = (Database.messages.query(Message_.dateDeleted.isNull().and(Message_.dateCreated.notNull()))
          ..link(Message_.chat, Chat_.id.equals(chatId)))
        .build();
    final messageIds = messageQuery.findIds();
    messageQuery.close();
    if (messageIds.isEmpty) return [];
    final attachmentQuery = (Database.attachments.query(Attachment_.mimeType.notNull())
          ..link(Attachment_.message, Message_.id.oneOf(messageIds)))
        .build();
    final attachments = attachmentQuery.find();
    attachmentQuery.close();
    final guids = <String?>{};
    return attachments.where((a) => guids.add(a.guid)).toList();
  }

  @override
  Future<void> clearTranscript(int chatId) async {
    Database.runInTransaction(TxMode.write, () {
      final query = Database.chats.query(Chat_.id.equals(chatId)).build();
      final chat = query.findFirst();
      query.close();
      if (chat == null) return;
      final messages = List<Message>.from(chat.messages);
      final now = DateTime.now().toUtc();
      for (final message in messages) {
        message.dateDeleted = now;
      }
      Database.messages.putMany(messages);
    });
  }

  @override
  Future<List<int>> chatPageIds({required int limit, required int offset, required List<int> ids}) async {
    return Database.runInTransaction(TxMode.read, () {
      final builder = ids.isNotEmpty
          ? Database.chats.query(Chat_.id.oneOf(ids))
          : (Database.chats.query(Chat_.dateDeleted.isNull())
            ..order(Chat_.dbOnlyLatestMessageDate, flags: Order.descending));
      final query = builder.build()
        ..limit = limit
        ..offset = offset;
      final chats = query.find();
      query.close();
      return chats.map((e) => e.id!).toList();
    });
  }
  /// Chat ids only grow, so a chat is new when its id is above every id stored
  /// when the stream started or emitted since (the same rule as SQLite; the
  /// former live-count rule missed a new chat whenever a delete landed in the
  /// same notification).
  @override
  Stream<List<Chat>> chatsWritten() {
    int? newest;
    return Database.chats.query().watch(triggerImmediately: true).map((_) {
      final query = (Database.chats.query(Chat_.id.greaterThan(newest ?? 0).and(Chat_.dateDeleted.isNull()))
            ..order(Chat_.id))
          .build();
      final chats = newest == null ? const <Chat>[] : query.find();
      query.close();
      final maxQuery = (Database.chats.query()..order(Chat_.id, flags: Order.descending)).build()..limit = 1;
      newest = maxQuery.findIds().firstOrNull ?? 0;
      maxQuery.close();
      return chats;
    }).where((chats) => chats.isNotEmpty);
  }

  @override
  ChatStatsReader chatStats(Chat chat) => _ObjectBoxChatStats(chat);

  @override
  Future<int> chatCount() async => Database.chats.count();

  @override
  Future<List<Chat>> threadedChats() async {
    final query = Database.chats.query(Chat_.threadKey.notNull()).build();
    final chats = query.find();
    query.close();
    return chats;
  }

  @override
  Future<Message?> newestMessageIn(int chatId, {bool listing = true}) async {
    final live = Message_.dateDeleted.isNull().and(Message_.dateCreated.notNull());
    final query = (Database.messages.query(listing ? live.and(listsThreadCondition) : live)
          ..link(Message_.chat, Chat_.id.equals(chatId))
          ..order(Message_.dateCreated, flags: Order.descending))
        .build();
    query.limit = 1;
    try {
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  List<Chat> _storedThread(String? key) {
    if (key == null || key.isEmpty) return const [];
    final query = Database.chats.query(Chat_.threadKey.equals(key)).build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  @override
  Future<List<Chat>> threadChatsOf(Chat chat) async {
    final chats = _storedThread(chat.threadKey).where((c) => c.dateDeleted == null).toList();
    return chats.any((c) => c.guid == chat.guid) ? chats : [chat, ...chats];
  }

  @override
  Future<List<String>> threadGuidsToMarkRead(String guid) async {
    final chat = Chat.findOne(guid: guid);
    return guidsToMarkRead(guid, chat == null ? const [] : _storedThread(chat.threadKey));
  }

  @override
  Future<String?> threadNameOf(Chat chat) async {
    final key = chat.threadKey;
    if (key == null || key.isEmpty || chat.id == null) return chat.currentName;
    final copies = _storedThread(key).where((c) => c.dateDeleted == null).toList();
    if (copies.length < 2) return chat.currentName;
    Message? newestRename;
    if ({for (final c in copies) c.latestGroupTitle}.whereType<String>().length > 1) {
      final query = (Database.messages.query(Message_.itemType.equals(2))
            ..link(Message_.chat, Chat_.id.equals(chat.id!))
            ..order(Message_.dateCreated, flags: Order.descending))
          .build();
      query.limit = 1;
      try {
        newestRename = query.findFirst();
      } finally {
        query.close();
      }
    }
    return threadName(chat, copies, newestRename: newestRename);
  }

  @override
  Future<Chat?> canonicalTwinOf(Chat chat) async {
    final key = chat.threadKey;
    if (key == null || key.isEmpty) return null;
    final query = Database.chats.query(Chat_.threadKey.equals(key)).build();
    final copies = query.find();
    query.close();
    return canonicalTwinFor(chat, copies);
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

bool _tryUpdateLastMessage(Chat chat, Message? lastMessage, bool toggleUnread) {
  if (lastMessage == null || lastMessage.dateCreated == null) return false;
  var didUpdate = false;
  var checkMessageText = false;
  final currentMs = chat.dbOnlyLatestMessageDate?.millisecondsSinceEpoch ?? 0;
  final lastMs = lastMessage.dateCreated!.millisecondsSinceEpoch;
  if (currentMs <= lastMs) {
    didUpdate = true;
    if (currentMs == lastMs) checkMessageText = true;
  }
  if (didUpdate && checkMessageText &&
      (chat.dbLatestMessage.target?.getNotificationText() ?? '') == lastMessage.getNotificationText()) {
    didUpdate = false;
  }
  if (didUpdate) {
    chat.setLatestMessage(lastMessage);
    if (toggleUnread && !(lastMessage.isFromMe ?? false)) chat.toggleHasUnreadAsync(true);
  }
  return didUpdate;
}

/// [ChatStatsReader] over ChatStatsQueries, each read scheduled between frames
/// as the stats screen did before.
class _ObjectBoxChatStats implements ChatStatsReader {
  _ObjectBoxChatStats(this.chat);

  final Chat chat;

  @override
  Future<int> messageCountForTier() =>
      runAsync(() => ChatStatsQueries.messageCountForTier(chat));

  @override
  Future<({int count, int latestMillis})> cacheKey() =>
      runAsync(() => ChatStatsQueries.cacheKey(chat));

  @override
  Future<Map<int, List<int>>> timestampsByParticipant({int? sinceMillis}) =>
      runAsync(() => ChatStatsQueries.timestampsByParticipant(chat, sinceMillis: sinceMillis));

  @override
  Future<int> attachmentMessageCount({int? sinceMillis}) =>
      runAsync(() => ChatStatsQueries.attachmentMessageCount(chat, sinceMillis: sinceMillis));

  @override
  Future<int> unattributedCount({int? sinceMillis}) =>
      runAsync(() => ChatStatsQueries.unattributedCount(chat, sinceMillis: sinceMillis));

  @override
  Future<int?> firstMessageMillis() =>
      runAsync(() => ChatStatsQueries.firstMessageMillis(chat));

  @override
  Future<List<int>> readTimestamps({int? sinceMillis}) =>
      runAsync(() => ChatStatsQueries.readTimestamps(chat, sinceMillis: sinceMillis));

  @override
  Future<double> textCoverage() =>
      runAsync(() => ChatStatsQueries.textCoverage(chat));

  @override
  Future<List<String>> recentTexts({required bool fromMe, int? limit, int? participantId}) =>
      runAsync(() => ChatStatsQueries.recentTexts(chat, fromMe: fromMe, limit: limit, participantId: participantId));

  @override
  Future<Map<int, List<int>>> textLengthsByParticipant({int? sinceMillis, int? limitPerParticipant}) =>
      runAsync(() => ChatStatsQueries.textLengthsByParticipant(chat, sinceMillis: sinceMillis, limitPerParticipant: limitPerParticipant));

  @override
  Future<List<({String type, int participantId})>> reactions() =>
      runAsync(() => ChatStatsQueries.reactions(chat));

  @override
  Future<List<String>> attachmentMimeTypes() =>
      runAsync(() => ChatStatsQueries.attachmentMimeTypes(chat));

  @override
  Future<List<String>> expressiveSendStyleIds() =>
      runAsync(() => ChatStatsQueries.expressiveSendStyleIds(chat));

  @override
  Future<int> editedCount({bool? fromMe, int? participantId}) =>
      runAsync(() => ChatStatsQueries.editedCount(chat, fromMe: fromMe, participantId: participantId));

  @override
  Future<int> unsentCount({bool? fromMe, int? participantId}) =>
      runAsync(() => ChatStatsQueries.unsentCount(chat, fromMe: fromMe, participantId: participantId));

  @override
  Future<int> sentCount() =>
      runAsync(() => ChatStatsQueries.sentCount(chat));

  @override
  Future<int> receivedCount({int? participantId}) =>
      runAsync(() => ChatStatsQueries.receivedCount(chat, participantId: participantId));

  @override
  Future<({int sent, int received, double? playedOfReceived})> audioStats() =>
      runAsync(() => ChatStatsQueries.audioStats(chat));

  @override
  Future<List<GroupEventRecord>> groupEvents() =>
      runAsync(() => ChatStatsQueries.groupEvents(chat));

  @override
  Future<({List<ReactionMatrixRow> reactionRows, Map<String, int> guidToSender})> reactionMatrixData({required int sinceMillis}) =>
      runAsync(() => ChatStatsQueries.reactionMatrixData(chat, sinceMillis: sinceMillis));

  @override
  Future<List<int>> participantHandleIds({int? sinceMillis}) =>
      runAsync(() => ChatStatsQueries.participantHandleIds(chat, sinceMillis: sinceMillis));
}
