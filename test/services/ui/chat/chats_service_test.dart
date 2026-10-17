import 'dart:convert';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/sync/recoverable_delete_journal.dart';
import 'package:bluebubbles/services/ui/chat/chats_service.dart';
import 'package:dio/dio.dart';
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

class _DeleteMemoryStorage {
  String? value;
  final List<String> events = [];

  String? read() => value;
  Future<bool> write(String next) async {
    value = next;
    final decoded = jsonDecode(next) as Map;
    final chat = ((decoded['servers'] as Map)['https://first'] as Map?)?['chat-a'] as Map?;
    events.add(chat == null ? 'clear' : 'persist:${chat['phase']}');
    return true;
  }
}

void main() {
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

  group('recoverable delete submission classification', () {
    final request = RequestOptions(path: '/api/v1/chat/delete');

    test('synthetic interceptor timeout response is ambiguous', () {
      final response = Response(
        requestOptions: request,
        statusCode: 500,
        data: const {
          'error': {'type': 'timeout'},
        },
      );
      expect(classifyRecoverableDeleteSubmissionError(response), RecoverableDeleteSubmissionDisposition.ambiguous);
    });

    test('Dio timeouts and missing responses are ambiguous', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(
          classifyRecoverableDeleteSubmissionError(DioException(requestOptions: request, type: type)),
          RecoverableDeleteSubmissionDisposition.ambiguous,
        );
      }
    });

    test('HTTP 5xx is ambiguous while HTTP 4xx and local preflight are definitive', () {
      expect(
        classifyRecoverableDeleteSubmissionError(Response(requestOptions: request, statusCode: 503)),
        RecoverableDeleteSubmissionDisposition.ambiguous,
      );
      expect(
        classifyRecoverableDeleteSubmissionError(Response(requestOptions: request, statusCode: 409)),
        RecoverableDeleteSubmissionDisposition.definitiveFailure,
      );
      expect(
        classifyRecoverableDeleteSubmissionError('No server URL!'),
        RecoverableDeleteSubmissionDisposition.definitiveFailure,
      );
      expect(
        classifyRecoverableDeleteSubmissionError('unknown local failure'),
        RecoverableDeleteSubmissionDisposition.ambiguous,
      );
    });
  });

  test('production delete orchestration returns true with pending UX for synthetic timeout', () async {
    final storage = _DeleteMemoryStorage();
    final coordinator = RecoverableDeleteRepository(
      readRaw: storage.read,
      writeRaw: storage.write,
    ).viewForServer('https://first');
    final notices = <String>[];
    var postCount = 0;

    final dismissed = await executeRecoverableDelete(
      coordinator: coordinator,
      guid: 'chat-a',
      now: DateTime.utc(2026, 10, 17, 12),
      submit: (_) async {
        postCount++;
        throw Response(
          requestOptions: RequestOptions(path: '/api/v1/chat/delete'),
          statusCode: 500,
          data: const {
            'error': {'type': 'timeout'},
          },
        );
      },
      status: (_) async => throw StateError('status unavailable'),
      localDelete: () async => fail('ambiguous submission must not delete locally'),
      pendingChanged: (_) {},
      onDefinitiveFailure: (_, _) => notices.add('definitive'),
      onPendingConfirmation: (_, _) => notices.add('pending'),
    );

    expect(dismissed, isTrue);
    expect(postCount, 1);
    expect(notices, ['pending']);
    expect(coordinator.isSuppressed('chat-a'), isTrue);
  });

  test('production delete orchestration returns false for 4xx', () async {
    final storage = _DeleteMemoryStorage();
    final coordinator = RecoverableDeleteRepository(
      readRaw: storage.read,
      writeRaw: storage.write,
    ).viewForServer('https://first');
    final notices = <String>[];

    final dismissed = await executeRecoverableDelete(
      coordinator: coordinator,
      guid: 'chat-a',
      now: DateTime.utc(2026, 10, 17, 12),
      submit: (_) async => RecoverableDeleteReceiptState.definitiveFailure,
      status: (_) async => RecoverableDeleteReceiptState.pending,
      localDelete: () async => fail('4xx must not delete locally'),
      pendingChanged: (_) {},
      onDefinitiveFailure: (_, _) => notices.add('definitive'),
      onPendingConfirmation: (_, _) => notices.add('pending'),
    );

    expect(dismissed, isFalse);
    expect(notices, ['definitive']);
    expect(coordinator.isSuppressed('chat-a'), isFalse);
  });

  test('production delete orchestration preserves submitted POST accepted local clear ordering', () async {
    final storage = _DeleteMemoryStorage();
    final coordinator = RecoverableDeleteRepository(
      readRaw: storage.read,
      writeRaw: storage.write,
    ).viewForServer('https://first');

    final dismissed = await executeRecoverableDelete(
      coordinator: coordinator,
      guid: 'chat-a',
      now: DateTime.utc(2026, 10, 17, 12),
      submit: (_) async {
        storage.events.add('post');
        return RecoverableDeleteReceiptState.succeeded;
      },
      status: (_) async => RecoverableDeleteReceiptState.pending,
      localDelete: () async => storage.events.add('local-delete'),
      pendingChanged: (_) {},
      onDefinitiveFailure: (_, _) {},
      onPendingConfirmation: (_, _) {},
    );

    expect(dismissed, isTrue);
    expect(storage.events, ['persist:submitted', 'post', 'persist:accepted', 'local-delete', 'clear']);
  });

  test('startup and addChat suppression helper uses the hydrated coordinator policy', () async {
    final storage = _DeleteMemoryStorage();
    final coordinator = RecoverableDeleteRepository(
      readRaw: storage.read,
      writeRaw: storage.write,
    ).viewForServer('https://first');
    await coordinator.recordSubmitted('chat-a', attemptId: 'attempt_startup_01', now: DateTime.utc(2026, 10, 17, 12));
    await coordinator.hydrate(
      status: (_, _) async => RecoverableDeleteReceiptState.pending,
      finishAccepted: (_) async {},
    );

    expect(shouldIncludeRecoverableDeleteChat(coordinator, 'chat-a'), isFalse);
    expect(shouldIncludeRecoverableDeleteChat(coordinator, 'chat-b'), isTrue);
  });

  test('production delete orchestration shows neutral UX for an explicit pending receipt', () async {
    final storage = _DeleteMemoryStorage();
    final coordinator = RecoverableDeleteRepository(
      readRaw: storage.read,
      writeRaw: storage.write,
    ).viewForServer('https://first');
    final notices = <String>[];

    final dismissed = await executeRecoverableDelete(
      coordinator: coordinator,
      guid: 'chat-a',
      now: DateTime.utc(2026, 10, 17, 12),
      submit: (_) async => RecoverableDeleteReceiptState.pending,
      status: (_) async => RecoverableDeleteReceiptState.pending,
      localDelete: () async => fail('pending must not delete locally'),
      pendingChanged: (_) {},
      onDefinitiveFailure: (_, _) => notices.add('definitive'),
      onPendingConfirmation: (_, _) => notices.add('pending'),
    );

    expect(dismissed, isTrue);
    expect(notices, ['pending']);
    expect(coordinator.isSuppressed('chat-a'), isTrue);
  });

  test('actual ChatsService.init first batch excludes claims and loads unrelated chats', () async {
    final storage = _DeleteMemoryStorage();
    final coordinator = RecoverableDeleteRepository(
      readRaw: storage.read,
      writeRaw: storage.write,
    ).viewForServer('https://first');
    await coordinator.recordSubmitted(
      'suppressed',
      attemptId: 'attempt_init_012345',
      now: DateTime.utc(2026, 10, 17, 12),
    );
    final service = ChatsService();
    final source = ChatsServiceInitSource(
      coordinator: coordinator,
      chats: [
        Chat(id: 10, guid: 'suppressed', hasUnreadMessage: false),
        Chat(id: 11, guid: 'unrelated', hasUnreadMessage: false),
      ],
    );
    await service.init(force: true, testSource: source);

    expect(source.visibleChats.map((chat) => chat.guid), ['unrelated']);
    expect(service.loadedFirstChatBatch.value, isTrue);
    service.close();
  });

  test('actual ChatsService.addChat path rejects a suppressed watcher insertion', () async {
    final storage = _DeleteMemoryStorage();
    final coordinator = RecoverableDeleteRepository(
      readRaw: storage.read,
      writeRaw: storage.write,
    ).viewForServer('https://first');
    await coordinator.recordSubmitted(
      'suppressed',
      attemptId: 'attempt_watcher_0123',
      now: DateTime.utc(2026, 10, 17, 12),
    );
    final service = ChatsService();
    await service.addChat(
      Chat(id: 12, guid: 'suppressed', hasUnreadMessage: false),
      immediate: true,
      testCoordinator: coordinator,
    );

    expect(service.getChatState('suppressed'), isNull);
    service.close();
  });
}
