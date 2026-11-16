// Spellcheck sends what's typed to LanguageTool (api.languagetoolplus.com).
// Android hides the setting but it defaults to on, so editing a sent message
// there used to send its text out. It now never runs off desktop and web.
import 'dart:async';

import 'package:bluebubbles/app/components/custom_text_editing_controllers.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:languagetool_textfield/languagetool_textfield.dart';
import 'package:languagetool_textfield/src/utils/result.dart';

/// Stands in for LanguageTool: records what would have been sent, and answers
/// when the test says so.
class _LanguageTool extends LanguageCheckService {
  final sent = <String>[];
  final answers = <Completer<Result<List<Mistake>>?>>[];

  @override
  Future<Result<List<Mistake>>?> findMistakes(String text) {
    sent.add(text);
    final answer = Completer<Result<List<Mistake>>?>();
    answers.add(answer);
    return answer.future;
  }
}

void main() {
  late _LanguageTool languageTool;

  setUp(() {
    GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = Settings());
    languageTool = _LanguageTool();
  });
  tearDown(() {
    SpellCheckTextEditingController.debugSupportedOverride = null;
    GetIt.I.reset();
  });

  test('off desktop and web, editing a message sends nothing to LanguageTool', () async {
    SpellCheckTextEditingController.debugSupportedOverride = false;
    expect(SettingsSvc.settings.spellcheck.value, isTrue, reason: 'the hidden setting defaults to on');

    final controller = SpellCheckTextEditingController(
      text: 'the message being edited',
      focusNode: FocusNode(),
      languageCheckService: languageTool,
    );
    controller.value = const TextEditingValue(text: 'the message, edited');
    await pumpEventQueue();
    expect(languageTool.sent, isEmpty);
    controller.dispose();
  });

  test('on desktop and web spellcheck still checks the text', () async {
    SpellCheckTextEditingController.debugSupportedOverride = true;
    final controller = SpellCheckTextEditingController(
      text: 'teh text',
      focusNode: FocusNode(),
      languageCheckService: languageTool,
    );
    await pumpEventQueue();
    expect(languageTool.sent, ['teh text']);
    languageTool.answers.single.complete(const Result.success([]));
    await pumpEventQueue();
    controller.dispose();
  });

  test('an answer that arrives after the field closed is dropped', () async {
    SpellCheckTextEditingController.debugSupportedOverride = true;
    final controller = SpellCheckTextEditingController(
      text: 'teh text',
      focusNode: FocusNode(),
      languageCheckService: languageTool,
    );
    await pumpEventQueue();
    controller.dispose();

    // notifyListeners() on a disposed controller throws.
    languageTool.answers.single.complete(const Result.success([]));
    await pumpEventQueue();
  });
}
