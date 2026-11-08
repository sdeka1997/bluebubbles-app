import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/interfaces/send_message_interface.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> handle(String address) => {'address': address};

void main() {
  test('a 1:1 chat sends its group id, participant and service', () {
    final chat = Chat.fromMap({
      'guid': 'iMessage;-;+15550001111',
      'groupId': 'F203DA0D',
      'participants': [handle('+15550001111')],
    });

    expect(SendMessageInterface.chatLookup(chat), {
      'groupId': 'F203DA0D',
      'participants': ['+15550001111'],
      'service': 'iMessage',
    });
  });

  test('a group chat sends its group id but not its participants', () {
    final chat = Chat.fromMap({
      'guid': 'iMessage;+;chat123',
      'groupId': 'A1B2C3',
      'participants': [handle('+15550001111'), handle('a@example.com')],
    });

    expect(SendMessageInterface.chatLookup(chat), {'groupId': 'A1B2C3', 'service': 'iMessage'});
  });

  test('a chat without a group id still sends its participant and service', () {
    final chat = Chat.fromMap({
      'guid': 'SMS;-;+15550001111',
      'participants': [handle('+15550001111')],
    });

    expect(SendMessageInterface.chatLookup(chat), {
      'participants': ['+15550001111'],
      'service': 'SMS',
    });
  });
}
