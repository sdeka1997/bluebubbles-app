// The conversation list's reads through MessagingStore (S2 switch plan,
// commit 7): new chats reach the list from the store's own change feed, and
// the list's counts and thread lookups come from the active store.
import 'dart:io';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/db_change_events.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/ui/chat/chats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../database/store/store_fixture.dart';

/// Records what the watch hands to addChat; the real one builds ChatState,
/// which needs app services.
class _ChatsService extends ChatsService {
  final added = <String>[];

  @override
  Future<void> addChat(Chat toAdd, {bool immediate = false}) async => added.add(toAdd.guid);
}

void main() {
  setUp(() {
    final settings = Settings()..finishedSetup.value = true;
    GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = settings);
  });
  tearDown(() => GetIt.I.unregister<SettingsService>());

  forEachStore((fixture) {
    test('a chat saved after the list loaded reaches addChat once; writes to stored chats do not', () async {
      final existing = await fixture().chat('existing', unread: true);
      final service = _ChatsService();
      final local = fixture().db == null ? null : DbChangeEvents.main.attachLocal(fixture().db!);
      addTearDown(() async {
        await service.countSub?.cancel();
        await local?.cancel();
      });

      service.initDbWatchers();
      await Future.delayed(const Duration(milliseconds: 100));
      await fixture().chat('new');
      await fixture().store.markChatsRead([existing.id!]);
      // A chat saved with no latest message is added after a 500 ms wait.
      await Future.delayed(const Duration(milliseconds: 900));

      expect(service.added, ['new']);
    });

    test('chatsWritten: only chats newer than every chat seen so far', () async {
      final existing = await fixture().chat('existing', unread: true);
      final local = fixture().db == null ? null : DbChangeEvents.main.attachLocal(fixture().db!);
      final seen = <String>[];
      final sub = fixture().store.chatsWritten().listen((chats) => seen.addAll(chats.map((c) => c.guid)));
      addTearDown(() async {
        await sub.cancel();
        await local?.cancel();
      });
      await Future.delayed(const Duration(milliseconds: 100));

      await fixture().store.markChatsRead([existing.id!]);
      await fixture().chat('second');
      await fixture().store.softDeleteChat('existing');
      await fixture().chat('third');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(seen, ['second', 'third']);
    });

    test('chatCount counts every stored chat, deleted ones too', () async {
      await fixture().chat('a');
      await fixture().chat('b', deleted: DateTime.utc(2024));
      expect(await fixture().store.chatCount(), 2);
    });

    test('threadedChats returns only the chats with a thread key', () async {
      await fixture().chat('plain');
      await fixture().chat('sms', threadKey: 'k');
      await fixture().chat('imessage', threadKey: 'k');
      expect((await fixture().store.threadedChats()).map((c) => c.guid), unorderedEquals(['sms', 'imessage']));
    });

    test('canonicalTwinOf: the older live copy is the thread, the newer one folds into it', () async {
      final older = await fixture().chat('older', threadKey: 'k');
      final newer = await fixture().chat('newer', threadKey: 'k');
      final alone = await fixture().chat('alone');
      expect((await fixture().store.canonicalTwinOf(newer))?.guid, 'older');
      expect(await fixture().store.canonicalTwinOf(older), isNull);
      expect(await fixture().store.canonicalTwinOf(alone), isNull);
    });
  });

  test('startup forwards the dbChanged events of both spawned isolates to the main feed', () {
    final source = File('lib/helpers/backend/startup_tasks.dart').readAsStringSync();
    expect(source, contains('DbChangeEvents.main.listenTo(GetIt.I<GlobalIsolate>())'));
    expect(source, contains('DbChangeEvents.main.listenTo(GetIt.I<IncrementalSyncIsolate>())'));
  });
}
