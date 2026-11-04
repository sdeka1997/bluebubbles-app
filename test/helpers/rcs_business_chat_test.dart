import 'package:bluebubbles/helpers/types/helpers/rcs_business_chat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a Google verified business sender is a business chat', () {
    expect(isRcsBusinessChat(chatIdentifier: 'vuori_faqs3z2t_agent@rbm.goog'), isTrue);
    expect(isRcsBusinessChat(guid: 'RCS;-;alaska_hawaiian_rnvdxhmm_agent@rbm.goog'), isTrue);
  });

  test('people are never business chats', () {
    expect(isRcsBusinessChat(chatIdentifier: '+12145550100', guid: 'RCS;-;+12145550100'), isFalse);
    expect(isRcsBusinessChat(chatIdentifier: 'chat612613285864880399', guid: 'RCS;+;chat612613285864880399'), isFalse);
    expect(isRcsBusinessChat(chatIdentifier: 'someone@gmail.com'), isFalse);
  });

  test('a short code is not matched by address', () {
    expect(isRcsBusinessChat(chatIdentifier: '41646', guid: 'SMS;-;41646'), isFalse);
  });
}
