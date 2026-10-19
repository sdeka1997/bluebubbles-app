import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/ui/chat/chat_open_guard.dart';
import 'package:flutter_test/flutter_test.dart';

Chat _chat(String guid) => Chat(id: guid.hashCode, guid: guid, hasUnreadMessage: false);

void main() {
  group('resolveOpenableChat', () {
    test('a suppressed guid is rejected before the lookup', () async {
      final guards = <String>[];
      var lookups = 0;

      final chat = await resolveOpenableChat(
        'suppressed',
        canOpen: (guid) {
          guards.add(guid);
          return false;
        },
        lookup: (guid) {
          lookups++;
          return _chat(guid);
        },
      );

      expect(chat, isNull);
      expect(guards, ['suppressed']);
      expect(lookups, 0);
    });

    test('an openable guid resolves its chat', () async {
      final open = _chat('open');

      final chat = await resolveOpenableChat('open', canOpen: (_) => true, lookup: (_) async => open);

      expect(chat, same(open));
    });

    test('a chat that disappears during the lookup resolves to null', () async {
      expect(await resolveOpenableChat('gone', canOpen: (_) => true, lookup: (_) => null), isNull);
    });

    test('a suppression that starts during the lookup still wins', () async {
      var suppressed = false;

      final chat = await resolveOpenableChat(
        'racing',
        canOpen: (_) => !suppressed,
        lookup: (guid) async {
          suppressed = true;
          return _chat(guid);
        },
      );

      expect(chat, isNull);
    });
  });

  group('openIfAllowed', () {
    test('a suppressed guid never runs the open callback', () async {
      var opened = 0;

      final result = await openIfAllowed('suppressed', canOpen: (_) => false, open: () => opened++);

      expect(result, isFalse);
      expect(opened, 0);
    });

    test('an openable guid runs the open callback once', () async {
      var opened = 0;

      final result = await openIfAllowed('open', canOpen: (_) => true, open: () async => opened++);

      expect(result, isTrue);
      expect(opened, 1);
    });
  });
}
