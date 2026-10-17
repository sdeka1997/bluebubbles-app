import 'dart:async';
import 'dart:convert';

import 'package:bluebubbles/services/backend/sync/recoverable_delete_journal.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage {
  String? value;
  final List<String> events = [];

  String? read() => value;
  Future<void> write(String next) async {
    value = next;
    events.add('write:${jsonDecode(next)}');
  }
}

RecoverableDeleteJournal _journal(_MemoryStorage storage, String server) =>
    RecoverableDeleteJournal(serverAddress: server, readRaw: storage.read, writeRaw: storage.write);

void main() {
  final now = DateTime.utc(2026, 10, 17, 12);

  test('journal round-trips entries without leaking across servers', () async {
    final storage = _MemoryStorage();
    final first = _journal(storage, 'https://first');
    final second = _journal(storage, 'https://second');

    await first.recordSubmitted('chat-a', now: now);
    await second.recordSubmitted('chat-b', now: now);
    await first.recordAccepted('chat-a');

    expect((await first.load(now: now)).entries, {
      'chat-a': RecoverableDeleteEntry(startedAt: now, phase: RecoverableDeletePhase.accepted),
    });
    expect((await second.load(now: now)).entries.keys, {'chat-b'});
  });

  test('malformed journal fails open and is safely reseeded', () async {
    final storage = _MemoryStorage()
      ..value = '{"schemaVersion":1,"servers":{"https://first":{"chat-a":{"startedAt":"bad","phase":"submitted"}}}}';

    final result = await _journal(storage, 'https://first').load(now: now);

    expect(result.entries, isEmpty);
    expect(result.wasMalformed, isTrue);
    expect(jsonDecode(storage.value!), {'schemaVersion': 1, 'servers': {}});
  });

  test('submitted entries expire after one ten-minute sync window but accepted entries do not', () async {
    final storage = _MemoryStorage();
    final journal = _journal(storage, 'https://first');
    await journal.recordSubmitted('submitted', now: now.subtract(const Duration(minutes: 10)));
    await journal.recordSubmitted('accepted', now: now.subtract(const Duration(days: 1)));
    await journal.recordAccepted('accepted');

    final result = await journal.load(now: now);

    expect(result.entries.keys, {'accepted'});
    expect(result.expiredSubmittedGuids, {'submitted'});
  });

  test('delete orchestration durably orders submitted, POST, accepted, local delete, and clear', () async {
    String? raw;
    final events = <String>[];
    final journal = RecoverableDeleteJournal(
      serverAddress: 'https://first',
      readRaw: () => raw,
      writeRaw: (next) async {
        raw = next;
        final encoded = jsonDecode(next) as Map;
        final chat = ((encoded['servers'] as Map)['https://first'] as Map?)?['chat-a'] as Map?;
        events.add(chat == null ? 'clear' : 'persist:${chat['phase']}');
      },
    );
    final coordinator = RecoverableDeleteCoordinator(journal);

    final deleted = await coordinator.delete(
      'chat-a',
      now: now,
      submit: () async => events.add('post'),
      localDelete: () async => events.add('local-delete'),
      pendingChanged: (pending) => events.add('pending:$pending'),
    );

    expect(deleted, RecoverableDeleteOutcome.deleted);
    expect(events, [
      'persist:submitted',
      'pending:true',
      'post',
      'persist:accepted',
      'local-delete',
      'clear',
      'pending:false',
    ]);
  });

  test('definitive submit failure clears the journal and leaves the chat visible', () async {
    final storage = _MemoryStorage();
    final coordinator = RecoverableDeleteCoordinator(_journal(storage, 'https://first'));

    final deleted = await coordinator.delete(
      'chat-a',
      now: now,
      submit: () async => throw StateError('definitive HTTP failure'),
      localDelete: () async => fail('must not delete locally'),
      pendingChanged: (_) {},
    );

    expect(deleted, RecoverableDeleteOutcome.definitiveFailure);
    expect(coordinator.isSuppressed('chat-a'), isFalse);
    expect((await _journal(storage, 'https://first').load(now: now)).entries, isEmpty);
  });

  test('ambiguous submit failure keeps submitted state without retrying', () async {
    final storage = _MemoryStorage();
    final journal = _journal(storage, 'https://first');
    final coordinator = RecoverableDeleteCoordinator(journal);
    var postCount = 0;

    final outcome = await coordinator.delete(
      'chat-a',
      now: now,
      submit: () async {
        postCount++;
        throw StateError('response lost');
      },
      localDelete: () async => fail('must not delete locally'),
      pendingChanged: (_) {},
      isDefinitiveFailure: (_) => false,
    );

    expect(outcome, RecoverableDeleteOutcome.pendingConfirmation);

    expect(postCount, 1);
    expect(coordinator.isSuppressed('chat-a'), isTrue);
    expect((await journal.load(now: now)).entries['chat-a']?.phase, RecoverableDeletePhase.submitted);
  });

  test('restart hydration suppresses submitted GUID from the first visible batch and blocks reinsertion', () async {
    final storage = _MemoryStorage();
    await _journal(storage, 'https://first').recordSubmitted('chat-a', now: now);
    final coordinator = RecoverableDeleteCoordinator(_journal(storage, 'https://first'));

    await coordinator.hydrate(now: now);

    expect(coordinator.visibleGuids(['chat-a', 'chat-b']), ['chat-b']);
    expect(coordinator.shouldAddChat('chat-a'), isFalse);
    expect(coordinator.shouldAddChat('chat-b'), isTrue);
  });

  test('accepted restart entry finishes local deletion before becoming unsuppressed', () async {
    final storage = _MemoryStorage();
    final journal = _journal(storage, 'https://first');
    await journal.recordSubmitted('chat-a', now: now);
    await journal.recordAccepted('chat-a');
    final coordinator = RecoverableDeleteCoordinator(journal);
    final observations = <bool>[];

    await coordinator.hydrate(
      now: now,
      finishAccepted: (guid) async => observations.add(coordinator.isSuppressed(guid)),
    );

    expect(observations, [true]);
    expect(coordinator.isSuppressed('chat-a'), isFalse);
    expect((await journal.load(now: now)).entries, isEmpty);
  });

  test('complete snapshot absence deletes and clears a journaled chat', () async {
    final storage = _MemoryStorage();
    final journal = _journal(storage, 'https://first');
    await journal.recordSubmitted('chat-a', now: now);
    final coordinator = RecoverableDeleteCoordinator(journal);
    await coordinator.hydrate(now: now);
    final events = <String>[];

    await coordinator.resolveSnapshot(
      messageCounts: const {},
      now: now,
      hasLocalWork: (_) => false,
      softDelete: (guid) async => events.add('delete:$guid'),
      deferDeletion: (guid) async => events.add('defer:$guid'),
      restore: (guid) async => events.add('restore:$guid'),
    );

    expect(events, ['delete:chat-a']);
    expect(coordinator.isSuppressed('chat-a'), isFalse);
    expect((await journal.load(now: now)).entries, isEmpty);
  });

  test('zero-message snapshot confirms deletion', () async {
    final storage = _MemoryStorage();
    final journal = _journal(storage, 'https://first');
    await journal.recordSubmitted('chat-a', now: now);
    final coordinator = RecoverableDeleteCoordinator(journal);
    final events = <String>[];

    await coordinator.resolveSnapshot(
      messageCounts: const {'chat-a': 0},
      now: now,
      hasLocalWork: (_) => false,
      softDelete: (guid) async => events.add('delete:$guid'),
      deferDeletion: (_) async {},
      restore: (_) async {},
    );

    expect(events, ['delete:chat-a']);
    expect((await journal.load(now: now)).entries, isEmpty);
  });

  test('populated snapshot restores active local chat and clears journal', () async {
    final storage = _MemoryStorage();
    final journal = _journal(storage, 'https://first');
    await journal.recordSubmitted('chat-a', now: now);
    final coordinator = RecoverableDeleteCoordinator(journal);
    await coordinator.hydrate(now: now);
    final events = <String>[];

    await coordinator.resolveSnapshot(
      messageCounts: const {'chat-a': 2},
      now: now,
      hasLocalWork: (_) => false,
      softDelete: (_) async {},
      deferDeletion: (_) async {},
      restore: (guid) async => events.add('restore:$guid'),
    );

    expect(events, ['restore:chat-a']);
    expect(coordinator.isSuppressed('chat-a'), isFalse);
    expect((await journal.load(now: now)).entries, isEmpty);
  });

  test('confirmed deletion with a draft transfers to deferred deletion and becomes visible', () async {
    final storage = _MemoryStorage();
    final journal = _journal(storage, 'https://first');
    await journal.recordSubmitted('chat-a', now: now);
    final coordinator = RecoverableDeleteCoordinator(journal);
    await coordinator.hydrate(now: now);
    final events = <String>[];

    await coordinator.resolveSnapshot(
      messageCounts: const {},
      now: now,
      hasLocalWork: (guid) => true,
      softDelete: (_) async => fail('draft chat must not be deleted'),
      deferDeletion: (guid) async => events.add('defer:$guid'),
      restore: (guid) async => events.add('restore:$guid'),
    );

    expect(events, ['defer:chat-a', 'restore:chat-a']);
    expect(coordinator.isSuppressed('chat-a'), isFalse);
    expect((await journal.load(now: now)).entries, isEmpty);
  });

  test('failed submitted persistence performs no POST and leaves the chat visible', () async {
    final coordinator = RecoverableDeleteCoordinator(
      RecoverableDeleteJournal(
        serverAddress: 'https://first',
        readRaw: () => null,
        writeRaw: (_) async => throw StateError('write failed'),
      ),
    );
    var postCount = 0;

    await expectLater(
      coordinator.delete(
        'chat-a',
        now: now,
        submit: () async => postCount++,
        localDelete: () async => fail('must not delete locally'),
        pendingChanged: (_) {},
      ),
      throwsStateError,
    );

    expect(postCount, 0);
    expect(coordinator.isSuppressed('chat-a'), isFalse);
  });

  test('malformed journal still fails open when clearing corrupt storage throws', () async {
    final reported = <Object>[];
    final journal = RecoverableDeleteJournal(
      serverAddress: 'https://first',
      readRaw: () => '{bad json',
      writeRaw: (_) async => throw StateError('clear failed'),
      onMalformed: (error, _) => reported.add(error),
    );

    final result = await journal.load(now: now);

    expect(result.entries, isEmpty);
    expect(result.wasMalformed, isTrue);
    expect(reported, hasLength(2));
    expect(reported.first, isA<FormatException>());
    expect(reported.last, isA<StateError>());
  });

  test('accepted hydration isolates failures and retains only failed entries', () async {
    final storage = _MemoryStorage();
    final journal = _journal(storage, 'https://first');
    for (final guid in ['bad-local', 'good', 'bad-clear']) {
      await journal.recordSubmitted(guid, now: now);
      await journal.recordAccepted(guid);
    }
    final finished = <String>[];
    final failures = <String>[];
    var failNextClear = false;
    final isolatingJournal = RecoverableDeleteJournal(
      serverAddress: 'https://first',
      readRaw: storage.read,
      writeRaw: (value) async {
        if (failNextClear) {
          failNextClear = false;
          throw StateError('clear failed');
        }
        await storage.write(value);
      },
    );
    final coordinator = RecoverableDeleteCoordinator(isolatingJournal);

    await coordinator.hydrate(
      now: now,
      finishAccepted: (guid) async {
        if (guid == 'bad-local') throw StateError('local delete failed');
        finished.add(guid);
        if (guid == 'bad-clear') failNextClear = true;
      },
      acceptedFailure: (guid, _, _) => failures.add(guid),
    );

    expect(finished, containsAll(['good', 'bad-clear']));
    expect(failures, containsAll(['bad-local', 'bad-clear']));
    expect(coordinator.isSuppressed('bad-local'), isTrue);
    expect(coordinator.isSuppressed('bad-clear'), isTrue);
    expect(coordinator.isSuppressed('good'), isFalse);
    expect((await journal.load(now: now)).entries.keys, containsAll(['bad-local', 'bad-clear']));
    expect((await journal.load(now: now)).entries.keys, isNot(contains('good')));
  });

  test('one journal write failure does not poison the next serialized write', () async {
    String? raw;
    var writes = 0;
    final journal = RecoverableDeleteJournal(
      serverAddress: 'https://first',
      readRaw: () => raw,
      writeRaw: (value) async {
        writes++;
        if (writes == 1) throw StateError('first failed');
        raw = value;
      },
    );

    await expectLater(journal.recordSubmitted('first', now: now), throwsStateError);
    await journal.recordSubmitted('second', now: now);

    expect((await journal.load(now: now)).entries.keys, {'second'});
  });

  test('a stalled write for one server does not block another journal instance', () async {
    final stalled = Completer<void>();
    final first = RecoverableDeleteJournal(
      serverAddress: 'https://first',
      readRaw: () => null,
      writeRaw: (_) => stalled.future,
    );
    final secondStorage = _MemoryStorage();
    final second = _journal(secondStorage, 'https://second');
    unawaited(first.recordSubmitted('chat-a', now: now));

    await second.recordSubmitted('chat-b', now: now).timeout(const Duration(seconds: 1));

    expect((await second.load(now: now)).entries.keys, {'chat-b'});
  });


  test('draft handoff failure retains suppression and journal for replay', () async {
    final storage = _MemoryStorage();
    final journal = _journal(storage, 'https://first');
    await journal.recordSubmitted('chat-a', now: now);
    final coordinator = RecoverableDeleteCoordinator(journal);
    await coordinator.hydrate(now: now);

    await expectLater(
      coordinator.resolveSnapshot(
        messageCounts: const {},
        now: now,
        hasLocalWork: (_) => true,
        softDelete: (_) async => fail('must not soft-delete draft'),
        deferDeletion: (_) async => throw StateError('deferred write failed'),
        restore: (_) async => fail('must not restore before durable handoff'),
      ),
      throwsStateError,
    );

    expect(coordinator.isSuppressed('chat-a'), isTrue);
    expect((await journal.load(now: now)).entries.keys, {'chat-a'});
  });

  test('live server switch hydrates each coordinator without leaking suppression', () async {
    final storage = _MemoryStorage();
    await _journal(storage, 'https://first').recordSubmitted('chat-a', now: now);
    await _journal(storage, 'https://second').recordSubmitted('chat-b', now: now);
    final store = RecoverableDeleteCoordinatorStore(
      (server) => RecoverableDeleteCoordinator(_journal(storage, server)),
    );

    final first = await store.forServer('https://first', now: now);
    final second = await store.forServer('https://second', now: now);
    final firstAgain = await store.forServer('https://first', now: now);

    expect(first.isSuppressed('chat-a'), isTrue);
    expect(first.isSuppressed('chat-b'), isFalse);
    expect(second.isSuppressed('chat-b'), isTrue);
    expect(second.isSuppressed('chat-a'), isFalse);
    expect(identical(first, firstAgain), isTrue);
  });


  test('malformation in one server bucket conservatively clears every server bucket', () async {
    final storage = _MemoryStorage()
      ..value = jsonEncode({
        'schemaVersion': 1,
        'servers': {
          'https://valid': {
            'chat-valid': {'startedAt': now.millisecondsSinceEpoch, 'phase': 'submitted'},
          },
          'https://malformed': {
            'chat-malformed': {'startedAt': 'bad', 'phase': 'submitted'},
          },
        },
      });

    final result = await _journal(storage, 'https://valid').load(now: now);

    expect(result.entries, isEmpty);
    expect(result.wasMalformed, isTrue);
    expect(jsonDecode(storage.value!), {'schemaVersion': 1, 'servers': {}});
  });
}
