import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/relation_fill.dart';
import 'package:bluebubbles/database/sqlite/row_writes.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:collection/collection.dart';

/// Contacts in SQLite, each with its linked handles in `handles`
/// (contact_handles), as ContactV2Actions reads and writes them today.
class ContactRepo {
  ContactRepo(this.db);

  final DbReader db;

  Future<ContactV2?> byId(int id) async => (await byIds([id])).firstOrNull;

  Future<List<ContactV2>> byIds(Iterable<int> ids) async {
    final result = <ContactV2>[];
    for (final chunk in ids.toSet().toList().slices(500)) {
      final rows = await db.select('SELECT * FROM contacts WHERE id IN (${sqlPlaceholders(chunk.length)})', chunk);
      result.addAll(rows.map(contactFromRow));
    }
    return _fillHandles(result..sort((a, b) => a.id.compareTo(b.id)));
  }

  Future<ContactV2?> byNativeId(String nativeId) async {
    final rows = await db.select('SELECT * FROM contacts WHERE native_contact_id = ?', [nativeId]);
    return (await _fillHandles(rows.map(contactFromRow).toList())).firstOrNull;
  }

  /// The contacts linked to any of [handleIds], each once.
  Future<List<ContactV2>> forHandles(Iterable<int> handleIds) async {
    final ids = <int>{};
    for (final chunk in handleIds.toSet().toList().slices(500)) {
      final rows = await db.select(
          'SELECT contact_id FROM contact_handles WHERE handle_id IN (${sqlPlaceholders(chunk.length)})', chunk);
      ids.addAll(rows.map((r) => r['contact_id'] as int));
    }
    return byIds(ids);
  }

  /// The first contact (by id) holding [address], matched the way
  /// [ContactV2.hasMatchingAddress] matches. Reads every contact, as today:
  /// addresses are a JSON list with no index, and the table is small (one
  /// row per address-book card).
  Future<ContactV2?> byAddress(String address) async {
    final rows = await db.select('SELECT * FROM contacts');
    final match = rows.map(contactFromRow).sortedBy<num>((c) => c.id).firstWhereOrNull((c) => c.hasMatchingAddress(address));
    return match == null ? null : (await _fillHandles([match])).single;
  }

  /// Every contact by display name (case-insensitive, as ObjectBox orders
  /// strings), sorted in Dart: an ORDER BY would sort in a temporary B-tree.
  Future<List<ContactV2>> all() async {
    final rows = await db.select('SELECT * FROM contacts');
    final contacts = rows.map(contactFromRow).toList()
      ..sort((a, b) {
        final byName = a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
        return byName != 0 ? byName : a.id.compareTo(b.id);
      });
    return _fillHandles(contacts);
  }

  Future<List<String>> nativeIds() async =>
      [for (final row in await db.select('SELECT native_contact_id FROM contacts')) row['native_contact_id'] as String];

  /// Inserts or updates [contacts] by native contact id, keeping a stored
  /// contact's id. Links: [setHandles]. Sets each contact's id.
  Future<List<ContactV2>> upsert(WriteTx tx, List<ContactV2> contacts) async {
    await saveByKey(tx, 'contacts', 'native_contact_id', contacts,
        key: (c) => c.nativeContactId, setId: (c, id) => c.id = id ?? 0, toRow: contactToRow);
    return contacts;
  }

  /// Makes [handleIds] the handles of [contactId] (ids with no stored handle
  /// are skipped). Reported as a change of the contact in `contact_handles`.
  Future<void> setHandles(WriteTx tx, int contactId, Iterable<int> handleIds) async {
    await tx.execute('DELETE FROM contact_handles WHERE contact_id = ?', [contactId]);
    for (final handleId in handleIds.toSet()) {
      await tx.execute(
          'INSERT INTO contact_handles (contact_id, handle_id) SELECT ?, id FROM handles WHERE id = ?', [contactId, handleId]);
    }
    tx.markChanged('contact_handles', [contactId]);
  }

  /// Removes the contacts with [nativeIds] and their links. Returns the ids of
  /// the handles they were linked to (whose names change).
  Future<List<int>> deleteByNativeIds(WriteTx tx, Iterable<String> nativeIds) async {
    final contactIds = <int>[];
    final handleIds = <int>{};
    for (final chunk in nativeIds.toSet().toList().slices(500)) {
      final rows = await tx.select(
          'SELECT id FROM contacts WHERE native_contact_id IN (${sqlPlaceholders(chunk.length)})', chunk);
      contactIds.addAll(rows.map((r) => r['id'] as int));
    }
    for (final chunk in contactIds.slices(500)) {
      final list = sqlPlaceholders(chunk.length);
      final links = await tx.select('SELECT handle_id FROM contact_handles WHERE contact_id IN ($list)', chunk);
      handleIds.addAll(links.map((r) => r['handle_id'] as int));
      // Explicitly: schema v1 as generated has no foreign keys (drift_dev drops
      // the `references` clauses), so nothing cascades.
      await tx.execute('DELETE FROM contact_handles WHERE contact_id IN ($list)', chunk);
      await tx.execute('DELETE FROM contacts WHERE id IN ($list)', chunk);
    }
    if (contactIds.isNotEmpty) tx.markChanged('contact_handles', contactIds);
    return handleIds.toList();
  }

  Future<List<ContactV2>> _fillHandles(List<ContactV2> contacts) async {
    await RelationFill(db).contacts(contacts);
    return contacts;
  }
}
