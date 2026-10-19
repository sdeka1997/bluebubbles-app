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
}
