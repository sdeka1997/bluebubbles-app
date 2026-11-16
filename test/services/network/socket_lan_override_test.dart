// #3405: a LAN override found on home Wi-Fi went stale after leaving it, and
// the socket kept dialing it: a failure only started the 30s+ "did the server
// move?" clock, and a heartbeat rebuild redialed the same dead address. Both
// now drop the override so the rebuild dials the server URL.
import 'package:bluebubbles/database/global/settings.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/network/http_service.dart';
import 'package:bluebubbles/services/network/socket_service.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:socket_io_client/socket_io_client.dart';

/// Records rebuilds instead of dialing, and what each one would have dialed.
class _Socket extends SocketService {
  final dialed = <String>[];

  @override
  void restartSocket() => dialed.add(serverAddress);
}

void main() {
  late _Socket socket;
  const lan = 'http://192.168.1.20:1234';

  setUp(() {
    GetIt.I.registerSingleton<BaseLogger>(BaseLogger());
    GetIt.I.registerSingleton<SettingsService>(
      SettingsService()
        ..settings = (Settings()
          ..finishedSetup.value = true
          ..serverAddress.value = 'https://server.example.com'),
    );
    GetIt.I.registerSingleton<HttpService>(HttpService()..originOverride = lan);
    socket = _Socket();
  });
  tearDown(() async {
    socket.disconnect();
    await GetIt.I.reset();
  });

  test('a connection error on the LAN address falls back to the server URL at once', () {
    expect(socket.serverAddress, lan);
    socket.handleStatusUpdate(SocketState.error, 'timeout');
    expect(HttpSvc.originOverride, isNull);
    expect(socket.dialed, ['https://server.example.com']);
  });

  test('a connection error on the server URL leaves socket.io retrying', () {
    HttpSvc.originOverride = null;
    socket.handleStatusUpdate(SocketState.error, 'timeout');
    expect(socket.dialed, isEmpty);
  });

  test('two missed heartbeats on the LAN address rebuild onto the server URL', () {
    fakeAsync((async) {
      socket.socket = io(lan, OptionBuilder().disableAutoConnect().enableForceNew().build());
      socket.state.value = SocketState.connected;
      socket.checkConnection();
      async.elapse(const Duration(seconds: 5));
      expect(socket.dialed, isEmpty, reason: 'one late ack is retried, not acted on');
      expect(HttpSvc.originOverride, lan);
      async.elapse(const Duration(seconds: 5));
      expect(HttpSvc.originOverride, isNull);
      expect(socket.dialed, ['https://server.example.com']);
      socket.socket!.dispose();
    });
  });
}
