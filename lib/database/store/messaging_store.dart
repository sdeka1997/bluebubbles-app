import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/store/objectbox/objectbox_messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_messaging_store.dart';
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

abstract class MessagingStore implements HandleStore, CustomGroupStore {
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
