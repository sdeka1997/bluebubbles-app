import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/chat_list_message.dart';
import 'package:flutter_test/flutter_test.dart';

Message msg(String guid, DateTime date, {int itemType = 0}) =>
    Message(guid: guid, dateCreated: date, itemType: itemType);

Chat stored(Message? latest, {DateTime? date}) {
  final chat = Chat(id: 7, guid: 'iMessage;-;+15550000001');
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
}
