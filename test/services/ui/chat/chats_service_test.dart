import 'dart:async';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/filesystem/filesystem_service.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:get_it/get_it.dart';
import 'package:universal_io/io.dart';
import 'package:bluebubbles/services/backend/sync/recoverable_delete_journal.dart';
import 'package:bluebubbles/services/ui/chat/chats_service.dart';
import 'package:bluebubbles/services/network/api/recoverable_delete_receipt.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingChat extends Chat {
  _RecordingChat() : super(id: 1, guid: 'test-chat', hasUnreadMessage: false);

  int toggleCallCount = 0;
  bool? recordedHasUnread;
  bool? recordedForce;
  bool? recordedClearLocalNotifications;
  bool? recordedPrivateMark;

  @override
  Future<Chat> toggleHasUnreadAsync(
    bool hasUnread, {
    bool force = false,
    bool clearLocalNotifications = true,
    bool privateMark = true,
  }) async {
    toggleCallCount++;
    recordedHasUnread = hasUnread;
    recordedForce = force;
    recordedClearLocalNotifications = clearLocalNotifications;
    recordedPrivateMark = privateMark;
    return this;
  }
}

class _MemoryStore implements RecoverableDeleteJournalStore {
  _MemoryStore({this.failOnWrite, this.onWrite});

  String? raw;
  bool failWrites = false;
  final int? failOnWrite;
  int writeCount = 0;
  final void Function(String value)? onWrite;
  @override
  String? read() => raw;
  @override
  Future<void> write(String value) async {
    writeCount++;
    onWrite?.call(value);
    if (failWrites || writeCount == failOnWrite) throw StateError('write failed');
    raw = value;
  }
}

Chat _chat(String guid) => Chat(id: guid.hashCode, guid: guid, hasUnreadMessage: false);

Future<void> _claim(
  RecoverableDeleteJournal journal,
  String guid,
  String attemptId, {
  RecoverableDeleteJournalPhase phase = RecoverableDeleteJournalPhase.submitted,
}) async {
  await journal.recordSubmitted(
    serverIdentity: 'server-a',
    chatGuid: guid,
    attemptId: attemptId,
    startedAt: DateTime.utc(2026, 1, 1),
  );
  if (phase == RecoverableDeleteJournalPhase.accepted) {
    await journal.recordAccepted('server-a', guid, attemptId);
  }
}

RecoverableDeleteReceiptResult _receipt(RecoverableDeleteReceiptState state, String attemptId) =>
    RecoverableDeleteReceiptResult(
      RecoverableDeleteReceipt(
        attemptId: attemptId,
        state: state,
        failureCode: state == RecoverableDeleteReceiptState.definitiveFailure ? 'failed' : null,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );

void main() {
  setUpAll(() {
    final filesystem = FilesystemService()..appDocDir = Directory.systemTemp;
    GetIt.I.registerSingleton<FilesystemService>(filesystem);
    GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = Settings());
  });

  tearDownAll(GetIt.I.reset);

  group('shouldApplyServerUnreadUpdate', () {
    const cases = <({bool localUnread, bool serverUnread, bool shouldApply})>[
      (localUnread: false, serverUnread: false, shouldApply: true),
      (localUnread: false, serverUnread: true, shouldApply: true),
      (localUnread: true, serverUnread: false, shouldApply: true),
      (localUnread: true, serverUnread: true, shouldApply: false),
    ];

    for (final testCase in cases) {
      test('local unread ${testCase.localUnread}, server unread ${testCase.serverUnread} '
          '${testCase.shouldApply ? 'applies' : 'short-circuits'}', () {
        expect(
          shouldApplyServerUnreadUpdate(localUnread: testCase.localUnread, serverUnread: testCase.serverUnread),
          testCase.shouldApply,
        );
      });
    }
  });

  test('a server read forces local persistence and notification cleanup without a private mark', () async {
    final chat = _RecordingChat();

    await ChatsService().setChatHasUnreadFromServer(chat, false);

    expect(chat.toggleCallCount, 1);
    expect(chat.recordedHasUnread, isFalse);
    expect(chat.recordedForce, isTrue);
    expect(chat.recordedClearLocalNotifications, isTrue);
    expect(chat.recordedPrivateMark, isFalse);
  });

  group('recoverable delete suppression', () {
    test('addChat drops a hydrated current-server claim but admits unrelated chats', () async {
      final store = _MemoryStore();
      final journal = RecoverableDeleteJournal.testing(store);
      await journal.hydrate();
      await journal.recordSubmitted(
        serverIdentity: 'server-a',
        chatGuid: 'claimed',
        attemptId: 'AAAAAAAAAAAAAAAA',
        startedAt: DateTime.utc(2026, 1, 1),
      );
      final service = ChatsService(journal: journal, configuredServerIdentity: () => 'server-a');

      await service.addChat(_chat('claimed'), immediate: true);
      await service.addChat(_chat('other'), immediate: true);

      expect(service.chatStates.keys, contains('other'));
      expect(service.chatStates.keys, isNot(contains('claimed')));
      expect(service.allChats.map((c) => c.guid), ['other']);
    });

    test('init hydrates before first ingestion and loads unclaimed chats', () async {
      final store = _MemoryStore();
      final preparation = RecoverableDeleteJournal.testing(store);
      await preparation.hydrate();
      await preparation.recordSubmitted(
        serverIdentity: 'server-a',
        chatGuid: 'claimed',
        attemptId: 'AAAAAAAAAAAAAAAA',
        startedAt: DateTime.utc(2026, 1, 1),
      );
      final journal = RecoverableDeleteJournal.testing(store);
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        initialActiveChatsLoader: () async => [_chat('claimed'), _chat('other')],
        localChatLookup: (_) => null,
        getRecoverableDelete: (_) async => const RecoverableDeleteAttemptAmbiguous(),
        noticeSink: (_, _, _) {},
      );

      await service.init(force: true);

      expect(journal.state, RecoverableDeleteJournalState.ready);
      expect(service.chatStates.keys, ['other']);
      expect(service.allChats.map((c) => c.guid), ['other']);
    });

    test('recordSubmitted persistence failure keeps a visible chat and sends nothing', () async {
      final store = _MemoryStore();
      final journal = RecoverableDeleteJournal.testing(store);
      await journal.hydrate();
      var submits = 0;
      final notices = <String>[];
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        attemptIdGenerator: () => 'BBBBBBBBBBBBBBBB',
        submitRecoverableDelete: ({required chatGuid, required attemptId}) async {
          submits++;
          return const RecoverableDeleteAttemptAmbiguous();
        },
        noticeSink: (title, message, type) => notices.add('$title|$message|${type.name}'),
      );
      final chat = _chat('visible');
      await service.addChat(chat, immediate: true);
      store.failWrites = true;

      final result = await service.recoverablyDeleteChat(chat);

      expect(result, isFalse);
      expect(submits, 0);
      expect(service.chatStates, contains('visible'));
      expect(service.allChats.map((c) => c.guid), ['visible']);
      expect(notices, hasLength(1));
      expect(notices.single, contains('Conversation not deleted'));
    });

    test('durable submission removes both live collections before POST completes', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      final submitted = Completer<RecoverableDeleteAttemptResult>();
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        attemptIdGenerator: () => 'CCCCCCCCCCCCCCCC',
        submitRecoverableDelete: ({required chatGuid, required attemptId}) => submitted.future,
        noticeSink: (_, _, _) {},
      );
      final chat = _chat('visible');
      await service.addChat(chat, immediate: true);
      final version = service.chatListVersion.value;

      final deletion = service.recoverablyDeleteChat(chat);
      await Future<void>.delayed(Duration.zero);

      expect(service.chatStates, isNot(contains('visible')));
      expect(service.allChats, isEmpty);
      expect(service.chatListVersion.value, greaterThan(version));
      submitted.complete(_receipt(RecoverableDeleteReceiptState.pending, 'CCCCCCCCCCCCCCCC'));
      expect(await deletion, isTrue);
    });

    test('success orders durable phases around submit and local soft delete', () async {
      final events = <String>[];
      var writes = 0;
      final store = _MemoryStore(onWrite: (_) => events.add(['submitted', 'accepted', 'clear'][writes++]));
      final journal = RecoverableDeleteJournal.testing(store);
      await journal.hydrate();
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        attemptIdGenerator: () => 'DDDDDDDDDDDDDDDD',
        submitRecoverableDelete: ({required chatGuid, required attemptId}) async {
          events.add('submit:$attemptId');
          return _receipt(RecoverableDeleteReceiptState.succeeded, attemptId);
        },
        localSoftDelete: (chat) async => events.add('local:${chat.guid}'),
        noticeSink: (_, _, _) {},
      );
      final chat = _chat('success');
      await service.addChat(chat);

      expect(await service.recoverablyDeleteChat(chat), isTrue);

      expect(events, ['submitted', 'submit:DDDDDDDDDDDDDDDD', 'accepted', 'local:success', 'clear']);
      expect(journal.lookup('server-a', 'success'), isNull);
    });

    for (final testCase
        in <({String name, RecoverableDeleteAttemptResult result, bool expected, bool restored, String notice})>[
          (
            name: 'pending',
            result: _receipt(RecoverableDeleteReceiptState.pending, 'EEEEEEEEEEEEEEEE'),
            expected: true,
            restored: false,
            notice: 'Deletion is being confirmed',
          ),
          (
            name: 'definitive failure',
            result: _receipt(RecoverableDeleteReceiptState.definitiveFailure, 'EEEEEEEEEEEEEEEE'),
            expected: false,
            restored: true,
            notice: 'Conversation not deleted',
          ),
          (
            name: 'rejected without dispatch',
            result: const RecoverableDeleteSubmitRejectedNoDispatch(),
            expected: false,
            restored: true,
            notice: 'Conversation not deleted',
          ),
        ]) {
      test('${testCase.name} has the expected result, visibility, claim and one notice', () async {
        final journal = RecoverableDeleteJournal.testing(_MemoryStore());
        await journal.hydrate();
        final notices = <String>[];
        final service = ChatsService(
          journal: journal,
          configuredServerIdentity: () => 'server-a',
          attemptIdGenerator: () => 'EEEEEEEEEEEEEEEE',
          submitRecoverableDelete: ({required chatGuid, required attemptId}) async => testCase.result,
          noticeSink: (title, _, _) => notices.add(title),
        );
        final chat = _chat('case-chat');
        await service.addChat(chat);

        expect(await service.recoverablyDeleteChat(chat), testCase.expected);

        expect(service.chatStates.containsKey(chat.guid), testCase.restored);
        expect(service.allChats.any((item) => item.guid == chat.guid), testCase.restored);
        expect(journal.lookup('server-a', chat.guid) != null, !testCase.restored);
        expect(notices, [testCase.notice]);
      });
    }

    test('ambiguous submit performs GET with the same ID and reports pending once', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      final calls = <String>[];
      final notices = <String>[];
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        attemptIdGenerator: () => 'FFFFFFFFFFFFFFFF',
        submitRecoverableDelete: ({required chatGuid, required attemptId}) async {
          calls.add('submit:$attemptId');
          return const RecoverableDeleteAttemptAmbiguous();
        },
        getRecoverableDelete: (attemptId) async {
          calls.add('get:$attemptId');
          return _receipt(RecoverableDeleteReceiptState.pending, attemptId);
        },
        noticeSink: (title, _, _) => notices.add(title),
      );
      final chat = _chat('ambiguous');
      await service.addChat(chat);

      expect(await service.recoverablyDeleteChat(chat), isTrue);
      expect(calls, ['submit:FFFFFFFFFFFFFFFF', 'get:FFFFFFFFFFFFFFFF']);
      expect(service.chatStates, isNot(contains(chat.guid)));
      expect(notices, ['Deletion is being confirmed']);
    });

    test('GET 404 resubmits the same ID once and a second unknown stays pending', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      final calls = <String>[];
      var submitCount = 0;
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        attemptIdGenerator: () => 'GGGGGGGGGGGGGGGG',
        submitRecoverableDelete: ({required chatGuid, required attemptId}) async {
          calls.add('submit:$attemptId');
          submitCount++;
          return const RecoverableDeleteAttemptAmbiguous();
        },
        getRecoverableDelete: (attemptId) async {
          calls.add('get:$attemptId');
          return const RecoverableDeleteAttemptNotRecorded();
        },
        noticeSink: (_, _, _) {},
      );
      final chat = _chat('unknown');
      await service.addChat(chat);

      expect(await service.recoverablyDeleteChat(chat), isTrue);
      expect(submitCount, 2);
      expect(calls, [
        'submit:GGGGGGGGGGGGGGGG',
        'get:GGGGGGGGGGGGGGGG',
        'submit:GGGGGGGGGGGGGGGG',
        'get:GGGGGGGGGGGGGGGG',
      ]);
      expect(journal.lookup('server-a', chat.guid)?.attemptId, 'GGGGGGGGGGGGGGGG');
    });

    for (final failure in <({String name, int? failOnWrite, bool localFails, RecoverableDeleteJournalPhase phase})>[
      (name: 'accepted persistence', failOnWrite: 2, localFails: false, phase: RecoverableDeleteJournalPhase.submitted),
      (name: 'local soft delete', failOnWrite: null, localFails: true, phase: RecoverableDeleteJournalPhase.accepted),
      (name: 'clear persistence', failOnWrite: 3, localFails: false, phase: RecoverableDeleteJournalPhase.accepted),
    ]) {
      test('${failure.name} failure retains the safe claim and never restores', () async {
        final journal = RecoverableDeleteJournal.testing(_MemoryStore(failOnWrite: failure.failOnWrite));
        await journal.hydrate();
        final service = ChatsService(
          journal: journal,
          configuredServerIdentity: () => 'server-a',
          attemptIdGenerator: () => 'HHHHHHHHHHHHHHHH',
          submitRecoverableDelete: ({required chatGuid, required attemptId}) async =>
              _receipt(RecoverableDeleteReceiptState.succeeded, attemptId),
          localSoftDelete: (_) async {
            if (failure.localFails) throw StateError('local failed');
          },
          noticeSink: (_, _, _) {},
        );
        final chat = _chat('failure-chat');
        await service.addChat(chat);

        expect(await service.recoverablyDeleteChat(chat), isTrue);

        expect(journal.lookup('server-a', chat.guid)?.phase, failure.phase);
        expect(service.chatStates, isNot(contains(chat.guid)));
        expect(service.allChats, isEmpty);
      });
    }

    test('recovery completes an accepted claim locally and clears it', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      await _claim(journal, 'accepted-recovery', 'IIIIIIIIIIIIIIII', phase: RecoverableDeleteJournalPhase.accepted);
      final deleted = <String>[];
      final chat = _chat('accepted-recovery');
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        localChatLookup: (_) => chat,
        localSoftDelete: (value) async => deleted.add(value.guid),
        noticeSink: (_, _, _) {},
      );

      await service.recoverPendingDeletes();

      expect(deleted, ['accepted-recovery']);
      expect(journal.lookup('server-a', chat.guid), isNull);
    });

    test('recovery GET success accepts, deletes locally, and clears without POST', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      await _claim(journal, 'submitted-success', 'JJJJJJJJJJJJJJJJ');
      var submits = 0;
      var deletes = 0;
      final chat = _chat('submitted-success');
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        localChatLookup: (_) => chat,
        getRecoverableDelete: (id) async => _receipt(RecoverableDeleteReceiptState.succeeded, id),
        submitRecoverableDelete: ({required chatGuid, required attemptId}) async {
          submits++;
          return const RecoverableDeleteAttemptAmbiguous();
        },
        localSoftDelete: (_) async => deletes++,
        noticeSink: (_, _, _) {},
      );

      await service.recoverPendingDeletes();

      expect(submits, 0);
      expect(deletes, 1);
      expect(journal.lookup('server-a', chat.guid), isNull);
    });

    test('recovery definitive failure clears and restores through addChat', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      await _claim(journal, 'restore-recovery', 'KKKKKKKKKKKKKKKK');
      final chat = _chat('restore-recovery');
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        localChatLookup: (_) => chat,
        getRecoverableDelete: (id) async => _receipt(RecoverableDeleteReceiptState.definitiveFailure, id),
        noticeSink: (_, _, _) {},
      );

      await service.recoverPendingDeletes();

      expect(journal.lookup('server-a', chat.guid), isNull);
      expect(service.chatStates, contains(chat.guid));
      expect(service.allChats.map((item) => item.guid), [chat.guid]);
    });

    test('recovery pending and GET error retain claims without POST', () async {
      for (final result in <RecoverableDeleteAttemptResult>[
        _receipt(RecoverableDeleteReceiptState.pending, 'LLLLLLLLLLLLLLLL'),
        const RecoverableDeleteAttemptAmbiguous(),
      ]) {
        final journal = RecoverableDeleteJournal.testing(_MemoryStore());
        await journal.hydrate();
        await _claim(journal, 'retain-recovery', 'LLLLLLLLLLLLLLLL');
        var submits = 0;
        final service = ChatsService(
          journal: journal,
          configuredServerIdentity: () => 'server-a',
          getRecoverableDelete: (_) async => result,
          submitRecoverableDelete: ({required chatGuid, required attemptId}) async {
            submits++;
            return const RecoverableDeleteAttemptAmbiguous();
          },
          localChatLookup: (_) => _chat('retain-recovery'),
          noticeSink: (_, _, _) {},
        );

        await service.recoverPendingDeletes();

        expect(submits, 0);
        expect(journal.lookup('server-a', 'retain-recovery'), isNotNull);
      }
    });

    test('recovery GET 404 resubmits the same ID once', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      await _claim(journal, 'resubmit-recovery', 'MMMMMMMMMMMMMMMM');
      final submits = <String>[];
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        localChatLookup: (_) => null,
        getRecoverableDelete: (_) async => const RecoverableDeleteAttemptNotRecorded(),
        submitRecoverableDelete: ({required chatGuid, required attemptId}) async {
          submits.add('$chatGuid:$attemptId');
          return _receipt(RecoverableDeleteReceiptState.pending, attemptId);
        },
        noticeSink: (_, _, _) {},
      );

      await service.recoverPendingDeletes();

      expect(submits, ['resubmit-recovery:MMMMMMMMMMMMMMMM']);
      expect(journal.lookup('server-a', 'resubmit-recovery'), isNotNull);
    });

    test('one recovery entry failure does not block the next entry', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      await _claim(journal, 'bad-entry', 'NNNNNNNNNNNNNNNN', phase: RecoverableDeleteJournalPhase.accepted);
      await _claim(journal, 'good-entry', 'OOOOOOOOOOOOOOOO', phase: RecoverableDeleteJournalPhase.accepted);
      final deleted = <String>[];
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        localChatLookup: _chat,
        localSoftDelete: (chat) async {
          if (chat.guid == 'bad-entry') throw StateError('bad local row');
          deleted.add(chat.guid);
        },
        noticeSink: (_, _, _) {},
      );

      await service.recoverPendingDeletes();

      expect(journal.lookup('server-a', 'bad-entry'), isNotNull);
      expect(journal.lookup('server-a', 'good-entry'), isNull);
      expect(deleted, ['good-entry']);
    });

    test('concurrent recovery calls collapse and do not duplicate POST', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      await _claim(journal, 'concurrent', 'PPPPPPPPPPPPPPPP');
      final submitResult = Completer<RecoverableDeleteAttemptResult>();
      var submits = 0;
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        localChatLookup: (_) => null,
        getRecoverableDelete: (_) async => const RecoverableDeleteAttemptNotRecorded(),
        submitRecoverableDelete: ({required chatGuid, required attemptId}) {
          submits++;
          return submitResult.future;
        },
        noticeSink: (_, _, _) {},
      );

      final first = service.recoverPendingDeletes();
      final second = service.recoverPendingDeletes();
      await Future<void>.delayed(Duration.zero);
      expect(submits, 1);
      submitResult.complete(_receipt(RecoverableDeleteReceiptState.pending, 'PPPPPPPPPPPPPPPP'));
      await Future.wait([first, second]);
      expect(submits, 1);
    });

    test('degraded journal fails open for load and open but disables delete and recovery', () async {
      final store = _MemoryStore()..raw = '{malformed';
      final journal = RecoverableDeleteJournal.testing(store);
      var submits = 0;
      var gets = 0;
      final notices = <String>[];
      final chat = _chat('degraded');
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        initialActiveChatsLoader: () async => [chat],
        submitRecoverableDelete: ({required chatGuid, required attemptId}) async {
          submits++;
          return const RecoverableDeleteAttemptAmbiguous();
        },
        getRecoverableDelete: (_) async {
          gets++;
          return const RecoverableDeleteAttemptAmbiguous();
        },
        noticeSink: (title, _, _) => notices.add(title),
      );

      await service.init(force: true);
      await service.addChat(chat);
      await service.recoverPendingDeletes();

      expect(journal.state, RecoverableDeleteJournalState.degraded);
      expect(service.chatStates, contains(chat.guid));
      expect(service.canOpenChat(chat.guid), isTrue);
      expect(await service.recoverablyDeleteChat(chat), isFalse);
      expect(submits, 0);
      expect(gets, 0);
      expect(notices, ['Conversation not deleted']);
    });

    test('an existing claim is suppressed with one neutral notice and no new operation', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      await _claim(journal, 'existing', 'QQQQQQQQQQQQQQQQ');
      var minted = 0;
      var submits = 0;
      var gets = 0;
      final notices = <String>[];
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        attemptIdGenerator: () {
          minted++;
          return 'RRRRRRRRRRRRRRRR';
        },
        submitRecoverableDelete: ({required chatGuid, required attemptId}) async {
          submits++;
          return const RecoverableDeleteAttemptAmbiguous();
        },
        getRecoverableDelete: (_) async {
          gets++;
          return const RecoverableDeleteAttemptAmbiguous();
        },
        noticeSink: (title, _, _) => notices.add(title),
      );
      final chat = _chat('existing');

      expect(await service.recoverablyDeleteChat(chat), isTrue);

      expect(minted, 0);
      expect(submits, 0);
      expect(gets, 0);
      expect(notices, ['Deletion is being confirmed']);
      expect(journal.lookup('server-a', chat.guid)?.attemptId, 'QQQQQQQQQQQQQQQQ');
    });

    test('concurrent init shares hydration, loader, locks, and recovery work', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      await _claim(journal, 'init-concurrent', 'SSSSSSSSSSSSSSSS');
      final lookupResult = Completer<RecoverableDeleteAttemptResult>();
      var loads = 0;
      var gets = 0;
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        initialActiveChatsLoader: () async {
          loads++;
          return [_chat('init-concurrent'), _chat('other-init')];
        },
        localChatLookup: (_) => null,
        getRecoverableDelete: (_) {
          gets++;
          return lookupResult.future;
        },
        noticeSink: (_, _, _) {},
      );

      final first = service.init(force: true);
      final second = service.init(force: true);
      await Future<void>.delayed(Duration.zero);
      expect(loads, 1);
      expect(gets, 1);
      lookupResult.complete(_receipt(RecoverableDeleteReceiptState.pending, 'SSSSSSSSSSSSSSSS'));
      await Future.wait([first, second]);

      expect(loads, 1);
      expect(gets, 1);
      expect(service.chatStates.keys, ['other-init']);
    });

    test('suppression-aware init still rebinds an unclaimed active chat', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        initialActiveChatsLoader: () async => [_chat('active-init')],
        noticeSink: (_, _, _) {},
      );
      service.activeChatGuid.value = 'active-init';

      await service.init(force: true);

      expect(service.activeChat?.chat.guid, 'active-init');
      expect(service.activeChat?.isActive.value, isTrue);
      expect(service.activeChat?.isAlive.value, isTrue);
    });

    test('sequential re-init reuses the journal and can complete twice', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      var loads = 0;
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        initialActiveChatsLoader: () async {
          loads++;
          return <Chat>[];
        },
        noticeSink: (_, _, _) {},
      );

      await service.init(force: true);
      await service.init(force: true);

      expect(loads, 2);
      expect(journal.state, RecoverableDeleteJournalState.ready);
    });
  });
}
