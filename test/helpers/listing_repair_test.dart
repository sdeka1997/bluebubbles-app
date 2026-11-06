import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/chat_list_message.dart';
import 'package:flutter_test/flutter_test.dart';

Message msg(String guid, DateTime date, {int itemType = 0}) =>
    Message(guid: guid, dateCreated: date, itemType: itemType);

Chat stored(Message? latest, {DateTime? date}) {
  final chat = Chat(id: 7, guid: 'iMessage;-;+155****0001');
  chat.dbLatestMessage.target = latest;
  chat.dbOnlyLatestMessageDate = date ?? latest?.dateCreated;
  return chat;
}

void main() {
  final newest = msg('newest', DateTime(2026, 10, 30, 20, 22));
  final older = msg('older', DateTime(2025, 10, 12));

  test('a thread listed by its newest message is fine', () {
    expect(listingProblem(stored(newest), newest), isNull);
  });

  test('a thread with no stored date is reported', () {
    expect(listingProblem(stored(null), newest), contains('no stored date'));
  });

  test('a thread listed by an older message is reported', () {
    expect(listingProblem(stored(older), newest), contains('older than its newest message'));
  });

  test('a stored date that disagrees with its own message is reported', () {
    expect(listingProblem(stored(newest, date: DateTime(1970)), newest), contains('date does not match'));
  });

  test('a thread with no messages on this phone is fine', () {
    expect(listingProblem(stored(null), null), isNull);
  });

  group('only a thread that may be listed wrongly gets its messages read', () {
    bool never(int _, DateTime _) => fail('should not need to look for newer messages');

    test('a thread listed by its newest message, with nothing newer, is skipped', () {
      var asked = 0;
      expect(mayBeMislisted(stored(newest), (_, _) { asked++; return false; }), isFalse);
      expect(asked, 1);
    });

    test('a thread with a newer message is checked', () {
      expect(mayBeMislisted(stored(older), (_, _) => true), isTrue);
    });

    test('a thread with no stored date is checked', () {
      expect(mayBeMislisted(stored(null), never), isTrue);
    });

    test('a stored date that disagrees with its own message is checked', () {
      expect(mayBeMislisted(stored(newest, date: DateTime(1970)), never), isTrue);
    });

    test('a thread listed by a status item is checked', () {
      expect(mayBeMislisted(stored(msg('rename', DateTime(2026), itemType: 2)), never), isTrue);
    });

    test('a thread listed by a deleted message is checked', () {
      final deleted = msg('deleted', DateTime(2026))..dateDeleted = DateTime(2026, 2);
      expect(mayBeMislisted(stored(deleted), never), isTrue);
    });
  });
}
