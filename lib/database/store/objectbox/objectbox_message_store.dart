import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/utils/logger/logger.dart';

/// MessageActions' ObjectBox code.
mixin ObjectBoxMessageStore implements MessageStore {
  @override
  Future<int> replaceMessage(String? oldGuid, Message inputNewMessage) async {
    return Database.runInTransaction(TxMode.write, () {
      final messageBox = Database.messages;

      // Find existing message
      final query = messageBox.query(Message_.guid.equals(oldGuid ?? '')).build();
      query.limit = 1;
      final existing = query.findFirst();
      query.close();

      if (existing == null) {
        throw Exception("Cannot replace on a null existing message!!");
      }

      // We just need to update the timestamps & error
      if (existing.guid != inputNewMessage.guid) {
        existing.guid = inputNewMessage.guid;
      }
      if (inputNewMessage.text != null) {
        existing.text = inputNewMessage.text;
      }
      existing.service ??= inputNewMessage.service;

      existing.dateDelivered = inputNewMessage.dateDelivered ?? existing.dateDelivered;
      existing.isDelivered = inputNewMessage.isDelivered;
      existing.dateRead = inputNewMessage.dateRead ?? existing.dateRead;
      existing.dateEdited = inputNewMessage.dateEdited ?? existing.dateEdited;
      existing.attributedBody =
          inputNewMessage.attributedBody.isNotEmpty ? inputNewMessage.attributedBody : existing.attributedBody;
      existing.messageSummaryInfo = inputNewMessage.messageSummaryInfo.isNotEmpty
          ? inputNewMessage.messageSummaryInfo
          : existing.messageSummaryInfo;
      existing.payloadData = inputNewMessage.payloadData ?? existing.payloadData;
      existing.wasDeliveredQuietly =
          inputNewMessage.wasDeliveredQuietly ? inputNewMessage.wasDeliveredQuietly : existing.wasDeliveredQuietly;
      existing.didNotifyRecipient =
          inputNewMessage.didNotifyRecipient ? inputNewMessage.didNotifyRecipient : existing.didNotifyRecipient;
      existing.error = inputNewMessage.error;
      existing.errorMessage = inputNewMessage.errorMessage;

      try {
        messageBox.put(existing, mode: PutMode.update);
      } catch (ex) {
        Logger.warn(
            'Failed to replace message! This is likely due to a unique constraint being violated: ${ex.toString()}');
      }

      // Return just the ID for efficient transfer across isolates
      return existing.id!;
    });
  }

  @override
  Future<void> deleteMessage(String guid) async {
    Database.runInTransaction(TxMode.write, () {
      final messageBox = Database.messages;

      final query = messageBox.query(Message_.guid.equals(guid)).build();
      final result = query.findFirst();
      query.close();
      if (result?.id != null) {
        messageBox.remove(result!.id!);
      }
    });
  }

  @override
  Future<void> softDeleteMessage(String guid) async {
    Database.runInTransaction(TxMode.write, () {
      final messageBox = Database.messages;

      final query = messageBox.query(Message_.guid.equals(guid)).build();
      query.limit = 1;
      final toDelete = query.findFirst();
      query.close();

      if (toDelete != null) {
        toDelete.dateDeleted = DateTime.now().toUtc();
        messageBox.put(toDelete);
      }
    });
  }

  @override
  Future<void> restoreMessage(String guid) async {
    Database.runInTransaction(TxMode.write, () {
      final messageBox = Database.messages;

      final query = messageBox.query(Message_.guid.equals(guid)).build();
      query.limit = 1;
      final toRestore = query.findFirst();
      query.close();

      if (toRestore != null && toRestore.dateDeleted != null) {
        toRestore.dateDeleted = null;
        messageBox.put(toRestore);
      }
    });
  }

  @override
  Future<int> saveMessage(Message inputMessage, {Chat? chat, required bool updateIsBookmarked}) async {
    final inputChat = chat;
    return Database.runInTransaction(TxMode.write, () {
      final messageBox = Database.messages;
      final handleBox = Database.handles;

      // Find existing message
      final existingQuery = messageBox.query(Message_.guid.equals(inputMessage.guid ?? '')).build();
      existingQuery.limit = 1;
      final existing = existingQuery.findFirst();
      existingQuery.close();

      if (existing != null) {
        inputMessage.id = existing.id;
        inputMessage.text ??= existing.text;
        inputMessage.service ??= existing.service;

        // Preserve existing handleRelation if available
        if (existing.handleRelation.hasValue && !inputMessage.handleRelation.hasValue) {
          inputMessage.handleRelation.target = existing.handleRelation.target;
          inputMessage.handle = existing.handleRelation.target;
        }
      }

      // Save the participant & set the handle ID to the new participant
      // Only do handleId lookup if we don't already have a handleRelation
      if (inputMessage.handle == null && !inputMessage.handleRelation.hasValue && inputMessage.handleId != null) {
        final handleQuery = handleBox.query(Handle_.originalROWID.equals(inputMessage.handleId!)).build();
        handleQuery.limit = 1;
        final foundHandle = handleQuery.findFirst();
        handleQuery.close();
        inputMessage.handle = foundHandle;

        // Set up handleRelation for the ToOne relationship
        if (foundHandle != null && foundHandle.id != null) {
          inputMessage.handleRelation.target = foundHandle;
        }
      } else if (inputMessage.handleRelation.hasValue && inputMessage.handle == null) {
        // Use existing relationship to populate handle field
        inputMessage.handle = inputMessage.handleRelation.target;
      }

      // Save associated messages or the original message (depending on whether
      // this message is a reaction or regular message
      if (inputMessage.associatedMessageType != null && inputMessage.associatedMessageGuid != null) {
        final associatedQuery = messageBox.query(Message_.guid.equals(inputMessage.associatedMessageGuid!)).build();
        associatedQuery.limit = 1;
        final associatedMessage = associatedQuery.findFirst();
        associatedQuery.close();

        if (associatedMessage != null) {
          associatedMessage.hasReactions = true;
          messageBox.put(associatedMessage);
        }
      } else if (!inputMessage.hasReactions) {
        final reactionQuery = messageBox.query(Message_.associatedMessageGuid.equals(inputMessage.guid ?? '')).build();
        reactionQuery.limit = 1;
        final reaction = reactionQuery.findFirst();
        reactionQuery.close();

        if (reaction != null) {
          inputMessage.hasReactions = true;
        }
      }

      if (!updateIsBookmarked) {
        inputMessage.isBookmarked = existing?.isBookmarked ?? inputMessage.isBookmarked;
      }

      try {
        if (inputChat != null) inputMessage.chat.target = inputChat;
        inputMessage.id = messageBox.put(inputMessage);
      } on UniqueViolationException catch (_) {}

      // Return just the ID for efficient transfer across isolates
      return inputMessage.id!;
    });
  }

  @override
  Future<int?> findMessageId({String? guid, String? associatedMessageGuid}) async {
    return Database.runInTransaction(TxMode.read, () {
      final messageBox = Database.messages;

      Message? result;

      if (guid != null) {
        final query = messageBox.query(Message_.guid.equals(guid)).build();
        query.limit = 1;
        result = query.findFirst();
        query.close();
      } else if (associatedMessageGuid != null) {
        final query = messageBox.query(Message_.associatedMessageGuid.equals(associatedMessageGuid)).build();
        query.limit = 1;
        result = query.findFirst();
        query.close();
      }

      // Return just the ID for efficient transfer across isolates
      return result?.id;
    });
  }

  @override
  Future<List<int>> allMessageIds() async {
    return Database.runInTransaction(TxMode.read, () {
      final messageBox = Database.messages;

      final query = messageBox.query().build();
      final results = query.find();
      query.close();

      // Return just the IDs for efficient transfer across isolates
      return results.map((e) => e.id!).toList();
    });
  }

  @override
  Future<List<Message>> messagesAssociatedWith(String guid) async {
    return Database.runInTransaction(TxMode.read, () {
      final query = Database.messages.query(Message_.associatedMessageGuid.equals(guid)).build();
      final associatedMessages = query.find();
      query.close();
      return associatedMessages;
    });
  }

  @override
  Future<void> fillLinkedMessages(Iterable<Message> messages) async {
    final reactions = messages.where((m) => m.associatedMessageGuid != null).toList();
    if (reactions.isNotEmpty) {
      final query = Database.messages
          .query(Message_.guid.oneOf(reactions.map((m) => m.associatedMessageGuid!).toSet().toList()))
          .build();
      final targets = {for (final t in query.find()) t.guid: t};
      query.close();
      for (final m in reactions) {
        m.reactionTarget = targets[m.associatedMessageGuid];
      }
    }
    final events = messages.where((m) => m.otherHandle != null && m.isParticipantEvent).toList();
    if (events.isNotEmpty) {
      final query = (Database.handles.query(Handle_.originalROWID.oneOf(events.map((m) => m.otherHandle!).toSet().toList()))
            ..order(Handle_.id))
          .build();
      final people = <int, Handle>{};
      for (final h in query.find()) {
        people.putIfAbsent(h.originalROWID!, () => h);
      }
      query.close();
      for (final m in events) {
        m.otherParticipant = people[m.otherHandle];
      }
    }
  }

  @override
  Future<Message?> messageByGuid(String guid) async {
    return _linked(Database.runInTransaction(TxMode.read, () {
      final originatorQuery = Database.messages.query(Message_.guid.equals(guid)).build();
      originatorQuery.limit = 1;
      final message = originatorQuery.findFirst();
      originatorQuery.close();
      return message;
    }));
  }

  @override
  Future<List<Message>> messagesCreatedAfter(int millisecondsSinceEpoch) {
    final query = Database.messages.query(Message_.dateCreated.greaterThan(millisecondsSinceEpoch)).build();
    return query.findAsync().whenComplete(query.close);
  }

  @override
  Future<int> relinkMessagesToHandle(int serverHandleId, int localHandleId) async {
    return Database.runInTransaction(TxMode.write, () {
      final messageBox = Database.messages;

      final query = messageBox.query(Message_.handleId.equals(serverHandleId)).build();
      final matches = query.find();
      query.close();

      final toUpdate = <Message>[];
      for (final message in matches) {
        if (message.isFromMe == true) continue;
        if (message.handleRelation.targetId == localHandleId) continue;
        message.handleRelation.targetId = localHandleId;
        toUpdate.add(message);
      }

      if (toUpdate.isNotEmpty) {
        messageBox.putMany(toUpdate);
      }

      return toUpdate.length;
    });
  }

  @override
  Future<Message?> messageById(int id) async => _linked(Database.messages.get(id));

  Future<Message?> _linked(Message? m) async {
    if (m != null) await fillLinkedMessages([m]);
    return m;
  }

  @override
  Future<List<Message>> messagesByIds(List<int> ids) async {
    final found = Database.messages.getMany(ids).whereType<Message>().toList();
    await fillLinkedMessages(found);
    return found;
  }
}
