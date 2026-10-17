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

    expect(deleted, isTrue);
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

    expect(deleted, isFalse);
    expect(coordinator.isSuppressed('chat-a'), isFalse);
    expect((await _journal(storage, 'https://first').load(now: now)).entries, isEmpty);
  });

  test('ambiguous submit failure keeps submitted state without retrying', () async {
    final storage = _MemoryStorage();
    final journal = _journal(storage, 'https://first');
    final coordinator = RecoverableDeleteCoordinator(journal);
    var postCount = 0;

    await expectLater(
      coordinator.delete(
        'chat-a',
        now: now,
        submit: () async {
          postCount++;
          throw StateError('response lost');
        },
        localDelete: () async => fail('must not delete locally'),
        pendingChanged: (_) {},
        isDefinitiveFailure: (_) => false,
      ),
      throwsStateError,
    );

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
}
