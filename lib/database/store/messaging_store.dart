import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart' show MessageKey;
import 'package:bluebubbles/database/store/sqlite/sqlite_attachment_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_chat_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_contact_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_custom_group_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_handle_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_message_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_send_target_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_storage_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_sync_helper_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_sync_store.dart';
import 'package:bluebubbles/services/backend/descriptors/attachment_query_descriptor.dart';
import 'package:bluebubbles/services/ui/chat/chat_stats/chat_stats_models.dart';
import 'package:flutter/foundation.dart';

// The messaging data behind the Actions and Interfaces: the repositories in
// lib/database/sqlite, each write one `Db.write`. The parts below are
// implemented by the mixins of lib/database/store/sqlite.
//
// Reads return entities with their relations filled. Writes return ids, as
// the Actions always have.

/// Contacts (ContactV2Actions, ContactV2Interface).
class ContactSyncResult {
  const ContactSyncResult({required this.affectedHandleIds, required this.matchedContactCount});

  final List<int> affectedHandleIds;
  final int matchedContactCount;
}

abstract interface class ContactStore {
  /// Reconciles the fetched server contacts and their already-written avatar paths,
  /// including contact-handle and empty-chat-handle links, in one write.
  Future<ContactSyncResult> syncContacts(
    List<ContactV2> contacts,
    Map<String, String?> avatarPaths, {
    required bool fetched,
  });

  Future<List<String>> contactNativeIds();
  Future<int?> findContactId(String nativeContactId);
  Future<List<int>> contactIdsForHandles(List<int> handleIds);
  Future<int?> contactIdByAddress(String address);
  Future<List<int>> allContactIds();
  Future<ContactV2?> contactById(int id);
  Future<List<ContactV2>> contactsByIds(List<int> ids);
}

/// Storage analysis/reset (StorageActions).
abstract interface class StorageStore {
  Future<Set<String>> storageAttachmentGuids({String? chatGuid, int? beforeMillis});

  /// Deletes every chat, message, attachment, handle, contact and custom group
  /// (the messaging reset and a full app reset); themes stay.
  Future<void> clearMessagingData();

  /// Resets download/image metadata for the stored attachments in [guids] in one write.
  Future<void> resetStorageAttachments(List<String> guids);
}

class SendTargetContext {
  const SendTargetContext({required this.copies, required this.recent, this.anchorChatGuid});

  final List<Chat> copies;
  final List<Message> recent;
  final String? anchorChatGuid;
}

/// Store reads needed to resolve the Apple chat used for an outgoing send.
abstract interface class SendTargetStore {
  Future<SendTargetContext> sendTargetContext(Chat thread, {String? anchorGuid, int recentLimit = 50});
}

/// Handles (HandleActions, HandleInterface).
abstract interface class HandleStore {
  /// Saves [handle] matched by ROWID or by address and service; keeps the stored
  /// color unless [updateColor]. Returns its id.
  Future<int?> saveHandle(Handle handle, {required bool updateColor, required bool matchOnOriginalROWID});

  /// Saves [handles] matched as [saveHandle] does, in one transaction; returns their ids in order.
  Future<List<int>> saveHandles(List<Handle> handles, {required bool matchOnOriginalROWID});

  /// The id of the handle with local [id] (or, failing that, ROWID [id]), with
  /// [originalROWID], or with [address] on [service], in that order of preference.
  Future<int?> findHandleId({int? id, int? originalROWID, String? address, String? service});

  Future<List<int>> allHandleIds();

  Future<List<Handle>> allHandles();

  /// Removes every handle. Used only by the handle-resync rollback flow.
  Future<void> clearHandles();

  Future<Handle?> handleById(int id);

  /// Removes the handle [id] (the handle audit's delete).
  Future<void> deleteHandle(int id);

  Future<int> handleCount();

  /// The server panel's local totals: live `messages` and `chats`, `handles`,
  /// and `attachments` with a MIME type, of which `images`, `videos` and
  /// `locations`.
  Future<Map<String, int>> localCounts();

  /// Handles never matched to a server row (no originalROWID), by id.
  Future<List<Handle>> handlesWithoutRowId();

  /// The stored handles of [ids], in that order; missing ones are skipped.
  Future<List<Handle>> handlesByIds(List<int> ids);
}

/// Custom chat groups (CustomGroupActions, CustomGroupInterface).
abstract interface class CustomGroupStore {
  /// Creates group [name] with the stored chats among [chatGuids]; throws when the name is taken.
  Future<int> createCustomGroup(String name, Set<String> chatGuids);

  /// Throws when the name is taken or the group does not exist.
  Future<int> renameCustomGroup(int id, String name);

  Future<int> setCustomGroupChats(int id, Set<String> chatGuids);

  Future<int> setCustomGroupShowUnreadBadge(int id, bool value);

  /// Every group id in settings order.
  Future<List<int>> customGroupIds();

  /// Gives each group of [ids] its position as sort order; unknown ids are skipped.
  Future<void> reorderCustomGroups(List<int> ids);

  Future<void> deleteCustomGroup(int id);

  Future<CustomGroup?> customGroupById(int id);

  /// The stored groups of [ids], in that order; missing ones are skipped.
  Future<List<CustomGroup>> customGroupsByIds(List<int> ids);
}

/// Messages (MessageActions, MessageInterface).
abstract interface class MessageStore {
  /// Updates the stored message [oldGuid] from [incoming] as a send receipt or
  /// edit does (MessageActions.replaceMessage); throws when there is none.
  Future<int> replaceMessage(String? oldGuid, Message incoming);

  Future<void> deleteMessage(String guid);

  /// Sets dateDeleted to now.
  Future<void> softDeleteMessage(String guid);

  /// Clears dateDeleted.
  Future<void> restoreMessage(String guid);

  /// Saves [message] by guid as MessageActions.saveMessageAsync does: keeps a
  /// stored message's id, text, service, sender and (unless
  /// [updateIsBookmarked]) bookmark; links the sender by server ROWID; flags
  /// reactions both ways; links [chat] when given. Returns its id.
  Future<int> saveMessage(Message message, {Chat? chat, required bool updateIsBookmarked});

  /// The id of the message [guid], else of a message associated with [associatedMessageGuid].
  Future<int?> findMessageId({String? guid, String? associatedMessageGuid});

  /// Every message id (MessageActions.findAsync ignores its condition).
  Future<List<int>> allMessageIds();

  /// The messages whose associatedMessageGuid is [guid] (reactions, stickers, ...).
  Future<List<Message>> messagesAssociatedWith(String guid);

  Future<Message?> messageByGuid(String guid);

  /// Sets [Message.reactionTarget] (with attachments) and
  /// [Message.otherParticipant] (with contacts) on [messages] that have one.
  Future<void> fillLinkedMessages(Iterable<Message> messages);

  /// Messages created after [millisecondsSinceEpoch] (MessageActions.getMessages).
  Future<List<Message>> messagesCreatedAfter(int millisecondsSinceEpoch);

  /// Links every message from server handle [serverHandleId] (not from me) to
  /// local handle [localHandleId]; returns how many changed.
  Future<int> relinkMessagesToHandle(int serverHandleId, int localHandleId);

  Future<Message?> messageById(int id);

  /// The stored messages of [ids], in that order; missing ones are skipped.
  Future<List<Message>> messagesByIds(List<int> ids);
}

/// Attachments (AttachmentActions, AttachmentInterface).
abstract interface class AttachmentStore {
  /// Saves [attachment] by guid, keeping a stored attachment's id and message
  /// unless [message] (with an id) is given. Returns its id.
  Future<int> saveAttachment(Attachment attachment, {Message? message});

  /// Saves [attachments] by guid in one transaction, keeping stored ids and
  /// message links when the new copy has none.
  Future<void> saveAttachments(List<Attachment> attachments);

  /// Moves the stored attachment [oldGuid] to [incoming]'s guid and server
  /// fields (merging into a stored attachment that already has that guid);
  /// sets [incoming]'s id, size and metadata from the stored one. Throws when
  /// [oldGuid] is not stored.
  Future<int> replaceAttachment(String oldGuid, Attachment incoming);

  Future<int?> findAttachmentId(String guid);

  /// Ids of the attachments matching [query] (every attachment when null).
  Future<List<int>> findAttachmentIds(AttachmentQueryDescriptor? query);

  Future<void> deleteAttachment(String guid);

  Future<Attachment?> attachmentById(int id);

  /// The stored attachments of [ids], in that order; missing ones are skipped.
  Future<List<Attachment>> attachmentsByIds(List<int> ids);

  /// The attachments linked to the message [messageId]; when it has none, the
  /// stored attachments with one of [guids] (those its attributed body names).
  Future<List<Attachment>> attachmentsOfMessage(int? messageId, List<String> guids);
}

/// The legacy sync_helpers.dart merge helpers.
abstract interface class SyncHelperStore {
  /// Inserts missing attachments and merges stored attachments, with incoming
  /// server fields taking precedence. The SQLite path is one Db.write.
  Future<List<Attachment>> syncAttachments(List<Attachment> attachments);

  /// Inserts missing messages, merges stored messages, and links every result
  /// to [chat]. The SQLite path is one Db.write.
  Future<List<Message>> syncMessages(Chat chat, List<Message> messages);
}

class ChatMetadataRefreshResult {
  const ChatMetadataRefreshResult({
    required this.changedChats,
    required this.foldedChats,
    required this.relistedChats,
  });

  final List<Chat> changedChats;
  final Map<String, Chat> foldedChats;
  final List<Chat> relistedChats;
}

/// The sync batch (SyncActions.bulkSyncData) and the chat reads of its callers.
abstract interface class SyncStore {
  /// Saves a server batch (`chatData`, `messagesData`) as one write: handles,
  /// chats with participants (service twins folded), messages wired to chat
  /// and sender, reactions and attachment flags, attachments, latest
  /// pointers. Returns `messageIds` (every saved message) and `chatIds`
  /// (chats whose latest pointer moved).
  Future<Map<String, dynamic>> syncBatch(dynamic data);

  Future<Chat?> chatById(int id);

  Future<Chat?> chatByGuid(String guid);

  /// The chat whose chatIdentifier is [identifier], with participants.
  Future<Chat?> chatByIdentifier(String identifier);

  /// The stored chats of [ids], in that order; missing ones are skipped.
  Future<List<Chat>> chatsByIds(List<int> ids);

  Future<List<Chat>> allChats();

  /// Soft-deleted chats, most recently deleted first.
  Future<List<Chat>> deletedChats();

  /// The chats not deleted that include any of [handleIds].
  Future<List<Chat>> liveChatsWithParticipants(List<int> handleIds);

  /// Replaces every listed chat's participant links in one write.
  Future<void> setChatHandleIds(Map<int, List<int>> handleIdsByChat);

  /// Newest stored group-name change for [chatGuid] or its canonical service copy.
  Future<DateTime?> newestStoredNameChange(String chatGuid);

  /// Applies remote grouping/spam metadata, folds service copies, and repairs
  /// latest pointers in the same write boundary as the legacy refresh.
  Future<ChatMetadataRefreshResult> refreshChatMetadata(List<Map<String, dynamic>> remoteChats);
}

/// Where the next older page of a chat's timeline starts, sendable between
/// isolates as [toMap]: the (sort_at, id) key of the last row a page returned,
/// the order the screen shows (Message.sort), so arrivals, deletes and
/// late-saved history can't shift a page.
class MessagePageCursor {
  const MessagePageCursor(this.key);

  final MessageKey key;

  Map<String, int> toMap() => {'sortAtUs': key.sortAtUs, 'id': key.id};

  static MessagePageCursor? fromMap(Object? map) {
    if (map is! Map || map['sortAtUs'] is! int || map['id'] is! int) return null;
    return MessagePageCursor(MessageKey(map['sortAtUs'] as int, map['id'] as int));
  }

  @override
  bool operator ==(Object other) => other is MessagePageCursor && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'MessagePageCursor($key)';
}

/// One page of a chat's timeline: message ids newest first, and where the next
/// older page starts ([next] is the request's cursor when nothing came back).
typedef MessagePage = ({List<int> ids, MessagePageCursor? next});

/// The chat-stats screen's reads for one chat (ChatStatsRepo). Timestamps are epoch milliseconds; participants
/// are local handle ids, [kMeParticipantId] for me.
abstract interface class ChatStatsReader {
  Future<int> messageCountForTier();
  Future<({int count, int latestMillis})> cacheKey();
  Future<Map<int, List<int>>> timestampsByParticipant({int? sinceMillis});
  Future<int> attachmentMessageCount({int? sinceMillis});
  Future<int> unattributedCount({int? sinceMillis});
  Future<int?> firstMessageMillis();
  Future<List<int>> readTimestamps({int? sinceMillis});
  Future<double> textCoverage();
  Future<List<String>> recentTexts({required bool fromMe, int? limit, int? participantId});
  Future<Map<int, List<int>>> textLengthsByParticipant({int? sinceMillis, int? limitPerParticipant});
  Future<List<({String type, int participantId})>> reactions();
  Future<List<String>> attachmentMimeTypes();
  Future<List<String>> expressiveSendStyleIds();
  Future<int> editedCount({bool? fromMe, int? participantId});
  Future<int> unsentCount({bool? fromMe, int? participantId});
  Future<int> sentCount();
  Future<int> receivedCount({int? participantId});
  Future<({int sent, int received, double? playedOfReceived})> audioStats();
  Future<List<GroupEventRecord>> groupEvents();
  Future<({List<ReactionMatrixRow> reactionRows, Map<String, int> guidToSender})> reactionMatrixData(
      {required int sinceMillis});
  Future<List<int>> participantHandleIds({int? sinceMillis});
}

/// Chat action reads and writes (ChatActions, ChatInterface).
abstract interface class ChatStore {
  Future<List<Chat>> markChatsRead(List<int> chatIds);

  Future<int?> saveChat(
    String guid,
    Chat inputChat,
    Map<String, bool> updateFlags, {
    int? latestMessageId,
    DateTime? latestMessageDate,
  });

  Future<void> deleteChat(int chatId, List<int> messageIds, List<int> handleIds);

  Future<void> softDeleteChat(String guid);

  Future<void> unDeleteChat(String guid);

  Future<Map<String, dynamic>> addMessageToChat(
    Message inputMessage,
    List<Attachment> inputAttachments,
    Chat inputChat,
    Message inputLatest, {
    required bool checkForMessageText,
  });

  Future<List<int>> supplementalMessageIds(List<String> messageGuids);

  Future<List<int>> syncLatestMessages(List<String> chatGuids, {required bool toggleUnread});

  /// Address-only lookup used by the legacy one-to-one GUID fallback before
  /// formatted-address work. The first stored handle is returned.
  Future<Handle?> handleByAddress(String address);

  /// The stored handles on [service] for each of [addresses] that has one,
  /// keyed by address, with contacts (Find My names).
  Future<Map<String, Handle>> handlesByAddresses(List<String> addresses, String service);

  /// Saves the prepared chats and handles in the former bulkSyncChats write.
  /// Address formatting has already happened outside this method.
  Future<({List<int> chatIds, List<int> brandNewHandleIds})> bulkSyncChats(
    List<Chat> inputChats,
    Map<String, Handle> inputHandles,
  );

  /// The former one-write contact match after bulkSyncChats.
  Future<void> linkContactToHandle(ContactV2 contact, int handleId);

  Future<List<int>> messagePageIds(
    int chatId,
    List<Handle> participants, {
    required int offset,
    required int limit,
    required bool includeDeleted,
  });

  /// The page of [chatId]'s timeline just older than [after] (the newest page
  /// when null), at most [limit] rows: what scrolling up in a chat loads.
  Future<MessagePage> olderMessagePage(int chatId, {MessagePageCursor? after, required int limit});

  /// [limit] messages of [chatId] either side of the message [aroundId] and that
  /// message, newest first: what jumping to a search result loads. [next] is
  /// where scrolling up continues.
  Future<MessagePage> messagePageAround(int chatId, List<Handle> participants, int aroundId, {required int limit});

  /// Messages whose text contains [term] (ASCII letters in either case), newest
  /// created first, with their chat and attachments: not reactions, not
  /// deleted, dated. Filters: [chatId], [isFromMe], [senderRowId] (the
  /// sender's server ROWID) and [since].
  Future<List<Message>> searchMessages(String term,
      {int? chatId, bool? isFromMe, int? senderRowId, DateTime? since, int limit = 50});

  /// The stored chats of [guids], in that order; missing ones are skipped.
  Future<List<Chat>> chatsByGuids(List<String> guids);

  /// Live link-preview messages of [chatId], newest created first.
  Future<List<Message>> linkMessages(int chatId);

  /// Bookmarked messages of [chatId] with attachments, newest created first.
  Future<List<Message>> bookmarkedMessages(int chatId);

  /// How many live timeline messages of [chatId] the chat screen shows above
  /// [messageId] when scrolled from the newest, or null when it is not one.
  Future<int?> timelinePosition(int chatId, int messageId);

  Future<List<int>> participantIds(int chatId);

  Future<void> clearTranscript(int chatId);

  /// The attachments with a mime type of [chatId]'s live messages, each with
  /// its message (the chat details media, documents and locations).
  Future<List<Attachment>> chatAttachments(int chatId);

  Future<List<int>> chatPageIds({required int limit, required int offset, required List<int> ids});

  /// Chats as they are written, so the conversation list picks up new ones:
  /// the chats each committed write touched ([DbChangeEvents.main]), read again.
  Stream<List<Chat>> chatsWritten();

  /// Every stored chat, deleted ones included.
  Future<int> chatCount();

  /// The stored chats that belong to a thread (threadKey set).
  Future<List<Chat>> threadedChats();

  /// The live chat [chat] is folded into, or null when [chat] is its own thread.
  Future<Chat?> canonicalTwinOf(Chat chat);

  /// The newest message, deleted ones excluded, of the local chat [chatId].
  /// With [listing], only a message that `listsThread`.
  Future<Message?> newestMessageIn(int chatId, {bool listing = true});

  /// Every live local chat in [chat]'s thread, [chat] included.
  Future<List<Chat>> threadChatsOf(Chat chat);

  /// `guidsToMarkRead` against the stored copies of [guid]'s thread.
  Future<List<String>> threadGuidsToMarkRead(String guid);

  /// `threadName` from the stored copies of [chat]'s thread (and its newest
  /// rename when renamed copies disagree); [Chat.currentName] when it has none.
  Future<String?> threadNameOf(Chat chat);

  /// The chat-stats reads of [chat].
  ChatStatsReader chatStats(Chat chat);
}

/// The messaging store of this isolate: its connection to `bluebubbles.db`.
class MessagingStore
    with
        SqliteContactStore,
        SqliteStorageStore,
        SqliteSendTargetStore,
        SqliteHandleStore,
        SqliteCustomGroupStore,
        SqliteMessageStore,
        SqliteAttachmentStore,
        SqliteSyncHelperStore,
        SqliteSyncStore,
        SqliteChatStore
    implements
        ContactStore,
        StorageStore,
        SendTargetStore,
        HandleStore,
        CustomGroupStore,
        MessageStore,
        AttachmentStore,
        SyncHelperStore,
        SyncStore,
        ChatStore {
  MessagingStore(this.db);

  @override
  final Db db;

  static MessagingStore? _current;

  /// The store of this isolate, opened by Database.init (openStorage).
  static MessagingStore get current => _current ?? (throw StateError('MessagingStore used before Database.init'));

  /// Database.init, once per isolate.
  static void select(MessagingStore store) => _current = store;

  @visibleForTesting
  static void use(MessagingStore? store) => _current = store;
}
