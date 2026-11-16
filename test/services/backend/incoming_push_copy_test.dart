// Which copies of a message the incoming handler lets through after a push,
// and what it does with an update whose message never arrives.
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
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

void main() {
  test('a full copy is worth writing over a trimmed push even when it is no newer', () {
    final pushed = Message(guid: 'g', text: 'hello', dateCreated: ms(t0));
    final full = Message(guid: 'g', text: 'hello', dateCreated: ms(t0), metadata: {'message': 'full'});

    expect(full.isNewerThan(pushed), isFalse, reason: 'the newer-than rule alone would skip it');
    expect(full.fillsGapsIn(pushed), isTrue);
    expect(pushed.fillsGapsIn(full), isFalse, reason: 'a trimmed copy has nothing to add');
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
    test('an update whose message never arrives is dropped once and asks for one sync', () async {
      final sync = _CountingSync();
      GetIt.I.registerSingleton<SyncService>(sync);
      addTearDown(() => GetIt.I.unregister<SyncService>());
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

      expect(handler.pendingUpdateCount, 0, reason: 'not parked again');
      expect(sync.catchUps, 1);
      expect(await fixture().store.messageByGuid('orphan-guid'), isNull);
    });
  });
}
