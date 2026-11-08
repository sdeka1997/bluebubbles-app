import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/server_contacts.dart';
import 'package:flutter_test/flutter_test.dart';

Handle person(ContactV2 card) => Handle(address: '+15550000001')..contactsV2.add(card);

void main() {
  test('reactions name an Apple Contacts card by its first name', () {
    final h = person(ContactV2(nativeContactId: 'c1', displayName: 'Sameer Allahabadi', firstName: 'Sameer'));
    expect(h.reactionDisplayName, 'Sameer');
  });

  test('a nickname beats the first name', () {
    final h = person(ContactV2(nativeContactId: 'c1', displayName: 'Robert Smith', firstName: 'Robert', nickname: 'Bobby'));
    expect(h.reactionDisplayName, 'Bobby');
  });

  test('a card with only a display name uses it', () {
    expect(person(ContactV2(nativeContactId: 'c1', displayName: 'Mom')).reactionDisplayName, 'Mom');
  });

  test('no card falls back to the number', () {
    expect(Handle(address: '+15550000001', formattedAddress: '(555) 000-0001').reactionDisplayName, '(555) 000-0001');
  });

  test('a card from the Mac reacts by its first name, as the iPhone shows it', () {
    final card = contactsFromServer([
      {
        'id': 'c1',
        'displayName': 'Sameer Allahabadi',
        'firstName': 'Sameer',
        'lastName': 'Allahabadi',
        'nickname': '',
        'phoneNumbers': [
          {'address': '+15550000001'}
        ],
      }
    ]).single.contact;
    expect(person(card).reactionDisplayName, 'Sameer');
  });

  test('a nickname on the Mac card beats the first name', () {
    final card = contactsFromServer([
      {
        'id': 'c2',
        'displayName': 'Robert Smith',
        'firstName': 'Robert',
        'nickname': 'Bobby',
        'phoneNumbers': [
          {'address': '+15550000002'}
        ],
      }
    ]).single.contact;
    expect(person(card).reactionDisplayName, 'Bobby');
  });
}
