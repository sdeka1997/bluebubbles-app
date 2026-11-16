// The send routes wait as long as the server does for iMessage (minutes), but
// the outgoing queue is shared by every chat, so it moves on after the usual
// request timeout. A send it moved on from still finalizes its own message
// when its result lands.
import 'dart:async';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/outgoing_message_handler.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

/// Stands in for the HTTP call of each send: the test decides when (and how)
/// each one answers.
class _Handler extends OutgoingMessageHandler {
  final calls = <String, Completer<Map<String, dynamic>>>{};
  final results = <String, String>{};

  @override
  Future<void> sendMessage(Chat c, Message m, Message? selected, String? r) {
    final guid = m.guid!;
    final call = calls[guid] = Completer<Map<String, dynamic>>();
    return debugSendWithRace(
      tempGuid: guid,
      chat: c,
      httpCall: () => call.future,
      onSuccess: (data) async => results[guid] = 'sent as ${data['guid']}',
      onError: (error, _) async => results[guid] = 'failed: $error',
    );
  }
}

void main() {
  late Settings settings;
  late _Handler handler;

  setUp(() {
    settings = Settings()..apiTimeout.value = 30000;
    GetIt.I.registerSingleton<BaseLogger>(BaseLogger());
    GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = settings);
    handler = _Handler();
  });
  tearDown(() => GetIt.I.reset());

  final chat = Chat(guid: 'iMessage;-;ana@example.com');
  final other = Chat(guid: 'iMessage;-;bo@example.com');

  OutgoingMessage item(String guid, Chat c, [Completer<void>? done]) => OutgoingMessage(
    chat: c,
    message: Message(guid: guid, text: guid),
    completer: done,
  );

  test('the queue sends the next message once a send has waited apiTimeout, and the slow one still lands', () {
    fakeAsync((async) {
      final firstDone = Completer<void>();
      handler.debugEnqueuePrepared(item('slow', chat, firstDone));
      handler.debugEnqueuePrepared(item('next', other));
      async.flushMicrotasks();
      expect(handler.calls.keys, ['slow']);

      async.elapse(const Duration(seconds: 29));
      expect(handler.calls.keys, ['slow'], reason: 'a send that is quick enough still holds the queue');

      async.elapse(const Duration(seconds: 1));
      expect(handler.calls.keys, ['slow', 'next']);
      expect(firstDone.isCompleted, isTrue);
      expect(handler.results, isEmpty);

      handler.calls['next']!.complete({'guid': 'real-next'});
      async.elapse(const Duration(minutes: 2));
      handler.calls['slow']!.complete({'guid': 'real-slow'});
      async.flushMicrotasks();
      expect(handler.results, {'next': 'sent as real-next', 'slow': 'sent as real-slow'});
      async.elapse(const Duration(seconds: 1));
    });
  });

  test('a slow send that fails after the queue moved on still marks its own message failed', () {
    fakeAsync((async) {
      handler.debugEnqueuePrepared(item('slow', chat));
      handler.debugEnqueuePrepared(item('next', other));
      async.elapse(const Duration(seconds: 30));
      expect(handler.calls.keys, ['slow', 'next']);

      handler.calls['slow']!.completeError('timed out on the server');
      async.flushMicrotasks();
      expect(handler.results, {'slow': 'failed: timed out on the server'});

      handler.calls['next']!.complete({'guid': 'real-next'});
      async.flushMicrotasks();
      expect(handler.results['next'], 'sent as real-next');
      async.elapse(const Duration(seconds: 1));
    });
  });

  test('a send that fails before apiTimeout still cancels the chat\'s queued messages', () {
    settings.cancelQueuedMessages.value = true;
    fakeAsync((async) {
      final queued = item('queued', chat);
      handler.debugEnqueuePrepared(item('fails', chat));
      handler.debugEnqueuePrepared(queued);
      async.flushMicrotasks();

      handler.calls['fails']!.completeError('bad request');
      async.elapse(const Duration(seconds: 1));
      expect(handler.calls.keys, ['fails'], reason: 'the queued message was never sent');
      expect(queued.message.errorMessage, 'Canceled due to previous failure');
    });
  });

  test('a slow send that fails after the queue moved on cancels nothing queued behind it', () {
    // By the time it fails, messages after it may already have gone: one
    // failure doesn't say anything about them any more.
    settings.cancelQueuedMessages.value = true;
    fakeAsync((async) {
      final queued = item('queued', chat);
      handler.debugEnqueuePrepared(item('slow', chat));
      handler.debugEnqueuePrepared(item('also-slow', chat));
      handler.debugEnqueuePrepared(queued);
      async.elapse(const Duration(seconds: 30));
      expect(handler.calls.keys, ['slow', 'also-slow']);

      handler.calls['slow']!.completeError('timed out on the server');
      async.flushMicrotasks();
      expect(handler.results['slow'], 'failed: timed out on the server');
      expect(queued.message.errorMessage, isNull);

      async.elapse(const Duration(seconds: 30));
      expect(handler.calls.keys, ['slow', 'also-slow', 'queued']);
      async.elapse(const Duration(seconds: 1));
    });
  });
}
