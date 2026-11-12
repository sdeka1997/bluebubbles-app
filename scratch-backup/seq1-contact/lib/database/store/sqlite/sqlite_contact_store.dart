import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/contact_repo.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_messaging_store.dart';
import 'package:bluebubbles/helpers/types/helpers/server_contacts.dart';

/// ContactV2Actions on SQLite repositories.
mixin SqliteContactStore implements ContactStore, SqliteStorePart {
  Set<String> _phoneVariants(String phone) {
    final variants = <String>{};
    final normalized = ContactV2.normalizePhoneNumber(phone);
    if (normalized.isEmpty) return variants;
    variants.add(normalized);
    if (normalized.startsWith('+')) {
      variants.add(normalized.substring(1));
      for (int i = 1; i <= 3 && i < normalized.length; i++) {
        final value = normalized.substring(i + 1);
        if (value.isNotEmpty) variants.add(value);
      }
    } else {
      variants.add('+$normalized');
      for (int i = 1; i <= 3 && i < normalized.length; i++) {
        final value = normalized.substring(i);
        if (value.isNotEmpty) {
          variants.add(value);
          variants.add('+$value');
        }
      }
    }
    return variants;
  }

  @override
  Future<ContactSyncResult> syncContacts(
    List<ContactV2> networkContacts,
    Map<String, String?> avatarPaths, {
    required bool fetched,
  }) {
    return db.write((tx) async {
      final repo = ContactRepo(tx);
      final affected = <int>{};
      var matchedCount = 0;
      final existingContacts = {for (final c in await repo.all()) c.nativeContactId: c};
      if (fetched) {
        final stale = contactIdsToRemove(existingContacts.keys, networkContacts.map((c) => c.nativeContactId));
        affected.addAll(await repo.deleteByNativeIds(tx, stale));
        existingContacts.removeWhere((id, _) => stale.contains(id));
      }

      final handles = (await tx.select('SELECT * FROM handles ORDER BY id')).map(handleFromRow).toList();
      final emailHandleMap = <String, List<Handle>>{};
      final phoneHandleMap = <String, List<Handle>>{};
      for (final handle in handles) {
        if (handle.address.contains('@')) {
          final normalized = ContactV2.normalizeEmail(handle.address);
          emailHandleMap.putIfAbsent(normalized, () => []).add(handle);
          if (handle.formattedAddress != null) {
            final formatted = ContactV2.normalizeEmail(handle.formattedAddress!);
            if (formatted != normalized) emailHandleMap.putIfAbsent(formatted, () => []).add(handle);
          }
        } else {
          for (final variant in _phoneVariants(handle.address)) {
            phoneHandleMap.putIfAbsent(variant, () => []).add(handle);
          }
          if (handle.formattedAddress != null) {
            for (final variant in _phoneVariants(handle.formattedAddress!)) {
              phoneHandleMap.putIfAbsent(variant, () => []).add(handle);
            }
          }
        }
      }

      for (final raw in networkContacts) {
        final addresses = <String>{};
        for (final phone in raw.phoneNumbers) {
          final normalized = ContactV2.normalizePhoneNumber(phone.number);
          if (normalized.isNotEmpty) addresses.add(normalized);
        }
        for (final email in raw.emailAddresses) {
          final normalized = ContactV2.normalizeEmail(email.address);
          if (normalized.isNotEmpty) addresses.add(normalized);
        }
        if (addresses.isEmpty) continue;

        final old = existingContacts[raw.nativeContactId];
        final oldHandleIds = old?.handles.map((h) => h.id).whereType<int>().toSet() ?? <int>{};
        final oldName = old?.computedDisplayName;
        final oldAvatar = old?.avatarPath;
        final contact = old ?? ContactV2(displayName: raw.displayName, nativeContactId: raw.nativeContactId);
        contact
          ..displayName = raw.displayName
          ..addresses = addresses.toList()
          ..firstName = raw.firstName
          ..lastName = raw.lastName
          ..middleName = raw.middleName
          ..namePrefix = raw.namePrefix
          ..nameSuffix = raw.nameSuffix
          ..nickname = raw.nickname
          ..company = raw.company
          ..phoneNumbers = raw.phoneNumbers
          ..emailAddresses = raw.emailAddresses
          ..isNative = false;
        if (old == null || avatarPaths.containsKey(raw.nativeContactId)) {
          contact.avatarPath = avatarPaths[raw.nativeContactId];
        }
        if (old != null && (oldName != contact.computedDisplayName || oldAvatar != contact.avatarPath)) {
          affected.addAll(oldHandleIds);
        }

        final matched = <Handle>{};
        for (final address in addresses) {
          if (address.contains('@')) {
            matched.addAll(emailHandleMap[address] ?? const <Handle>[]);
          } else {
            for (final variant in _phoneVariants(address)) {
              matched.addAll(phoneHandleMap[variant] ?? const <Handle>[]);
            }
          }
        }
        if (matched.isNotEmpty) matchedCount++;
        final newHandleIds = matched.map((h) => h.id).whereType<int>().toSet();
        final handlesChanged = old == null ||
            oldHandleIds.length != newHandleIds.length ||
            !oldHandleIds.containsAll(newHandleIds);

        await repo.upsert(tx, [contact]);
        await repo.setHandles(tx, contact.id, newHandleIds);
        existingContacts[contact.nativeContactId] = contact;
        if (!handlesChanged) continue;
        affected
          ..addAll(oldHandleIds)
          ..addAll(newHandleIds);
        for (final handle in matched) {
          final rows = await tx.select(
            'SELECT c.id FROM chats c WHERE instr(c.guid, ?) > 0 '
            'AND NOT EXISTS (SELECT 1 FROM chat_handles ch WHERE ch.chat_id = c.id)',
            [';-;${handle.address}'],
          );
          for (final row in rows) {
            final chatId = row['id'] as int;
            await tx.execute('INSERT INTO chat_handles (chat_id, handle_id) VALUES (?, ?)', [chatId, handle.id]);
            tx.markChanged('chat_handles', [chatId]);
          }
        }
      }
      return ContactSyncResult(affectedHandleIds: affected.toList(), matchedContactCount: matchedCount);
    });
  }

  @override
  Future<List<String>> contactNativeIds() => ContactRepo(db).nativeIds();

  @override
  Future<int?> findContactId(String nativeContactId) async => (await ContactRepo(db).byNativeId(nativeContactId))?.id;

  @override
  Future<List<int>> contactIdsForHandles(List<int> handleIds) async =>
      (await ContactRepo(db).forHandles(handleIds)).map((c) => c.id).toList();

  @override
  Future<int?> contactIdByAddress(String address) async => (await ContactRepo(db).byAddress(address))?.id;

  @override
  Future<List<int>> allContactIds() async => (await ContactRepo(db).all()).map((c) => c.id).toList();

  @override
  Future<ContactV2?> contactById(int id) => ContactRepo(db).byId(id);

  @override
  Future<List<ContactV2>> contactsByIds(List<int> ids) async {
    final found = {for (final c in await ContactRepo(db).byIds(ids)) c.id: c};
    return [for (final id in ids) ?found[id]];
  }
}
