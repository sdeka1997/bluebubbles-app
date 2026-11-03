import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/chat_keys.dart';
import 'package:flutter_test/flutter_test.dart';

Handle handle(String address, [String? contactId]) {
  final h = Handle(address: address);
  if (contactId != null) h.contactsV2.add(ContactV2(nativeContactId: contactId, displayName: contactId));
  return h;
}

Chat chat(String guid,
    {List<Handle> people = const [],
    int? style,
    String? groupId,
    String? originalGroupId,
    List<String>? legacy,
    String? displayName,
    String? latestGroupTitle,
    String? chatIdentifier}) {
  final c = Chat(
    guid: guid,
    chatIdentifier: chatIdentifier ?? guid.split(';').last,
    style: style,
    groupId: groupId,
    originalGroupId: originalGroupId,
    legacyGroupIds: legacy,
    displayName: displayName,
    latestGroupTitle: latestGroupTitle,
  );
  c.handles.addAll(people);
  return c;
}

void main() {
  test('every group id a chat has is a key', () {
    final keys = chatKeysFor(chat('iMessage;+;x', style: 43, groupId: 'G', originalGroupId: 'O', legacy: ['L1', 'L2']));
    expect(keys.groupIds, {'G', 'O', 'L1', 'L2'});
  });

  test('a person on a contact card is that card; anyone else is their address', () {
    final keys = chatKeysFor(chat('iMessage;+;x',
        style: 43, people: [handle('jiahui@example.com', 'card-1'), handle('+15550000002')]));
    expect(keys.people, {'card:card-1', 'address:+15550000002'});
  });

  test('email and phone on one card are the same person', () {
    final a = chatKeysFor(chat('iMessage;-;jiahui@example.com', style: 45, people: [handle('jiahui@example.com', 'c1')]));
    final b = chatKeysFor(chat('SMS;-;+15550000001', style: 45, people: [handle('+15550000001', 'c1')]));
    expect(a.people, b.people);
    expect(a.isGroup, isFalse);
  });

  test('the newest rename is the name, even when the stored name lags behind', () {
    expect(chatKeysFor(chat('g', style: 43, displayName: 'family', latestGroupTitle: '')).name, '');
    expect(chatKeysFor(chat('g', style: 43, displayName: 'old', latestGroupTitle: 'new')).name, 'new');
  });

  test('a chat never renamed uses its stored name, and no name is empty', () {
    expect(chatKeysFor(chat('g', style: 43, displayName: 'apes')).name, 'apes');
    expect(chatKeysFor(chat('g', style: 43)).name, '');
  });

  test('a group is style 43, or a chat with more than one person', () {
    expect(chatKeysFor(chat('iMessage;+;x', style: 43, people: [handle('a')])).isGroup, isTrue);
    expect(chatKeysFor(chat('x', people: [handle('a'), handle('b')])).isGroup, isTrue);
    expect(chatKeysFor(chat('iMessage;-;a', style: 45, people: [handle('a')])).isGroup, isFalse);
  });

  test('addresses compare the way Messages formats them', () {
    final a = chatKeysFor(chat('x', style: 45, people: [handle('+15550000001')]));
    final b = chatKeysFor(chat('y', style: 45, people: [handle('+1 (555) 000-0001')]));
    expect(a.people, b.people);
    expect(chatKeysFor(chat('z', style: 45, people: [handle('A@Example.com')])).people, {'address:a@example.com'});
  });
}
