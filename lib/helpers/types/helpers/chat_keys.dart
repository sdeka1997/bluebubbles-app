import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/thread_grouping.dart';

/// What [threadKeys] needs from a stored chat. People are the Apple Contacts
/// card they're on, so the grouping follows the iPhone's own cards.
ChatKeys chatKeysFor(Chat chat) {
  return ChatKeys(
    guid: chat.guid,
    chatIdentifier: chat.chatIdentifier,
    isGroup: chat.style == 43 || chat.handles.length > 1,
    groupIds: {
      if (chat.groupId != null) chat.groupId!,
      if (chat.originalGroupId != null) chat.originalGroupId!,
      ...?chat.legacyGroupIds,
    },
    people: {for (final h in chat.handles) _person(h)},
    // The stored name can lag behind a rename; the newest rename is current.
    name: chat.latestGroupTitle ?? chat.displayName ?? '',
  );
}

String _person(Handle handle) {
  final card = handle.contactsV2.firstOrNull;
  if (card != null) return 'card:${card.nativeContactId}';
  final address = handle.address;
  return 'address:${address.contains('@') ? ContactV2.normalizeEmail(address) : ContactV2.normalizePhoneNumber(address)}';
}
