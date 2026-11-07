import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

class Chats extends Table {
  IntColumn get id => integer().autoIncrement()();
}

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
