import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:collection/collection.dart';

/// sync_helpers.dart's attachment update on ObjectBox, moved unchanged behind
/// MessagingStore.
mixin ObjectBoxSyncHelperStore implements SyncHelperStore {
  @override
  Future<List<Attachment>> syncAttachments(List<Attachment> attachments) async {
    // Get a list of the GUIDs
    List<String> inputAttachmentGuids = attachments.map((element) => element.guid!).toList();

    // Query the database for existing attachments
    final query = Database.attachments.query(Attachment_.guid.oneOf(inputAttachmentGuids)).build();
    List<Attachment> existingAttachments = query.find();
    List<String> existingAttachmentGuids = existingAttachments.map((e) => e.guid!).toList();

    // Insert any non-existing attachments
    List<Attachment> newAttachments =
        attachments.where((element) => !existingAttachmentGuids.contains(element.guid)).toList();
    Database.attachments.putMany(newAttachments);

    // Update any existing attachments
    if (existingAttachments.isNotEmpty) {
      int mods = 0;
      for (var i = 0; i < existingAttachments.length; i++) {
        Attachment? newAttachment = attachments.firstWhereOrNull((e) => e.guid == existingAttachments[i].guid);
        if (newAttachment == null) continue;

        // We put newAttachment first because we want the new info to take precedence
        existingAttachments[i] = Attachment.merge(newAttachment, existingAttachments[i]);
        mods += 1;
      }

      if (mods > 0) {
        Database.attachments.putMany(existingAttachments);
      }
    }

    // Return a list of the inserted/existing attachments
    final query2 = Database.attachments.query(Attachment_.guid.oneOf(inputAttachmentGuids)).build();
    List<Attachment> syncedAttachments = query2.find().toList();

    // Insert the real ID
    for (var i = 0; i < attachments.length; i++) {
      Attachment? synced = syncedAttachments.firstWhereOrNull((e) => e.guid == attachments[i].guid);
      if (synced == null) continue;

      attachments[i] = Attachment.merge(attachments[i], synced);
    }

    return attachments;
  }

  @override
  Future<List<Message>> syncMessages(Chat c, List<Message> messages) async {
    // Get a list of the GUIDs
    List<String> inputMessageGuids = messages.map((element) => element.guid!).toList();

    // Query the database for existing messages
    final query = Database.messages.query(Message_.guid.oneOf(inputMessageGuids)).build();
    List<Message> existingMessages = query.find();
    List<String> existingMessageGuids = existingMessages.map((e) => e.guid!).toList();

    // Insert any non-existing messages
    List<Message> newMessages = messages.where((element) => !existingMessageGuids.contains(element.guid)).toList();
    Database.messages.putMany(newMessages);

    // Update any existing messages
    if (existingMessages.isNotEmpty) {
      int mods = 0;
      for (var i = 0; i < existingMessages.length; i++) {
        Message? newMessage = messages.firstWhereOrNull((e) => e.guid == existingMessages[i].guid);
        if (newMessage == null) continue;

        // We put newMessage first because we want the new info to take precedence
        existingMessages[i] = Message.merge(newMessage, existingMessages[i]);
        mods += 1;
      }

      if (mods > 0) {
        Database.messages.putMany(existingMessages, mode: PutMode.update);
      }
    }

    matchChats() {
      // Return a list of the inserted/existing messages
      final query2 = Database.messages.query(Message_.guid.oneOf(inputMessageGuids)).build();
      List<Message> syncedMessages = query2.find().toList();

      // Insert the real ID & chat
      for (var i = 0; i < messages.length; i++) {
        Message? synced = syncedMessages.firstWhereOrNull((e) => e.guid == messages[i].guid);
        if (synced == null) continue;

        messages[i] = Message.merge(messages[i], synced);
        messages[i].chat.target = c;
      }

      // Apply the chats
      Database.messages.putMany(messages, mode: PutMode.update);
    }

    // Try the matchChats function 3 times, or until it succeeds
    int tries = 0;
    bool success = false;
    dynamic lastError;
    StackTrace? stackTrace;
    while (tries < 3) {
      try {
        matchChats();
        success = true;
        break;
      } catch (ex, stack) {
        lastError = ex;
        stackTrace = stack;
        tries += 1;
        Logger.warn("Failed to match messages to chats, retrying... (Attempt $tries)", error: ex, trace: stackTrace);
      }
    }

    if (!success) {
      Logger.error("Failed to match messages to chats after 3 attempts, skipping...",
          error: lastError, trace: stackTrace);
    } else {
      Logger.debug("Successfully matched messages to chats after ${tries + 1} attempts!");
    }

    return messages;
  }
}
