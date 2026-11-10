// A chat screen's background, once the chat is closed, must not stay alive.
// It registers with the app binding to follow light/dark mode changes; left
// registered, the binding keeps the background, its chat controller and
// through that the whole closed chat screen alive. On the phone every chat
// screen ever opened stayed in memory with every bubble it built (seq.43l
// BBLIVE after 4 visits: MessagesView 4/4, ChatController 18/18).
import 'dart:developer' show reachabilityBarrier;

import 'package:bluebubbles/app/wrappers/gradient_background_wrapper.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/ui/chat/chats_service.dart';
import 'package:bluebubbles/services/ui/chat/conversation_view_controller.dart';
import 'package:bluebubbles/services/ui/theme/themes_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

/// Tracks which observers are registered with the app binding.
class _Binding extends AutomatedTestWidgetsFlutterBinding {
  final Set<WidgetsBindingObserver> observers = {};

  @override
  void addObserver(WidgetsBindingObserver observer) {
    observers.add(observer);
    super.addObserver(observer);
  }

  @override
  bool removeObserver(WidgetsBindingObserver observer) {
    observers.remove(observer);
    return super.removeObserver(observer);
  }
}

/// The real lookup reads the saved theme from the database.
class _Themes extends ThemesService {
  @override
  bool isGradientBg(BuildContext context) => false;
}

Future<void> _fullGc() async {
  final start = reachabilityBarrier;
  final junk = <List<int>>[];
  while (reachabilityBarrier < start + 2) {
    junk.add(List<int>.filled(200000, 0));
    if (junk.length > 40) junk.removeAt(0);
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  final binding = _Binding();
  setUpAll(() => KeyboardVisibilityTesting.setVisibilityForTesting(false));
  setUp(() {
    GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = Settings());
    GetIt.I.registerSingleton<ThemesService>(_Themes());
    GetIt.I.registerSingleton<ChatsService>(ChatsService());
  });
  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  testWidgets('a closed chat\'s background stops listening to the app and is released', (tester) async {
    var controller = cvc(Chat(guid: 'chat-a'));
    await tester.pumpWidget(GetMaterialApp(
      home: GradientBackground(controller: controller, child: const SizedBox()),
    ));
    // Only weak handles from here on, so the test itself holds nothing.
    final background = WeakReference<State>(tester.state(find.byType(GradientBackground)));
    expect(binding.observers, contains(background.target),
        reason: 'the background follows light/dark changes while open');
    final chatController = WeakReference(controller);

    // Leaving the chat: the screen goes away and its controller is deleted.
    await tester.pumpWidget(GetMaterialApp(home: const SizedBox()));
    Get.delete<ConversationViewController>(tag: 'chat-a');
    controller = cvc(Chat(guid: 'unrelated')); // drop this test's own strong reference

    expect(binding.observers.whereType<State>().where((s) => !s.mounted), isEmpty,
        reason: 'a closed chat\'s background is still registered with the app');

    SchedulerBinding.instance.handleBeginFrame(Duration.zero);
    SchedulerBinding.instance.handleDrawFrame();
    await tester.runAsync(_fullGc);
    expect(background.target, isNull, reason: 'something still holds the closed chat\'s background');
    expect(chatController.target, isNull, reason: 'something still holds the closed chat\'s controller');
  });
}
