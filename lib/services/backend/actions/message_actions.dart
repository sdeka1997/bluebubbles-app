import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/helpers/types/helpers/message_helper.dart';

class MessageActions {
  static Future<List<Message>?> getMessages() async {
    // Fetch messages from the last day from the active store.
    final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
    final messages = await MessagingStore.current.messagesCreatedAfter(oneDayAgo.millisecondsSinceEpoch);
    if (messages.isNotEmpty) {
      return messages;
    }
    return null;
  }

  static Future<int> replaceMessage(dynamic data) async {
    final oldGuid = data['oldGuid'] as String?;
    final newMessageData = data['newMessageData'] as Map<String, dynamic>;
    return MessagingStore.current.replaceMessage(oldGuid, Message.fromMap(newMessageData));
  }

  static Future<void> deleteMessage(dynamic data) async {
    final guid = data['guid'] as String;
    await MessagingStore.current.deleteMessage(guid);
  }

  static Future<void> softDeleteMessage(dynamic data) async {
    final guid = data['guid'] as String;
    await MessagingStore.current.softDeleteMessage(guid);
  }

  /// Clears [Message.dateDeleted], putting a message Apple took back out of
  /// Recently Deleted in front of the user again. The inverse of
  /// [softDeleteMessage]; the conversation view filters on dateDeleted being
  /// null, so clearing it is all that is needed to un-hide the message.
  static Future<void> restoreMessage(dynamic data) async {
    final guid = data['guid'] as String;
    await MessagingStore.current.restoreMessage(guid);
  }

  static Future<Map<String, dynamic>> fetchAssociatedMessagesAsync(dynamic data) async {
    final messageGuid = data['messageGuid'] as String;
    final threadOriginatorGuid = data['threadOriginatorGuid'] as String?;
    final store = MessagingStore.current;

    // Fetch associated messages (reactions)
    List<Message> associatedMessages = await store.messagesAssociatedWith(messageGuid);

    associatedMessages = MessageHelper.normalizedAssociatedMessages(associatedMessages);

    // If there's a thread originator, fetch it
    if (threadOriginatorGuid != null) {
      final threadOriginator = await store.messageByGuid(threadOriginatorGuid);
      if (threadOriginator != null) {
        associatedMessages.add(threadOriginator);
      }
    }

    associatedMessages.sort((a, b) => a.originalROWID!.compareTo(b.originalROWID!));

    return {
      'associatedMessages': associatedMessages.map((e) => e.toMap()).toList(),
    };
  }

  static Future<int> saveMessageAsync(dynamic data) async {
    final messageData = data['messageData'] as Map<String, dynamic>;
    final chatData = data['chatData'] as Map<String, dynamic>?;
    final updateIsBookmarked = data['updateIsBookmarked'] as bool;

    return MessagingStore.current.saveMessage(
      Message.fromMap(messageData),
      chat: chatData != null ? Chat.fromMap(chatData) : null,
      updateIsBookmarked: updateIsBookmarked,
    );
  }

  static Future<int?> findOneAsync(dynamic data) async {
    final guid = data['guid'] as String?;
    final associatedMessageGuid = data['associatedMessageGuid'] as String?;
    return MessagingStore.current.findMessageId(guid: guid, associatedMessageGuid: associatedMessageGuid);
  }

  static Future<List<int>> findAsync(dynamic data) async {
    // For now, we'll support finding all messages
    // A more sophisticated implementation would deserialize the condition JSON
    return MessagingStore.current.allMessageIds();
  }

  /// Re-links messages whose `handleId` (the sender's server-side ROWID)
  /// matches `serverHandleId` to `localHandleId`'s `handleRelation`.
  ///
  /// Mirrors `MessageHandleRelationshipMigration` — a message never gets a
  /// `handleRelation` if its `handleId` didn't match a `Handle.originalROWID`
  /// at save time (see "Handle Auditing" in Developer Tools). Scoped to a
  /// single server ROWID instead of a full-table scan since this only runs
  /// right after that one handle's `originalROWID` was repaired.
  static Future<int> relinkMessagesToHandle(dynamic data) async {
    final serverHandleId = data['handleId'] as int;
    final localHandleId = data['localHandleId'] as int;
    return MessagingStore.current.relinkMessagesToHandle(serverHandleId, localHandleId);
  }
}
