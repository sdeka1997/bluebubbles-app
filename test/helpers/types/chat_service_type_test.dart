import 'package:bluebubbles/helpers/types/classes/chat_service_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatServiceType.fromServer', () {
    test('uses the server service when an any GUID has no service prefix', () {
      expect(ChatServiceType.fromServer('RCS', 'any;-;+15550000000'), ChatServiceType.rcs);
      expect(ChatServiceType.fromServer('SMS', 'any;-;+15550000000'), ChatServiceType.sms);
      expect(ChatServiceType.fromServer('iMessage', 'any;-;+15550000000'), ChatServiceType.iMessage);
    });

    test('falls back to the GUID for older servers', () {
      expect(ChatServiceType.fromServer(null, 'RCS;-;+15550000000'), ChatServiceType.rcs);
      expect(ChatServiceType.fromServer(null, 'SMS;-;+15550000000'), ChatServiceType.sms);
      expect(ChatServiceType.fromServer(null, 'iMessage;-;+15550000000'), ChatServiceType.iMessage);
    });

    test('falls back to the GUID for an unknown server value', () {
      expect(ChatServiceType.fromServer('future-service', 'SMS;-;+15550000000'), ChatServiceType.sms);
    });
  });

  test('all Apple chat services support Tapbacks', () {
    expect(ChatServiceType.iMessage.supportsTapbacks, isTrue);
    expect(ChatServiceType.sms.supportsTapbacks, isTrue);
    expect(ChatServiceType.rcs.supportsTapbacks, isTrue);
  });
}
