import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/store/objectbox/objectbox_messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_messaging_store.dart';
import 'package:bluebubbles/services/backend/descriptors/attachment_query_descriptor.dart';
import 'package:bluebubbles/services/backend/sync/sync_marker.dart';
import 'package:flutter/foundation.dart';

export 'package:bluebubbles/services/backend/sync/sync_marker.dart' show ActiveStore;

// The messaging data behind the Actions and Interfaces (S2 switch plan,
// commits 4-6). Two implementations: ObjectBox (the code the Actions ran
// before, moved verbatim) and SQLite (the repositories in lib/database/sqlite,
// each former `runInTransaction(TxMode.write)` body one `Db.write`).
//
// Reads return entities with their relations usable (ObjectBox lazy-loads
// them, SQLite fills them). Writes return ids, as the Actions always have.

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

  Future<Handle?> handleById(int id);

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

  /// Messages created after [millisecondsSinceEpoch], matching
  /// MessageActions.getMessages' legacy ObjectBox query.
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
}

/// The sync batch (SyncActions.bulkSyncData) and the chat reads of its callers.
abstract interface class SyncStore {
  /// Saves a server batch (`chatData`, `messagesData`) as one write: handles,
  /// chats with participants (service twins folded), messages wired to chat
  /// and sender, reactions and attachment flags, attachments, latest
  /// pointers. Returns `messageIds` (every saved message) and `chatIds`
  /// (chats whose latest pointer moved). On ObjectBox the batch's handles are
  /// saved in a transaction of their own just before it.
  Future<Map<String, dynamic>> syncBatch(dynamic data);

  Future<Chat?> chatById(int id);

  Future<Chat?> chatByGuid(String guid);

  /// The stored chats of [ids], in that order; missing ones are skipped.
  Future<List<Chat>> chatsByIds(List<int> ids);
}

abstract class MessagingStore
    implements
        ContactStore,
        StorageStore,
        SendTargetStore,
        HandleStore,
        CustomGroupStore,
        MessageStore,
        AttachmentStore,
        SyncStore {
  /// Which store this is; picks the sync markers (SyncMarker.of).
  ActiveStore get kind;

  /// The implementation for [store]. [db] is the SQLite file of this isolate.
  static MessagingStore forStore(ActiveStore store, {Db? db}) => switch (store) {
        ActiveStore.objectBox => ObjectBoxMessagingStore(),
        ActiveStore.sqlite => SqliteMessagingStore(db ?? (throw ArgumentError.notNull('db'))),
      };

  static MessagingStore? _current;

  /// The store of this isolate. ObjectBox until startup selects SQLite (switch
  /// plan commit 9: `storage_state.dart` decideStorage returns
  /// ActiveStore.objectBox in every state until then).
  static MessagingStore get current => _current ??= forStore(ActiveStore.objectBox);

  @visibleForTesting
  static void use(MessagingStore? store) => _current = store;
}
