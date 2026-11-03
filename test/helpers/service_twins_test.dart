import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/service_twin_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

Chat chat(int id, String guid, [String? threadKey]) => Chat(id: id, guid: guid, threadKey: threadKey);

void main() {
  final sms = chat(1, 'SMS;-;+155****1111', 'G1');
  final rcs = chat(2, 'RCS;-;+155****1111', 'G1');
  final imessage = chat(3, 'iMessage;-;+155****1111', 'G1');
  final other = chat(4, 'iMessage;-;+155****2222', 'G2');
  final legacy = chat(5, 'iMessage;-;+155****3333');
  final local = [rcs, other, sms, legacy];

  group('canonicalTwinFor', () {
    test('folds a chat into the first chat stored for its thread', () {
      expect(canonicalTwinFor(rcs, local)?.guid, sms.guid);
      expect(canonicalTwinFor(imessage, local)?.guid, sms.guid);
    });

    test('a new twin with no local id yet folds too', () {
      expect(canonicalTwinFor(Chat(guid: 'iMessage;-;+155****1111', threadKey: 'G1'), local)?.guid, sms.guid);
    });

    test('leaves the canonical chat and non-twins alone', () {
      expect(canonicalTwinFor(sms, local), isNull);
      expect(canonicalTwinFor(other, local), isNull);
      expect(canonicalTwinFor(legacy, local), isNull);
      expect(canonicalTwinFor(chat(6, 'SMS;-;+155****4444', ''), [chat(7, 'RCS;-;+155****4444', '')]), isNull);
    });
  });

  group('foldedTwinGuids', () {
    test('hides every twin but the thread', () {
      expect(foldedTwinGuids([rcs, imessage, other, sms, legacy]), {rcs.guid, imessage.guid});
    });

    test('a deleted thread hands over to the next twin', () {
      final deleted = Chat(id: 1, guid: sms.guid, threadKey: 'G1', dateDeleted: DateTime(2026));
      expect(foldedTwinGuids([deleted, rcs, imessage]), {deleted.guid, imessage.guid});
    });
  });

  group('guidsToMarkRead', () {
    test('marks every twin of the thread read', () {
      expect(guidsToMarkRead(sms.guid, [sms, rcs, imessage, other]), [sms.guid, rcs.guid, imessage.guid]);
    });

    test('marks only the chat itself when it has no twins', () {
      expect(guidsToMarkRead(other.guid, local), [other.guid]);
      expect(guidsToMarkRead(legacy.guid, local), [legacy.guid]);
    });
  });

  group('assignThreadKeys', () {
    Handle person(String address) => Handle(address: address);
    Chat group(int id, String guid, List<String> people, {String? groupId, String? name, List<String>? legacy}) =>
        Chat(id: id, guid: guid, style: 43, groupId: groupId, legacyGroupIds: legacy, latestGroupTitle: name)
          ..handles.addAll(people.map(person));

    test('chats the rule joins get one key; others keep their own', () {
      final a = group(1, 'iMessage;+;chat1', ['+15550000001', '+15550000002'], groupId: 'G1');
      final b = group(2, 'SMS;+;chat2', ['+15550000001', '+15550000002'], groupId: 'G2', legacy: ['G1']);
      final c = group(3, 'RCS;+;chat3', ['+15550000001', '+15550000002'], groupId: 'G3', name: 'apes');
      final changed = assignThreadKeys([a, b, c]);
      expect(a.threadKey, b.threadKey);
      expect(c.threadKey, isNot(a.threadKey));
      expect(changed, unorderedEquals([a, b, c]));
    });

    test('same people and same name join without a shared group id', () {
      final a = group(1, 'iMessage;+;chat1', ['+15550000001', '+15550000002'], groupId: 'G1', name: 'apes');
      final b = group(2, 'iMessage;+;chat2', ['+15550000002', '+15550000001'], groupId: 'G2', name: 'apes');
      assignThreadKeys([a, b]);
      expect(a.threadKey, b.threadKey);
    });

    test('only chats whose key changed are returned', () {
      final a = group(1, 'iMessage;+;chat1', ['+15550000001', '+15550000002'], groupId: 'G1');
      assignThreadKeys([a]);
      expect(assignThreadKeys([a]), isEmpty);
    });
  });

  group('updateGroupIdsFromRemote', () {
    test('updates only group ids returned by a new server', () {
      final first = Chat(id: 1, guid: 'SMS;-;+155****1111');
      final second = Chat(id: 2, guid: 'RCS;-;+155****1111', groupId: 'old');
      final untouched = Chat(id: 3, guid: 'iMessage;-;+155****2222', groupId: 'keep');

      final changed = updateGroupIdsFromRemote(
        [first, second, untouched],
        [
          {'guid': first.guid, 'groupId': 'G1'},
          {'guid': second.guid, 'groupId': 'G1'},
          {'guid': untouched.guid},
          {'guid': 'missing-locally', 'groupId': 'G2'},
        ],
      );

      expect(changed, [first, second]);
      expect(first.groupId, 'G1');
      expect(second.groupId, 'G1');
      expect(untouched.groupId, 'keep');
    });

    test('does not write when the group id is unchanged', () {
      final chat = Chat(id: 1, guid: 'SMS;-;+155****1111', groupId: 'G1');
      expect(
        updateGroupIdsFromRemote(
          [chat],
          [
            {'guid': chat.guid, 'groupId': 'G1'},
          ],
        ),
        isEmpty,
      );
    });

    test('accepts a real null from a capable server but ignores old servers that omit the field', () {
      final cleared = Chat(id: 1, guid: 'SMS;-;+155****1111', groupId: 'G1');
      final legacy = Chat(id: 2, guid: 'SMS;-;+155****2222', groupId: 'G2');
      final changed = updateGroupIdsFromRemote(
        [cleared, legacy],
        [
          {'guid': cleared.guid, 'groupId': null},
          {'guid': legacy.guid},
        ],
      );
      expect(changed, [cleared]);
      expect(cleared.groupId, isNull);
      expect(legacy.groupId, 'G2');
    });
  });

  group('carryOverThreadSettings', () {
    test('the thread takes over pin, mute, archive and a custom name from a folded twin', () {
      final thread = Chat(id: 1, guid: 'SMS;-;+155****1111', groupId: 'G1');
      final twin = Chat(
        id: 2,
        guid: 'RCS;-;+155****1111',
        groupId: 'G1',
        isPinned: true,
        muteType: 'mute',
        isArchived: true,
        displayName: 'Karan',
        lockChatName: true,
      )..pinIndex = 3;
      expect(carryOverThreadSettings(thread, [twin]), isTrue);
      expect(thread.isPinned, isTrue);
      expect(thread.pinIndex, 3);
      expect(thread.muteType, 'mute');
      expect(thread.isArchived, isTrue);
      expect(thread.displayName, 'Karan');
      expect(thread.lockChatName, isTrue);
    });

    test("never overrides what the thread already has", () {
      final thread = Chat(
        id: 1,
        guid: 'SMS;-;+155****1111',
        groupId: 'G1',
        muteType: 'temporary_mute',
        displayName: 'Mine',
        lockChatName: true,
      );
      final twin = Chat(
        id: 2,
        guid: 'RCS;-;+155****1111',
        groupId: 'G1',
        muteType: 'mute',
        displayName: 'Theirs',
        lockChatName: true,
      );
      expect(carryOverThreadSettings(thread, [twin]), isFalse);
      expect(thread.muteType, 'temporary_mute');
      expect(thread.displayName, 'Mine');
    });

    test('nothing to carry over leaves the thread unchanged', () {
      final thread = Chat(id: 1, guid: 'SMS;-;+155****1111', groupId: 'G1');
      expect(carryOverThreadSettings(thread, [Chat(id: 2, guid: 'RCS;-;+155****1111', groupId: 'G1')]), isFalse);
      expect(thread.isPinned, isFalse);
      expect(thread.muteType, isNull);
    });
  });
}
