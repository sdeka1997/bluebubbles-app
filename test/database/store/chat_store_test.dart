// ChatActions/ChatInterface through MessagingStore. Every behavior runs against
// the real ObjectBox and SQLite implementations.
import 'package:bluebubbles/env.dart';
import 'package:bluebubbles/services/backend/actions/chat_actions.dart';
import 'package:bluebubbles/services/backend/interfaces/chat_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'store_fixture.dart';

void main() {
  setUpAll(() => isIsolateOverride = true);
  tearDownAll(() => isIsolateOverride = false);

  forEachStore((fixture) {
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
  });
}
