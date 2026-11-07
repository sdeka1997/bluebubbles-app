import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:collection/collection.dart';

/// Handles in SQLite, each with its linked contacts in `contactsV2`.
class HandleRepo {
  HandleRepo(this.db);

  final DbReader db;

  Future<Handle?> byId(int id) async => (await byIds([id]))[id];

  /// The handle for [address] on [service], as `Handle.findOne(addressAndService:)` finds it.
  Future<Handle?> byUniqueKey(String address, String service) async {
    final rows = await db.select('SELECT * FROM handles WHERE address = ? AND service = ? LIMIT 1', [address, service]);
    if (rows.isEmpty) return null;
    final handle = handleFromRow(rows.single);
    await _fillContacts([handle]);
    return handle;
  }

  Future<Map<int, Handle>> byIds(Iterable<int> ids) async {
    final handles = <int, Handle>{};
    for (final chunk in ids.toSet().toList().slices(500)) {
      for (final row in await db.select('SELECT * FROM handles WHERE id IN (${sqlPlaceholders(chunk.length)})', chunk)) {
        final handle = handleFromRow(row);
        handles[handle.id!] = handle;
      }
    }
    await _fillContacts(handles.values);
    return handles;
  }

  Future<void> _fillContacts(Iterable<Handle> handles) async {
    final byId = {for (final h in handles) h.id!: h};
    for (final chunk in byId.keys.toList().slices(500)) {
      final rows = await db.select(
          'SELECT ch.handle_id AS linked_handle_id, c.* FROM contact_handles ch JOIN contacts c ON c.id = ch.contact_id '
          'WHERE ch.handle_id IN (${sqlPlaceholders(chunk.length)})',
          chunk);
      for (final row in rows) {
        byId[row['linked_handle_id'] as int]!.contactsV2.add(contactFromRow(row));
      }
    }
  }
}
