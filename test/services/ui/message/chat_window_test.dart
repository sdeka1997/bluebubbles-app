// S3 chat window (SQLITE-PLAN-2.md section 5, scroll-path tests 9 and 10 and
// the call sites the plan's summary missed): on SQLite the chat screen holds
// at most MessagesService.windowRows timeline rows. Paging past that drops
// rows at the far end and releases them; scrolling back reads them again.
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/env.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/ui/message/messages_service.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../database/store/store_fixture.dart';

void main() {
  setUpAll(() {
    isIsolateOverride = true;
    if (!GetIt.I.isRegistered<BaseLogger>()) GetIt.I.registerSingleton<BaseLogger>(BaseLogger());
  });
  tearDownAll(() => isIsolateOverride = false);
  setUp(() => GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = Settings()));
  tearDown(() => GetIt.I.unregister<SettingsService>());

  MessagesService serviceFor(Chat chat) => MessagesService(chat.guid)
    ..chat = chat
    ..newFunc = ((_) {})
    ..updateFunc = ((_, {String? oldGuid}) {})
    ..removeFunc = ((_) {})
    ..jumpToMessage = ((_) {})
    ..messagesRef = [];

  List<String> held(MessagesService s) => s.timeline.map((m) => m.guid!).toList();

  forEachStore((fixture) {
    late Chat chat;
    setUp(() async {
      chat = await fixture().chat('c');
      for (var i = 0; i < 400; i++) {
        await fixture().message('m$i', chat, t0 + i * 1000, deliveredMs: i == 399 ? t0 + i * 1000 : null);
      }
    });

    test('scrolling up holds at most 150 rows, drops the newest and releases their states', () async {
      final service = serviceFor(chat);
      final dropped = <String>[];
      service.droppedFunc = (rows, {required newest}) {
        expect(newest, isTrue);
        dropped.addAll(rows.map((m) => m.guid!));
      };

      for (var i = 0; i < 10; i++) {
        await service.loadChunk(null);
      }

      // 10 pages of 25 read m399..m150; the window keeps the oldest 150.
      expect(held(service), [for (var i = 299; i >= 150; i--) 'm$i']);
      expect(service.atNewestEdge, isFalse);
      expect(dropped.toSet(), {for (var i = 300; i < 400; i++) 'm$i'});
      expect(service.messageStates.keys.toSet(), {for (var i = 150; i < 300; i++) 'm$i'});
      expect(service.struct.messages, hasLength(150));
    });

    test('scrolling back down reads the dropped rows again in order and reaches the newest', () async {
      final service = serviceFor(chat);
      for (var i = 0; i < 10; i++) {
        await service.loadChunk(null);
      }
      final droppedOld = <String>[];
      service.droppedFunc = (rows, {required newest}) {
        if (!newest) droppedOld.addAll(rows.map((m) => m.guid!));
      };

      final seen = <String>[];
      while (!service.atNewestEdge) {
        final page = await service.loadNewerPage(null);
        seen.addAll(page.reversed.map((m) => m.guid!));
        expect(service.struct.messages.length, lessThanOrEqualTo(150));
      }

      expect(seen, [for (var i = 300; i < 400; i++) 'm$i']);
      expect(held(service), [for (var i = 399; i >= 250; i--) 'm$i']);
      expect(droppedOld.toSet(), {for (var i = 150; i < 250; i++) 'm$i'});
      // And up again continues right below the window.
      await service.loadChunk(null);
      expect(held(service).last, 'm225');
    });

    test('the read receipt stays on the newest read message while the window holds older ones', () async {
      final service = serviceFor(chat);
      final read = (await fixture().store.messageByGuid('m399'))!..dateRead = ms(t0 + 500000);
      service.struct.addMessages([read]);
      await service.loadChunk(null);
      expect(service.messageStates['m399']!.showDeliveredIndicator.value || service.messageStates['m399']!.showReadIndicator.value,
          isTrue);

      for (var i = 0; i < 9; i++) {
        await service.loadChunk(null);
      }
      // No held message took the receipt over.
      expect(service.messageStates.values.where((s) => s.showReadIndicator.value || s.showDeliveredIndicator.value), isEmpty);

      while (!service.atNewestEdge) {
        await service.loadNewerPage(null);
      }
      final state = service.messageStates['m399']!;
      expect(state.showReadIndicator.value || state.showDeliveredIndicator.value, isTrue);
    });

    test('a message arriving while the window holds older rows waits for paging; at the newest it is shown', () async {
      final service = serviceFor(chat);
      final shown = <String>[];
      service.newFunc = (m) => shown.add(m.guid!);
      for (var i = 0; i < 10; i++) {
        await service.loadChunk(null);
      }

      final late = await fixture().message('late', chat, t0 + 999000);
      await service.addNewMessage(late);
      expect(shown, isEmpty);
      expect(service.struct.getMessage('late'), isNull);

      // An old message saved late inside the held range is shown in place.
      final inside = await fixture().message('inside', chat, t0 + 200500);
      await service.addNewMessage(inside);
      expect(shown, ['inside']);

      while (!service.atNewestEdge) {
        await service.loadNewerPage(null);
      }
      expect(held(service).first, 'late');
      final now = await fixture().message('now', chat, t0 + 1999000);
      await service.addNewMessage(now);
      expect(shown, ['inside', 'now']);
    });

    test('replies count wherever they are: the originator held, its replies dropped or never loaded', () async {
      final service = serviceFor(chat);
      for (var i = 0; i < 5; i++) {
        await fixture().message('reply$i', chat, t0 + 390000 + i * 100 + 50, threadOriginator: 'm200');
      }
      for (var i = 0; i < 10; i++) {
        await service.loadChunk(null);
      }

      expect(service.struct.getMessage('reply0'), isNull);
      expect(service.struct.threads('m200', 0, returnOriginator: false).map((m) => m.guid).toSet(),
          {for (var i = 0; i < 5; i++) 'reply$i'});
    });

    test('newest sent and received come from the database once the newest rows were dropped', () async {
      final service = serviceFor(chat);
      for (var i = 0; i < 10; i++) {
        await service.loadChunk(null);
      }
      expect((await service.newestMessage())?.guid, 'm399');
      expect((await service.newestMessage(fromMe: true))?.guid, 'm399');
    });

    test('jumping to an old message holds the rows around it, and scrolling down from there reaches the newest', () async {
      final service = serviceFor(chat);
      await service.loadChunk(null);
      final target = (await fixture().store.messageByGuid('m100'))!;

      await service.loadAroundPage(target);

      expect(held(service), [for (var i = 125; i >= 75; i--) 'm$i']);
      expect(service.atNewestEdge, isFalse);
      var pages = 0;
      while (!service.atNewestEdge && pages++ < 20) {
        await service.loadNewerPage(null);
      }
      expect(held(service).first, 'm399');
    });
  }, only: {ActiveStore.sqlite});

  forEachStore((fixture) {
    test('ObjectBox keeps every row it loaded, as before', () async {
      final chat = await fixture().chat('c');
      for (var i = 0; i < 200; i++) {
        await fixture().message('m$i', chat, t0 + i * 1000);
      }
      final service = serviceFor(chat);
      for (var i = 0; i < 8; i++) {
        await service.loadChunk(null);
      }
      expect(service.struct.messages, hasLength(200));
      expect(service.atNewestEdge, isTrue);
    });
  }, only: {ActiveStore.objectBox});
}
