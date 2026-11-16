// The send animation aims at where the new bubble will be once the smart
// reply row has settled. ML suggestions are cleared by the send, but the
// app's own pills ("Attach recent photo", "Jump to oldest unread") stay, so a
// row holding one keeps its height and the target must keep it too, or the
// bubble lands one row low and hops up.
import 'package:bluebubbles/app/layouts/conversation_view/widgets/messages_view_components.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/ui/chat/conversation_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

void main() {
  late ConversationViewController controller;

  setUpAll(() => KeyboardVisibilityTesting.setVisibilityForTesting(false));
  setUp(() {
    GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = Settings());
    controller = cvc(Chat(guid: 'chat'));
  });
  tearDown(() {
    Get.delete<ConversationViewController>(tag: 'chat');
    GetIt.I.unregister<SettingsService>();
  });

  test('only a visible row that holds an app pill survives a send', () {
    controller.updateSmartReplyLayout(visible: true, height: 40, persistsOnSend: true);
    expect(controller.smartReplyRowPersistsOnSend, isTrue);
    controller.updateSmartReplyLayout(visible: true, height: 40);
    expect(controller.smartReplyRowPersistsOnSend, isFalse, reason: 'ML suggestions only');
    controller.updateSmartReplyLayout(visible: false, height: 0, persistsOnSend: true);
    expect(controller.smartReplyRowPersistsOnSend, isFalse);
  });

  testWidgets('a row showing the app\'s own pill reports that it survives a send', (tester) async {
    final pills = <String, Widget>{}.obs;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [BubbleText(bubbleText: TextStyle(fontSize: 15))]),
        home: Scaffold(
          body: SmartRepliesRow(controller: controller, smartReplies: <String>[].obs, internalSmartReplies: pills),
        ),
      ),
    );
    expect(controller.showSmartReplyRow.value, isFalse);

    pills['attach-recent'] = const Text('Attach recent photo');
    await tester.pumpAndSettle();
    expect(controller.showSmartReplyRow.value, isTrue);
    expect(controller.smartReplyRowPersistsOnSend, isTrue);
    expect(
      controller.smartReplyRowHeight.value,
      15 + 35 + 8,
      reason: 'font size + 35, plus the iOS skin\'s top padding',
    );

    pills.clear();
    await tester.pumpAndSettle();
    expect(controller.smartReplyRowPersistsOnSend, isFalse);
  });
}
