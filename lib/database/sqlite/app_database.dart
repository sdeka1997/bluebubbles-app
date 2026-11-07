import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

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
  IntColumn get latestMessageId =>
      integer().nullable().customConstraint('REFERENCES messages(id) ON DELETE SET NULL')();
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
}

class LegacyHandles extends Table {
  IntColumn get id => integer().autoIncrement()();
}

class ChatParticipants extends Table {
  IntColumn get id => integer().autoIncrement()();
}

class MessageAttachments extends Table {
  IntColumn get id => integer().autoIncrement()();
}

class StorageMeta extends Table {
  IntColumn get id => integer().autoIncrement()();
}

class CopyCheckpoints extends Table {
  IntColumn get id => integer().autoIncrement()();
}

@DriftDatabase(
  tables: [Chats, Messages, LegacyHandles, ChatParticipants, MessageAttachments, StorageMeta, CopyCheckpoints],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.inMemory() : this(NativeDatabase.memory());

  AppDatabase.file(File file) : this(NativeDatabase.createInBackground(file));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA synchronous = NORMAL');
      await customStatement('PRAGMA busy_timeout = 5000');
      await customStatement('PRAGMA cache_size = -20000');
    },
  );
}
