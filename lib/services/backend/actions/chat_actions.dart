import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/helpers/types/helpers/service_twin_helpers.dart' show findGuidsToMarkRead;
import 'package:bluebubbles/services/backend/interfaces/contact_v2_interface.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

class ChatActions {
  static Future<void> clearNotificationForChat(dynamic data) async {
    if (kIsDesktop || kIsWeb) return;
    final chatId = data['chatId'] as int;
    await MethodChannelSvc.actions.deleteNotification(notificationId: chatId, tag: 'new_message');
  }

  static Future<void> markAllChatsRead(dynamic data) async {
    final chatIds = (data['chatIds'] as List).cast<int>();
    final shouldMarkOnServer = data['shouldMarkOnServer'] as bool;
    final chats = await MessagingStore.current.markChatsRead(chatIds);

    if (shouldMarkOnServer &&
        SettingsSvc.settings.enablePrivateAPI.value &&
        SettingsSvc.settings.privateMarkChatAsRead.value) {
      for (final chat in chats) {
        for (final guid in findGuidsToMarkRead(chat.guid)) {
          await HttpSvc.chat.markRead(guid);
        }
      }
    }
  }

  static Future<void> markChatReadUnread(dynamic data) async {
    final chatGuid = data['chatGuid'] as String;
    final markAsRead = data['markAsRead'] as bool;
    final shouldMarkOnServer = data['shouldMarkOnServer'] as bool;
    if (shouldMarkOnServer && SettingsSvc.settings.enablePrivateAPI.value) {
      for (final guid in findGuidsToMarkRead(chatGuid)) {
        if (markAsRead) {
          await HttpSvc.chat.markRead(guid);
        } else {
          await HttpSvc.chat.markUnread(guid);
        }
      }
    }
  }

  static Future<void> startTyping(dynamic data) async => HttpSvc.chat.startTyping(data['chatGuid'] as String);

  static Future<void> stopTyping(dynamic data) async => HttpSvc.chat.stopTyping(data['chatGuid'] as String);

  static Future<int?> saveChat(dynamic data) async {
    final chatData = data['chatData'] as Map<String, dynamic>;
    final latestDateMs = chatData['dbOnlyLatestMessageDate'] as int?;
    return MessagingStore.current.saveChat(
      data['guid'] as String,
      Chat.fromMap(chatData),
      (data['updateFlags'] as Map).cast<String, bool>(),
      latestMessageId: chatData['dbLatestMessageId'] as int?,
      latestMessageDate: latestDateMs == null ? null : DateTime.fromMillisecondsSinceEpoch(latestDateMs),
    );
  }

  static Future<void> deleteChat(dynamic data) => MessagingStore.current.deleteChat(
        data['chatId'] as int,
        (data['messageIds'] as List).cast<int>(),
        (data['handleIds'] as List? ?? []).cast<int>(),
      );

  static Future<void> softDeleteChat(dynamic data) {
    final chat = Chat.fromMap(data['chatData'] as Map<String, dynamic>);
    return MessagingStore.current.softDeleteChat(chat.guid);
  }

  static Future<void> unDeleteChat(dynamic data) {
    final chat = Chat.fromMap(data['chatData'] as Map<String, dynamic>);
    return MessagingStore.current.unDeleteChat(chat.guid);
  }

  static Future<Map<String, dynamic>> addMessageToChat(dynamic data) {
    final attachmentsData = ((data['attachmentsData'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    return MessagingStore.current.addMessageToChat(
      Message.fromMap(data['messageData'] as Map<String, dynamic>),
      attachmentsData.map(Attachment.fromMap).toList(),
      Chat.fromMap(data['chatData'] as Map<String, dynamic>),
      Message.fromMap(data['latestMessageData'] as Map<String, dynamic>),
      checkForMessageText: data['checkForMessageText'] as bool,
    );
  }

  static Future<List<int>> loadSupplementalData(dynamic data) =>
      MessagingStore.current.supplementalMessageIds((data['messageGuids'] as List).cast<String>());

  static Future<List<int>> syncLatestMessages(dynamic data) => MessagingStore.current.syncLatestMessages(
        (data['chatGuids'] as List).cast<String>(),
        toggleUnread: data['toggleUnread'] as bool,
      );

  static Future<Map<String, dynamic>> bulkSyncChats(dynamic data) async {
    final chatsData = (data['chatsData'] as List).cast<Map<String, dynamic>>();
    final inputChats = chatsData.map(Chat.fromMap).toList();
    final inputHandles = <String, Handle>{};

    for (final chat in inputChats) {
      if (chat.participants.isNotEmpty) {
        for (final participant in chat.participants) {
          inputHandles.putIfAbsent(participant.uniqueAddressAndService, () => participant);
        }
      } else if (chat.guid.contains(';-;')) {
        final address = chat.guid.split(';-;').lastOrNull;
        if (address != null) {
          final handle = await MessagingStore.current.handleByAddress(address);
          if (handle != null) inputHandles[handle.uniqueAddressAndService] = handle;
        }
      }
    }

    // Formatting can call platform code; it must stay outside Db.write.
    for (final handle in inputHandles.values) {
      await handle.updateFormattedAddress();
    }

    final result = await MessagingStore.current.bulkSyncChats(inputChats, inputHandles);
    final affectedHandleIds = <int>[];
    for (final handleId in result.brandNewHandleIds) {
      final handle = await MessagingStore.current.handleById(handleId);
      if (handle == null) continue;
      final contact = await ContactV2Interface.getContactByAddress(address: handle.address);
      if (contact == null) continue;
      await MessagingStore.current.linkContactToHandle(contact, handleId);
      affectedHandleIds.add(handleId);
      Logger.info(
        'Linked new handle ${handle.address} to contact ${contact.computedDisplayName}',
        tag: 'ChatActions',
      );
    }

    return {'chatIds': result.chatIds, 'affectedHandleIds': affectedHandleIds};
  }

  static Future<List<int>> getMessagesAsync(dynamic data) {
    final participants = (data['participantsData'] as List)
        .cast<Map<String, dynamic>>()
        .map(Handle.fromMap)
        .toList();
    return MessagingStore.current.messagePageIds(
      data['chatId'] as int,
      participants,
      offset: data['offset'] as int? ?? 0,
      limit: data['limit'] as int? ?? 25,
      includeDeleted: data['includeDeleted'] as bool? ?? false,
      searchAround: data['searchAround'] as int?,
    );
  }

  static Future<List<int>> getParticipantsAsync(dynamic data) =>
      MessagingStore.current.participantIds(data['chatId'] as int);

  static Future<void> clearTranscriptAsync(dynamic data) =>
      MessagingStore.current.clearTranscript(data['chatId'] as int);

  static Future<List<int>> getChatsAsync(dynamic data) => MessagingStore.current.chatPageIds(
        limit: data['limit'] as int? ?? 15,
        offset: data['offset'] as int? ?? 0,
        ids: (data['ids'] as List?)?.cast<int>() ?? const <int>[],
      );
}
