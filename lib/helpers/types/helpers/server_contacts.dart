import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/contact_helpers.dart';

/// One card from the Mac's Apple Contacts, with its photo as the server sent it
/// (base64), or null when the card has none.
typedef ServerContact = ({ContactV2 contact, String? avatar});

/// Parses the server's contact list. Cards without a phone number or email
/// can't match anyone, so they're skipped.
List<ServerContact> contactsFromServer(Iterable<dynamic> data) {
  final contacts = <ServerContact>[];
  for (final item in data) {
    if (item is! Map) continue;
    final displayName =
        getDisplayName(item['displayName']?.toString(), item['firstName']?.toString(), item['lastName']?.toString());
    final emails = [
      for (final e in item['emails'] as List? ?? const [])
        if (e is Map && e['address'] != null)
          ContactEmail(address: e['address'].toString(), label: e['label']?.toString() ?? '')
    ];
    final phones = [
      for (final e in item['phoneNumbers'] as List? ?? const [])
        if (e is Map && e['address'] != null)
          ContactPhone(number: e['address'].toString(), label: e['label']?.toString() ?? '')
    ];
    if (emails.isEmpty && phones.isEmpty) continue;

    final contact = ContactV2(
      nativeContactId: (item['id'] ?? displayName).toString(),
      displayName: displayName,
      firstName: item['firstName']?.toString(),
      lastName: item['lastName']?.toString(),
      nickname: item['nickname']?.toString(),
    );
    contact.phoneNumbers = phones;
    contact.emailAddresses = emails;
    final avatar = item['avatar']?.toString();
    contacts.add((contact: contact, avatar: avatar == null || avatar.isEmpty ? null : avatar));
  }
  return contacts;
}

/// Ids of stored contacts the server no longer has, including any left from
/// when the app read the phone's own contacts.
Set<String> contactIdsToRemove(Iterable<String> stored, Iterable<String> fromServer) =>
    stored.toSet().difference(fromServer.toSet());


/// The server's name for the current state of its contact photos, or null from
/// a server that doesn't send one.
String? photosVersionOf(dynamic body) {
  if (body is! Map) return null;
  final metadata = body['metadata'];
  return metadata is Map ? metadata['photosVersion']?.toString() : null;
}

/// Whether to download the contact photos: only when they may differ from the
/// ones saved from [saved]. A server that sends no version always needs them.
bool photosNeeded({required String? server, required String? saved}) => server == null || server != saved;
