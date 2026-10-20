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

/// Its restore insert fails after the claim was cleared.
class _UnrestorableChat extends Chat {
  _UnrestorableChat(String guid) : super(id: guid.hashCode, guid: guid, hasUnreadMessage: false);

  @override
  bool? get isPinned => throw StateError('restore failed');
}

Chat _chat(String guid) => Chat(id: guid.hashCode, guid: guid, hasUnreadMessage: false);

Future<void> _claim(
  RecoverableDeleteJournal journal,
  String guid,
  String attemptId, {
  RecoverableDeleteJournalPhase phase = RecoverableDeleteJournalPhase.submitted,
  String serverIdentity = 'server-a',
}) async {
  await journal.recordSubmitted(
    serverIdentity: serverIdentity,
    chatGuid: guid,
    attemptId: attemptId,
    startedAt: DateTime.utc(2026, 1, 1),
  );
  if (phase == RecoverableDeleteJournalPhase.accepted) {
    await journal.recordAccepted(serverIdentity, guid, attemptId);
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
        final chat = _chat('case-chat');
        final service = ChatsService(
          journal: journal,
          configuredServerIdentity: () => 'server-a',
          attemptIdGenerator: () => 'EEEEEEEEEEEEEEEE',
          submitRecoverableDelete: ({required chatGuid, required attemptId}) async => testCase.result,
          localChatLookup: (_) => chat,
          noticeSink: (title, _, _) => notices.add(title),
        );
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

    test('a different-server recovery runs its own pass after a blocked prior pass', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      await _claim(journal, 'server-a-chat', 'UUUUUUUUUUUUUUUU', phase: RecoverableDeleteJournalPhase.accepted);
      await _claim(
        journal,
        'server-b-chat',
        'VVVVVVVVVVVVVVVV',
        phase: RecoverableDeleteJournalPhase.accepted,
        serverIdentity: 'server-b',
      );
      var identity = 'server-a';
      final aDeleteEntered = Completer<void>();
      final releaseADelete = Completer<void>();
      final deleted = <String>[];
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => identity,
        localChatLookup: _chat,
        localSoftDelete: (chat) async {
          if (chat.guid == 'server-a-chat') {
            aDeleteEntered.complete();
            await releaseADelete.future;
          }
          deleted.add(chat.guid);
        },
        noticeSink: (_, _, _) {},
      );

      final recoveryA = service.recoverPendingDeletes();
      await aDeleteEntered.future;
      identity = 'server-b';
      final recoveryB = service.recoverPendingDeletes();
      releaseADelete.complete();
      await Future.wait([recoveryA, recoveryB]).timeout(const Duration(seconds: 5));

      expect(deleted, ['server-a-chat', 'server-b-chat']);
      expect(journal.lookup('server-b', 'server-b-chat'), isNull);
      expect(journal.lookup('server-a', 'server-a-chat')?.phase, RecoverableDeleteJournalPhase.accepted);
    });

    for (final path in ['user delete', 'recovery']) {
      for (final state in [RecoverableDeleteReceiptState.succeeded, RecoverableDeleteReceiptState.definitiveFailure]) {
        test('server switch before a $path ${state.name} result leaves the old claim and new list untouched', () async {
          final journal = RecoverableDeleteJournal.testing(_MemoryStore());
          await journal.hydrate();
          if (path == 'recovery') await _claim(journal, 'switch-row', 'WWWWWWWWWWWWWWWW');
          var identity = 'server-a';
          final network = Completer<RecoverableDeleteAttemptResult>();
          var deletes = 0;
          final chat = _chat('switch-row');
          final service = ChatsService(
            journal: journal,
            configuredServerIdentity: () => identity,
            attemptIdGenerator: () => 'WWWWWWWWWWWWWWWW',
            submitRecoverableDelete: ({required chatGuid, required attemptId}) => network.future,
            getRecoverableDelete: (_) => network.future,
            localChatLookup: (_) => chat,
            localSoftDelete: (_) async => deletes++,
            noticeSink: (_, _, _) {},
          );
          final Future<Object?> operation;
          if (path == 'user delete') {
            await service.addChat(chat);
            operation = service.recoverablyDeleteChat(chat);
          } else {
            operation = service.recoverPendingDeletes();
          }
          await Future<void>.delayed(Duration.zero);
          identity = 'server-b';
          final replacement = _chat('switch-row');
          await service.addChat(replacement, immediate: true);
          network.complete(_receipt(state, 'WWWWWWWWWWWWWWWW'));
          final result = await operation.timeout(const Duration(seconds: 5));

          if (path == 'user delete') expect(result, isTrue);
          expect(deletes, 0);
          expect(journal.lookup('server-a', 'switch-row')?.phase, RecoverableDeleteJournalPhase.submitted);
          expect(service.chatStates['switch-row']?.chat, same(replacement));
          expect(service.allChats.where((item) => item.guid == 'switch-row'), hasLength(1));
        });
      }
    }

    test('a different-server init runs after the in-flight init and owns the final state', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      await _claim(journal, 'a-claimed', 'XXXXXXXXXXXXXXXX');
      await _claim(journal, 'b-claimed', 'YYYYYYYYYYYYYYYY', serverIdentity: 'server-b');
      var identity = 'server-a';
      final firstLoadEntered = Completer<void>();
      final releaseFirstLoad = Completer<void>();
      var loads = 0;
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => identity,
        initialActiveChatsLoader: () async {
          loads++;
          if (loads == 1) {
            firstLoadEntered.complete();
            await releaseFirstLoad.future;
          }
          return [_chat('a-claimed'), _chat('b-claimed')];
        },
        localChatLookup: (_) => null,
        getRecoverableDelete: (_) async => const RecoverableDeleteAttemptAmbiguous(),
        noticeSink: (_, _, _) {},
      );

      final initA = service.init(force: true);
      await firstLoadEntered.future;
      identity = 'server-b';
      final initB = service.init(force: true);
      releaseFirstLoad.complete();
      await Future.wait([initA, initB]).timeout(const Duration(seconds: 5));

      expect(loads, 2);
      expect(service.loadedAllChats.isCompleted, isTrue);
      expect(service.loadedFirstChatBatch.value, isTrue);
      expect(service.chatStates.keys, ['a-claimed']);
      expect(service.isRecoverableDeleteSuppressed('b-claimed'), isTrue);
      expect(service.isRecoverableDeleteSuppressed('a-claimed'), isFalse);
    });

    test('init awaits the prior watcher cancellation before loading', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      final cancelEntered = Completer<void>();
      final releaseCancel = Completer<void>();
      var loads = 0;
      final controller = StreamController<void>(
        onCancel: () async {
          cancelEntered.complete();
          await releaseCancel.future;
        },
      );
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        initialActiveChatsLoader: () async {
          loads++;
          return <Chat>[];
        },
        noticeSink: (_, _, _) {},
      );
      service.countSub = controller.stream.listen((_) {});

      final initialization = service.init(force: true);
      await cancelEntered.future;
      await Future<void>.delayed(Duration.zero);
      expect(loads, 0);
      releaseCancel.complete();
      await initialization.timeout(const Duration(seconds: 5));

      expect(loads, 1);
      await controller.close();
    });

    for (final clearThrows in [false, true]) {
      test('claimed re-init clears a remembered active guid by guid (clear throws: $clearThrows)', () async {
        final journal = RecoverableDeleteJournal.testing(_MemoryStore());
        await journal.hydrate();
        await _claim(journal, 'remembered', 'ZZZZZZZZZZZZZZZZ', phase: RecoverableDeleteJournalPhase.accepted);
        var clears = 0;
        final deleted = <String>[];
        final service = ChatsService(
          journal: journal,
          configuredServerIdentity: () => 'server-a',
          initialActiveChatsLoader: () async => [_chat('remembered'), _chat('other')],
          localChatLookup: (_) => null,
          localSoftDelete: (chat) async => deleted.add(chat.guid),
          clearLastOpenedChat: () async {
            clears++;
            if (clearThrows) throw StateError('prefs failed');
          },
          noticeSink: (_, _, _) {},
        );
        service.activeChatGuid.value = 'remembered';

        await service.init(force: true).timeout(const Duration(seconds: 5));

        expect(service.chatStates.keys, ['other']);
        expect(service.pendingDeletes, isNot(contains('remembered')));
        expect(service.activeChatGuid.value, isNull);
        expect(service.activeChat, isNull);
        expect(clears, 1);
        expect(journal.lookup('server-a', 'remembered'), isNull);
      });
    }

    for (final path in ['user delete', 'recovery']) {
      for (final fresh in [true, false]) {
        test('$path definitive failure restores ${fresh ? 'only the fresh live row' : 'nothing for an absent row'}', () async {
          final journal = RecoverableDeleteJournal.testing(_MemoryStore());
          await journal.hydrate();
          if (path == 'recovery') await _claim(journal, 'restore-row', 'abababababababab');
          final network = Completer<RecoverableDeleteAttemptResult>();
          final original = _chat('restore-row');
          final replacement = _chat('restore-row');
          var lookups = 0;
          final service = ChatsService(
            journal: journal,
            configuredServerIdentity: () => 'server-a',
            attemptIdGenerator: () => 'abababababababab',
            submitRecoverableDelete: ({required chatGuid, required attemptId}) => network.future,
            getRecoverableDelete: (_) => network.future,
            localChatLookup: (_) => lookups++ == 0 && path == 'recovery' ? original : (fresh ? replacement : null),
            noticeSink: (_, _, _) {},
          );
          final Future<Object?> operation;
          if (path == 'user delete') {
            await service.addChat(original);
            operation = service.recoverablyDeleteChat(original);
          } else {
            operation = service.recoverPendingDeletes();
          }
          await Future<void>.delayed(Duration.zero);
          // Fresh: the captured object went stale. Absent: the row is gone though the captured object looks live.
          if (fresh) original.dateDeleted = DateTime.utc(2026, 1, 2);
          network.complete(_receipt(RecoverableDeleteReceiptState.definitiveFailure, 'abababababababab'));
          final result = await operation.timeout(const Duration(seconds: 5));

          if (path == 'user delete') expect(result, isFalse);
          expect(journal.lookup('server-a', 'restore-row'), isNull);
          expect(service.pendingDeletes, isNot(contains('restore-row')));
          if (fresh) {
            expect(service.chatStates['restore-row']?.chat, same(replacement));
            expect(service.allChats.where((item) => item.guid == 'restore-row').single, same(replacement));
          } else {
            expect(service.chatStates, isNot(contains('restore-row')));
            expect(service.allChats, isEmpty);
          }
        });
      }
    }

    for (final scenario in <({String name, bool expected, bool claimed})>[
      (name: 'last-open clear throws after submitted', expected: true, claimed: true),
      (name: 'pending notice throws', expected: true, claimed: true),
      (name: 'submit callback throws', expected: true, claimed: true),
      (name: 'restore lookup throws', expected: true, claimed: true),
      (name: 'failure notice throws after restore', expected: false, claimed: false),
      (name: 'attempt id generation throws before the durable write', expected: false, claimed: false),
      (name: 'failure notice throws when the durable write fails', expected: false, claimed: false),
      (name: 'pending notice throws for an existing claim', expected: true, claimed: true),
    ]) {
      test('public delete returns ${scenario.expected} when ${scenario.name}', () async {
        final store = _MemoryStore();
        final journal = RecoverableDeleteJournal.testing(store);
        await journal.hydrate();
        final chat = _chat('boundary');
        final definitive = scenario.name.contains('restore');
        if (scenario.name.contains('existing claim')) await _claim(journal, chat.guid, 'cdcdcdcdcdcdcdcd');
        final service = ChatsService(
          journal: journal,
          configuredServerIdentity: () => 'server-a',
          attemptIdGenerator: () {
            if (scenario.name.startsWith('attempt id')) throw StateError('id failed');
            return 'cdcdcdcdcdcdcdcd';
          },
          submitRecoverableDelete: ({required chatGuid, required attemptId}) async {
            if (scenario.name.startsWith('submit')) throw StateError('submit failed');
            return _receipt(
              definitive ? RecoverableDeleteReceiptState.definitiveFailure : RecoverableDeleteReceiptState.pending,
              attemptId,
            );
          },
          getRecoverableDelete: (_) async => const RecoverableDeleteAttemptAmbiguous(),
          localChatLookup: (_) {
            if (scenario.name.startsWith('restore lookup')) throw StateError('lookup failed');
            return chat;
          },
          clearLastOpenedChat: () async {
            if (scenario.name.startsWith('last-open')) throw StateError('prefs failed');
          },
          noticeSink: (title, _, _) {
            if (scenario.name.contains('notice throws')) throw StateError('notice failed');
          },
        );
        await service.addChat(chat);
        service.activeChatGuid.value = chat.guid;
        if (scenario.name.contains('durable write fails')) store.failWrites = true;

        final result = await service.recoverablyDeleteChat(chat).timeout(const Duration(seconds: 5));

        expect(result, scenario.expected);
        expect(journal.lookup('server-a', chat.guid) != null, scenario.claimed);
        expect(service.chatStates.containsKey(chat.guid), !scenario.claimed);
        expect(service.pendingDeletes.contains(chat.guid), scenario.claimed);
      });
    }

    test('pending notices are neutral info and the failure notice stays an error, once each', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      final notices = <String>[];
      var result = _receipt(RecoverableDeleteReceiptState.pending, 'efefefefefefefef');
      final pendingChat = _chat('neutral-pending');
      final failedChat = _chat('neutral-failed');
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        attemptIdGenerator: () => 'efefefefefefefef',
        submitRecoverableDelete: ({required chatGuid, required attemptId}) async => result,
        localChatLookup: (guid) => guid == failedChat.guid ? failedChat : null,
        noticeSink: (title, _, type) => notices.add('$title|${type.name}'),
      );
      await service.addChat(pendingChat);
      await service.addChat(failedChat);

      expect(await service.recoverablyDeleteChat(pendingChat), isTrue);
      expect(service.canOpenChat(pendingChat.guid, explain: true), isFalse);
      result = _receipt(RecoverableDeleteReceiptState.definitiveFailure, 'efefefefefefefef');
      expect(await service.recoverablyDeleteChat(failedChat), isFalse);

      expect(notices, [
        'Deletion is being confirmed|info',
        'Deletion is being confirmed|info',
        'Conversation not deleted|error',
      ]);
    });
    test('an identity change mid-load still finishes the started init pass', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      await _claim(journal, 'a-claimed', 'hihihihihihihihi');
      var identity = 'server-a';
      final loadEntered = Completer<void>();
      final releaseLoad = Completer<void>();
      var lookups = 0;
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => identity,
        initialActiveChatsLoader: () async {
          loadEntered.complete();
          await releaseLoad.future;
          return [_chat('a-claimed'), _chat('other')];
        },
        localChatLookup: (_) => null,
        getRecoverableDelete: (_) async {
          lookups++;
          return const RecoverableDeleteAttemptAmbiguous();
        },
        noticeSink: (_, _, _) {},
      );

      final initialization = service.init(force: true);
      await loadEntered.future;
      // Address rediscovery rewrites the configured identity; nothing re-runs init.
      identity = 'server-b';
      releaseLoad.complete();
      await initialization.timeout(const Duration(seconds: 5));

      expect(service.loadedAllChats.isCompleted, isTrue);
      await service.loadedAllChats.future.timeout(const Duration(seconds: 5));
      expect(service.loadedFirstChatBatch.value, isTrue);
      expect(service.chatStates.keys, ['other']);
      expect(service.isRecoverableDeleteSuppressed('a-claimed'), isTrue);
      expect(lookups, 0);
      expect(journal.lookup('server-a', 'a-claimed')?.phase, RecoverableDeleteJournalPhase.submitted);
    });

    for (final path in ['user delete', 'recovery']) {
      test('$path pending mark does not follow a server switch into the next list', () async {
        final journal = RecoverableDeleteJournal.testing(_MemoryStore());
        await journal.hydrate();
        if (path == 'recovery') await _claim(journal, 'switch-row', 'ghghghghghghghgh');
        var identity = 'server-a';
        final network = Completer<RecoverableDeleteAttemptResult>();
        final chat = _chat('switch-row');
        final service = ChatsService(
          journal: journal,
          configuredServerIdentity: () => identity,
          initialActiveChatsLoader: () async => [_chat('switch-row')],
          attemptIdGenerator: () => 'ghghghghghghghgh',
          submitRecoverableDelete: ({required chatGuid, required attemptId}) => network.future,
          getRecoverableDelete: (_) => network.future,
          localChatLookup: (_) => chat,
          localSoftDelete: (_) async {},
          noticeSink: (_, _, _) {},
        );
        final Future<Object?> operation;
        if (path == 'user delete') {
          await service.addChat(chat);
          operation = service.recoverablyDeleteChat(chat);
        } else {
          operation = service.recoverPendingDeletes();
        }
        await Future<void>.delayed(Duration.zero);
        identity = 'server-b';
        network.complete(_receipt(RecoverableDeleteReceiptState.succeeded, 'ghghghghghghghgh'));
        await operation.timeout(const Duration(seconds: 5));

        expect(service.pendingDeletes, isNot(contains('switch-row')));
        await service.init(force: true).timeout(const Duration(seconds: 5));
        expect(service.chatStates.keys, ['switch-row']);
        expect(service.pendingDeletes, isEmpty);
        expect(service.isRecoverableDeleteSuppressed('switch-row'), isFalse);
        expect(journal.lookup('server-a', 'switch-row'), isNotNull);
      });
    }

    for (final failure in ['identity changes during clear', 'restore insert throws']) {
      test('a cleared definitive failure restores the mark and explains once when $failure', () async {
        var identity = 'server-a';
        var writes = 0;
        final journal = RecoverableDeleteJournal.testing(
          _MemoryStore(
            onWrite: (_) {
              if (++writes == 2 && failure.startsWith('identity')) identity = 'server-b';
            },
          ),
        );
        await journal.hydrate();
        final notices = <String>[];
        final chat = _chat('cleared-row');
        final service = ChatsService(
          journal: journal,
          configuredServerIdentity: () => identity,
          attemptIdGenerator: () => 'ijijijijijijijij',
          submitRecoverableDelete: ({required chatGuid, required attemptId}) async =>
              _receipt(RecoverableDeleteReceiptState.definitiveFailure, attemptId),
          localChatLookup: (_) => failure.startsWith('restore') ? _UnrestorableChat('cleared-row') : chat,
          noticeSink: (title, _, type) => notices.add('$title|${type.name}'),
        );
        await service.addChat(chat);

        final result = await service.recoverablyDeleteChat(chat).timeout(const Duration(seconds: 5));

        expect(result, isFalse);
        expect(service.pendingDeletes, isNot(contains('cleared-row')));
        expect(notices, ['Conversation not deleted|error']);
        expect(journal.lookup('server-a', 'cleared-row'), isNull);
      });
    }

    test('a delete while the list belongs to another server sends nothing and explains once', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      var identity = 'server-a';
      var posts = 0;
      final notices = <String>[];
      final chat = _chat('stale-list');
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => identity,
        initialActiveChatsLoader: () async => [chat],
        attemptIdGenerator: () => 'klklklklklklklkl',
        submitRecoverableDelete: ({required chatGuid, required attemptId}) async {
          posts++;
          return const RecoverableDeleteAttemptAmbiguous();
        },
        noticeSink: (title, _, type) => notices.add('$title|${type.name}'),
      );
      await service.init(force: true);
      identity = 'server-b';

      final result = await service.recoverablyDeleteChat(chat).timeout(const Duration(seconds: 5));

      expect(result, isFalse);
      expect(posts, 0);
      expect(notices, ['Conversation not deleted|error']);
      expect(service.pendingDeletes, isEmpty);
      expect(service.chatStates.keys, ['stale-list']);
    });
    test('init for another server drops a pending mark kept for the previous server', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      var identity = 'server-a';
      final chat = _chat('kept-mark');
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => identity,
        initialActiveChatsLoader: () async => [_chat('kept-mark')],
        attemptIdGenerator: () => 'mnmnmnmnmnmnmnmn',
        submitRecoverableDelete: ({required chatGuid, required attemptId}) async =>
            _receipt(RecoverableDeleteReceiptState.pending, attemptId),
        localChatLookup: (_) => chat,
        noticeSink: (_, _, _) {},
      );
      await service.init(force: true);
      expect(await service.recoverablyDeleteChat(chat), isTrue);
      expect(service.pendingDeletes, contains('kept-mark'));

      identity = 'server-b';
      await service.init(force: true).timeout(const Duration(seconds: 5));

      expect(service.pendingDeletes, isNot(contains('kept-mark')));
      expect(service.chatStates.keys, ['kept-mark']);
      expect(journal.lookup('server-a', 'kept-mark')?.attemptId, 'mnmnmnmnmnmnmnmn');
    });

    test('public recovery stays on the list server while the configured server differs', () async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      await _claim(journal, 'shared-guid', 'opopopopopopopop', serverIdentity: 'server-b');
      var identity = 'server-a';
      var lookups = 0;
      var softDeletes = 0;
      final service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => identity,
        initialActiveChatsLoader: () async => [_chat('shared-guid')],
        getRecoverableDelete: (attemptId) async {
          lookups++;
          return _receipt(RecoverableDeleteReceiptState.succeeded, attemptId);
        },
        localChatLookup: _chat,
        localSoftDelete: (_) async => softDeletes++,
        noticeSink: (_, _, _) {},
      );
      await service.init(force: true);
      identity = 'server-b';

      await service.recoverPendingDeletes().timeout(const Duration(seconds: 5));

      expect(service.chatStates.keys, ['shared-guid']);
      expect(service.pendingDeletes, isEmpty);
      expect(lookups, 0);
      expect(softDeletes, 0);
      final claim = journal.lookup('server-b', 'shared-guid');
      expect(claim?.attemptId, 'opopopopopopopop');
      expect(claim?.phase, RecoverableDeleteJournalPhase.submitted);
    });
  });


  test('recoverable delete can suppress a pending result notice', () async {
    final journal = RecoverableDeleteJournal.testing(_MemoryStore());
    await journal.hydrate();
    final notices = <String>[];
    final service = ChatsService(
      journal: journal,
      configuredServerIdentity: () => 'server-a',
      submitRecoverableDelete: ({required chatGuid, required attemptId}) async =>
          _receipt(RecoverableDeleteReceiptState.pending, attemptId),
      localChatLookup: (_) => null,
      noticeSink: (title, _, _) => notices.add(title),
    );

    final result = await service.recoverablyDeleteChat(_chat('quiet-pending'), notify: false);

    expect(result, isTrue);
    expect(notices, isEmpty);
  });

  test('recoverable delete suppresses notices on every early result', () async {
    final notices = <String>[];
    final unavailable = ChatsService(
      journal: RecoverableDeleteJournal.testing(_MemoryStore()),
      configuredServerIdentity: () => 'server-a',
      noticeSink: (title, _, _) => notices.add(title),
    );
    expect(await unavailable.recoverablyDeleteChat(_chat('unavailable'), notify: false), isFalse);

    final existingJournal = RecoverableDeleteJournal.testing(_MemoryStore());
    await existingJournal.hydrate();
    await _claim(existingJournal, 'existing', 'AAAAAAAAAAAAAAAA');
    final existing = ChatsService(
      journal: existingJournal,
      configuredServerIdentity: () => 'server-a',
      noticeSink: (title, _, _) => notices.add(title),
    );
    expect(await existing.recoverablyDeleteChat(_chat('existing'), notify: false), isTrue);

    var identityReads = 0;
    final switchedJournal = RecoverableDeleteJournal.testing(_MemoryStore());
    await switchedJournal.hydrate();
    final switched = ChatsService(
      journal: switchedJournal,
      configuredServerIdentity: () => identityReads++ == 0 ? 'server-a' : 'server-b',
      noticeSink: (title, _, _) => notices.add(title),
    );
    expect(await switched.recoverablyDeleteChat(_chat('switched'), notify: false), isFalse);

    final failingStore = _MemoryStore()..failWrites = true;
    final failingJournal = RecoverableDeleteJournal.testing(failingStore);
    await failingJournal.hydrate();
    final unsaved = ChatsService(
      journal: failingJournal,
      configuredServerIdentity: () => 'server-a',
      noticeSink: (title, _, _) => notices.add(title),
    );
    expect(await unsaved.recoverablyDeleteChat(_chat('unsaved'), notify: false), isFalse);

    expect(notices, isEmpty);
  });
}
