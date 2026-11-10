// A chat screen's ConversationViewController, once the chat is closed, must
// not stay alive: it holds the scroll controller, the per-message text
// analysis made while scrolling, and the media players. On the phone each
// scroll through a long chat left 70-90 MB of Dart heap behind after leaving
// it, even with the app in the background (seq.43j, 2026-11-10).
import 'dart:developer' show reachabilityBarrier;

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/ui/chat/conversation_view_controller.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

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

/// Opens the chat's controller the way the chat screen does, then deletes it
/// the way leaving the chat does, and returns a weak handle to it.
WeakReference<ConversationViewController> _openAndClose(String guid) {
  final controller = cvc(Chat(guid: guid));
  final ref = WeakReference(controller);
  Get.delete<ConversationViewController>(tag: guid);
  return ref;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Keeps the keyboard plugin off its platform channel, as on a host.
  setUpAll(() => KeyboardVisibilityTesting.setVisibilityForTesting(false));
  setUp(() => GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = Settings()));
  tearDown(() => GetIt.I.unregister<SettingsService>());

  test('a closed chat\'s controller is released', () async {
    final ref = _openAndClose('chat-a');
    expect(Get.isRegistered<ConversationViewController>(tag: 'chat-a'), isFalse);

    await _fullGc();

    expect(ref.target, isNull, reason: 'something still holds the chat controller after the chat closed');
  });

  test('a keyboard change after the chat closed reaches no closed controller', () async {
    final ref = _openAndClose('chat-b');
    KeyboardVisibilityTesting.setVisibilityForTesting(true);
    await Future<void>.delayed(Duration.zero);
    expect(ref.target?.keyboardOpen ?? false, isFalse);
    KeyboardVisibilityTesting.setVisibilityForTesting(false);
  });
}
