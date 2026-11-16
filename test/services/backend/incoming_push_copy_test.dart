// Which copies of a message the incoming handler lets through after a push,
// and what it does with an update whose message never arrives.
import 'dart:async';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../database/store/store_fixture.dart';

class _CountingSync extends SyncService {
  int catchUps = 0;

  @override
  Future<void> startIncrementalSync({bool useGlobalIsolate = false, bool catchUp = false}) async {
    if (catchUp) catchUps++;
  }
}

AttributedBody _richBody(String text) => AttributedBody(
  string: text,
  runs: [
    Run(
      range: [0, text.length],
      attributes: Attributes(messagePart: 0, mention: 'mailto:person@example.com'),
    ),
  ],
);

void main() {
  test('a full copy is written over a trimmed push even when it is no newer', () {
    final pushed = Message(guid: 'g', text: 'hello', dateCreated: ms(t0));
    final full = Message(guid: 'g', text: 'hello', dateCreated: ms(t0), metadata: {'message': 'full'});

    expect(full.isNewerThan(pushed), isFalse, reason: 'the newer-than rule alone would skip it');
    expect(full.supersedes(pushed), isTrue);
    expect(pushed.supersedes(full), isFalse, reason: 'a trimmed copy has nothing to add');
  });

  test('an older copy never overwrites a newer stored one, even with fields to fill', () {
    final stored = Message(guid: 'g', text: 'edit 2', dateCreated: ms(t0), dateEdited: ms(t0 + 2000));
    final stale = Message(
      guid: 'g',
      text: 'edit 1',
      dateCreated: ms(t0),
      dateEdited: ms(t0 + 1000),
      attributedBody: [_richBody('edit 1')],
    );

    expect(stale.fillsGapsIn(stored), isTrue);
    expect(stale.supersedes(stored), isFalse);
  });

  test('filling gaps never clears a stored error', () {
    final failed = Message(guid: 'g', text: 'hello', dateCreated: ms(t0), error: 22);
    final full = Message(guid: 'g', text: 'hello', dateCreated: ms(t0), attributedBody: [_richBody('hello')]);

    expect(full.fillsGapsIn(failed), isTrue);
    expect(full.supersedes(failed), isFalse);
  });

  test('after a push, the next copy from elsewhere goes through once; repeats are dropped', () {
    final handler = IncomingMessageHandler();
    addTearDown(handler.dispose);

    handler.debugMarkProcessed('pushed', fromPush: true);
    expect(handler.debugIsDuplicate('pushed', fromPush: true), isTrue, reason: 'a repeated push adds nothing');
    expect(handler.debugIsDuplicate('pushed', fromPush: false), isFalse, reason: 'the socket copy may be complete');
    expect(handler.debugIsDuplicate('pushed', fromPush: false), isTrue, reason: 'only the first one');

    handler.debugMarkProcessed('socket', fromPush: false);
    expect(handler.debugIsDuplicate('socket', fromPush: true), isTrue, reason: 'a late push never replaces it');
    expect(handler.debugIsDuplicate('socket', fromPush: false), isTrue);
  });

  storeTests((fixture) {
    test('a catch-up asked for during the cooldown waits for it, once', () {
      fakeAsync((async) {
        final sync = SyncService()..debugLastIncrementalSync = DateTime.now();
        for (var i = 0; i < 3; i++) {
          unawaited(sync.startIncrementalSync(catchUp: true));
        }
        async.flushMicrotasks();
        expect(async.pendingTimers, hasLength(1));
        expect(sync.isIncrementalSyncing.value, isFalse);
      });
    });
  });

  storeTests((fixture) {
    late _CountingSync sync;
    late Settings settings;

    setUp(() {
      sync = _CountingSync();
      settings = Settings()..finishedSetup.value = true;
      GetIt.I.registerSingleton<SyncService>(sync);
      GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = settings);
    });
    tearDown(() {
      GetIt.I.unregister<SyncService>();
      GetIt.I.unregister<SettingsService>();
    });

    Future<IncomingMessageHandler> orphanUpdate() async {
      final handler = IncomingMessageHandler(pendingUpdateTimeout: const Duration(milliseconds: 10));
      addTearDown(handler.dispose);
      await handler.handle(
        IncomingPayload(
          type: MessageEventType.updatedMessage,
          source: MessageSource.socket,
          chat: Chat(guid: 'orphan-chat'),
          message: Message(guid: 'orphan-guid', text: 'updated', dateCreated: ms(t0 + 5000)),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return handler;
    }

    test('an update whose message never arrives is dropped once and asks for one sync', () async {
      final handler = await orphanUpdate();

      expect(handler.pendingUpdateCount, 0, reason: 'not parked again');
      expect(sync.catchUps, 1);
      expect(await fixture().store.messageByGuid('orphan-guid'), isNull);
    });

    test('during setup a lost update asks for nothing: the full sync is fetching everything', () async {
      settings.finishedSetup.value = false;
      final handler = await orphanUpdate();

      expect(handler.pendingUpdateCount, 0);
      expect(sync.catchUps, 0);
    });
  });
}
