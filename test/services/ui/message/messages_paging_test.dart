// Scrolling up in a chat through MessagesService (S2 switch plan, commit 7):
// each older page comes from MessagingStore.olderMessagePage. A page starts
// after the (sort_at, id) key of the last message shown, so it is the screen's
// own order (Message.sort) and arrivals, deletes, ties and late-saved history
// can't repeat or skip a message (the seq.39 failure).
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/env.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/ui/message/messages_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../database/store/store_fixture.dart';

/// Pages until an empty one; returns the guid of every timeline message (not
/// reactions: the struct files them apart) in the
/// order read, and the cursors each page started from.
Future<(List<String>, List<MessagePageCursor?>)> walk(MessagesService service, {int limit = 25, int maxPages = 400}) async {
  final guids = <String>[];
  final cursors = <MessagePageCursor?>[];
  for (var i = 0; i < maxPages; i++) {
    cursors.add(service.olderCursor);
    final page = await service.loadOlderPage(limit: limit);
    if (page.isEmpty) return (guids, cursors);
    guids.addAll(page.where((m) => m.associatedMessageGuid == null).map((m) => m.guid!));
  }
  fail('no empty page after $maxPages pages');
}

void main() {
  setUpAll(() => isIsolateOverride = true);
  tearDownAll(() => isIsolateOverride = false);
  setUp(() {
    final settings = Settings();
    GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = settings);
  });
  tearDown(() => GetIt.I.unregister<SettingsService>());

  MessagesService serviceFor(Chat chat) => MessagesService(chat.guid)..chat = chat;

  storeTests((fixture) {
    test('a chat with reactions walks newest to oldest, every message once, in screen order', () async {
      final chat = await fixture().chat('c');
      final expected = <Message>[];
      for (var i = 0; i < 300; i++) {
        final m = await fixture().message('m$i', chat, t0 + i * 1000);
        expected.add(m);
        if (i % 7 == 0) await fixture().message('r$i', chat, t0 + i * 1000 + 1, reactsTo: 'm$i');
      }
      final service = serviceFor(chat);

      final (guids, _) = await walk(service);

      expect(guids, (expected..sort(Message.sort)).map((m) => m.guid));
      expect(service.struct.messages, hasLength(300));
    });

    test('history saved late (old dates, new ids) is reached in date order', () async {
      final chat = await fixture().chat('c');
      for (var i = 0; i < 60; i++) {
        await fixture().message('new$i', chat, t0 + 100000000 + i * 1000);
      }
      for (var i = 0; i < 60; i++) {
        await fixture().message('old$i', chat, t0 + i * 1000);
      }

      final (guids, _) = await walk(serviceFor(chat), limit: 25);

      expect(guids, [
        for (var i = 59; i >= 0; i--) 'new$i',
        for (var i = 59; i >= 0; i--) 'old$i',
      ]);
    });
  });

  storeTests((fixture) {
    test('delivered before created: pages follow the screen order, which uses the earlier date', () async {
      final chat = await fixture().chat('c');
      final all = <Message>[];
      for (var i = 0; i < 60; i++) {
        // Every third message was delivered 10.5 s before its created date.
        all.add(await fixture().message('m$i', chat, t0 + i * 1000, deliveredMs: i % 3 == 0 ? t0 + i * 1000 - 10500 : null));
      }

      final (guids, _) = await walk(serviceFor(chat), limit: 7);

      expect(guids, (all..sort(Message.sort)).map((m) => m.guid));
    });

    test('200 messages with one timestamp page across boundaries by id, none twice', () async {
      final chat = await fixture().chat('c');
      for (var i = 0; i < 200; i++) {
        await fixture().message('tie$i', chat, t0);
      }

      final (guids, _) = await walk(serviceFor(chat), limit: 25);

      expect(guids, [for (var i = 199; i >= 0; i--) 'tie$i']);
    });

    test('a message arriving mid-scroll does not shift the next older page', () async {
      final chat = await fixture().chat('c');
      for (var i = 0; i < 60; i++) {
        await fixture().message('m$i', chat, t0 + i * 1000);
      }
      final service = serviceFor(chat);
      final first = await service.loadOlderPage(limit: 25);
      await fixture().message('arrived', chat, t0 + 999999);
      final second = await service.loadOlderPage(limit: 25);

      expect(first.map((m) => m.guid), [for (var i = 59; i >= 35; i--) 'm$i']);
      expect(second.map((m) => m.guid), [for (var i = 34; i >= 10; i--) 'm$i']);
    });

    test('a shown message deleted mid-scroll does not skip one of the next older page', () async {
      final chat = await fixture().chat('c');
      for (var i = 0; i < 60; i++) {
        await fixture().message('m$i', chat, t0 + i * 1000);
      }
      final service = serviceFor(chat);
      await service.loadOlderPage(limit: 25);
      await fixture().store.deleteMessage('m50');
      final second = await service.loadOlderPage(limit: 25);

      expect(second.map((m) => m.guid), [for (var i = 34; i >= 10; i--) 'm$i']);
    });

    test('every page starts from a new cursor, and the empty page at the end keeps it', () async {
      final chat = await fixture().chat('c');
      for (var i = 0; i < 100; i++) {
        await fixture().message('m$i', chat, t0 + (i ~/ 10) * 1000);
      }
      final service = serviceFor(chat);

      final (guids, cursors) = await walk(service, limit: 9);

      expect(guids.toSet(), hasLength(100));
      // Pages 1..12 each start from a different cursor; the last (empty) page
      // started from the 12th page's end, which it kept.
      expect(cursors.toSet(), hasLength(cursors.length));
      expect(service.olderCursor, cursors.last);
    });

    test('jumping to a message loads both sides in screen order, ties included, and scrolling up continues below', () async {
      final chat = await fixture().chat('c');
      for (var i = 0; i < 100; i++) {
        await fixture().message('m$i', chat, t0 + (i ~/ 4) * 1000);
      }
      final target = (await fixture().store.messageByGuid('m50'))!;
      final service = serviceFor(chat);

      final around = await service.loadAroundPage(target, limit: 10);
      final older = await service.loadOlderPage(limit: 10);

      expect(around.map((m) => m.guid), [for (var i = 60; i >= 40; i--) 'm$i']);
      expect(older.map((m) => m.guid), [for (var i = 39; i >= 30; i--) 'm$i']);
    });
  });

  storeTests((fixture) {
    test('jumping to a message loads the message and its neighbours', () async {
      final chat = await fixture().chat('c');
      for (var i = 0; i < 60; i++) {
        await fixture().message('m$i', chat, t0 + i * 1000);
      }
      final target = (await fixture().store.messageByGuid('m30'))!;
      final service = serviceFor(chat);

      final around = await service.loadAroundPage(target, limit: 5);

      expect(around.map((m) => m.guid), [for (var i = 35; i >= 25; i--) 'm$i']);
      expect(service.struct.messages, hasLength(11));
    });
  });
}
