import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/utils/logger/logger.dart';

/// CustomGroupActions' ObjectBox code.
mixin ObjectBoxCustomGroupStore implements CustomGroupStore {
  @override
  Future<int> createCustomGroup(String name, Set<String> chatGuids) async {
    return Database.runInTransaction(TxMode.write, () {
      final group = CustomGroup(name: name);
      final matchedChats = chatGuids
          .map((guid) => Database.chats.query(Chat_.guid.equals(guid)).build().findFirst())
          .whereType<Chat>()
          .toList();
      group.chats.addAll(matchedChats);
      try {
        return Database.customGroups.put(group);
      } on UniqueViolationException catch (_) {
        Logger.warn('Duplicate custom group name — skipping', tag: 'CustomGroupActions');
        rethrow;
      }
    });
  }

  @override
  Future<int> renameCustomGroup(int id, String name) async {
    return Database.runInTransaction(TxMode.write, () {
      final group = Database.customGroups.get(id)!;
      group.name = name;
      try {
        return Database.customGroups.put(group);
      } on UniqueViolationException catch (_) {
        Logger.warn('Duplicate custom group name — skipping', tag: 'CustomGroupActions');
        rethrow;
      }
    });
  }

  @override
  Future<int> setCustomGroupChats(int id, Set<String> chatGuids) async {
    return Database.runInTransaction(TxMode.write, () {
      final group = Database.customGroups.get(id)!;
      final matchedChats = chatGuids
          .map((guid) => Database.chats.query(Chat_.guid.equals(guid)).build().findFirst())
          .whereType<Chat>()
          .toList();
      group.chats.clear();
      group.chats.addAll(matchedChats);
      group.chats.applyToDb();
      return group.id!;
    });
  }

  @override
  Future<int> setCustomGroupShowUnreadBadge(int id, bool value) async {
    return Database.runInTransaction(TxMode.write, () {
      final group = Database.customGroups.get(id)!;
      group.showUnreadBadge = value;
      return Database.customGroups.put(group);
    });
  }

  @override
  Future<List<int>> customGroupIds() async {
    return Database.runInTransaction(TxMode.read, () {
      final groups = Database.customGroups.getAll();
      groups.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return groups.map((g) => g.id!).toList();
    });
  }

  @override
  Future<void> reorderCustomGroups(List<int> ids) async {
    Database.runInTransaction(TxMode.write, () {
      for (var i = 0; i < ids.length; i++) {
        final group = Database.customGroups.get(ids[i]);
        if (group == null) continue;
        group.sortOrder = i;
        Database.customGroups.put(group);
      }
    });
  }

  @override
  Future<void> deleteCustomGroup(int id) async {
    Database.runInTransaction(TxMode.write, () => Database.customGroups.remove(id));
  }

  @override
  Future<CustomGroup?> customGroupById(int id) async => Database.customGroups.get(id);

  @override
  Future<List<CustomGroup>> customGroupsByIds(List<int> ids) async =>
      ids.map((id) => Database.customGroups.get(id)).whereType<CustomGroup>().toList();
}
