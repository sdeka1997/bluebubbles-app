import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/java_dart_interop/intents_service.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUpAll(() => GetIt.I.registerSingleton<BaseLogger>(BaseLogger()));
  tearDownAll(GetIt.I.reset);

  test('a suppressed chat guid is rejected before the lookup or any navigation state', () async {
    final guards = <String>[];
    var lookups = 0;
    final service = IntentsService(
      canOpenChat: (guid) {
        guards.add(guid);
        return false;
      },
      findChat: (_) {
        lookups++;
        return null;
      },
    );

    await service.openChat('suppressed', text: 'draft', isInitialIntent: false);

    expect(guards, ['suppressed']);
    expect(lookups, 0);
    expect(service.pendingOpenChatGuid, isNull);
  });

  test('an openable chat guid is still looked up', () async {
    final guards = <String>[];
    var lookups = 0;
    final service = IntentsService(
      canOpenChat: (guid) {
        guards.add(guid);
        return true;
      },
      findChat: (_) {
        lookups++;
        return null;
      },
    );

    await service.openChat('open', isInitialIntent: false);

    expect(guards, ['open']);
    expect(lookups, 1);
  });


  test('suppression after waiting for UI uses the injected guard and stops navigation setup', () async {
    var guardCalls = 0;
    var waits = 0;
    final chat = Chat(id: 1, guid: 'racing', hasUnreadMessage: false);
    final service = IntentsService(
      canOpenChat: (_) => ++guardCalls < 3,
      findChat: (_) => chat,
      waitForUI: () async => waits++,
    );

    await service.openChat('racing', isInitialIntent: false);

    expect(guardCalls, 3);
    expect(waits, 1);
    expect(service.pendingOpenChatGuid, isNull);
  });
}
