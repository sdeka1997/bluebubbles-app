import 'package:bluebubbles/services/backend/actions/sync_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('payloadSenderKey', () {
    test('is the address and service of the sender the server reported', () {
      final key = payloadSenderKey({
        'isFromMe': false,
        'handleId': 10,
        'handle': {'originalROWID': 10, 'address': '+15555557463', 'service': 'iMessage'},
      });

      expect(key, '+15555557463/iMessage');
    });

    test('is null for a message from me', () {
      final key = payloadSenderKey({
        'isFromMe': true,
        'handleId': 10,
        'handle': {'originalROWID': 10, 'address': '+15555557463', 'service': 'iMessage'},
      });

      expect(key, isNull);
    });

    test('is null when the server sent no sender', () {
      expect(payloadSenderKey({'isFromMe': false, 'handleId': 10}), isNull);
    });
  });
}
