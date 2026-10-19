import 'package:bluebubbles/app/layouts/chat_creator/chat_creator.dart' show SelectedContact;
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


  test('a suppressed local group outside the visible list resolves before creation', () async {
    final chat = Chat(id: 3, guid: 'suppressed-group', hasUnreadMessage: false);
    chat.handles.addAll([
      Handle(address: '+15550000001', service: 'iMessage'),
      Handle(address: '+15550000002', service: 'iMessage'),
    ]);
    final guards = <String>[];
    final controller = ChatCreatorController(recoverableChatSource: () => [chat])
      ..selectedContacts.addAll([
        SelectedContact(displayName: 'One', address: '+15550000001'),
        SelectedContact(displayName: 'Two', address: '+15550000002'),
      ])
      ..canOpenChat = (guid, {explain = false}) {
        guards.add('$guid|$explain');
        return false;
      };

    final result = await controller.findExistingChat(checkDeleted: true, update: false);
    await controller.settleExistingChat(result, checkDeleted: true, update: true);

    expect(result, same(chat));
    expect(guards, ['suppressed-group|false', 'suppressed-group|true']);
    expect(controller.activeController.value, isNull);
  });

  test('an openable local group outside the visible list still resolves', () async {
    final chat = Chat(id: 4, guid: 'open-group', hasUnreadMessage: false);
    chat.handles.addAll([
      Handle(address: '+15550000003', service: 'iMessage'),
      Handle(address: '+15550000004', service: 'iMessage'),
    ]);
    final controller = ChatCreatorController(recoverableChatSource: () => [chat])
      ..selectedContacts.addAll([
        SelectedContact(displayName: 'Three', address: '+15550000003'),
        SelectedContact(displayName: 'Four', address: '+15550000004'),
      ])
      ..canOpenChat = (guid, {explain = false}) => true;

    final result = await controller.findExistingChat(checkDeleted: true, update: false);

    expect(result, same(chat));
    expect(controller.activeController.value, isNull);
  });
}
