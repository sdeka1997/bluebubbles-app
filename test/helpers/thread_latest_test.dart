import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/chat_list_message.dart';
import 'package:flutter_test/flutter_test.dart';

Chat threadShowing(Message m) => Chat(id: 1, guid: 'SMS;+;chat1')
  ..dbLatestMessage.target = m
  ..dbOnlyLatestMessageDate = m.dateCreated;

Message msg(String guid, DateTime date,
        {int itemType = 0, int groupActionType = 0, String? groupTitle, String? reactsTo, DateTime? deleted}) =>
    Message(
        guid: guid,
        dateCreated: date,
        itemType: itemType,
        groupActionType: groupActionType,
        groupTitle: groupTitle,
        associatedMessageGuid: reactsTo,
        associatedMessageType: reactsTo == null ? null : 'laugh',
        dateDeleted: deleted);

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

  group('group events never list a thread', () {
    final text = msg('text', DateTime(2026, 10, 31, 16, 48));
    final reaction = msg('reaction', DateTime(2026, 11, 3, 12, 26), reactsTo: 'text');
    final unnamed = msg('unnamed', DateTime(2026, 11, 3, 9, 45), itemType: 2);
    final removed = msg('removed', DateTime(2026, 11, 3, 9, 39), itemType: 1, groupActionType: 1);
    final left = msg('left', DateTime(2026, 11, 3, 9, 52), itemType: 3, groupActionType: 3);

    test('messages and reactions list a thread; renames and member changes do not', () {
      expect(listsThread(text), isTrue);
      expect(listsThread(reaction), isTrue);
      expect(listsThread(Message(guid: 'sent', dateCreated: DateTime(2026))), isTrue);
      expect(listsThread(rename), isFalse);
      expect(listsThread(unnamed), isFalse);
      expect(listsThread(removed), isFalse);
      expect(listsThread(left), isFalse);
    });

    test('a thread whose newest items are events previews its last real message', () {
      final thread = threadShowing(unnamed);
      expect(refreshThreadLatest(thread, [text, unnamed, removed]), isTrue);
      expect(thread.dbLatestMessage.target?.guid, 'text');
      expect(thread.dbOnlyLatestMessageDate, text.dateCreated);
    });

    test('a reaction newer than an event lists the thread', () {
      final thread = threadShowing(text);
      refreshThreadLatest(thread, [text, rename, reaction]);
      expect(thread.dbLatestMessage.target?.guid, 'reaction');
    });

    test('a thread holding only events lists nothing', () {
      final thread = threadShowing(unnamed);
      expect(refreshThreadLatest(thread, [unnamed, removed]), isTrue);
      expect(thread.dbLatestMessage.target, isNull);
      expect(thread.dbOnlyLatestMessageDate, isNull);
    });
  });
}
