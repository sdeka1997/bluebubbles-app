import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:bluebubbles/services/backend/settings/actions/shared_preferences_database_actions.dart';
import 'package:bluebubbles/services/backend/settings/shared_preferences_service.dart';
import 'package:bluebubbles/services/backend/sync/recoverable_delete_journal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

base class ControllablePreferencesPlatform extends InMemorySharedPreferencesAsync {
  ControllablePreferencesPlatform() : super.empty();

  bool failNextStringWrite = false;

  @override
  Future<bool> setString(String key, String value, SharedPreferencesOptions options) async {
    if (failNextStringWrite) {
      failNextStringWrite = false;
      throw StateError('injected platform write failure');
    }
    return super.setString(key, value, options);
  }
}

Future<SharedPreferencesDatabaseActions> realActions() async {
  final service = SharedPreferencesService();
  service.i = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
  return SharedPreferencesDatabaseActions(service);
}

class DelayedStore implements RecoverableDeleteJournalStore {
  DelayedStore(this.inner);

  final RecoverableDeleteJournalStore inner;
  final entered = Completer<void>();
  final release = Completer<void>();
  bool _delayFirst = true;

  @override
  String? read() => inner.read();

  @override
  Future<void> write(String value) async {
    if (_delayFirst) {
      _delayFirst = false;
      entered.complete();
      await release.future;
    }
    await inner.write(value);
  }
}

class RawStore implements RecoverableDeleteJournalStore {
  RawStore(this.value);
  String? value;
  int writes = 0;

  @override
  String? read() => value;

  @override
  Future<void> write(String value) async {
    writes++;
    this.value = value;
  }
}

String opaque(String value) => sha256.convert(utf8.encode(value)).toString();

Map<String, Object> entryJson(String server, String chat, String attempt, String phase, int startedAt) =>
    <String, Object>{
      'serverIdentity': server,
      'chatGuid': chat,
      'attemptId': attempt,
      'startedAt': startedAt,
      'phase': phase,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('submitted claim survives construction and hydration of a new repository', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final firstActions = await realActions();
    final first = RecoverableDeleteJournal.testing(SharedPreferencesDeleteJournalStore(firstActions));
    await first.hydrate();

    await first.recordSubmitted(
      serverIdentity: 'https://server.example',
      chatGuid: 'iMessage;-;+15551234567',
      attemptId: 'abcdefghijklmnop',
      startedAt: DateTime.fromMillisecondsSinceEpoch(1234),
    );

    final restarted = RecoverableDeleteJournal.testing(SharedPreferencesDeleteJournalStore(await realActions()));
    await restarted.hydrate();

    expect(
      restarted.lookup('https://server.example', 'iMessage;-;+15551234567'),
      isA<RecoverableDeleteJournalEntry>()
          .having((entry) => entry.attemptId, 'attemptId', 'abcdefghijklmnop')
          .having((entry) => entry.phase, 'phase', RecoverableDeleteJournalPhase.submitted),
    );
  });

  test('platform write failure leaves state unpublished and does not poison the queue', () async {
    final platform = ControllablePreferencesPlatform();
    SharedPreferencesAsyncPlatform.instance = platform;
    final journal = RecoverableDeleteJournal.testing(SharedPreferencesDeleteJournalStore(await realActions()));
    await journal.hydrate();

    platform.failNextStringWrite = true;
    await expectLater(
      journal.recordSubmitted(
        serverIdentity: 'server-a',
        chatGuid: 'chat-a',
        attemptId: 'aaaaaaaaaaaaaaaa',
        startedAt: DateTime.fromMillisecondsSinceEpoch(1),
      ),
      throwsA(isA<StateError>()),
    );
    expect(journal.lookup('server-a', 'chat-a'), isNull);

    await journal.recordSubmitted(
      serverIdentity: 'server-a',
      chatGuid: 'chat-b',
      attemptId: 'bbbbbbbbbbbbbbbb',
      startedAt: DateTime.fromMillisecondsSinceEpoch(2),
    );
    expect(journal.lookup('server-a', 'chat-b')?.attemptId, 'bbbbbbbbbbbbbbbb');
  });

  test('delayed cross-server writes preserve both buckets', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final actions = await realActions();
    final store = DelayedStore(SharedPreferencesDeleteJournalStore(actions));
    final journal = RecoverableDeleteJournal.testing(store);
    await journal.hydrate();

    final first = journal.recordSubmitted(
      serverIdentity: 'server-a',
      chatGuid: 'chat-a',
      attemptId: 'aaaaaaaaaaaaaaaa',
      startedAt: DateTime.fromMillisecondsSinceEpoch(1),
    );
    await store.entered.future;
    final second = journal.recordSubmitted(
      serverIdentity: 'server-b',
      chatGuid: 'chat-b',
      attemptId: 'bbbbbbbbbbbbbbbb',
      startedAt: DateTime.fromMillisecondsSinceEpoch(2),
    );
    store.release.complete();
    await Future.wait(<Future<void>>[first, second]);

    final restarted = RecoverableDeleteJournal.testing(SharedPreferencesDeleteJournalStore(await realActions()));
    await restarted.hydrate();
    expect(restarted.lookup('server-a', 'chat-a'), isNotNull);
    expect(restarted.lookup('server-b', 'chat-b'), isNotNull);
  });

  test('accepted and clear are compare-and-set against attempt id', () async {
    final store = RawStore(null);
    final journal = RecoverableDeleteJournal.testing(store);
    await journal.hydrate();
    await journal.recordSubmitted(
      serverIdentity: 'server',
      chatGuid: 'chat',
      attemptId: 'aaaaaaaaaaaaaaaa',
      startedAt: DateTime.fromMillisecondsSinceEpoch(1),
    );

    expect(await journal.recordAccepted('server', 'chat', 'bbbbbbbbbbbbbbbb'), isFalse);
    expect(journal.lookup('server', 'chat')?.phase, RecoverableDeleteJournalPhase.submitted);
    expect(await journal.clear('server', 'chat', 'bbbbbbbbbbbbbbbb'), isFalse);
    expect(journal.lookup('server', 'chat'), isNotNull);
    expect(await journal.recordAccepted('server', 'chat', 'aaaaaaaaaaaaaaaa'), isTrue);
    expect(journal.lookup('server', 'chat')?.phase, RecoverableDeleteJournalPhase.accepted);
    expect(await journal.clear('server', 'chat', 'aaaaaaaaaaaaaaaa'), isTrue);
    expect(journal.lookup('server', 'chat'), isNull);
  });

  test('old entries never expire and server views are stable and cheap', () async {
    final journal = RecoverableDeleteJournal.testing(RawStore(null));
    await journal.hydrate();
    await journal.recordSubmitted(
      serverIdentity: 'server',
      chatGuid: 'chat',
      attemptId: 'aaaaaaaaaaaaaaaa',
      startedAt: DateTime.now().subtract(const Duration(days: 900)),
    );

    final firstView = journal.forServer('server');
    expect(identical(firstView, journal.forServer('server')), isTrue);
    expect(firstView.isSuppressed('chat'), isTrue);
    expect(firstView.listUnresolved(), hasLength(1));
    expect(journal.isSuppressed('server', 'chat'), isTrue);
  });

  test('valid entries survive adjacent malformed entries and malformed ids stay quarantined', () async {
    const server = 'server';
    const validChat = 'valid-chat';
    const badChat = 'bad-chat';
    final store = RawStore(
      jsonEncode(<String, Object>{
        'version': 1,
        'servers': <String, Object>{
          opaque(server): <String, Object>{
            opaque(validChat): entryJson(server, validChat, 'aaaaaaaaaaaaaaaa', 'submitted', 1),
            opaque(badChat): entryJson(server, badChat, 'not valid!', 'submitted', 2),
            opaque('bad-shape'): entryJson(server, 'bad-shape', 'bbbbbbbbbbbbbbbb', 'submitted', 999999999999999999),
          },
        },
      }),
    );
    final journal = RecoverableDeleteJournal.testing(store);
    await journal.hydrate();

    expect(journal.state, RecoverableDeleteJournalState.ready);
    expect(journal.lookup(server, validChat), isNotNull);
    expect(journal.lookup(server, badChat), isNull);
    expect(journal.listUnresolved(), hasLength(1));
    expect(store.writes, 0);
  });

  test('corrupt whole document degrades without wiping persistence', () async {
    final store = RawStore('{not json');
    final journal = RecoverableDeleteJournal.testing(store);
    await journal.hydrate();

    expect(journal.state, RecoverableDeleteJournalState.degraded);
    expect(store.value, '{not json');
    expect(store.writes, 0);
    expect(
      () => journal.recordSubmitted(
        serverIdentity: 'server',
        chatGuid: 'chat',
        attemptId: 'aaaaaaaaaaaaaaaa',
        startedAt: DateTime.fromMillisecondsSinceEpoch(1),
      ),
      throwsStateError,
    );
  });

  test('serialized keys are opaque while raw guid remains recovery data', () async {
    const server = 'https://literal-server.example';
    const chat = 'iMessage;-;literal-guid';
    final store = RawStore(null);
    final journal = RecoverableDeleteJournal.testing(store);
    await journal.hydrate();
    await journal.recordSubmitted(
      serverIdentity: server,
      chatGuid: chat,
      attemptId: 'aaaaaaaaaaaaaaaa',
      startedAt: DateTime.fromMillisecondsSinceEpoch(1),
    );

    final decoded = jsonDecode(store.value!) as Map<String, dynamic>;
    final servers = decoded['servers'] as Map<String, dynamic>;
    expect(servers.keys, isNot(contains(server)));
    final chats = servers.values.single as Map<String, dynamic>;
    expect(chats.keys, isNot(contains(chat)));
    expect(store.value, contains(chat));
  });

  test('same chat shares a serial lock while different chats are independent', () async {
    final journal = RecoverableDeleteJournal.testing(RawStore(null));
    final sameA = journal.chatLock('server', 'chat');
    final sameB = journal.chatLock('server', 'chat');
    final other = journal.chatLock('server', 'other');
    expect(identical(sameA, sameB), isTrue);

    final held = Completer<void>();
    final release = Completer<void>();
    final first = sameA.synchronized(() async {
      held.complete();
      await release.future;
    });
    await held.future;
    var sameEntered = false;
    final waiting = sameB.synchronized(() async => sameEntered = true);
    var otherEntered = false;
    await other.synchronized(() async => otherEntered = true);
    expect(otherEntered, isTrue);
    expect(sameEntered, isFalse);
    release.complete();
    await Future.wait(<Future<void>>[first, waiting]);
    expect(sameEntered, isTrue);
  });
}
