import 'package:bluebubbles/app/layouts/findmy/findmy_controller.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_tiles.dart';
import 'package:bluebubbles/app/layouts/findmy/widgets/findmy_map_widget.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:get/get.dart';
import 'package:http/testing.dart';

import 'findmy_test_support.dart';

Position position(double latitude, double longitude) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: DateTime(2026),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: double.nan,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  late FakeICloudApi icloud;

  setUp(() {
    icloud = registerFindMyServices();
    ConnectivityPlatform.instance = FakeConnectivity();
  });

  tearDown(resetFindMyServices);

  FindMyController openController() => Get.put(
    FindMyController(
      tiles: FindMyTileLoader(
        httpClient: MockClient((request) async => MockClient.pngResponse(request: request)),
        cachingProvider: const DisabledMapCachingProvider(),
      ),
    ),
  );

  Widget page(FindMyController controller) => MaterialApp(
    home: Center(
      child: SizedBox(width: 300, height: 300, child: FindMyMapWidget(controller: controller)),
    ),
  );

  /// Answers the opening load so nothing is left waiting when the test ends.
  Future<void> settle(WidgetTester tester) async {
    icloud.answer('refreshFriends');
    await tester.pump();
    icloud.answer('getDevices');
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    Get.delete<FindMyController>();
    await tester.pump(const Duration(minutes: 2));
  }

  testWidgets('every rebuild of the map keeps the one tile provider', (tester) async {
    final controller = openController();
    controller.location.value = position(32.78, -96.80);
    await tester.pumpWidget(page(controller));
    await tester.pump();

    final layer = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(layer.tileProvider, same(controller.tiles.tileProvider));

    controller.location.value = position(32.79, -96.81);
    await tester.pump();
    controller.markers.refresh();
    await tester.pump();

    final rebuilt = tester.widget<TileLayer>(find.byType(TileLayer));
    expect(rebuilt.tileProvider, same(layer.tileProvider));

    await settle(tester);
  });
}
