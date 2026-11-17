// A message that arrives while the chat list is on screen still joins the
// drawer, silently, so the drawer never shows an older message without the
// newer ones.
import 'package:bluebubbles/services/backend/java_dart_interop/method_channel_service.dart';
import 'package:bluebubbles/services/backend/notifications/notifications_service.dart';
import 'package:bluebubbles/services/network/method_channel_actions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorder extends MethodChannelService {
  final calls = <MethodCall>[];

  @override
  Future<dynamic> invokeMethod(String method, [dynamic arguments]) async => calls.add(MethodCall(method, arguments));
}

void main() {
  test('the open chat shows the message, so it gets no notification', () {
    expect(foregroundNotice(chatOpen: true, onChatList: false, notifyOnChatList: true), NewMessageNotice.none);
  });

  test('on the chat list a message joins the drawer silently', () {
    expect(foregroundNotice(chatOpen: false, onChatList: true, notifyOnChatList: false), NewMessageNotice.silent);
  });

  test('on the chat list with "notify on chat list" on, it alerts', () {
    expect(foregroundNotice(chatOpen: false, onChatList: true, notifyOnChatList: true), NewMessageNotice.alert);
  });

  test('anywhere else in the app, another chat\'s message alerts', () {
    expect(foregroundNotice(chatOpen: false, onChatList: false, notifyOnChatList: false), NewMessageNotice.alert);
  });

  test('a silent notification tells Android not to alert', () async {
    final channel = _Recorder();
    Future<void> post({bool? silent}) => silent == null
        ? MethodChannelActions(channel).createIncomingMessageNotification(
            channelId: 'c',
            chatId: 1,
            chatGuid: 'g',
            chatIsGroup: false,
            chatTitle: 't',
            chatIcon: Uint8List(0),
            contactName: 'n',
            contactAvatar: Uint8List(0),
            messageGuid: 'm',
            messageText: 'x',
            messageDate: 0,
            messageIsFromMe: false,
            showReactionAction: false,
            reactionType: 'like',
          )
        : MethodChannelActions(channel).createIncomingMessageNotification(
            channelId: 'c',
            chatId: 1,
            chatGuid: 'g',
            chatIsGroup: false,
            chatTitle: 't',
            chatIcon: Uint8List(0),
            contactName: 'n',
            contactAvatar: Uint8List(0),
            messageGuid: 'm',
            messageText: 'x',
            messageDate: 0,
            messageIsFromMe: false,
            showReactionAction: false,
            reactionType: 'like',
            silent: silent,
          );

    await post(silent: true);
    await post();

    expect(channel.calls.map((c) => c.method), everyElement('create-incoming-message-notification'));
    expect(channel.calls.map((c) => (c.arguments as Map)['silent']), [true, false]);
  });
}
