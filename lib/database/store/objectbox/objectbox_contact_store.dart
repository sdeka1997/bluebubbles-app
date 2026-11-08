import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/helpers/types/helpers/server_contacts.dart';
import 'package:bluebubbles/utils/logger/logger.dart';

/// ContactV2Actions' ObjectBox transaction and reads, moved behind MessagingStore.
mixin ObjectBoxContactStore implements ContactStore {
  Set<String> _phoneVariants(String phone) {
    final variants = <String>{};
    final normalized = ContactV2.normalizePhoneNumber(phone);
    if (normalized.isEmpty) return variants;
    variants.add(normalized);
    if (normalized.startsWith('+')) {
      variants.add(normalized.substring(1));
      for (int i = 1; i <= 3 && i < normalized.length; i++) {
        final withoutCountryCode = normalized.substring(i + 1);
        if (withoutCountryCode.isNotEmpty) variants.add(withoutCountryCode);
      }
    } else {
      variants.add('+$normalized');
      for (int i = 1; i <= 3 && i < normalized.length; i++) {
        final withoutPrefix = normalized.substring(i);
        if (withoutPrefix.isNotEmpty) {
          variants.add(withoutPrefix);
          variants.add('+$withoutPrefix');
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
  }) async {
    final affectedHandleIds = <int>[];
    var matchedContactCount = 0;
    Database.runInTransaction(TxMode.write, () {
      final contactsBox = Database.contactsV2;
      final handlesBox = Database.handles;

      if (fetched) {
        final stale = contactIdsToRemove(
          contactsBox.getAll().map((c) => c.nativeContactId),
          networkContacts.map((c) => c.nativeContactId),
        );
        if (stale.isNotEmpty) {
          final query = contactsBox.query(ContactV2_.nativeContactId.oneOf(stale.toList())).build();
          final removed = query.find();
          query.close();
          for (final contact in removed) {
            affectedHandleIds.addAll(contact.handles.map((h) => h.id).whereType<int>());
          }
          contactsBox.removeMany(removed.map((c) => c.id).toList());
          Logger.info('[ContactV2] Removed ${removed.length} contacts no longer on the server');
        }
      }
      final allHandles = handlesBox.getAll();
      final emailHandleMap = <String, List<Handle>>{};
      final phoneHandleMap = <String, List<Handle>>{};
      for (final handle in allHandles) {
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

      for (final rawContact in networkContacts) {
        final normalizedAddresses = <String>{};
        for (final phone in rawContact.phoneNumbers) {
          final normalized = ContactV2.normalizePhoneNumber(phone.number);
          if (normalized.isNotEmpty) normalizedAddresses.add(normalized);
        }
        for (final email in rawContact.emailAddresses) {
          final normalized = ContactV2.normalizeEmail(email.address);
          if (normalized.isNotEmpty) normalizedAddresses.add(normalized);
        }
        if (normalizedAddresses.isEmpty) continue;

        final existingQuery = contactsBox.query(ContactV2_.nativeContactId.equals(rawContact.nativeContactId)).build();
        final existingContact = existingQuery.findFirst();
        existingQuery.close();
        final ContactV2 contact;
        var existingHandleIds = <int>{};
        if (existingContact != null) {
          contact = existingContact;
          final oldComputedName = contact.computedDisplayName;
          final oldAvatarPath = contact.avatarPath;
          contact
            ..displayName = rawContact.displayName
            ..addresses = normalizedAddresses.toList()
            ..firstName = rawContact.firstName
            ..lastName = rawContact.lastName
            ..middleName = rawContact.middleName
            ..namePrefix = rawContact.namePrefix
            ..nameSuffix = rawContact.nameSuffix
            ..nickname = rawContact.nickname
            ..company = rawContact.company
            ..phoneNumbers = rawContact.phoneNumbers
            ..emailAddresses = rawContact.emailAddresses;
          if (avatarPaths.containsKey(contact.nativeContactId)) {
            contact.avatarPath = avatarPaths[contact.nativeContactId];
          }
          existingHandleIds = contact.handles.map((h) => h.id).whereType<int>().toSet();
          if (oldComputedName != contact.computedDisplayName || oldAvatarPath != contact.avatarPath) {
            affectedHandleIds.addAll(existingHandleIds);
          }
        } else {
          contact = ContactV2(
            displayName: rawContact.displayName,
            nativeContactId: rawContact.nativeContactId,
            avatarPath: avatarPaths[rawContact.nativeContactId],
            addresses: normalizedAddresses.toList(),
            firstName: rawContact.firstName,
            lastName: rawContact.lastName,
            middleName: rawContact.middleName,
            namePrefix: rawContact.namePrefix,
            nameSuffix: rawContact.nameSuffix,
            nickname: rawContact.nickname,
            company: rawContact.company,
          )
            ..phoneNumbers = rawContact.phoneNumbers
            ..emailAddresses = rawContact.emailAddresses;
        }
        contact.isNative = false;

        final matchedHandles = <Handle>{};
        for (final address in normalizedAddresses) {
          if (address.contains('@')) {
            matchedHandles.addAll(emailHandleMap[address] ?? const []);
          } else {
            for (final variant in _phoneVariants(address)) {
              matchedHandles.addAll(phoneHandleMap[variant] ?? const []);
            }
          }
        }
        if (matchedHandles.isNotEmpty) matchedContactCount++;
        final newHandleIds = matchedHandles.map((h) => h.id).whereType<int>().toSet();
        final handlesChanged = existingContact == null ||
            existingHandleIds.length != newHandleIds.length ||
            !existingHandleIds.containsAll(newHandleIds);
        contact.handles
          ..clear()
          ..addAll(matchedHandles);
        try {
          contactsBox.put(contact);
        } on UniqueViolationException catch (e) {
          Logger.warn('[ContactV2] Unique violation for contact ${contact.nativeContactId}: $e');
        }

        if (handlesChanged) {
          affectedHandleIds
            ..addAll(existingHandleIds)
            ..addAll(newHandleIds);
          final chatsToUpdate = <Chat>{};
          for (final handle in matchedHandles) {
            final chatQuery = Database.chats.query(Chat_.guid.contains(';-;${handle.address}')).build();
            final chats = chatQuery.find();
            chatQuery.close();
            for (final chat in chats) {
              if (chat.handles.isEmpty) {
                chat.handles.add(handle);
                chatsToUpdate.add(chat);
              }
            }
          }
          if (chatsToUpdate.isNotEmpty) Database.chats.putMany(chatsToUpdate.toList());
        }
      }
    });
    return ContactSyncResult(
      affectedHandleIds: affectedHandleIds.toSet().toList(),
      matchedContactCount: matchedContactCount,
    );
  }

  @override
  Future<List<String>> contactNativeIds() async =>
      Database.runInTransaction(TxMode.read, () => Database.contactsV2.getAll().map((c) => c.nativeContactId).toList());

  @override
  Future<int?> findContactId(String nativeContactId) async => Database.runInTransaction(TxMode.read, () {
        final query = Database.contactsV2.query(ContactV2_.nativeContactId.equals(nativeContactId)).build()..limit = 1;
        final id = query.findFirst()?.id;
        query.close();
        return id;
      });

  @override
  Future<List<int>> contactIdsForHandles(List<int> handleIds) async => Database.runInTransaction(TxMode.read, () {
        final ids = <int>{};
        for (final handle in Database.handles.getMany(handleIds).whereType<Handle>()) {
          ids.addAll(handle.contactsV2.map((c) => c.id).where((id) => id != 0));
        }
        return ids.toList();
      });

  @override
  Future<int?> contactIdByAddress(String address) async => Database.runInTransaction(TxMode.read, () {
        final normalized =
            address.contains('@') ? ContactV2.normalizeEmail(address) : ContactV2.normalizePhoneNumber(address);
        for (final contact in Database.contactsV2.getAll()) {
          if (contact.hasMatchingAddress(normalized)) return contact.id;
        }
        return null;
      });

  @override
  Future<List<int>> allContactIds() async => Database.runInTransaction(TxMode.read, () {
        final query = (Database.contactsV2.query()..order(ContactV2_.displayName)).build();
        final ids = query.find().map((c) => c.id).toList();
        query.close();
        return ids;
      });

  @override
  Future<ContactV2?> contactById(int id) async => Database.contactsV2.get(id);

  @override
  Future<List<ContactV2>> contactsByIds(List<int> ids) async =>
      Database.contactsV2.getMany(ids).whereType<ContactV2>().toList();
}
