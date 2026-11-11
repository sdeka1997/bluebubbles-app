import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/env.dart';
import 'package:bluebubbles/services/backend/actions/chat_actions.dart';
import 'package:bluebubbles/models/models.dart' show MessageSaveResult;
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:bluebubbles/services/isolates/global_isolate.dart';

class ChatInterface {
  static Future<void> clearNotificationForChat({
    required int chatId,
    required String chatGuid,
  }) async {
    final data = {
      'chatId': chatId,
      'chatGuid': chatGuid,
    };

    if (isIsolate) {
      return await ChatActions.clearNotificationForChat(data);
    } else if (!LifecycleSvc.isBubble) {
      return await GetIt.I<GlobalIsolate>().send<void>(IsolateRequestType.clearNotificationForChat, input: data);
    }
  }

  static Future<void> markAllChatsRead({
    required List<int> chatIds,
    required bool shouldMarkOnServer,
  }) async {
    final data = {
      'chatIds': chatIds,
      'shouldMarkOnServer': shouldMarkOnServer,
    };
    if (isIsolate) {
      return await ChatActions.markAllChatsRead(data);
    } else {
      return await GetIt.I<GlobalIsolate>().send<void>(IsolateRequestType.markAllChatsRead, input: data);
    }
  }

  static Future<void> markChatReadUnread({
    required String chatGuid,
    required bool markAsRead,
    required bool shouldMarkOnServer,
  }) async {
    final Map<String, dynamic> data = {
      'chatGuid': chatGuid,
      'markAsRead': markAsRead,
      'shouldMarkOnServer': shouldMarkOnServer,
    };

    if (isIsolate) {
      return await ChatActions.markChatReadUnread(data);
    } else {
      return await GetIt.I<GlobalIsolate>().send<void>(IsolateRequestType.markChatReadUnread, input: data);
    }
  }

  static Future<void> startTyping({required String chatGuid}) async {
    final data = {'chatGuid': chatGuid};
    if (isIsolate || kIsWeb) {
      return await ChatActions.startTyping(data);
    } else {
      return await GetIt.I<GlobalIsolate>().send<void>(IsolateRequestType.startTyping, input: data);
    }
  }

  static Future<void> stopTyping({required String chatGuid}) async {
    final data = {'chatGuid': chatGuid};
    if (isIsolate || kIsWeb) {
      return await ChatActions.stopTyping(data);
    } else {
      return await GetIt.I<GlobalIsolate>().send<void>(IsolateRequestType.stopTyping, input: data);
    }
  }

  static Future<int?> saveChat({
    required String guid,
    required Map<String, dynamic> chatData,
    required Map<String, bool> updateFlags,
  }) async {
    final data = {
      'guid': guid,
      'chatData': chatData,
      'updateFlags': updateFlags,
    };

    if (isIsolate) {
      return await ChatActions.saveChat(data);
    } else {
      return await GetIt.I<GlobalIsolate>().send<int?>(IsolateRequestType.saveChat, input: data);
    }
  }

  static Future<void> deleteChat({
    required int chatId,
    required List<int> messageIds,
    List<int> handleIds = const [],
  }) async {
    final data = {
      'chatId': chatId,
      'messageIds': messageIds,
      'handleIds': handleIds,
    };

    if (isIsolate) {
      return await ChatActions.deleteChat(data);
    } else {
      return await GetIt.I<GlobalIsolate>().send<void>(IsolateRequestType.deleteChat, input: data);
    }
  }

  static Future<void> softDeleteChat({
    required Map<String, dynamic> chatData,
  }) async {
    final data = {
      'chatData': chatData,
    };

    if (isIsolate) {
      return await ChatActions.softDeleteChat(data);
    } else {
      return await GetIt.I<GlobalIsolate>().send<void>(IsolateRequestType.softDeleteChat, input: data);
    }
  }

  static Future<void> unDeleteChat({
    required Map<String, dynamic> chatData,
  }) async {
    final data = {
      'chatData': chatData,
    };

    if (isIsolate) {
      return await ChatActions.unDeleteChat(data);
    } else {
      return await GetIt.I<GlobalIsolate>().send<void>(IsolateRequestType.unDeleteChat, input: data);
    }
  }

  static Future<MessageSaveResult> addMessageToChat({
    required Map<String, dynamic> messageData,
    List<Map<String, dynamic>> attachmentsData = const [],
    required Map<String, dynamic> chatData,
    required Map<String, dynamic> latestMessageData,
    required bool checkForMessageText,
  }) async {
    final data = {
      'messageData': messageData,
      'attachmentsData': attachmentsData,
      'chatData': chatData,
      'latestMessageData': latestMessageData,
      'checkForMessageText': checkForMessageText,
    };

    late Map<String, dynamic> result;
    if (isIsolate) {
      result = await ChatActions.addMessageToChat(data);
    } else {
      result =
          await GetIt.I<GlobalIsolate>().send<Map<String, dynamic>>(IsolateRequestType.addMessageToChat, input: data);
    }

    final messageId = result['messageId'] as int?;
    final isNewer = result['isNewer'] as bool? ?? false;

    Message? message;
    if (messageId != null) {
      message = await MessagingStore.current.messageById(messageId);
    }

    // Fallback: resolve by GUID when a put collided / retried and ID is absent
    // or stale by the time we hydrate on this isolate.
    if (message == null) {
      Logger.warn('[addMessageToChat] Message ID was null or not found, attempting to resolve by GUID');
      final guid = messageData['guid'] as String?;
      if (guid != null) {
        message = await MessagingStore.current.messageByGuid(guid);
        if (message != null) {
          Logger.info('[addMessageToChat] Successfully resolved message by GUID');
        } else {
          Logger.error('[addMessageToChat] Failed to resolve message by GUID: $guid');
        }
      }
    }

    // Last resort: keep pipeline moving and let downstream save/reload logic
    // reconcile this object without crashing on a null force-unwrap.
    message ??= Message.fromMap(messageData);

    return MessageSaveResult(message, isNewer);
  }

  static Future<({List<Chat> chats, List<int> affectedHandleIds})> bulkSyncChats(
      {required List<Map<String, dynamic>> chatsData}) async {
    final data = {
      'chatsData': chatsData,
    };

    late List<int> chatIds;
    late List<int> affectedHandleIds;
    if (isIsolate) {
      final result = await ChatActions.bulkSyncChats(data);
      chatIds = (result['chatIds'] as List).cast<int>();
      affectedHandleIds = (result['affectedHandleIds'] as List).cast<int>();
    } else {
      final result =
          await GetIt.I<GlobalIsolate>().send<Map<String, dynamic>>(IsolateRequestType.bulkSyncChats, input: data);
      chatIds = (result['chatIds'] as List).cast<int>();
      affectedHandleIds = (result['affectedHandleIds'] as List).cast<int>();
    }

    final chats = await MessagingStore.current.chatsByIds(chatIds);
    return (chats: chats, affectedHandleIds: affectedHandleIds);
  }

  static Future<List<Handle>> getParticipantsAsync({
    required int chatId,
    required String chatGuid,
  }) async {
    final data = {
      'chatId': chatId,
      'chatGuid': chatGuid,
    };

    late List<int> handleIds;
    if (isIsolate) {
      handleIds = await ChatActions.getParticipantsAsync(data);
    } else {
      handleIds = await GetIt.I<GlobalIsolate>().send<List<int>>(IsolateRequestType.getParticipantsAsync, input: data);
    }

    return MessagingStore.current.handlesByIds(handleIds);
  }

  static Future<void> clearTranscriptAsync({
    required int chatId,
    required String chatGuid,
  }) async {
    final data = {
      'chatId': chatId,
      'chatGuid': chatGuid,
    };

    if (isIsolate) {
      return await ChatActions.clearTranscriptAsync(data);
    } else {
      return await GetIt.I<GlobalIsolate>().send<void>(IsolateRequestType.clearTranscriptAsync, input: data);
    }
  }

  static Future<List<Chat>> getChatsAsync({
    int limit = 15,
    int offset = 0,
    List<int> ids = const [],
  }) async {
    final data = {
      'limit': limit,
      'offset': offset,
      'ids': ids,
    };

    late List<int> chatIds;
    if (isIsolate) {
      chatIds = await ChatActions.getChatsAsync(data);
    } else {
      chatIds = await GetIt.I<GlobalIsolate>().send<List<int>>(IsolateRequestType.getChatsAsync, input: data);
    }

    return MessagingStore.current.chatsByIds(chatIds);
  }
}
