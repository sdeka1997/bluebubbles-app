import 'package:flutter/foundation.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';

import 'package:bluebubbles/helpers/types/helpers/chat_list_message.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/interfaces/chat_interface.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/utils/memory_trace.dart';

/// A validated `message-deleted` / `message-restored` event.
class RecoverableMessageEvent {
  const RecoverableMessageEvent({
    required this.chatGuid,
    required this.messageGuid,
    required this.deleted,
  });

  final String chatGuid;
  final String messageGuid;

  /// True for `message-deleted`, false for `message-restored`.
  final bool deleted;
}

/// Validates a live Recently Deleted event payload.
///
/// Returns null for anything malformed. Both GUIDs are required: acting on a
/// half-formed event would either hide the wrong message or hide nothing while
/// reporting success.
RecoverableMessageEvent? parseRecoverableMessageEvent(dynamic data, {required bool deleted}) {
  if (data is! Map) return null;

  final chatGuid = data['chatGuid'];
  final messageGuid = data['messageGuid'];
  if (chatGuid is! String || chatGuid.isEmpty) return null;
  if (messageGuid is! String || messageGuid.isEmpty) return null;

  return RecoverableMessageEvent(chatGuid: chatGuid, messageGuid: messageGuid, deleted: deleted);
}

/// What Apple reports right now, for a client that was offline when it changed.
class AppleStateSnapshot {
  const AppleStateSnapshot({this.readByChat = const {}, this.deletedMessages = const {}, this.deletedChats = const {}});

  /// Each chat's read state.
  final Map<String, bool> readByChat;

  /// Messages in Recently Deleted whose chat still has other messages.
  final Set<String> deletedMessages;

  /// Chats whose messages are all in Recently Deleted: the chat was deleted whole.
  final Set<String> deletedChats;
}

/// Parses the two catch-up responses. Malformed entries are skipped; a
/// response that is missing altogether contributes nothing.
AppleStateSnapshot parseAppleStateSnapshot({dynamic chatState, dynamic recentlyDeleted}) {
  final readByChat = <String, bool>{};
  final chats = chatState is Map ? chatState['chats'] : null;
  for (final chat in chats is List ? chats : const []) {
    if (chat is! Map) continue;
    final guid = chat['guid'];
    final read = chat['read'];
    if (guid is String && guid.isNotEmpty && read is bool) readByChat[guid] = read;
  }

  final deletedMessages = <String>{};
  final deletedChats = <String>{};
  final groups = recentlyDeleted is Map ? recentlyDeleted['chats'] : null;
  for (final group in groups is List ? groups : const []) {
    if (group is! Map) continue;
    final guid = group['guid'];
    final hasMessages = group['hasMessages'];
    final messages = group['deletedMessageGuids'];
    if (guid is! String || guid.isEmpty || hasMessages is! bool || messages is! List) continue;
    if (hasMessages) {
      deletedMessages.addAll(messages.whereType<String>().where((m) => m.isNotEmpty));
    } else {
      deletedChats.add(guid);
    }
  }

  return AppleStateSnapshot(readByChat: readByChat, deletedMessages: deletedMessages, deletedChats: deletedChats);
}

/// What a catch-up has to do on this device, worked out before anything is written.
class AppleStateCatchUpPlan {
  const AppleStateCatchUpPlan({
    this.deleteChats = const [],
    this.readStateChanges = const {},
    this.clearNotificationFor = const [],
  });

  /// Chats Apple deleted whole.
  final List<Chat> deleteChats;

  /// Chats whose read state differs from Apple's, mapped to whether they should be unread.
  final Map<Chat, bool> readStateChanges;

  /// Chats already read here that still have a notification showing.
  final List<Chat> clearNotificationFor;
}

/// Compares this device's chats with Apple's state. [shownNotificationIds] are the
/// chat notifications Android is showing (each is posted under its chat's id); null
/// when they could not be read, which falls back to clearing every read chat.
///
/// Nearly every chat is read on both sides with nothing showing, so nearly every
/// chat needs nothing: asking Android to clear ~1,800 notifications one at a time
/// took ~10 s on every app open.
AppleStateCatchUpPlan planAppleStateCatchUp(
  Iterable<Chat> chats,
  AppleStateSnapshot snapshot, {
  required Set<int>? shownNotificationIds,
}) {
  final deleteChats = <Chat>[];
  final readStateChanges = <Chat, bool>{};
  final clearNotificationFor = <Chat>[];
  for (final chat in chats) {
    if (snapshot.deletedChats.contains(chat.guid)) {
      deleteChats.add(chat);
      continue;
    }
    final read = snapshot.readByChat[chat.guid];
    if (read == null) continue;
    if ((chat.hasUnreadMessage ?? false) == read) {
      readStateChanges[chat] = !read;
    } else if (read && (shownNotificationIds == null || shownNotificationIds.contains(chat.id))) {
      // Already read here, but a notification posted before the read arrived may still be up.
      clearNotificationFor.add(chat);
    }
  }
  return AppleStateCatchUpPlan(
    deleteChats: deleteChats,
    readStateChanges: readStateChanges,
    clearNotificationFor: clearNotificationFor,
  );
}

/// Brings the device in line with Apple after it was offline.
///
/// The live `chat-read-status-changed`, `message-deleted` and `chat-deleted`
/// events only reach a connected device. This fetches what Apple reports now
/// and applies it through the same paths the live events use. It only ever
/// hides and never restores: a hidden message may have been deleted by the
/// user on this device, and only the live `message-restored` event says Apple
/// put it back.
class AppleStateCatchUp {
  static Future<void> run() async {
    if (kIsWeb) return;
    try {
      final chatState = await HttpSvc.server.chatStateSnapshot();
      final recentlyDeleted = await HttpSvc.server.getRecoverableMessageSnapshot().then<dynamic>(
            (response) => response.data['data'],
            // Recently Deleted needs Ventura; older servers still catch up read state.
            onError: (_) => null,
          );
      await apply(parseAppleStateSnapshot(chatState: chatState.data['data'], recentlyDeleted: recentlyDeleted));
    } catch (error, trace) {
      // A correction pass, not a sync: an older server without the endpoint is normal.
      Logger.warn('Could not catch up with Apple', error: error, trace: trace, tag: 'AppleStateCatchUp');
    }
  }

  static Future<void> apply(AppleStateSnapshot snapshot) async {
    var changed = 0;
    final plan = planAppleStateCatchUp(ChatsSvc.allChats.toList(), snapshot,
        shownNotificationIds: await NotificationsSvc.shownChatNotificationIds());
    MemTrace.mark('catch-up: planned (${plan.deleteChats.length} deleted, '
        '${plan.readStateChanges.length} read changes, ${plan.clearNotificationFor.length} notifications)');
    for (final chat in plan.deleteChats) {
      await ChatsSvc.softDeleteChat(chat);
      changed++;
    }
    MemTrace.mark('catch-up: deleted chats');
    for (final entry in plan.readStateChanges.entries) {
      await ChatsSvc.setChatHasUnreadFromServer(entry.key, entry.value);
      changed++;
    }
    for (final chat in plan.clearNotificationFor) {
      await ChatInterface.clearNotificationForChat(chatId: chat.id!, chatGuid: chat.guid);
    }
    MemTrace.mark('catch-up: read state applied');

    for (final guid in snapshot.deletedMessages) {
      final message = await MessagingStore.current.messageByGuid(guid);
      if (message == null || message.dateDeleted != null) continue;
      await RecoverableMessages.apply(guid, hide: true);
      changed++;
    }
    MemTrace.mark('catch-up: deleted messages hidden');

    if (changed > 0) Logger.info('Caught up $changed change(s) from Apple', tag: 'AppleStateCatchUp');
  }
}

/// Applies an Apple-side single-message delete or restore to this device.
class RecoverableMessages {
  /// Prefers MessagesService so an OPEN conversation updates its message list
  /// and tile exactly as other live changes do. That service only exists while
  /// the chat's view is registered, so otherwise write the database and correct
  /// the chat tile directly: it renders from the stored latest-message pointer,
  /// not a live query.
  static Future<void> apply(String guid, {required bool hide}) async {
    if (kIsWeb) return;
    final message = await MessagingStore.current.messageByGuid(guid);
    final chatGuid = message?.chat.target?.guid;

    final service = chatGuid == null ? null : maybeFindMessagesSvc(chatGuid);
    if (service != null) {
      if (hide) {
        await service.softDeleteMessage(message!);
      } else {
        await service.restoreMessage(message!);
      }
      return;
    }

    if (hide) {
      await Message.softDelete(guid);
    } else {
      await Message.restore(guid);
    }
    if (chatGuid == null) return;

    final chat = ChatsSvc.findChatByGuid(chatGuid);
    if (chat == null) return;
    final surviving = chat.id == null ? null : newestMessageIn(chat.id!);
    if (surviving == null) {
      ChatsSvc.clearChatLatestMessage(chatGuid);
    } else {
      ChatsSvc.updateChatLatestMessage(chatGuid, surviving, allowOlder: true);
    }
  }
}
