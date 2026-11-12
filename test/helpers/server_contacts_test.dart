import 'package:bluebubbles/helpers/types/helpers/contact_helpers.dart';
import 'package:bluebubbles/helpers/types/helpers/server_contacts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a card becomes a contact with its phones, emails and photo', () {
    final parsed = contactsFromServer([
      {
        'id': 'ABC:ABPerson',
        'displayName': 'Jiahui Liao',
        'firstName': 'Jiahui',
        'lastName': 'Liao',
        'phoneNumbers': [
          {'address': '+1 (555) 000-0001', 'label': 'mobile'}
        ],
        'emails': [
          {'address': 'jiahui@example.com', 'label': null}
        ],
        'avatar': 'AAAA',
      }
    ]);
    expect(parsed, hasLength(1));
    final contact = parsed.single.contact;
    expect(contact.nativeContactId, 'ABC:ABPerson');
    expect(contact.displayName, 'Jiahui Liao');
    expect(contact.firstName, 'Jiahui');
    expect(contact.lastName, 'Liao');
    expect(contact.isNative, isFalse);
    expect(contact.phoneNumbers.single.number, '+1 (555) 000-0001');
    expect(contact.phoneNumbers.single.label, 'mobile');
    expect(contact.emailAddresses.single.address, 'jiahui@example.com');
    expect(contact.emailAddresses.single.label, '');
    expect(parsed.single.avatar, 'AAAA');
  });

  test('a card without a display name is named the way the app names people', () {
    final parsed = contactsFromServer([
      {
        'id': '1',
        'firstName': 'Ada',
        'lastName': 'Lovelace',
        'phoneNumbers': [
          {'address': '5550000002'}
        ],
      }
    ]);
    expect(parsed.single.contact.displayName, getDisplayName(null, 'Ada', 'Lovelace'));
  });

  test('a card with no phone number or email is skipped', () {
    expect(
        contactsFromServer([
          {'id': '1', 'displayName': 'No Address', 'phoneNumbers': [], 'emails': []}
        ]),
        isEmpty);
  });

  test('a missing or empty photo is null', () {
    final parsed = contactsFromServer([
      {
        'id': '1',
        'displayName': 'A',
        'emails': [
          {'address': 'a@example.com'}
        ],
        'avatar': ''
      },
      {
        'id': '2',
        'displayName': 'B',
        'emails': [
          {'address': 'b@example.com'}
        ]
      },
    ]);
    expect(parsed.map((p) => p.avatar), [null, null]);
  });

  test('entries that are not cards are ignored', () {
    expect(contactsFromServer([null, 'x', 3]), isEmpty);
  });

  test('stored contacts the server no longer has are removed, including ones from the phone', () {
    expect(contactIdsToRemove(['phone-17', 'A', 'B'], ['A', 'C']), {'phone-17', 'B'});
    expect(contactIdsToRemove(['A'], ['A']), isEmpty);
  });


  group('photos version', () {
    test('is read from the response metadata', () {
      expect(photosVersionOf({'data': [], 'metadata': {'photosVersion': '1.0.277.x'}}), '1.0.277.x');
    });

    test('is null from a server that does not send one', () {
      expect(photosVersionOf({'data': []}), isNull);
      expect(photosVersionOf('not a map'), isNull);
    });

    // Photos are 98% of the contacts download (4.2 MB of 4.3 MB for 277
    // contacts), so they are fetched only when they may have changed.
    test('photos are fetched only when the version differs from the saved photos', () {
      expect(photosNeeded(server: 'v2', saved: 'v1'), isTrue);
      expect(photosNeeded(server: 'v1', saved: 'v1'), isFalse);
      expect(photosNeeded(server: 'v1', saved: null), isTrue);
      expect(photosNeeded(server: null, saved: 'v1'), isTrue, reason: 'a server without versions always sends photos');
    });
  });
}
