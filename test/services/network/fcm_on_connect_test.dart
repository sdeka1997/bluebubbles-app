import 'package:bluebubbles/database/global/settings.dart';
import 'package:bluebubbles/helpers/network/network_tasks.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/backend/sync/sync_service.dart';
import 'package:bluebubbles/services/network/firebase/cloud_messaging_service.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

// Push registration needs the server. At launch Android can still be holding
// the app's network for a few seconds, so registering then failed and showed
// "Failed to register FCM device!" for a server that was fine. Registering
// each time the server connection comes up can't hit that.
class _Registrations extends CloudMessagingService {
  int count = 0;

  @override
  Future<void> registerDevice() async => count++;
}

class _NoSync extends SyncService {
  @override
  Future<void> startIncrementalSync({bool useGlobalIsolate = false}) async {}
}

void main() {
  late _Registrations fcm;

  setUp(() {
    GetIt.I.registerSingleton<BaseLogger>(BaseLogger());
    GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = (Settings()..finishedSetup.value = true));
    GetIt.I.registerSingleton<SyncService>(_NoSync());
    fcm = _Registrations();
    GetIt.I.registerSingleton<CloudMessagingService>(fcm);
  });
  tearDown(() => GetIt.I.reset());

  test('connecting to the server registers this device for push', () async {
    await NetworkTasks.onConnect();
    expect(fcm.count, 1);
  });

  test('before setup is finished nothing is registered', () async {
    SettingsSvc.settings.finishedSetup.value = false;
    await NetworkTasks.onConnect();
    expect(fcm.count, 0);
  });
}
