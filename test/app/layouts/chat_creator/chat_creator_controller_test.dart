import 'package:bluebubbles/app/layouts/chat_creator/chat_creator_controller.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

// No ChatsService is registered, so activating, undeleting or re-adding the chat throws.
void main() {
  ChatCreatorController creator(List<String> guards, {required bool allowed}) =>
      ChatCreatorController()
        ..canOpenChat = (guid, {explain = false}) {
          guards.add('$guid|$explain');
          return allowed;
        };

  test('a suppressed existing chat is explained once and never activated or undeleted', () async {
    final guards = <String>[];
    final controller = creator(guards, allowed: false);
    final chat = Chat(id: 1, guid: 'suppressed', hasUnreadMessage: false, dateDeleted: DateTime.utc(2026));

    final result = await controller.settleExistingChat(chat, checkDeleted: true, update: true);

    expect(result, same(chat));
    expect(guards, ['suppressed|true']);
    expect(controller.activeController.value, isNull);
    expect(controller.messagesService, isNull);
    expect(chat.dateDeleted, isNotNull);
  });

  test('the send-path lookup of a suppressed chat stays silent so the sender explains once', () async {
    final guards = <String>[];
    final controller = creator(guards, allowed: false);
    final chat = Chat(id: 1, guid: 'suppressed', hasUnreadMessage: false, dateDeleted: DateTime.utc(2026));

    final result = await controller.settleExistingChat(chat, checkDeleted: true, update: false);

    expect(result, same(chat));
    expect(guards, ['suppressed|false']);
    expect(chat.dateDeleted, isNotNull);
  });

  test('an openable chat resolved without an update is returned unchanged', () async {
    final guards = <String>[];
    final controller = creator(guards, allowed: true);
    final chat = Chat(id: 2, guid: 'open', hasUnreadMessage: false);

    final result = await controller.settleExistingChat(chat, checkDeleted: false, update: false);

    expect(result, same(chat));
    expect(guards, ['open|false']);
    expect(controller.activeController.value, isNull);
  });
}
