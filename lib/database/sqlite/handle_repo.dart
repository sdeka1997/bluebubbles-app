import 'package:bluebubbles/database/io/handle.dart' as io show adoptServerRowIds;
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/relation_fill.dart';
import 'package:bluebubbles/database/sqlite/row_writes.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:collection/collection.dart';

/// Handles in SQLite, each with its linked contacts in `contactsV2`.
class HandleRepo {
  HandleRepo(this.db);

  final DbReader db;

  Future<Handle?> byId(int id) async => (await byIds([id]))[id];

  Future<List<Handle>> all() async {
    final rows = await db.select('SELECT * FROM handles ORDER BY id');
    final handles = rows.map(handleFromRow).toList();
    await _fillContacts(handles);
    return handles;
  }

  Future<void> clear(WriteTx tx) => tx.execute('DELETE FROM handles');

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

  Future<void> _fillContacts(Iterable<Handle> handles) => RelationFill(db).handles(handles);

  /// Handles holding each of the server [rowIds], by ROWID (the sender
  /// lookup of a synced message). Should two hold one ROWID, the newer wins,
  /// as the sync's map over all handles does today.
  Future<Map<int, Handle>> byRowIds(Iterable<int> rowIds) async {
    final found = <Handle>[];
    for (final chunk in rowIds.toSet().toList().slices(500)) {
      final rows =
          await db.select('SELECT * FROM handles WHERE original_rowid IN (${sqlPlaceholders(chunk.length)})', chunk);
      found.addAll(rows.map(handleFromRow));
    }
    found.sort((a, b) => a.id!.compareTo(b.id!));
    await _fillContacts(found);
    return {for (final h in found) h.originalROWID!: h};
  }

  /// Saves [handles] by address/service (HandleActions.saveHandleAsync): a
  /// stored handle keeps its id, its ROWID when the new copy has none, and its
  /// color unless [updateColor]. Sets each handle's id.
  Future<List<Handle>> upsert(WriteTx tx, List<Handle> handles, {bool updateColor = false}) async {
    final stored = await _byUniqueKeys(tx, handles.map((h) => h.uniqueAddressAndService));
    for (final h in handles) {
      final existing = stored[h.uniqueAddressAndService];
      if (existing != null) {
        h.id = existing.id;
        h.originalROWID ??= existing.originalROWID;
        if (!updateColor) h.color = existing.color ?? h.color;
      } else {
        h.id = null;
      }
    }
    await saveByKey(tx, 'handles', 'unique_address_and_service', handles,
        key: (h) => h.uniqueAddressAndService, setId: (h, id) => h.id = id, toRow: handleToRow);
    return handles;
  }

  /// Inserts the [handles] not stored yet and returns every one by unique
  /// key: stored ones as stored, untouched (the sync's `_syncHandles`).
  Future<Map<String, Handle>> insertMissing(WriteTx tx, List<Handle> handles) async {
    final stored = await _byUniqueKeys(tx, handles.map((h) => h.uniqueAddressAndService));
    final fresh = <String, Handle>{
      for (final h in handles)
        if (!stored.containsKey(h.uniqueAddressAndService)) h.uniqueAddressAndService: h,
    };
    for (final h in fresh.values) {
      h.id = await tx.insert('handles', handleToRow(h)..['id'] = null);
    }
    return {...stored, ...fresh};
  }

  /// `adoptServerRowIds` (handle.dart) against the stored handles holding a reported
  /// ROWID; saves the ROWID of every handle it changed.
  Future<void> adoptServerRowIds(WriteTx tx, List<(Handle, int)> reported) async {
    if (reported.isEmpty) return;
    final holders = <Handle>[];
    for (final chunk in reported.map((r) => r.$2).toSet().toList().slices(500)) {
      final rows = await tx.select(
          'SELECT * FROM handles WHERE original_rowid IN (${sqlPlaceholders(chunk.length)})', chunk);
      holders.addAll(rows.map(handleFromRow));
    }
    for (final h in io.adoptServerRowIds(reported, holders)) {
      if (h.id == null) continue;
      await tx.execute('UPDATE handles SET original_rowid = ? WHERE id = ?', [h.originalROWID, h.id]);
    }
  }

  Future<Map<String, Handle>> _byUniqueKeys(DbReader reader, Iterable<String> keys) async {
    final result = <String, Handle>{};
    for (final chunk in keys.toSet().toList().slices(500)) {
      final rows = await reader.select(
          'SELECT * FROM handles WHERE unique_address_and_service IN (${sqlPlaceholders(chunk.length)})', chunk);
      for (final row in rows) {
        final h = handleFromRow(row);
        result[h.uniqueAddressAndService] = h;
      }
    }
    return result;
  }
}
