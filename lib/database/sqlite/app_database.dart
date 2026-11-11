import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart' show emptySummaryInfoJson, plainTextBodyJson;

part 'app_database.g.dart';

// One table per ObjectBox entity of the linked messaging set, same columns in
// snake_case (SQLITE-PLAN-2 Appendix D). ObjectBox ids are kept as the primary
// key. Dates are microseconds since epoch (`*_us`), booleans 0/1, string
// vectors and FlexBuffer maps JSON text.
//
// Schema v2 adds the foreign keys v1 never had (drift_dev 2.31 drops every
// `references(Table, #id)`, so they are raw constraints here) and the
// messages_fts search index. A parent's delete unlinks its messages and
// attachments (SET NULL, as ObjectBox leaves a dangling relation) and removes
// its join rows (CASCADE).

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
  IntColumn get chatId => integer().nullable().customConstraint('NULL REFERENCES chats (id) ON DELETE SET NULL')();
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
      integer().nullable().customConstraint('NULL REFERENCES handles (id) ON DELETE SET NULL')();
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
  IntColumn get chatId => integer().customConstraint('NOT NULL REFERENCES chats (id) ON DELETE CASCADE')();
  IntColumn get handleId => integer().customConstraint('NOT NULL REFERENCES handles (id) ON DELETE CASCADE')();

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
  IntColumn get messageId => integer().nullable().customConstraint('NULL REFERENCES messages (id) ON DELETE SET NULL')();
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
  IntColumn get contactId => integer().customConstraint('NOT NULL REFERENCES contacts (id) ON DELETE CASCADE')();
  IntColumn get handleId => integer().customConstraint('NOT NULL REFERENCES handles (id) ON DELETE CASCADE')();

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
  IntColumn get groupId => integer().customConstraint('NOT NULL REFERENCES custom_groups (id) ON DELETE CASCADE')();
  IntColumn get chatId => integer().customConstraint('NOT NULL REFERENCES chats (id) ON DELETE CASCADE')();

  @override
  Set<Column> get primaryKey => {groupId, chatId};

  @override
  bool get withoutRowId => true;
}

/// Key/value state of the SQLite file: `fts_state`, `vacuum_pending`.
class StorageMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

/// The app's themes (stage S4), kept outside drift's generated tables: only
/// ThemeStore reads or writes them.
const themesTable = 'CREATE TABLE IF NOT EXISTS themes (name TEXT NOT NULL PRIMARY KEY, '
    'gradient_bg INTEGER NOT NULL, google_font TEXT NOT NULL, data_json TEXT NOT NULL)';

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
  // Group renames of a chat by creation date (MessageRepo.newestRename): a few
  // rows per group chat, so no walk back through a history that has none.
  'CREATE INDEX IF NOT EXISTS messages_renames ON messages (chat_id, date_created_us, id) WHERE item_type = 2',
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

/// Search over message text and subject. Trigram: `LIKE '%term%'` on it finds
/// the same rows as a substring scan, for terms of 3+ characters (shorter ones
/// can't use it; MessageRepo.search falls back to LIKE on messages). The
/// trigrams only pick candidates; SQLite's LIKE then checks each row, so case
/// is folded for ASCII letters only, exactly as ObjectBox's
/// `contains(caseSensitive: false)`. `detail='none'`: LIKE needs no positions,
/// and the index is half the size of the default.
const ftsTable = "CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts5(text, subject, content='messages', "
    "content_rowid='id', tokenize='trigram', detail='none')";

/// Keep messages_fts in step with messages. The bulk copy drops these, fills
/// the index once at the end ([rebuildFts]) and creates them again.
const ftsTriggers = <String>[
  'CREATE TRIGGER IF NOT EXISTS messages_fts_ai AFTER INSERT ON messages BEGIN '
      'INSERT INTO messages_fts (rowid, text, subject) VALUES (new.id, new.text, new.subject); END',
  'CREATE TRIGGER IF NOT EXISTS messages_fts_ad AFTER DELETE ON messages BEGIN '
      "INSERT INTO messages_fts (messages_fts, rowid, text, subject) VALUES ('delete', old.id, old.text, old.subject); END",
  'CREATE TRIGGER IF NOT EXISTS messages_fts_au AFTER UPDATE OF text, subject ON messages BEGIN '
      "INSERT INTO messages_fts (messages_fts, rowid, text, subject) VALUES ('delete', old.id, old.text, old.subject); "
      'INSERT INTO messages_fts (rowid, text, subject) VALUES (new.id, new.text, new.subject); END',
];

const _ftsTriggerNames = ['messages_fts_ai', 'messages_fts_ad', 'messages_fts_au'];

/// Stops maintaining messages_fts and empties it (`storage_meta.fts_state =
/// building`), so a bulk insert costs no index work per row.
/// Run it in one transaction with the caller's other changes.
Future<void> suspendFts(Future<void> Function(String sql) run) async {
  await run("INSERT OR REPLACE INTO storage_meta (key, value) VALUES ('fts_state', 'building')");
  for (final name in _ftsTriggerNames) {
    await run('DROP TRIGGER IF EXISTS $name');
  }
  await run("INSERT INTO messages_fts (messages_fts) VALUES ('delete-all')");
}

/// Fills messages_fts from every stored message in one pass and maintains it
/// from then on (`fts_state = ready`).
Future<void> rebuildFts(Future<void> Function(String sql) run) async {
  await run("INSERT INTO messages_fts (messages_fts) VALUES ('rebuild')");
  for (final statement in ftsTriggers) {
    await run(statement);
  }
  await run("INSERT OR REPLACE INTO storage_meta (key, value) VALUES ('fts_state', 'ready')");
}

/// v1 rows the v2 keys would refuse (v1 had none): pointers at rows that don't
/// exist are cleared, join rows to them dropped.
const _danglingCleanup = <String>[
  'UPDATE messages SET chat_id = NULL WHERE chat_id IS NOT NULL AND chat_id NOT IN (SELECT id FROM chats)',
  'UPDATE messages SET handle_relation_id = NULL '
      'WHERE handle_relation_id IS NOT NULL AND handle_relation_id NOT IN (SELECT id FROM handles)',
  'UPDATE attachments SET message_id = NULL WHERE message_id IS NOT NULL AND message_id NOT IN (SELECT id FROM messages)',
  'DELETE FROM chat_handles WHERE chat_id NOT IN (SELECT id FROM chats) OR handle_id NOT IN (SELECT id FROM handles)',
  'DELETE FROM contact_handles WHERE contact_id NOT IN (SELECT id FROM contacts) OR handle_id NOT IN (SELECT id FROM handles)',
  'DELETE FROM custom_group_chats WHERE group_id NOT IN (SELECT id FROM custom_groups) OR chat_id NOT IN (SELECT id FROM chats)',
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.inMemory() : this(NativeDatabase.memory());

  /// v3 -> v4: [plainTextBody] bodies and empty summary infos become NULL
  /// (the mappers rebuild them), the copy's checkpoint table goes, and the
  /// next open compacts the file ([Db.vacuumIfPending]). Every step can run
  /// again: a kill midway finishes on the next open.
  Future<void> _shrinkMessages() async {
    await customStatement(
        "UPDATE messages SET message_summary_info_json = NULL WHERE message_summary_info_json IN ('[]', ?)",
        [emptySummaryInfoJson]);
    var after = 0;
    while (true) {
      final rows = await customSelect(
        'SELECT id, text, attributed_body_json AS b FROM messages WHERE id > ? AND text IS NOT NULL '
        "AND attributed_body_json LIKE '[{\"string\":%' ORDER BY id LIMIT 5000",
        variables: [Variable.withInt(after)],
      ).get();
      if (rows.isEmpty) break;
      after = rows.last.read<int>('id');
      final plain = [
        for (final r in rows)
          if (r.read<String>('b') == plainTextBodyJson(r.read<String>('text'))) r.read<int>('id')
      ];
      for (var i = 0; i < plain.length; i += 500) {
        final chunk = plain.sublist(i, i + 500 > plain.length ? plain.length : i + 500);
        await customStatement(
            'UPDATE messages SET attributed_body_json = NULL WHERE id IN (${List.filled(chunk.length, '?').join(', ')})',
            chunk);
      }
    }
    await customStatement('DROP TABLE IF EXISTS copy_checkpoints');
    await customStatement("INSERT OR REPLACE INTO storage_meta (key, value) VALUES ('vacuum_pending', '1')");
  }

  AppDatabase.file(File file) : this(NativeDatabase.createInBackground(file));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      for (final statement in [...schemaIndexes, ftsTable, themesTable]) {
        await customStatement(statement);
      }
      await rebuildFts(customStatement);
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v1 -> v2 (the S1 copy-check file): clear what the keys would refuse,
        // rebuild each table that holds a key (drift's alterTable: new table,
        // copy, drop, rename, indexes again, with keys off), then add the new
        // index and fill the search index.
        for (final statement in _danglingCleanup) {
          await customStatement(statement);
        }
        for (final TableInfo table in [messages, attachments, chatHandles, contactHandles, customGroupChats]) {
          // Drift's documented way to add constraints to an existing table.
          // ignore: experimental_member_use
          await m.alterTable(TableMigration(table));
        }
        for (final statement in [...schemaIndexes, ftsTable]) {
          await customStatement(statement);
        }
        await rebuildFts(customStatement);
      }
      // v2 -> v3: the themes table (stage S4).
      if (from < 3) await customStatement(themesTable);
      if (from < 4) await _shrinkMessages();
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
