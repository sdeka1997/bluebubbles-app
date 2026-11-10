// A chat screen's MessagesService, once closed, must not keep the messages it
// loaded alive: on the phone each scroll through a long chat left 55-75 MB of
// Dart heap behind after leaving it (seq.43i, 2026-11-10).
import 'dart:developer' show reachabilityBarrier;

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/env.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/ui/message/messages_service.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../database/store/store_fixture.dart';

/// Draws a frame (GetxController.onInit queues onReady as a post-frame
/// callback, which holds the controller until a frame runs), then allocates
/// until the VM has run two full collections.
Future<void> _fullGc() async {
  SchedulerBinding.instance.handleBeginFrame(Duration.zero);
  SchedulerBinding.instance.handleDrawFrame();
  final start = reachabilityBarrier;
  final junk = <List<int>>[];
  while (reachabilityBarrier < start + 2) {
    junk.add(List<int>.filled(200000, 0));
    if (junk.length > 40) junk.removeAt(0);
    await Future<void>.delayed(Duration.zero);
  }
}

/// Opens a service, scrolls 10 pages up, makes each message's state, closes it.
Future<({List<WeakReference<Message>> messages, List<WeakReference<Object>> states})> _scrollAndClose(Chat chat) async {
  final service = MessagesService(chat.guid)..chat = chat;
  for (var i = 0; i < 10; i++) {
    await service.loadOlderPage(limit: 25);
  }
  final messages = <WeakReference<Message>>[];
  final states = <WeakReference<Object>>[];
  for (final m in service.struct.messages) {
    messages.add(WeakReference(m));
    states.add(WeakReference(service.getOrCreateMessageState(m.guid!)));
  }
  service.close(force: true);
  return (messages: messages, states: states);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => isIsolateOverride = true);
  tearDownAll(() => isIsolateOverride = false);
  setUp(() => GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = Settings()));
  tearDown(() => GetIt.I.unregister<SettingsService>());

  forEachStore((fixture) {
    test('closing the service lets its loaded messages and states be collected', () async {
      final chat = await fixture().chat('c');
      for (var i = 0; i < 300; i++) {
        await fixture().message('m$i', chat, t0 + i * 1000);
      }
      final refs = await _scrollAndClose(chat);
      expect(refs.messages, hasLength(250));
      await _fullGc();
      final liveMessages = refs.messages.where((r) => r.target != null).length;
      final liveStates = refs.states.where((r) => r.target != null).length;
      // ignore: avoid_print
      print('LEAKCHECK ${fixture().kind}: live messages $liveMessages/250, live states $liveStates/250');
      expect((liveMessages, liveStates), (0, 0));
    });
  });

}
