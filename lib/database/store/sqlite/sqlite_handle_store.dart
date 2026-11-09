import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/handle_repo.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_messaging_store.dart';

/// HandleActions on SQLite.
mixin SqliteHandleStore implements HandleStore, SqliteStorePart {
  @override
  Future<int?> saveHandle(Handle handle, {required bool updateColor, required bool matchOnOriginalROWID}) {
    return db.write((tx) async {
      final existing = await _match(tx, handle, matchOnOriginalROWID);
      if (existing != null) {
        handle.id = existing.id;
        handle.originalROWID ??= existing.originalROWID;
      }
      if (!updateColor) {
        handle.color = existing?.color ?? handle.color;
      }
      try {
        handle.id = await _put(tx, handle);
      } catch (e) {
        if (!isUniqueViolation(e)) rethrow;
      }
      return handle.id!;
    });
  }

  @override
  Future<List<int>> saveHandles(List<Handle> handles, {required bool matchOnOriginalROWID}) {
    return db.write((tx) async {
      for (final h in handles) {
        final existing = await _match(tx, h, matchOnOriginalROWID);
        if (existing != null) {
          h.id = existing.id;
          h.originalROWID ??= existing.originalROWID;
        }
      }
      for (final h in handles) {
        h.id = await _put(tx, h);
      }
      return handles.map((e) => e.id!).toList();
    });
  }

  /// The stored handle [h] saves over: by ROWID, or by address and service
  /// (Handle.findOne, first stored wins).
  Future<Handle?> _match(DbReader reader, Handle h, bool matchOnOriginalROWID) async {
    if (matchOnOriginalROWID) {
      if (h.originalROWID == null) return null;
      return _first(reader, 'original_rowid = ?', [h.originalROWID]);
    }
    return _first(reader, 'address = ? AND service = ?', [h.address, h.service]);
  }

  Future<Handle?> _first(DbReader reader, String where, List<Object?> args) async {
    final rows = await reader.select('SELECT * FROM handles WHERE $where ORDER BY id LIMIT 1', args);
    return rows.isEmpty ? null : handleFromRow(rows.single);
  }

  /// ObjectBox's put for a handle matched by [_match] (id set to the stored
  /// row) or new. An id the handle arrived with that names a different stored
  /// handle (a server payload's ROWID lands in `id` via Handle.fromMap) is not
  /// a local id: the handle is inserted under a new one instead of
  /// overwriting that other handle, as ObjectBox's put would.
  Future<int> _put(WriteTx tx, Handle h) async {
    final row = handleToRow(h);
    if (h.id != null) {
      final stored = await tx.select('SELECT unique_address_and_service FROM handles WHERE id = ?', [h.id]);
      if (stored.isNotEmpty && stored.single['unique_address_and_service'] == h.uniqueAddressAndService) {
        await tx.update('handles', row);
        return h.id!;
      }
    }
    return tx.insert('handles', row..['id'] = null);
  }

  @override
  Future<int?> findHandleId({int? id, int? originalROWID, String? address, String? service}) async {
    Future<int?> firstId(String where, List<Object?> args) async {
      final rows = await db.select('SELECT id FROM handles WHERE $where ORDER BY id LIMIT 1', args);
      return rows.isEmpty ? null : rows.single['id'] as int;
    }

    if (id != null && id != 0) {
      return await firstId('id = ?', [id]) ?? await firstId('original_rowid = ?', [id]);
    } else if (originalROWID != null) {
      return firstId('original_rowid = ?', [originalROWID]);
    } else if (address != null && service != null) {
      return firstId('address = ? AND service = ?', [address, service]);
    }
    return null;
  }

  @override
  Future<List<int>> allHandleIds() async =>
      [for (final row in await db.select('SELECT id FROM handles ORDER BY id')) row['id'] as int];

  @override
  Future<Map<String, int>> localCounts() async {
    final row = (await db.select('SELECT '
            '(SELECT count(*) FROM messages WHERE date_deleted_us IS NULL) AS messages, '
            '(SELECT count(*) FROM chats WHERE date_deleted_us IS NULL) AS chats, '
            '(SELECT count(*) FROM handles) AS handles, '
            '(SELECT count(*) FROM attachments WHERE mime_type IS NOT NULL) AS attachments, '
            "(SELECT count(*) FROM attachments WHERE mime_type GLOB 'image/*') AS images, "
            "(SELECT count(*) FROM attachments WHERE mime_type GLOB 'video/*') AS videos, "
            "(SELECT count(*) FROM attachments WHERE mime_type = 'text/x-vlocation' OR uti = 'public.vlocation') AS locations"))
        .single;
    return {for (final key in ['messages', 'chats', 'handles', 'attachments', 'images', 'videos', 'locations']) key: row[key] as int};
  }

  @override
  Future<int> handleCount() async => (await db.select('SELECT count(*) AS n FROM handles')).first['n'] as int;

  @override
  Future<List<Handle>> handlesWithoutRowId() async {
    final ids = [for (final row in await db.select('SELECT id FROM handles WHERE original_rowid IS NULL ORDER BY id')) row['id'] as int];
    return inIdOrder(ids, await HandleRepo(db).byIds(ids));
  }

  @override
  Future<List<Handle>> allHandles() => HandleRepo(db).all();

  @override
  Future<void> clearHandles() => db.write((tx) => HandleRepo(tx).clear(tx));

  @override
  Future<Handle?> handleById(int id) => HandleRepo(db).byId(id);

  @override
  Future<List<Handle>> handlesByIds(List<int> ids) async => inIdOrder(ids, await HandleRepo(db).byIds(ids));
}
