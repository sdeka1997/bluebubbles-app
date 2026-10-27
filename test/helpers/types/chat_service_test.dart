import 'package:bluebubbles/database/io/chat.dart';
import 'package:bluebubbles/database/io/handle.dart';
import 'package:bluebubbles/database/io/message.dart';
import 'package:bluebubbles/helpers/types/classes/chat_service_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Chat.fromMap keeps the service supplied by the server', () {
    final chat = Chat.fromMap({'guid': 'any;-;+15550000000', 'serviceName': 'RCS'});

    expect(chat.serviceName, 'RCS');
    expect(chat.service, ChatServiceType.rcs);
    expect(chat.toMap()['serviceName'], 'RCS');
  });

  test('Chat still derives service from the GUID for an older server', () {
    final chat = Chat.fromMap({'guid': 'SMS;-;+15550000000'});
    expect(chat.service, ChatServiceType.sms);
  });

  test('composer label distinguishes RCS, SMS and iMessage', () {
    expect(Chat.fromMap({'guid': 'any;-;1', 'serviceName': 'RCS'}).composerLabel(), 'Text Message • RCS');
    expect(Chat.fromMap({'guid': 'any;-;2', 'serviceName': 'SMS'}).composerLabel(), 'Text Message • SMS');
    expect(Chat.fromMap({'guid': 'any;-;3', 'serviceName': 'iMessage'}).composerLabel(), 'iMessage');
  });

  test('composer label follows the newest message when Messages filed it in an SMS record', () {
    final chat = Chat.fromMap({'guid': 'SMS;-;+155****0000', 'serviceName': 'SMS'});
    final latest = Message(handle: Handle(address: '+155****0000', service: 'RCS'));
    latest.handleRelation.target = latest.handle;
    expect(chat.composerLabel(latest), 'Text Message • RCS');
  });
}
