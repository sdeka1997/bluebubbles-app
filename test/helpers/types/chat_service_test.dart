import 'package:bluebubbles/database/io/chat.dart';
import 'package:bluebubbles/database/io/message.dart';
import 'package:bluebubbles/helpers/types/classes/chat_service_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Chat.fromMap keeps the service supplied by the server', () {
    final chat = Chat.fromMap({'guid': 'any;-;+155****0000', 'serviceName': 'RCS'});

    expect(chat.serviceName, 'RCS');
    expect(chat.service, ChatServiceType.rcs);
    expect(chat.toMap()['serviceName'], 'RCS');
  });

  test('Chat still derives service from the GUID for an older server', () {
    final chat = Chat.fromMap({'guid': 'SMS;-;+155****0000'});
    expect(chat.service, ChatServiceType.sms);
  });

  test('composer label distinguishes RCS, SMS and iMessage', () {
    expect(Chat.fromMap({'guid': 'any;-;1', 'serviceName': 'RCS'}).composerLabel(), 'Text Message • RCS');
    expect(Chat.fromMap({'guid': 'any;-;2', 'serviceName': 'SMS'}).composerLabel(), 'Text Message • SMS');
    expect(Chat.fromMap({'guid': 'any;-;3', 'serviceName': 'iMessage'}).composerLabel(), 'iMessage');
  });

  test('composer label follows my newest message when Messages filed it in an SMS record', () {
    // Messages from me have no sender handle, so the label must come from the message's own service.
    final chat = Chat.fromMap({'guid': 'SMS;-;+155****0000', 'serviceName': 'SMS'});
    final latest = Message.fromMap({'guid': 'm1', 'isFromMe': true, 'service': 'RCS'});
    expect(latest.getHandle(), isNull);
    expect(chat.composerLabel(latest), 'Text Message • RCS');
  });

  test('Message.fromMap reads the service the server sent and toMap writes it', () {
    final message = Message.fromMap({'guid': 'm1', 'isFromMe': false, 'service': 'RCS'});

    expect(message.service, 'RCS');
    expect(message.toMap()['service'], 'RCS');
  });

  test('Message.merge fills a missing service and never clears a stored one', () {
    final stored = Message.fromMap({'guid': 'm1', 'service': 'RCS'});
    expect(Message.merge(stored, Message.fromMap({'guid': 'm1'})).service, 'RCS');

    final old = Message.fromMap({'guid': 'm2'});
    expect(Message.merge(old, Message.fromMap({'guid': 'm2', 'service': 'RCS'})).service, 'RCS');
  });
}
