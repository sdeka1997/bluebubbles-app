import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/service_twin_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

Chat chat(int id, String guid, [String? groupId]) => Chat(id: id, guid: guid, groupId: groupId);

void main() {
  final sms = chat(1, 'SMS;-;+155****1111', 'G1');
  final rcs = chat(2, 'RCS;-;+155****1111', 'G1');
  final imessage = chat(3, 'iMessage;-;+155****1111', 'G1');
  final other = chat(4, 'iMessage;-;+155****2222', 'G2');
  final legacy = chat(5, 'iMessage;-;+155****3333');
  final local = [rcs, other, sms, legacy];

  group('canonicalTwinFor', () {
    test('folds a twin into the first chat stored for its group id', () {
      expect(canonicalTwinFor(rcs, local)?.guid, sms.guid);
      expect(canonicalTwinFor(imessage, local)?.guid, sms.guid);
    });

    test('a new twin with no local id yet folds too', () {
      expect(canonicalTwinFor(Chat(guid: 'iMessage;-;+155****1111', groupId: 'G1'), local)?.guid, sms.guid);
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
      final deleted = Chat(id: 1, guid: sms.guid, groupId: 'G1', dateDeleted: DateTime(2026));
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
      final thread = Chat(id: 1, guid: 'SMS;-;+155****1111', groupId: 'G1', muteType: 'temporary_mute', displayName: 'Mine', lockChatName: true);
      final twin = Chat(id: 2, guid: 'RCS;-;+155****1111', groupId: 'G1', muteType: 'mute', displayName: 'Theirs', lockChatName: true);
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
