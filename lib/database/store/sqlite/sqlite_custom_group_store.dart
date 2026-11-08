import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/custom_group_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_messaging_store.dart';
import 'package:bluebubbles/utils/logger/logger.dart';

/// CustomGroupActions on SQLite.
mixin SqliteCustomGroupStore implements CustomGroupStore, SqliteStorePart {
  CustomGroupRepo get _groups => CustomGroupRepo(db);

  @override
  Future<int> createCustomGroup(String name, Set<String> chatGuids) {
    return db.write((tx) async {
      try {
        return await _groups.create(tx, name, chatGuids);
      } catch (e) {
        if (isUniqueViolation(e)) Logger.warn('Duplicate custom group name — skipping', tag: 'CustomGroupActions');
        rethrow;
      }
    });
  }

  @override
  Future<int> renameCustomGroup(int id, String name) {
    return db.write((tx) async {
      await _require(tx, id);
      try {
        await _groups.rename(tx, id, name);
      } catch (e) {
        if (isUniqueViolation(e)) Logger.warn('Duplicate custom group name — skipping', tag: 'CustomGroupActions');
        rethrow;
      }
      return id;
    });
  }

  @override
  Future<int> setCustomGroupChats(int id, Set<String> chatGuids) {
    return db.write((tx) async {
      await _require(tx, id);
      await _groups.setChats(tx, id, chatGuids);
      return id;
    });
  }

  @override
  Future<int> setCustomGroupShowUnreadBadge(int id, bool value) {
    return db.write((tx) async {
      await _require(tx, id);
      await _groups.setShowUnreadBadge(tx, id, value);
      return id;
    });
  }

  /// ObjectBox's `customGroups.get(id)!`: a missing group throws.
  Future<void> _require(WriteTx tx, int id) async {
    if ((await tx.select('SELECT 1 FROM custom_groups WHERE id = ?', [id])).isEmpty) {
      throw StateError('No custom group $id');
    }
  }

  @override
  Future<List<int>> customGroupIds() async => [for (final g in await _groups.all()) g.id!];

  @override
  Future<void> reorderCustomGroups(List<int> ids) => db.write((tx) => _groups.reorder(tx, ids));

  @override
  Future<void> deleteCustomGroup(int id) => db.write((tx) => _groups.delete(tx, id));

  @override
  Future<CustomGroup?> customGroupById(int id) => _groups.byId(id);

  @override
  Future<List<CustomGroup>> customGroupsByIds(List<int> ids) async => [
        for (final group in await _groups.all())
          if (ids.contains(group.id)) group,
      ]..sort((a, b) => ids.indexOf(a.id!).compareTo(ids.indexOf(b.id!)));
}
