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
  Future<void> write(String next) async {
    value = next;
    final decoded = jsonDecode(next) as Map;
    final chat = ((decoded['servers'] as Map)['https://first'] as Map?)?['chat-a'] as Map?;
    events.add(chat == null ? 'clear' : 'persist:${chat['phase']}');
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
        data: const {'error': {'type': 'timeout'}},
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
    final coordinator = RecoverableDeleteCoordinator(
      RecoverableDeleteJournal(serverAddress: 'https://first', readRaw: storage.read, writeRaw: storage.write),
    );
    final notices = <String>[];
    var postCount = 0;

    final dismissed = await executeRecoverableDelete(
      coordinator: coordinator,
      guid: 'chat-a',
      now: DateTime.utc(2026, 10, 17, 12),
      submit: () async {
        postCount++;
        throw Response(
          requestOptions: RequestOptions(path: '/api/v1/chat/delete'),
          statusCode: 500,
          data: const {'error': {'type': 'timeout'}},
        );
      },
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
    final coordinator = RecoverableDeleteCoordinator(
      RecoverableDeleteJournal(serverAddress: 'https://first', readRaw: storage.read, writeRaw: storage.write),
    );
    final notices = <String>[];

    final dismissed = await executeRecoverableDelete(
      coordinator: coordinator,
      guid: 'chat-a',
      now: DateTime.utc(2026, 10, 17, 12),
      submit: () async => throw Response(
        requestOptions: RequestOptions(path: '/api/v1/chat/delete'),
        statusCode: 409,
      ),
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
    final coordinator = RecoverableDeleteCoordinator(
      RecoverableDeleteJournal(serverAddress: 'https://first', readRaw: storage.read, writeRaw: storage.write),
    );

    final dismissed = await executeRecoverableDelete(
      coordinator: coordinator,
      guid: 'chat-a',
      now: DateTime.utc(2026, 10, 17, 12),
      submit: () async => storage.events.add('post'),
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
    final journal = RecoverableDeleteJournal(
      serverAddress: 'https://first',
      readRaw: storage.read,
      writeRaw: storage.write,
    );
    await journal.recordSubmitted('chat-a', now: DateTime.utc(2026, 10, 17, 12));
    final coordinator = RecoverableDeleteCoordinator(journal);
    await coordinator.hydrate(now: DateTime.utc(2026, 10, 17, 12));

    expect(shouldIncludeRecoverableDeleteChat(coordinator, 'chat-a'), isFalse);
    expect(shouldIncludeRecoverableDeleteChat(coordinator, 'chat-b'), isTrue);
  });
}
