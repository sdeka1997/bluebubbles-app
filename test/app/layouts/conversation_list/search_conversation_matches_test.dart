import 'package:bluebubbles/app/layouts/conversation_list/pages/search/search_query_helper.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

Chat chat(String guid, {String? name, List<Handle> handles = const [], DateTime? latest, DateTime? deleted}) {
  final c = Chat(guid: guid, displayName: name, chatIdentifier: guid, dateDeleted: deleted)
    ..dbOnlyLatestMessageDate = latest;
  c.handles.addAll(handles);
  return c;
}

Handle handle(String address, [String? contactName]) {
  final h = Handle(address: address, formattedAddress: address);
  if (contactName != null) h.contactsV2.add(ContactV2(displayName: contactName, nativeContactId: address));
  return h;
}

void main() {
  final socc = chat('iMessage;+;chat1', name: 'Socc Talk 🇺🇸', latest: DateTime(2026, 10, 1));
  final ming = chat('iMessage;-;ming@example.com', handles: [handle('ming@example.com', 'Ming Li')], latest: DateTime(2026, 9, 1));
  final karan = chat('SMS;-;+15551234567', handles: [handle('+15551234567')], latest: DateTime(2026, 8, 1));
  final chats = [ming, karan, socc];

  group('matchConversations', () {
    test('matches the group name ignoring case', () {
      expect(matchConversations('socc', chats), [socc]);
    });

    test('matches a participant contact name', () {
      expect(matchConversations('ming l', chats), [ming]);
    });

    test('matches an address, ignoring phone punctuation', () {
      expect(matchConversations('example.com', chats), [ming]);
      expect(matchConversations('(555) 123-4567', chats), [karan]);
    });

    test('returns nothing when no conversation matches', () {
      expect(matchConversations('hoops', chats), isEmpty);
    });

    test('leaves out deleted chats', () {
      final deleted = chat('iMessage;+;chat2', name: 'Socc Old', deleted: DateTime(2026, 9, 1));
      expect(matchConversations('socc', [deleted, socc]), [socc]);
    });

    test('orders by latest activity, without duplicates, up to the limit', () {
      final older = chat('iMessage;+;chat3', name: 'Socc Fans', latest: DateTime(2026, 1, 1));
      final never = chat('iMessage;+;chat4', name: 'Socc Planning');
      expect(matchConversations('socc', [never, older, socc, socc]), [socc, older, never]);
      expect(matchConversations('socc', [never, older, socc], limit: 2), [socc, older]);
    });
  });
}
