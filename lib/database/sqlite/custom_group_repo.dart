import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/relation_fill.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:collection/collection.dart';

/// Custom chat groups in SQLite, each with its chats (custom_group_chats), as
/// CustomGroupActions reads and writes them today.
class CustomGroupRepo {
  CustomGroupRepo(this.db);

  final DbReader db;

  Future<CustomGroup?> byId(int id) async {
    final rows = await db.select('SELECT * FROM custom_groups WHERE id = ?', [id]);
    return (await _fillChats(rows.map(customGroupFromRow).toList())).firstOrNull;
  }

  /// Every group in its settings order, sorted in Dart (a handful of rows; an
  /// ORDER BY would sort in a temporary B-tree).
  Future<List<CustomGroup>> all() async {
    final groups = (await db.select('SELECT * FROM custom_groups')).map(customGroupFromRow).toList()
      ..sort((a, b) => a.sortOrder != b.sortOrder ? a.sortOrder.compareTo(b.sortOrder) : a.id!.compareTo(b.id!));
    return _fillChats(groups);
  }

  /// The groups [chatId] belongs to (the `Chat.customGroups` backlink).
  Future<List<int>> idsForChat(int chatId) async =>
      [for (final row in await db.select('SELECT group_id FROM custom_group_chats WHERE chat_id = ?', [chatId])) row['group_id'] as int];

  /// Creates the group [name] holding the stored chats among [chatGuids].
  /// Throws (SQLITE_CONSTRAINT) when the name is taken, as ObjectBox's unique
  /// name does. Returns the new id.
  Future<int> create(WriteTx tx, String name, Iterable<String> chatGuids) async {
    final id = await tx.insert('custom_groups', customGroupToRow(CustomGroup(name: name))..['id'] = null);
    await setChats(tx, id, chatGuids);
    return id;
  }

  Future<void> rename(WriteTx tx, int id, String name) =>
      tx.execute('UPDATE custom_groups SET name = ? WHERE id = ?', [name, id]);

  /// Makes the stored chats among [chatGuids] the chats of group [id].
  Future<void> setChats(WriteTx tx, int id, Iterable<String> chatGuids) async {
    await tx.execute('DELETE FROM custom_group_chats WHERE group_id = ?', [id]);
    for (final chunk in chatGuids.toSet().toList().slices(500)) {
      await tx.execute(
          'INSERT INTO custom_group_chats (group_id, chat_id) '
          'SELECT ?, id FROM chats WHERE guid IN (${sqlPlaceholders(chunk.length)})',
          [id, ...chunk]);
    }
    tx.markChanged('custom_group_chats', [id]);
  }

  Future<void> setShowUnreadBadge(WriteTx tx, int id, bool value) =>
      tx.execute('UPDATE custom_groups SET show_unread_badge = ? WHERE id = ?', [value, id]);

  /// Gives each group of [ids] its position as sort order; unknown ids are skipped.
  Future<void> reorder(WriteTx tx, List<int> ids) async {
    for (final (i, id) in ids.indexed) {
      await tx.execute('UPDATE custom_groups SET sort_order = ? WHERE id = ?', [i, id]);
    }
  }

  /// Removes group [id] and its custom_group_chats rows (explicitly: schema v1
  /// as generated has no foreign keys, so nothing cascades).
  Future<void> delete(WriteTx tx, int id) async {
    await tx.execute('DELETE FROM custom_group_chats WHERE group_id = ?', [id]);
    await tx.execute('DELETE FROM custom_groups WHERE id = ?', [id]);
    tx.markChanged('custom_group_chats', [id]);
  }

  Future<List<CustomGroup>> _fillChats(List<CustomGroup> groups) async {
    await RelationFill(db).groups(groups);
    return groups;
  }
}
