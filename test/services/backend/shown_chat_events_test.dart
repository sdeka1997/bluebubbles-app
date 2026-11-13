// Apple events name the copy of a conversation they happened in. A thread
// shown as one conversation is several Apple chats (service twins), so read
// status, typing and the offline catch-up apply to the conversation the copy
// is shown as, not only to a copy that happens to be the shown one.
import 'dart:io';

import 'package:bluebubbles/services/backend/action_handler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../database/store/store_fixture.dart';

void main() {
  storeTests((fixture) {
    test('a read on the hidden copy of a group applies to the conversation shown', () async {
      final shown = await fixture().chat('iMessage;+;chat-old', threadKey: 'family');
      await fixture().chat('iMessage;+;chat-new', threadKey: 'family');

      final chat = await chatForEvent('chat-read-status-changed', {'chatGuid': 'iMessage;+;chat-new', 'read': true});
      expect(chat?.guid, shown.guid);
    });

    test('typing in the hidden copy shows in the conversation shown', () async {
      final shown = await fixture().chat('SMS;-;+1', threadKey: 'k');
      await fixture().chat('iMessage;-;+1', threadKey: 'k');

      final chat = await chatForEvent('typing-indicator', {'guid': 'iMessage;-;+1', 'display': true});
      expect(chat?.guid, shown.guid);
    });

    test('a chat that is its own conversation is itself; an unknown chat is null', () async {
      final alone = await fixture().chat('iMessage;-;+2');
      expect((await chatForEvent('typing-indicator', {'guid': alone.guid}))?.guid, alone.guid);
      expect((await chatForEvent('chat-read-status-changed', {'chatGuid': alone.guid}))?.guid, alone.guid);
      expect(await chatForEvent('chat-read-status-changed', {'chatGuid': 'missing'}), isNull);
      expect(await chatForEvent('typing-indicator', const {}), isNull);
    });

    test('the store maps a copy to the chat it is shown as', () async {
      final shown = await fixture().chat('a', threadKey: 'k');
      await fixture().chat('b', threadKey: 'k');
      expect((await fixture().store.shownChatByGuid('b'))?.guid, shown.guid);
      expect((await fixture().store.shownChatByGuid('a'))?.guid, shown.guid);
      expect(await fixture().store.shownChatByGuid('missing'), isNull);
    });
  });

  test('the read and typing handlers find their chat only through chatForEvent', () {
    final source = File('lib/services/backend/action_handler.dart').readAsStringSync();
    String branch(String event) {
      final start = source.indexOf('case "$event":');
      expect(start, isNot(-1), reason: event);
      return source.substring(start, source.indexOf('return;', start));
    }

    for (final event in ['chat-read-status-changed', 'typing-indicator']) {
      final body = branch(event);
      expect(body, contains('chatForEvent('), reason: event);
      // Never the copy Apple named, straight from the payload.
      expect(body, isNot(matches(RegExp(r'[cC]hatByGuid\(\s*data\['))), reason: event);
    }
  });
}
