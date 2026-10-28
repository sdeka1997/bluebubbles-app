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

  group('ChatServiceType.current', () {
    test('uses the newest message service when Messages filed it in another service record', () {
      // Messages stores RCS messages in an older SMS chat record for the same contact.
      expect(ChatServiceType.current(ChatServiceType.sms, latestMessageService: 'RCS'), ChatServiceType.rcs);
      expect(ChatServiceType.current(ChatServiceType.sms, latestMessageService: 'iMessage'), ChatServiceType.iMessage);
    });

    test('keeps the chat service without a usable newest message service', () {
      expect(ChatServiceType.current(ChatServiceType.rcs), ChatServiceType.rcs);
      expect(ChatServiceType.current(ChatServiceType.sms, latestMessageService: 'future-service'), ChatServiceType.sms);
    });
  });

  group('ChatServiceType.forNewChat', () {
    test('starts on iMessage with no recipients', () {
      expect(ChatServiceType.forNewChat(const []), ChatServiceType.iMessage);
    });

    test('uses iMessage when the Mac reports every recipient on iMessage', () {
      expect(
        ChatServiceType.forNewChat(const [
          (address: '+15550000001', status: ChatServiceType.iMessage),
          (address: '+15550000002', status: ChatServiceType.iMessage),
        ]),
        ChatServiceType.iMessage,
      );
    });

    test('texts when the Mac reports any recipient off iMessage', () {
      expect(
        ChatServiceType.forNewChat(const [
          (address: '+15550000001', status: ChatServiceType.iMessage),
          (address: '+15550000002', status: ChatServiceType.sms),
        ]),
        ChatServiceType.sms,
      );
    });

    test('keeps an email recipient on iMessage', () {
      expect(
        ChatServiceType.forNewChat(const [(address: 'a@example.com', status: ChatServiceType.sms)]),
        ChatServiceType.iMessage,
      );
    });

    test('uses iMessage while a recipient\'s status is unknown', () {
      expect(
        ChatServiceType.forNewChat(const [(address: '+15550000001', status: null)]),
        ChatServiceType.iMessage,
      );
    });
  });

  test('composer label names the text service', () {
    expect(ChatServiceType.iMessage.composerLabel, 'iMessage');
    expect(ChatServiceType.rcs.composerLabel, 'Text Message • RCS');
    expect(ChatServiceType.sms.composerLabel, 'Text Message • SMS');
  });

  test('all Apple chat services support Tapbacks', () {
    expect(ChatServiceType.iMessage.supportsTapbacks, isTrue);
    expect(ChatServiceType.sms.supportsTapbacks, isTrue);
    expect(ChatServiceType.rcs.supportsTapbacks, isTrue);
  });
}
