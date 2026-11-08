import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an incoming message keeps the sender the server reported when re-serialized', () {
    // ROWID 10 belonged to someone else in the previous Apple database, so the
    // sender must travel by address and service, not be looked up by ROWID.
    final message = Message.fromMap({
      'guid': 'm1',
      'handleId': 10,
      'isFromMe': false,
      'handle': {'originalROWID': 10, 'address': '+15555557463', 'service': 'iMessage'},
    });

    final handle = message.toMap()['handle'] as Map<String, dynamic>;

    expect(handle['address'], '+15555557463');
    expect(handle['uniqueAddrAndService'], '+15555557463/iMessage');
    expect(handle['originalROWID'], 10);
  });

  group('shouldLinkSender', () {
    final tate = Handle(id: 1, address: '+15555557463');
    final diya = Handle(id: 2, address: 'diya@example.com');

    test('links a message that has no sender yet', () {
      expect(shouldLinkSender(linked: null, resolved: tate, fromPayload: false), isTrue);
    });

    test('replaces a wrong sender with the one the server reported', () {
      // Saved while a stale ROWID pointed at Diya; the re-sync names Tate.
      expect(shouldLinkSender(linked: diya, resolved: tate, fromPayload: true), isTrue);
    });

    test('keeps the sender when the server reports the same one', () {
      final sameTate = Handle(id: 1, address: '+15555557463');

      expect(shouldLinkSender(linked: tate, resolved: sameTate, fromPayload: true), isFalse);
    });

    test('keeps the sender when the replacement was only found by ROWID', () {
      expect(shouldLinkSender(linked: diya, resolved: tate, fromPayload: false), isFalse);
    });

    test('keeps the sender when nothing was resolved', () {
      expect(shouldLinkSender(linked: diya, resolved: null, fromPayload: true), isFalse);
    });
  });
}
