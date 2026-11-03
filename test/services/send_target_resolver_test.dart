import 'package:bluebubbles/services/backend/send_target_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a new 1:1 iMessage chat carries what the Mac needs to open it', () {
    final chat = SendTargetResolver.newIMessageChat('+15550000001');
    expect(chat.guid, 'iMessage;-;+15550000001');
    expect(chat.service.isIMessageService, isTrue);
    expect(chat.isGroup, isFalse);
  });
}
