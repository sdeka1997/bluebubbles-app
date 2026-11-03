import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/service_twin_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

Chat threadShowing(Message m) => Chat(id: 1, guid: 'SMS;+;chat1')
  ..dbLatestMessage.target = m
  ..dbOnlyLatestMessageDate = m.dateCreated;

Message msg(String guid, DateTime date, {int itemType = 0, String? groupTitle, DateTime? deleted}) =>
    Message(guid: guid, dateCreated: date, itemType: itemType, groupTitle: groupTitle, dateDeleted: deleted);

void main() {
  // A rename-only copy became the thread; the real conversation was folded in.
  final rename = msg('rename', DateTime(2026, 11, 3, 9, 52), itemType: 2, groupTitle: 'Ming Dynasty');
  final reply = msg('reply', DateTime(2026, 11, 3, 12, 26));
  final older = msg('older', DateTime(2026, 11, 3, 10, 27));

  test('a thread previews its newest message after copies fold into it', () {
    final thread = threadShowing(rename);
    expect(refreshThreadLatest(thread, [rename, older, reply]), isTrue);
    expect(thread.dbLatestMessage.target?.guid, 'reply');
    expect(thread.dbOnlyLatestMessageDate, reply.dateCreated);
  });

  test('a thread already showing its newest message is left alone', () {
    final thread = threadShowing(reply);
    expect(refreshThreadLatest(thread, [rename, older, reply]), isFalse);
    expect(thread.dbLatestMessage.target?.guid, 'reply');
  });

  test('deleted messages are not previewed', () {
    final gone = msg('gone', DateTime(2026, 11, 3, 13), deleted: DateTime(2026, 11, 3, 14));
    final thread = threadShowing(rename);
    refreshThreadLatest(thread, [rename, reply, gone]);
    expect(thread.dbLatestMessage.target?.guid, 'reply');
  });

  test('a thread with no messages keeps what it has', () {
    final thread = threadShowing(rename);
    expect(refreshThreadLatest(thread, const []), isFalse);
    expect(thread.dbLatestMessage.target?.guid, 'rename');
  });
}
