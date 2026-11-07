import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

// Schema v1: one table per ObjectBox entity of the linked messaging set, same
// columns in snake_case (SQLITE-PLAN-2 Appendix D). ObjectBox ids are kept as
// the primary key. Dates are microseconds since epoch (`*_us`), booleans 0/1,
// string vectors and FlexBuffer maps JSON text.

@DataClassName('SqliteChatRow')
class Chats extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get guid => text().unique()();
  TextColumn get chatIdentifier => text().nullable()();
  TextColumn get serviceName => text().nullable()();
  TextColumn get groupId => text().nullable()();
  TextColumn get originalGroupId => text().nullable()();
  TextColumn get legacyGroupIdsJson => text().nullable()();
  TextColumn get latestGroupTitle => text().nullable()();
  TextColumn get threadKey => text().nullable()();
  BoolColumn get isArchived => boolean().nullable()();
  TextColumn get muteType => text().nullable()();
  TextColumn get muteArgs => text().nullable()();
  BoolColumn get isPinned => boolean().nullable()();
  BoolColumn get hasUnreadMessage => boolean().nullable()();
  TextColumn get displayName => text().nullable()();
  BoolColumn get isFilteredAsSpam => boolean().nullable()();
  BoolColumn get autoSendReadReceipts => boolean().nullable()();
  BoolColumn get autoSendTypingIndicators => boolean().nullable()();
  TextColumn get textFieldText => text().nullable()();
  TextColumn get textFieldAttachmentsJson => text().withDefault(const Constant('[]'))();
  // messages.id. No foreign key: chats and messages point at each other, and
  // ObjectBox can hold a pointer to a message that is gone (reads as no preview).
  IntColumn get latestMessageId => integer().nullable()();
  IntColumn get latestMessageDateUs => integer().nullable()();
  IntColumn get dateDeletedUs => integer().nullable()();
  IntColumn get style => integer().nullable()();
  BoolColumn get lockChatName => boolean().withDefault(const Constant(false))();
  BoolColumn get lockChatIcon => boolean().withDefault(const Constant(false))();
  TextColumn get lastReadMessageGuid => text().nullable()();
  TextColumn get customThemeLight => text().nullable()();
  TextColumn get customThemeDark => text().nullable()();
  TextColumn get wallpaperType => text().nullable()();
  TextColumn get dynamicWallpaperId => text().nullable()();
  TextColumn get dynamicWallpaperConfig => text().nullable()();
  TextColumn get customAvatarPath => text().nullable()();
  TextColumn get customBackgroundPath => text().nullable()();
  IntColumn get pinIndex => integer().nullable()();
}

@DataClassName('SqliteMessageRow')
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get originalRowid => integer().nullable()();
  TextColumn get guid => text().nullable().unique()();
  IntColumn get handleId => integer().nullable()();
  IntColumn get otherHandle => integer().nullable()();
  TextColumn get messageText => text().named('text').nullable()();
  TextColumn get subject => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get service => text().nullable()();
  IntColumn get dateCreatedUs => integer().nullable()();
  // min(date_created, coalesce(date_delivered, date_created)), as Message.sort
  // orders the screen; (sort_at_us, id) is the paging key.
  IntColumn get sortAtUs => integer()();
  IntColumn get dateReadUs => integer().nullable()();
  IntColumn get dateDeliveredUs => integer().nullable()();
  BoolColumn get isFromMe => boolean().nullable()();
  BoolColumn get hasDdResults => boolean().nullable()();
  IntColumn get datePlayedUs => integer().nullable()();
  IntColumn get itemType => integer().nullable()();
  TextColumn get groupTitle => text().nullable()();
  IntColumn get groupActionType => integer().nullable()();
  TextColumn get balloonBundleId => text().nullable()();
  TextColumn get associatedMessageGuid => text().nullable()();
  IntColumn get associatedMessagePart => integer().nullable()();
  TextColumn get associatedMessageType => text().nullable()();
  TextColumn get expressiveSendStyleId => text().nullable()();
  BoolColumn get hasAttachments => boolean()();
  BoolColumn get hasReactions => boolean()();
  IntColumn get dateDeletedUs => integer().nullable()();
  TextColumn get threadOriginatorGuid => text().nullable()();
  TextColumn get threadOriginatorPart => text().nullable()();
  BoolColumn get bigEmoji => boolean().nullable()();
  IntColumn get error => integer()();
  IntColumn get chatId => integer().nullable().references(Chats, #id, onDelete: KeyAction.cascade)();
  TextColumn get attributedBodyJson => text().nullable()();
  TextColumn get messageSummaryInfoJson => text().nullable()();
  TextColumn get payloadDataJson => text().nullable()();
  TextColumn get metadataJson => text().nullable()();
  BoolColumn get hasApplePayloadData => boolean()();
  IntColumn get dateEditedUs => integer().nullable()();
  BoolColumn get wasDeliveredQuietly => boolean()();
  BoolColumn get didNotifyRecipient => boolean()();
  BoolColumn get isBookmarked => boolean()();
  BoolColumn get isDelivered => boolean()();
  IntColumn get handleRelationId =>
      integer().nullable().references(Handles, #id, onDelete: KeyAction.setNull)();
  TextColumn get errorMessage => text().nullable()();
  BoolColumn get hasEffectPlayed => boolean()();
  TextColumn get appleChatGuid => text().nullable()();
}

@DataClassName('SqliteHandleRow')
class Handles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get originalRowid => integer().nullable()();
  TextColumn get address => text()();
  TextColumn get country => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get defaultPhone => text().nullable()();
  TextColumn get defaultEmail => text().nullable()();
  TextColumn get formattedAddress => text().nullable()();
  TextColumn get uniqueAddressAndService => text().unique()();
  TextColumn get service => text()();
}

@DataClassName('SqliteChatHandleRow')
class ChatHandles extends Table {
  IntColumn get chatId => integer().references(Chats, #id, onDelete: KeyAction.cascade)();
  IntColumn get handleId => integer().references(Handles, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {chatId, handleId};

  @override
  bool get withoutRowId => true;
}

@DataClassName('SqliteAttachmentRow')
class Attachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get originalRowid => integer().nullable()();
  TextColumn get guid => text().nullable().unique()();
  TextColumn get uti => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  BoolColumn get isOutgoing => boolean().nullable()();
  TextColumn get transferName => text().nullable()();
  IntColumn get totalBytes => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get width => integer().nullable()();
  TextColumn get webUrl => text().nullable()();
  IntColumn get messageId => integer().nullable().references(Messages, #id, onDelete: KeyAction.cascade)();
  BoolColumn get hasLivePhoto => boolean()();
  BoolColumn get isDownloaded => boolean()();
  TextColumn get metadataJson => text().nullable()();
  TextColumn get exifJson => text().nullable()();
}

@DataClassName('SqliteContactRow')
class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get displayName => text()();
  TextColumn get nativeContactId => text().unique()();
  TextColumn get avatarPath => text().nullable()();
  TextColumn get addressesJson => text()();
  TextColumn get nickname => text().nullable()();
  TextColumn get firstName => text().nullable()();
  TextColumn get lastName => text().nullable()();
  TextColumn get middleName => text().nullable()();
  TextColumn get namePrefix => text().nullable()();
  TextColumn get nameSuffix => text().nullable()();
  TextColumn get company => text().nullable()();
  TextColumn get phoneNumbersJson => text().nullable()();
  TextColumn get emailAddressesJson => text().nullable()();
  BoolColumn get isNative => boolean()();
}

@DataClassName('SqliteContactHandleRow')
class ContactHandles extends Table {
  IntColumn get contactId => integer().references(Contacts, #id, onDelete: KeyAction.cascade)();
  IntColumn get handleId => integer().references(Handles, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {contactId, handleId};

  @override
  bool get withoutRowId => true;
}

@DataClassName('SqliteCustomGroupRow')
class CustomGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  IntColumn get sortOrder => integer()();
  BoolColumn get showUnreadBadge => boolean()();
}

@DataClassName('SqliteCustomGroupChatRow')
class CustomGroupChats extends Table {
  IntColumn get groupId => integer().references(CustomGroups, #id, onDelete: KeyAction.cascade)();
  IntColumn get chatId => integer().references(Chats, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {groupId, chatId};

  @override
  bool get withoutRowId => true;
}

/// Key/value state of the SQLite file: schema, copy state, verification result.
class StorageMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

/// How far the ObjectBox copy got per entity: the highest ObjectBox id copied.
class CopyCheckpoints extends Table {
  TextColumn get entity => text()();
  IntColumn get lastSourceId => integer()();
  IntColumn get rowsCopied => integer()();

  @override
  Set<Column> get primaryKey => {entity};
}

/// Secondary indexes, by the query shape each serves (SQLITE-PLAN-2 section 3).
const schemaIndexes = <String>[
  // The chat screen's timeline: one chat, no reactions, not deleted, by (sort_at, id).
  'CREATE INDEX IF NOT EXISTS messages_timeline ON messages (chat_id, sort_at_us, id) '
      'WHERE associated_message_guid IS NULL AND date_deleted_us IS NULL',
  // Every row of one chat: includeDeleted, stats, renames, latest-pointer recompute.
  'CREATE INDEX IF NOT EXISTS messages_chat_time ON messages (chat_id, sort_at_us, id)',
  'CREATE INDEX IF NOT EXISTS messages_assoc ON messages (associated_message_guid) '
      'WHERE associated_message_guid IS NOT NULL',
  'CREATE INDEX IF NOT EXISTS messages_thread ON messages (thread_originator_guid) '
      'WHERE thread_originator_guid IS NOT NULL',
  'CREATE INDEX IF NOT EXISTS messages_handle_id ON messages (handle_id)',
  'CREATE INDEX IF NOT EXISTS messages_handle_rel ON messages (handle_relation_id)',
  'CREATE INDEX IF NOT EXISTS messages_bookmarked ON messages (chat_id, sort_at_us) WHERE is_bookmarked = 1',
  'CREATE INDEX IF NOT EXISTS attachments_message ON attachments (message_id)',
  'CREATE INDEX IF NOT EXISTS chats_list ON chats (latest_message_date_us DESC, id DESC) '
      'WHERE date_deleted_us IS NULL',
  'CREATE INDEX IF NOT EXISTS chats_identifier ON chats (chat_identifier)',
  'CREATE INDEX IF NOT EXISTS chats_thread_key ON chats (thread_key) WHERE thread_key IS NOT NULL',
  'CREATE INDEX IF NOT EXISTS handles_rowid ON handles (original_rowid)',
  'CREATE INDEX IF NOT EXISTS handles_address ON handles (address, service)',
  'CREATE INDEX IF NOT EXISTS chat_handles_handle ON chat_handles (handle_id)',
  'CREATE INDEX IF NOT EXISTS contact_handles_handle ON contact_handles (handle_id)',
  'CREATE INDEX IF NOT EXISTS custom_group_chats_chat ON custom_group_chats (chat_id)',
];

@DriftDatabase(
  tables: [
    Chats,
    Messages,
    Handles,
    ChatHandles,
    Attachments,
    Contacts,
    ContactHandles,
    CustomGroups,
    CustomGroupChats,
    StorageMeta,
    CopyCheckpoints,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.inMemory() : this(NativeDatabase.memory());

  AppDatabase.file(File file) : this(NativeDatabase.createInBackground(file));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      for (final statement in schemaIndexes) {
        await customStatement(statement);
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA synchronous = NORMAL');
      await customStatement('PRAGMA busy_timeout = 5000');
      await customStatement('PRAGMA cache_size = -20000');
    },
  );
}
