import "package:bluebubbles/app/layouts/findmy/findmy_warmup.dart";
import "package:bluebubbles/utils/logger/logger.dart";
import "package:flutter_test/flutter_test.dart";
import "package:get_it/get_it.dart";

void main() {
  setUp(() {
    if (!GetIt.I.isRegistered<BaseLogger>()) GetIt.I.registerSingleton<BaseLogger>(BaseLogger());
  });

  test("connecting in the foreground starts Find My ahead of the map", () {
    var sent = 0;
    FindMyWarmup(foreground: () => true, send: () async => sent++).onConnected();
    expect(sent, 1);
  });

  test("connecting in the background does not", () {
    var sent = 0;
    FindMyWarmup(foreground: () => false, send: () async => sent++).onConnected();
    expect(sent, 0);
  });

  test("a server that never answers is only logged", () async {
    FindMyWarmup(foreground: () => true, send: () => Future.error(StateError("Socket not connected"))).onConnected();
    await Future<void>.delayed(Duration.zero);
  });
}
