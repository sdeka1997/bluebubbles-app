// Leaving a chat must dispose every controller its screen made. Flutter
// reports each animation, scroll, text and focus controller as it is created
// and disposed; anything created but never disposed keeps its listeners (and
// often the State that made it) alive after the chat closes.
import 'package:bluebubbles/app/layouts/conversation_view/widgets/text_field/send_button.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/ui/chat/conversation_view_controller.dart';
import 'package:bluebubbles/services/ui/theme/themes_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

/// The real check reads the saved theme from the database.
class _Themes extends ThemesService {
  @override
  bool get isAnyMaterialYouSelected => false;
}

/// Records Flutter objects created and not yet disposed while [body] runs.
Future<List<String>> _undisposed(Future<void> Function() body) async {
  final live = <Object, String>{};
  void listener(ObjectEvent event) {
    if (event is ObjectCreated) live[event.object] = event.className;
    if (event is ObjectDisposed) live.remove(event.object);
  }

  FlutterMemoryAllocations.instance.addListener(listener);
  try {
    await body();
  } finally {
    FlutterMemoryAllocations.instance.removeListener(listener);
  }
  return live.values.toList();
}

void main() {
  setUpAll(() => KeyboardVisibilityTesting.setVisibilityForTesting(false));
  setUp(() {
    GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = Settings());
    GetIt.I.registerSingleton<ThemesService>(_Themes());
  });
  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  testWidgets('a closed chat\'s send button disposes its animation', (tester) async {
    // No debug banner: it is the test app's, not the chat's.
    await tester.pumpWidget(const MaterialApp(debugShowCheckedModeBanner: false, home: SizedBox()));
    final leftOver = await _undisposed(() async {
      await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false, home: SendButton(onLongPress: () {}, sendMessage: () {})));
      await tester.pumpWidget(const MaterialApp(debugShowCheckedModeBanner: false, home: SizedBox()));
    });
    // Elements, States and render objects are the widget tree's own bookkeeping.
    expect(leftOver, isNot(contains('AnimationController')));
    expect(leftOver, isNot(contains('Ticker')));
  });

  testWidgets('a closed chat\'s controller disposes everything it made', (tester) async {
    // Made first: the binding's own one-time setup is not the chat's.
    cvc(Chat(guid: 'warm-up'));
    final leftOver = await _undisposed(() async {
      cvc(Chat(guid: 'chat-a'));
      Get.delete<ConversationViewController>(tag: 'chat-a');
    });
    expect(leftOver, isEmpty);
  });
}
