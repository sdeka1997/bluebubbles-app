import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:collection/collection.dart';

/// Saves [items] into [table] by their unique [keyColumn], as ObjectBox's
/// `put` after a lookup by that key does today: an item whose key is stored
/// takes the stored id and overwrites the row; any other item is inserted
/// under a new id (an id it arrived with, e.g. a server ROWID, is dropped).
/// An item without a key is always inserted. A key twice in [items] is one
/// row, the last one wins. Sets each item's id via [setId].
Future<void> saveByKey<T>(
  WriteTx tx,
  String table,
  String keyColumn,
  List<T> items, {
  required String? Function(T item) key,
  required void Function(T item, int? id) setId,
  required Map<String, Object?> Function(T item) toRow,
}) async {
  final keys = items.map(key).whereType<String>().toSet().toList();
  final stored = <String, int>{};
  for (final chunk in keys.slices(500)) {
    final rows = await tx.select('SELECT id, $keyColumn FROM $table WHERE $keyColumn IN (${sqlPlaceholders(chunk.length)})', chunk);
    for (final row in rows) {
      stored[row[keyColumn] as String] = row['id'] as int;
    }
  }
  for (final item in items) {
    final k = key(item);
    final id = k == null ? null : stored[k];
    setId(item, id);
    final row = toRow(item);
    if (id != null) {
      await tx.update(table, row);
    } else {
      final newId = await tx.insert(table, row..['id'] = null);
      setId(item, newId);
      if (k != null) stored[k] = newId;
    }
  }
}
