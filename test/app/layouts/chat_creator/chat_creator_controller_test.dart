import 'package:bluebubbles/app/layouts/chat_creator/chat_creator_controller.dart';
import 'package:bluebubbles/database/io/chat.dart';
import 'package:bluebubbles/helpers/types/classes/chat_service_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatCreatorController.preferredMatch', () {
    final iMessage = Chat.fromMap({'guid': 'iMessage;-;+15550000001', 'serviceName': 'iMessage'});
    final sms = Chat.fromMap({'guid': 'SMS;-;+15550000001', 'serviceName': 'SMS'});
    final rcs = Chat.fromMap({'guid': 'any;-;+15550000001', 'serviceName': 'RCS'});

    test('prefers the chat on the chosen service', () {
      expect(ChatCreatorController.preferredMatch([sms, iMessage], ChatServiceType.iMessage), same(iMessage));
      expect(ChatCreatorController.preferredMatch([iMessage, sms], ChatServiceType.sms), same(sms));
    });

    test('treats an RCS chat as a text chat', () {
      expect(ChatCreatorController.preferredMatch([iMessage, rcs], ChatServiceType.sms), same(rcs));
    });

    test('falls back to the first match on another service', () {
      // A folded service twin can be the only thread left for the contact.
      expect(ChatCreatorController.preferredMatch([rcs], ChatServiceType.iMessage), same(rcs));
    });

    test('returns null without a match', () {
      expect(ChatCreatorController.preferredMatch(const [], ChatServiceType.iMessage), isNull);
    });
  });
}
