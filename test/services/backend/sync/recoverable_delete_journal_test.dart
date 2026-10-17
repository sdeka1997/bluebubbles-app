import 'dart:async';
import 'dart:convert';

import 'package:bluebubbles/services/backend/sync/recoverable_delete_journal.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryStorage {
  String? value;
  bool failNext = false;
  Completer<void>? pauseNext;
  int writes = 0;
  String? read() => value;
  Future<bool> write(String next) async {
    writes++;
    final pause = pauseNext;
    pauseNext = null;
    if (pause != null) await pause.future;
    if (failNext) {
      failNext = false;
      throw StateError('write failed');
    }
    value = next;
    return true;
  }
}

void main() {
  final now = DateTime.utc(2026, 10, 17, 12);

  test('shared delayed A and B transactions preserve both server buckets', () async {
    final storage = MemoryStorage();
    final repository = RecoverableDeleteRepository(readRaw: storage.read, writeRaw: storage.write);
    await repository.ensureLoaded();
    final gate = storage.pauseNext = Completer<void>();
    final a = repository.viewForServer('A').recordSubmitted('chat-a', attemptId: 'attempt_A_0123456', now: now);
    await Future<void>.delayed(Duration.zero);
    var bDone = false;
    final b = repository.viewForServer('B').recordSubmitted('chat-b', attemptId: 'attempt_B_0123456', now: now)
      ..then((_) => bDone = true);
    await Future<void>.delayed(Duration.zero);
    expect(bDone, isFalse);
    gate.complete();
    await Future.wait([a, b]);
    final servers = (jsonDecode(storage.value!) as Map)['servers'] as Map;
    expect(servers.keys.toSet(), {'A', 'B'});
  });

  test('failed transaction does not publish and queue remains usable', () async {
    final storage = MemoryStorage();
    final repository = RecoverableDeleteRepository(readRaw: storage.read, writeRaw: storage.write);
    await repository.ensureLoaded();
    storage.failNext = true;
    await expectLater(
      repository.viewForServer('A').recordSubmitted('bad', attemptId: 'attempt_bad_01234', now: now),
      throwsStateError,
    );
    expect(repository.viewForServer('A').isSuppressed('bad'), isFalse);
    await repository.viewForServer('B').recordSubmitted('good', attemptId: 'attempt_good_0123', now: now);
    expect(repository.viewForServer('B').isSuppressed('good'), isTrue);
  });

  test('failed submitted persistence means zero POST calls', () async {
    final storage = MemoryStorage();
    final repository = RecoverableDeleteRepository(readRaw: storage.read, writeRaw: storage.write);
    await repository.ensureLoaded();
    storage.failNext = true;
    var posts = 0;
    await expectLater(
      repository
          .viewForServer('A')
          .delete(
            'chat',
            now: now,
            submit: (_) async {
              posts++;
              return RecoverableDeleteReceiptState.succeeded;
            },
            status: (_) async => RecoverableDeleteReceiptState.pending,
            localDelete: () async {},
            pendingChanged: (_) {},
          ),
      throwsStateError,
    );
    expect(posts, 0);
  });

  test('submitted recovery uses status only and pending never expires', () async {
    final storage = MemoryStorage();
    var repository = RecoverableDeleteRepository(readRaw: storage.read, writeRaw: storage.write);
    await repository.ensureLoaded();
    await repository
        .viewForServer('A')
        .recordSubmitted('chat', attemptId: 'attempt_restart_01', now: now.subtract(const Duration(days: 30)));

    repository = RecoverableDeleteRepository(readRaw: storage.read, writeRaw: storage.write);
    var posts = 0;
    var statuses = 0;
    await repository
        .viewForServer('A')
        .hydrate(
          status: (_, _) async {
            statuses++;
            return RecoverableDeleteReceiptState.pending;
          },
          finishAccepted: (_) async {},
        );
    expect(posts, 0);
    expect(statuses, 1);
    expect(repository.viewForServer('A').isSuppressed('chat'), isTrue);
  });

  test('same repository returns stable views and server suppression does not leak', () async {
    final repository = RecoverableDeleteRepository(readRaw: () => null, writeRaw: (_) async => true);
    await repository.ensureLoaded();
    final a1 = repository.viewForServer('A');
    final a2 = repository.viewForServer('A');
    final b = repository.viewForServer('B');
    expect(identical(a1, a2), isTrue);
    await a1.recordSubmitted('chat', attemptId: 'attempt_stable_01', now: now);
    expect(a1.isSuppressed('chat'), isTrue);
    expect(b.isSuppressed('chat'), isFalse);
  });

  test('unreadable storage degrades and disables new deletes', () async {
    final repository = RecoverableDeleteRepository(
      readRaw: () => throw StateError('read failed'),
      writeRaw: (_) async => true,
    );
    await repository.ensureLoaded();
    expect(repository.degraded, isTrue);
    var posts = 0;
    await expectLater(
      repository
          .viewForServer('A')
          .delete(
            'chat',
            now: now,
            submit: (_) async {
              posts++;
              return RecoverableDeleteReceiptState.succeeded;
            },
            status: (_) async => RecoverableDeleteReceiptState.pending,
            localDelete: () async {},
            pendingChanged: (_) {},
          ),
      throwsStateError,
    );
    expect(posts, 0);
  });

  test('snapshot never resolves submitted without a causal fence', () async {
    final repository = RecoverableDeleteRepository(readRaw: () => null, writeRaw: (_) async => true);
    final view = repository.viewForServer('A');
    await view.recordSubmitted('chat', attemptId: 'attempt_snapshot01', now: now);
    var effects = 0;
    final protected = await view.resolveSnapshot(
      messageCounts: const {},
      now: now.add(const Duration(days: 1)),
      hasLocalWork: (_) => false,
      softDelete: (_) async => effects++,
      deferDeletion: (_) async => effects++,
      restore: (_) async => effects++,
    );
    expect(protected, {'chat'});
    expect(effects, 0);
    expect(view.isSuppressed('chat'), isTrue);
  });

  test('SharedPreferences false is a failed transaction and performs no POST', () async {
    var posts = 0;
    final repository = RecoverableDeleteRepository(readRaw: () => null, writeRaw: (_) async => false);
    await expectLater(
      repository
          .viewForServer('A')
          .delete(
            'chat',
            now: now,
            submit: (_) async {
              posts++;
              return RecoverableDeleteReceiptState.succeeded;
            },
            status: (_) async => RecoverableDeleteReceiptState.pending,
            localDelete: () async {},
            pendingChanged: (_) {},
          ),
      throwsStateError,
    );
    expect(posts, 0);
    expect(repository.viewForServer('A').isSuppressed('chat'), isFalse);
  });

  test('active delete and startup recovery share a lock and recovery re-reads the claim', () async {
    final storage = MemoryStorage();
    final repository = RecoverableDeleteRepository(readRaw: storage.read, writeRaw: storage.write);
    final view = repository.viewForServer('A');
    final submitStarted = Completer<void>();
    final releaseSubmit = Completer<void>();
    var statusCalls = 0;
    final deleting = view.delete(
      'chat',
      now: now,
      submit: (_) async {
        submitStarted.complete();
        await releaseSubmit.future;
        return RecoverableDeleteReceiptState.pending;
      },
      status: (_) async => RecoverableDeleteReceiptState.pending,
      localDelete: () async => fail('pending must not delete'),
      pendingChanged: (_) {},
    );
    await submitStarted.future;
    var recoveryDone = false;
    final recovery = view.hydrate(
      status: (_, _) async {
        statusCalls++;
        return RecoverableDeleteReceiptState.pending;
      },
      finishAccepted: (_) async => fail('pending must not finish'),
    )..then((_) => recoveryDone = true);
    await Future<void>.delayed(Duration.zero);
    expect(recoveryDone, isFalse);
    releaseSubmit.complete();
    await deleting;
    await recovery;
    expect(statusCalls, 1);
    expect(view.isSuppressed('chat'), isTrue);
  });

  test('narrow malformed quarantine preserves valid accepted claims and sanitizes storage', () async {
    final storage = MemoryStorage()
      ..value = jsonEncode({
        'schemaVersion': 2,
        'servers': {
          'A': {
            'valid': {'attemptId': 'attempt_valid_0123', 'startedAt': now.millisecondsSinceEpoch, 'phase': 'accepted'},
            'bad': {'attemptId': 7, 'startedAt': 'bad', 'phase': 'submitted'},
          },
          'broken-bucket': 'not-a-map',
        },
      });
    final reported = <Object>[];
    final repository = RecoverableDeleteRepository(
      readRaw: storage.read,
      writeRaw: storage.write,
      onMalformed: (error, _) => reported.add(error),
    );
    await repository.ensureLoaded();
    expect(repository.degraded, isFalse);
    expect(repository.viewForServer('A').isSuppressed('valid'), isTrue);
    expect(repository.viewForServer('A').isSuppressed('bad'), isFalse);
    expect(reported, isNotEmpty);
    final servers = (jsonDecode(storage.value!) as Map)['servers'] as Map;
    expect((servers['A'] as Map).keys, ['valid']);
    expect(servers.containsKey('broken-bucket'), isFalse);
  });

  test('failed malformed cleanup preserves valid suppression but disables new deletes', () async {
    final raw = jsonEncode({
      'schemaVersion': 2,
      'servers': {
        'A': {
          'valid': {'attemptId': 'attempt_valid_0123', 'startedAt': now.millisecondsSinceEpoch, 'phase': 'accepted'},
          'bad': {'attemptId': 7},
        },
      },
    });
    final repository = RecoverableDeleteRepository(readRaw: () => raw, writeRaw: (_) async => false);
    await repository.ensureLoaded();
    expect(repository.degraded, isTrue);
    expect(repository.viewForServer('A').isSuppressed('valid'), isTrue);
    await expectLater(
      repository.viewForServer('A').recordSubmitted('new', attemptId: 'attempt_new_012345', now: now),
      throwsStateError,
    );
  });

  test('repository owner is stable per preferences key', () {
    RecoverableDeleteRepository.resetOwnersForTesting();
    Future<bool> write(String _) async => true;
    final first = RecoverableDeleteRepository.ownerForKey('prefs-key', readRaw: () => null, writeRaw: write);
    final second = RecoverableDeleteRepository.ownerForKey('prefs-key', readRaw: () => null, writeRaw: write);
    expect(identical(first, second), isTrue);
    RecoverableDeleteRepository.resetOwnersForTesting();
  });

  test('startup maps succeeded, definitive failure, pending, and accepted replay independently', () async {
    final storage = MemoryStorage();
    var repository = RecoverableDeleteRepository(readRaw: storage.read, writeRaw: storage.write);
    final original = repository.viewForServer('A');
    for (final guid in ['succeeded', 'failed', 'pending', 'accepted', 'local-error']) {
      await original.recordSubmitted(guid, attemptId: 'attempt_${guid}_012345', now: now);
    }
    await repository.transaction((state) {
      final current = state['A']!['accepted']!;
      state['A']!['accepted'] = RecoverableDeleteEntry(
        attemptId: current.attemptId,
        startedAt: current.startedAt,
        phase: RecoverableDeletePhase.accepted,
      );
    });

    repository = RecoverableDeleteRepository(readRaw: storage.read, writeRaw: storage.write);
    final view = repository.viewForServer('A');
    final finished = <String>[];
    final failures = <String>[];
    await view.hydrate(
      status: (guid, _) async => switch (guid) {
        'succeeded' || 'local-error' => RecoverableDeleteReceiptState.succeeded,
        'failed' => RecoverableDeleteReceiptState.definitiveFailure,
        _ => RecoverableDeleteReceiptState.pending,
      },
      finishAccepted: (guid) async {
        if (guid == 'local-error') throw StateError('local failure');
        finished.add(guid);
      },
      acceptedFailure: (guid, _, _) => failures.add(guid),
    );

    expect(finished.toSet(), {'succeeded', 'accepted'});
    expect(failures, ['local-error']);
    expect(view.isSuppressed('succeeded'), isFalse);
    expect(view.isSuppressed('failed'), isFalse);
    expect(view.isSuppressed('accepted'), isFalse);
    expect(view.isSuppressed('pending'), isTrue);
    expect(view.isSuppressed('local-error'), isTrue);
  });

  test('draft handoff retains journal protection across restart until deferred persistence succeeds', () async {
    final storage = MemoryStorage();
    var repository = RecoverableDeleteRepository(readRaw: storage.read, writeRaw: storage.write);
    final first = repository.viewForServer('A');
    await first.recordSubmitted('draft', attemptId: 'attempt_draft_012345', now: now);
    await repository.transaction((state) {
      final current = state['A']!['draft']!;
      state['A']!['draft'] = RecoverableDeleteEntry(
        attemptId: current.attemptId,
        startedAt: current.startedAt,
        phase: RecoverableDeletePhase.accepted,
      );
    });

    repository = RecoverableDeleteRepository(readRaw: storage.read, writeRaw: storage.write);
    final restarted = repository.viewForServer('A');
    await expectLater(
      restarted.resolveSnapshot(
        messageCounts: const {},
        now: now,
        hasLocalWork: (_) => true,
        softDelete: (_) async => fail('draft must not be deleted'),
        deferDeletion: (_) async => throw StateError('deferred persistence failed'),
        restore: (_) async => fail('must not restore before durable handoff'),
      ),
      throwsStateError,
    );
    expect(restarted.isSuppressed('draft'), isTrue);

    final events = <String>[];
    await restarted.resolveSnapshot(
      messageCounts: const {},
      now: now,
      hasLocalWork: (_) => true,
      softDelete: (_) async => fail('draft must not be deleted'),
      deferDeletion: (_) async => events.add('durable-deferred'),
      restore: (_) async => events.add('restore'),
    );
    expect(events, ['durable-deferred', 'restore']);
    expect(restarted.isSuppressed('draft'), isFalse);
  });

  test('repeated hydration rechecks pending status on the same repository and lock domain', () async {
    final storage = MemoryStorage();
    final repository = RecoverableDeleteRepository(readRaw: storage.read, writeRaw: storage.write);
    final view = repository.viewForServer('A');
    await view.recordSubmitted('chat', attemptId: 'attempt_recheck_0123', now: now);
    var receipt = RecoverableDeleteReceiptState.pending;
    var statusCalls = 0;
    final finished = <String>[];

    Future<void> hydrate() => view.hydrate(
      status: (_, _) async {
        statusCalls++;
        return receipt;
      },
      finishAccepted: (guid) async => finished.add(guid),
    );
    await hydrate();
    expect(view.isSuppressed('chat'), isTrue);
    receipt = RecoverableDeleteReceiptState.succeeded;
    await hydrate();

    expect(statusCalls, 2);
    expect(finished, ['chat']);
    expect(view.isSuppressed('chat'), isFalse);
    expect(identical(view, repository.viewForServer('A')), isTrue);
  });
}
