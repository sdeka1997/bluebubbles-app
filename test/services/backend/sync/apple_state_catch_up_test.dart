import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/sync/apple_state_catch_up.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseRecoverableMessageEvent', () {
    test('a message-deleted payload yields the chat and message GUIDs', () {
      final event = parseRecoverableMessageEvent({'chatGuid': 'chat-a', 'messageGuid': 'm1'}, deleted: true);

      expect(event, isNotNull);
      expect(event!.chatGuid, 'chat-a');
      expect(event.messageGuid, 'm1');
      expect(event.deleted, isTrue);
    });

    test('a message-restored payload is parsed as a restore', () {
      final event = parseRecoverableMessageEvent({'chatGuid': 'chat-a', 'messageGuid': 'm1'}, deleted: false);
      expect(event!.deleted, isFalse);
    });

    test('a payload missing either GUID is rejected', () {
      expect(parseRecoverableMessageEvent({'chatGuid': 'chat-a'}, deleted: true), isNull);
      expect(parseRecoverableMessageEvent({'messageGuid': 'm1'}, deleted: true), isNull);
      expect(parseRecoverableMessageEvent({'chatGuid': '', 'messageGuid': 'm1'}, deleted: true), isNull);
      expect(parseRecoverableMessageEvent('not a map', deleted: true), isNull);
    });
  });

  group('parseAppleStateSnapshot', () {
    test('reads each chat\'s read state', () {
      final snapshot = parseAppleStateSnapshot(chatState: {
        'chats': [
          {'guid': 'read-chat', 'read': true},
          {'guid': 'unread-chat', 'read': false},
        ],
      });

      expect(snapshot.readByChat, {'read-chat': true, 'unread-chat': false});
    });

    test('a single delete hides the message; a chat with nothing left was deleted whole', () {
      final snapshot = parseAppleStateSnapshot(recentlyDeleted: {
        'chats': [
          {'guid': 'chat-a', 'hasMessages': true, 'deletedMessageGuids': ['m1', 'm2']},
          {'guid': 'chat-b', 'hasMessages': false, 'deletedMessageGuids': ['m3']},
        ],
      });

      expect(snapshot.deletedMessages, {'m1', 'm2'});
      expect(snapshot.deletedChats, {'chat-b'});
    });

    test('malformed entries are skipped and the rest still apply', () {
      final snapshot = parseAppleStateSnapshot(
        chatState: {
          'chats': [
            {'guid': 'ok', 'read': true},
            {'guid': '', 'read': true},
            {'guid': 'no-read'},
            'not a map',
          ],
        },
        recentlyDeleted: {
          'chats': [
            {'guid': 'chat-a', 'hasMessages': true, 'deletedMessageGuids': ['m1', '', 7]},
            {'guid': 'chat-b', 'deletedMessageGuids': ['m2']},
          ],
        },
      );

      expect(snapshot.readByChat, {'ok': true});
      expect(snapshot.deletedMessages, {'m1'});
      expect(snapshot.deletedChats, isEmpty);
    });

    test('a missing response contributes nothing', () {
      final snapshot = parseAppleStateSnapshot();

      expect(snapshot.readByChat, isEmpty);
      expect(snapshot.deletedMessages, isEmpty);
      expect(snapshot.deletedChats, isEmpty);
    });
  });

  group('planAppleStateCatchUp', () {
    Chat chat(int id, String guid, {bool unread = false}) => Chat(id: id, guid: guid, hasUnreadMessage: unread);

    test('a chat read on both sides with no notification showing is left alone', () {
      final plan = planAppleStateCatchUp(
        [chat(1, 'a'), chat(2, 'b')],
        const AppleStateSnapshot(readByChat: {'a': true, 'b': true}),
        shownNotificationIds: const {},
      );

      expect(plan.clearNotificationFor, isEmpty);
      expect(plan.readStateChanges, isEmpty);
      expect(plan.deleteChats, isEmpty);
    });

    test('a read chat whose notification is still showing has it cleared', () {
      final plan = planAppleStateCatchUp(
        [chat(1, 'a'), chat(2, 'b')],
        const AppleStateSnapshot(readByChat: {'a': true, 'b': true}),
        shownNotificationIds: const {2},
      );

      expect(plan.clearNotificationFor.map((c) => c.guid), ['b']);
    });

    test('when the shown notifications cannot be read, every read chat is cleared as before', () {
      final plan = planAppleStateCatchUp(
        [chat(1, 'a'), chat(2, 'b')],
        const AppleStateSnapshot(readByChat: {'a': true, 'b': true}),
        shownNotificationIds: null,
      );

      expect(plan.clearNotificationFor.map((c) => c.guid), ['a', 'b']);
    });

    test('a chat whose read state differs from Apple is changed to match', () {
      final plan = planAppleStateCatchUp(
        [chat(1, 'a', unread: true), chat(2, 'b')],
        const AppleStateSnapshot(readByChat: {'a': true, 'b': false}),
        shownNotificationIds: const {},
      );

      expect({for (final e in plan.readStateChanges.entries) e.key.guid: e.value}, {'a': false, 'b': true});
      expect(plan.clearNotificationFor, isEmpty);
    });

    test('a chat Apple deleted whole is deleted and nothing else is done to it', () {
      final plan = planAppleStateCatchUp(
        [chat(1, 'a', unread: true)],
        const AppleStateSnapshot(readByChat: {'a': true}, deletedChats: {'a'}),
        shownNotificationIds: const {1},
      );

      expect(plan.deleteChats.map((c) => c.guid), ['a']);
      expect(plan.readStateChanges, isEmpty);
      expect(plan.clearNotificationFor, isEmpty);
    });

    test('a copy read on Apple clears the conversation it is folded into', () {
      // Tonight's case: the message landed in the hidden copy, the iPhone read
      // it there, and the shown copy has no unread of its own on Apple.
      final plan = planAppleStateCatchUp(
        [chat(1, 'shown', unread: true)],
        const AppleStateSnapshot(readByChat: {'shown': true, 'hidden': true}),
        shownNotificationIds: const {1},
        threadCopies: const {'shown': ['shown', 'hidden']},
      );

      expect({for (final e in plan.readStateChanges.entries) e.key.guid: e.value}, {'shown': false});
    });

    test('a read conversation with a notification up is cleared when only a hidden copy was reported', () {
      final plan = planAppleStateCatchUp(
        [chat(1, 'shown')],
        const AppleStateSnapshot(readByChat: {'hidden': true}),
        shownNotificationIds: const {1},
        threadCopies: const {'shown': ['shown', 'hidden']},
      );

      expect(plan.clearNotificationFor.map((c) => c.guid), ['shown']);
    });

    test('a conversation is unread while any of its copies is unread on Apple', () {
      final plan = planAppleStateCatchUp(
        [chat(1, 'shown')],
        const AppleStateSnapshot(readByChat: {'shown': true, 'hidden': false}),
        shownNotificationIds: const {},
        threadCopies: const {'shown': ['shown', 'hidden']},
      );

      expect({for (final e in plan.readStateChanges.entries) e.key.guid: e.value}, {'shown': true});
    });

    test('threadCopyGuids maps each shown chat to every live copy of its thread', () {
      final shown = [Chat(id: 1, guid: 'a', threadKey: 'k'), Chat(id: 3, guid: 'c')];
      final threaded = [
        Chat(id: 1, guid: 'a', threadKey: 'k'),
        Chat(id: 2, guid: 'b', threadKey: 'k'),
        Chat(id: 4, guid: 'gone', threadKey: 'k', dateDeleted: DateTime.utc(2024)),
      ];
      expect(threadCopyGuids(shown, threaded), {
        'a': ['a', 'b'],
      });
    });

    test('a chat Apple did not report is left alone', () {
      final plan = planAppleStateCatchUp(
        [chat(1, 'a', unread: true)],
        const AppleStateSnapshot(),
        shownNotificationIds: const {1},
      );

      expect(plan.readStateChanges, isEmpty);
      expect(plan.clearNotificationFor, isEmpty);
    });
  });
}
