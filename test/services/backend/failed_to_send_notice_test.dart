// A send the app gave up on (connection dropped or timed out) that the server
// then confirmed: the chat's failed-to-send notification is removed, unless
// another of the chat's messages is still failed.
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../database/store/store_fixture.dart';

class _Notifications extends NotificationsService {
  final cleared = <int>[];

  @override
  Future<void> clearFailedToSend(int chatId) async => cleared.add(chatId);
}

void main() {
  storeTests((fixture) {
    late _Notifications notifications;
    late Chat chat;

    setUp(() async {
      notifications = _Notifications();
      GetIt.I.registerSingleton<NotificationsService>(notifications);
      chat = await fixture().chat('iMessage;-;ana@example.com');
    });
    tearDown(() => GetIt.I.unregister<NotificationsService>());

    Future<Message> failed(String guid, int at) =>
        fixture().message(guid, chat, at, edit: (m) => m..isFromMe = true..error = 1001);

    /// What the update pipeline does: store the server's copy, then the rule.
    Future<void> confirm(Message stored, String guid) async {
      final update = Message(guid: guid, text: stored.text, dateCreated: stored.dateCreated, isFromMe: true);
      await fixture().store.replaceMessage(stored.guid, update);
      await clearResolvedFailedNotice(stored: stored, update: update, chatId: chat.id!);
    }

    test('the server confirming the only failed send clears the notification', () async {
      await confirm(await failed('temp-1', t0), 'real-1');
      expect(notifications.cleared, [chat.id]);
      expect((await fixture().store.messageByGuid('real-1'))!.error, 0);
    });

    test('another failed message in the chat keeps it', () async {
      final first = await failed('temp-1', t0);
      await failed('temp-2', t0 + 10);
      await confirm(first, 'real-1');
      expect(notifications.cleared, isEmpty);
    });

    test('a deleted failed message does not keep it', () async {
      final first = await failed('temp-1', t0);
      await failed('temp-2', t0 + 10);
      await fixture().store.softDeleteMessage('temp-2');
      await confirm(first, 'real-1');
      expect(notifications.cleared, [chat.id]);
    });

    test('an ordinary send receipt leaves notifications alone', () async {
      final sent = await fixture().message('temp-1', chat, t0, edit: (m) => m..isFromMe = true);
      await confirm(sent, 'real-1');
      expect(notifications.cleared, isEmpty);
    });
  });
}
