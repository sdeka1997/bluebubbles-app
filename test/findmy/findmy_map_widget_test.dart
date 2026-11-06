import 'dart:async';

import 'package:bluebubbles/app/layouts/findmy/findmy_camera.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_controller.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_panel.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_selection.dart';
import 'package:bluebubbles/app/layouts/findmy/widgets/findmy_selected_card.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_tiles.dart';
import 'package:bluebubbles/app/layouts/findmy/widgets/findmy_map_widget.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter_test/flutter_test.dart' hide EventDispatcher;
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:get/get.dart' hide Response;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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

/// Location permission granted, with one fix that arrives when the test says.
class GrantedGeolocator extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  final Completer<Position> fix = Completer();
  final StreamController<Position> stream = StreamController.broadcast();

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.whileInUse;

  @override
  Future<Position?> getLastKnownPosition({bool forceLocationManager = false}) async => null;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) => fix.future;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) => stream.stream;
}

/// A friend at [latitude], [longitude] whose fix was taken at [at].
FindMyFriend friendAt(double latitude, double longitude, DateTime at) => FindMyFriend(
  latitude: latitude,
  longitude: longitude,
  longAddress: null,
  shortAddress: "Plano, TX",
  title: "Dad",
  subtitle: null,
  handle: null,
  handleAddress: "dad@example.com",
  lastUpdated: at,
  status: LocationStatus.live,
  locatingInProgress: false,
  favoriteOrder: null,
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

  // Markers read the theme through Get.context, which only GetMaterialApp sets.
  Widget page(FindMyController controller) => GetMaterialApp(
    home: Center(
      child: SizedBox(width: 300, height: 300, child: FindMyMapWidget(controller: controller)),
    ),
  );

  Future<void> answerOpening(WidgetTester tester) async {
    icloud.answer('getFriends');
    icloud.answer('getDevices');
    await tester.pump();
  }

  /// Tears down a page whose opening load was already answered.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    Get.delete<FindMyController>();
    await tester.pump(const Duration(minutes: 2));
  }

  /// Answers the opening load so nothing is left waiting when the test ends.
  Future<void> settle(WidgetTester tester) async {
    await answerOpening(tester);
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

  testWidgets('the map is on screen from the first frame with no location and no data', (tester) async {
    final controller = openController();
    await tester.pumpWidget(page(controller));

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(controller.mapController.camera.center, findMyWorldCenter);
    expect(controller.mapController.camera.zoom, findMyWorldZoom);

    await settle(tester);
  });

  testWidgets('switching to a tab with nothing on it keeps the same map', (tester) async {
    final controller = openController();
    controller.location.value = position(32.78, -96.80);
    await tester.pumpWidget(page(controller));
    await tester.pump();
    final map = tester.element(find.byType(FlutterMap));

    controller.tabIndex.value = 2;
    await tester.pump();

    expect(tester.element(find.byType(FlutterMap)), same(map));
    expect(find.text('Location unavailable'), findsNothing, reason: 'still loading');

    await settle(tester);
  });

  testWidgets('says so over the map when a tab has nothing to show', (tester) async {
    final controller = openController();
    await tester.pumpWidget(page(controller));
    await answerOpening(tester);

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Location unavailable'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    Get.delete<FindMyController>();
    await tester.pump(const Duration(minutes: 2));
  });

  testWidgets('the first location fix frames the map once', (tester) async {
    final geolocator = GrantedGeolocator();
    GeolocatorPlatform.instance = geolocator;
    final controller = openController();
    await tester.pumpWidget(page(controller));
    await tester.pump();
    await answerOpening(tester);

    geolocator.fix.complete(position(32.78, -96.80));
    await tester.pump();
    await tester.pump(findMyCameraSettle);
    expect(controller.mapController.camera.center.latitude, closeTo(32.78, 0.01));
    expect(controller.mapController.camera.center.longitude, closeTo(-96.80, 0.01));

    const elsewhere = LatLng(47.61, -122.33);
    controller.mapController.move(elsewhere, 10);
    geolocator.stream.add(position(32.79, -96.81));
    await tester.pump();
    await tester.pump(findMyCameraSettle);
    expect(controller.mapController.camera.center, elsewhere, reason: 'a later fix must not reframe the map');

    await tester.pumpWidget(const SizedBox());
    Get.delete<FindMyController>();
    await tester.pump(const Duration(minutes: 2));
  });

  testWidgets('friends, devices and the first fix arriving together frame the map once', (tester) async {
    final geolocator = GrantedGeolocator();
    GeolocatorPlatform.instance = geolocator;
    final controller = openController()..tabIndex.value = 1;
    await tester.pumpWidget(page(controller));
    await tester.pump();
    final moves = <MapEvent>[];
    final sub = controller.mapController.mapEventStream
        .where((event) => event is MapEventMove && event.source == MapEventSource.mapController)
        .listen(moves.add);

    icloud.answer('getFriends', data: [unnamedFriendJson(33.02, -96.70)]);
    icloud.answer('getDevices', data: [phoneJson]);
    await tester.pump();
    EventDispatcherSvc.emit('findmy-devices-updated', [phoneJson]);
    await tester.pump();
    geolocator.fix.complete(position(32.78, -96.80));
    await tester.pump();
    await tester.pump(findMyCameraSettle);

    expect(moves, hasLength(1));
    unawaited(sub.cancel());
    await tester.pumpWidget(const SizedBox());
    Get.delete<FindMyController>();
    await tester.pump(const Duration(minutes: 2));
  });

  testWidgets('new data never moves a map the user has moved', (tester) async {
    final controller = openController();
    await tester.pumpWidget(page(controller));
    await answerOpening(tester);
    controller.tabIndex.value = 1;
    await tester.pump(findMyCameraSettle);

    const elsewhere = LatLng(47.61, -122.33);
    controller.noteCameraGesture();
    controller.mapController.move(elsewhere, 10);
    EventDispatcherSvc.emit('findmy-devices-updated', [phoneJson]);
    await tester.pump();
    await tester.pump(findMyCameraSettle);

    expect(controller.mapController.camera.center, elsewhere);
    await tester.pumpWidget(const SizedBox());
    Get.delete<FindMyController>();
    await tester.pump(const Duration(minutes: 2));
  });

  test('frames the map below the buttons and above the halfway drawer', () {
    final padding = findMyCameraPadding(topInset: 24, hiddenBelowPanel: 80, maxPanelHeight: 600);
    expect(padding.top, 24 + findMyMapButtonInset + findMyMapButtonSize + findMyCameraMargin);
    expect(
      padding.bottom,
      80 + findMyPanelMinHeight + findMyPanelSnapPoint * (600 - findMyPanelMinHeight) + findMyCameraMargin,
    );
    expect(padding.left, findMyCameraMargin);
    expect(padding.right, findMyCameraMargin);
  });


  group('a selected person who moves', () {
    const gym = LatLng(33.02, -96.70);
    const road = LatLng(33.08, -96.75);

    Future<FindMyController> selectDad(WidgetTester tester) async {
      final controller = openController();
      await tester.pumpWidget(page(controller));
      await answerOpening(tester);
      final dad = friendAt(gym.latitude, gym.longitude, DateTime(2026, 11, 6, 9));
      controller.friends.value = [dad];
      controller.buildFriendMarker(dad);
      await controller.select(FindMySelection.ofFriend(dad), gym);
      await tester.pump();
      expect(controller.mapController.camera.center.latitude, closeTo(gym.latitude, 0.01));
      return controller;
    }

    testWidgets('stays in view: the map follows them as their location changes', (tester) async {
      final controller = await selectDad(tester);

      controller.onFriendLocation(friendAt(road.latitude, road.longitude, DateTime(2026, 11, 6, 9, 5)));
      await tester.pump();

      expect(controller.mapController.camera.center.latitude, closeTo(road.latitude, 0.01));
      expect(controller.mapController.camera.center.longitude, closeTo(road.longitude, 0.01));
      await close(tester);
    });

    testWidgets('a map the user has moved since stays where they put it', (tester) async {
      final controller = await selectDad(tester);
      const elsewhere = LatLng(47.61, -122.33);
      controller.noteCameraGesture();
      controller.mapController.move(elsewhere, 10);

      controller.onFriendLocation(friendAt(road.latitude, road.longitude, DateTime(2026, 11, 6, 9, 5)));
      await tester.pump();

      expect(controller.mapController.camera.center, elsewhere);
      await close(tester);
    });

    testWidgets('once nobody is selected, their moves no longer move the map', (tester) async {
      final controller = await selectDad(tester);
      controller.clearSelection();

      controller.onFriendLocation(friendAt(road.latitude, road.longitude, DateTime(2026, 11, 6, 9, 5)));
      await tester.pump();

      expect(controller.mapController.camera.center.latitude, closeTo(gym.latitude, 0.01));
      await close(tester);
    });
  });

  testWidgets('the selected card spins while the tapped person is being located', (tester) async {
    SettingsSvc.settings.skin.value = Skins.Material;
    await tester.pumpWidget(const GetMaterialApp(
      home: Material(child: FindMySelectedCard(title: 'Dad', status: '5 min. ago', locating: true)),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(const GetMaterialApp(
      home: Material(child: FindMySelectedCard(title: 'Dad', status: '5 min. ago')),
    ));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

/// A friend with no handle or name, which the tests can parse without a
/// handle database. Its address spares the platform geocoder.
Map<String, dynamic> unnamedFriendJson(double latitude, double longitude) => {
  'coordinates': [latitude, longitude],
  'short_address': 'Plano, TX',
  'last_updated': DateTime(2026).millisecondsSinceEpoch,
};
