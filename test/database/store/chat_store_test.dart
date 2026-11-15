// ChatActions/ChatInterface through MessagingStore, on a real SQLite store.
import 'package:bluebubbles/env.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/actions/chat_actions.dart';
import 'package:bluebubbles/services/backend/interfaces/chat_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'store_fixture.dart';

void main() {
  setUpAll(() => isIsolateOverride = true);
  tearDownAll(() => isIsolateOverride = false);

  storeTests((fixture) {
    group('ChatActions', () {
      test('markAllChatsRead updates only the requested chats', () async {
        final selected = await fixture().chat('c-selected', unread: true);
        final untouched = await fixture().chat('c-untouched', unread: true);

        await ChatActions.markAllChatsRead({
          'chatIds': [selected.id!],
          'shouldMarkOnServer': false,
        });

        expect((await fixture().store.chatById(selected.id!))!.hasUnreadMessage, isFalse);
        expect((await fixture().store.chatById(untouched.id!))!.hasUnreadMessage, isTrue);
      });
    });

    group('ChatInterface hydration', () {
      test('getChatsAsync hydrates ids from the active store', () async {
        final first = await fixture().chat('hydrate-1');
        final second = await fixture().chat('hydrate-2');

        final chats = await ChatInterface.getChatsAsync(ids: [second.id!, first.id!]);

        expect(chats.map((chat) => chat.guid), unorderedEquals(['hydrate-1', 'hydrate-2']));
      });
    });

    test('photo state is stored but cannot advance the live visible timeline', () async {
      final chat = await fixture().chat('photo-state-chat');
      final latest = await fixture().message('visible', chat, t0 + 1000);
      await fixture().setLatest(chat, latest);
      final state = Message(
        guid: 'photo-state',
        dateCreated: ms(t0 + 2000),
        isFromMe: false,
        itemType: 3,
        groupActionType: 3,
      );

      final result = await fixture().store.addMessageToChat(
        state,
        const [],
        chat,
        latest,
        checkForMessageText: true,
      );

      expect(result['isNewer'], isFalse);
      expect(await fixture().store.messageByGuid('photo-state'), isNotNull);
      expect((await fixture().store.chatById(chat.id!))!.latestMessage?.guid, 'visible');
    });

    test('genuine photo changes and removals remain visible live events', () async {
      final chat = await fixture().chat('photo-events-chat');
      final latest = await fixture().message('visible', chat, t0 + 1000);
      for (final action in [1, 2]) {
        final event = Message(
          guid: 'photo-event-$action',
          dateCreated: ms(t0 + 1000 + action),
          isFromMe: false,
          itemType: 3,
          groupActionType: action,
        );
        final result = await fixture().store.addMessageToChat(
          event,
          const [],
          chat,
          latest,
          checkForMessageText: true,
        );
        expect(result['isNewer'], isTrue);
      }
    });
  });
}
