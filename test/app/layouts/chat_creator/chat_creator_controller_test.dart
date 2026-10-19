import 'package:bluebubbles/app/layouts/chat_creator/chat_creator.dart' show SelectedContact;
import 'package:bluebubbles/app/layouts/chat_creator/chat_creator_controller.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

// No ChatsService is registered, so activating, undeleting or re-adding the chat throws.
void main() {
  ChatCreatorController creator(List<String> guards, {required bool allowed}) =>
      ChatCreatorController()
        ..canOpenChat = (guid, {explain = false}) {
          guards.add('$guid|$explain');
          return allowed;
        };

  Chat group(String guid, List<String> addresses, {String service = 'iMessage'}) {
    final chat = Chat(id: 99, guid: guid, hasUnreadMessage: false);
    chat.handles.addAll(addresses.map((address) => Handle(address: address, service: service)));
    return chat;
  }

  test('duplicate selected recipients cannot reuse one participant handle', () {
    final chat = group('iMessage;+;different-group', ['same@example.com', 'other@example.com']);

    expect(
      ChatCreatorController.chatMatchesParticipants(
        chat,
        ['same@example.com', 'same@example.com'],
        ChatServiceType.iMessage,
      ),
      isFalse,
    );
  });

  test('email participant matching is case insensitive', () {
    final chat = group('iMessage;+;email-group', ['Person@Example.COM', 'other@example.com']);

    expect(
      ChatCreatorController.chatMatchesParticipants(
        chat,
        ['person@example.com', 'OTHER@example.com'],
        ChatServiceType.iMessage,
      ),
      isTrue,
    );
  });

  test('an SMS chat cannot match an iMessage request with identical participants', () {
    final chat = group('SMS;+;sms-group', ['one@example.com', 'two@example.com'], service: 'SMS');

    expect(
      ChatCreatorController.chatMatchesParticipants(
        chat,
        ['one@example.com', 'two@example.com'],
        ChatServiceType.iMessage,
      ),
      isFalse,
    );
  });

  test('participant order does not affect matching', () {
    final chat = group('iMessage;+;ordered-group', ['two@example.com', 'one@example.com']);

    expect(
      ChatCreatorController.chatMatchesParticipants(
        chat,
        ['one@example.com', 'two@example.com'],
        ChatServiceType.iMessage,
      ),
      isTrue,
    );
  });

  test('equivalent phone formatting and country code match', () {
    final chat = group('iMessage;+;phone-group', ['+1 (555) 123-4567', '+1 (555) 765-4321']);

    expect(
      ChatCreatorController.chatMatchesParticipants(
        chat,
        ['555-123-4567', '(555) 765-4321'],
        ChatServiceType.iMessage,
      ),
      isTrue,
    );
  });

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
