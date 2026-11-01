import "dart:async";

import "package:bluebubbles/app/layouts/findmy/findmy_controller.dart";
import "package:bluebubbles/database/models.dart";
import "package:bluebubbles/services/backend/settings/actions/shared_preferences_findmy_actions.dart";
import "package:bluebubbles/services/network/api/icloud_api.dart";
import "package:bluebubbles/services/services.dart";
import "package:bluebubbles/utils/logger/logger.dart";
import "package:dio/dio.dart";
import "package:fake_async/fake_async.dart";
import "package:flutter_test/flutter_test.dart" hide EventDispatcher;
import "package:geolocator_platform_interface/geolocator_platform_interface.dart";
import "package:get/get.dart" hide Response;
import "package:get_it/get_it.dart";
import "package:plugin_platform_interface/plugin_platform_interface.dart";

class FakeGeolocator extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.denied;

  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.deniedForever;
}

class FakeFindMyPrefs extends SharedPreferencesFindMyActions {
  FakeFindMyPrefs(super.service);

  @override
  String? getLocationCache() => null;

  @override
  Future<void> setLocationCache(String json) async {}
}

/// Holds every Find My request open until the test answers it, so a request
/// that the tunnel cancelled mid-flight can be modelled as one that simply
/// never completes.
class FakeICloudApi extends iCloudApi {
  FakeICloudApi(super.svc);

  final Map<String, List<Completer<Response>>> requests = {};

  Future<Response> _request(String name) {
    final completer = Completer<Response>();
    requests.putIfAbsent(name, () => []).add(completer);
    return completer.future;
  }

  void answer(String name, {Object data = const []}) => requests[name]!
      .removeAt(0)
      .complete(
        Response(
          requestOptions: RequestOptions(path: ""),
          statusCode: 200,
          data: {"data": data},
        ),
      );

  @override
  Future<Response> refreshFriends({CancelToken? cancelToken}) => _request("refreshFriends");

  @override
  Future<Response> getFriends({CancelToken? cancelToken}) => _request("getFriends");

  @override
  Future<Response> refreshDevices({CancelToken? cancelToken}) => _request("refreshDevices");

  @override
  Future<Response> getDevices({CancelToken? cancelToken}) => _request("getDevices");
}

void main() {
  late FakeICloudApi icloud;

  setUp(() {
    GeolocatorPlatform.instance = FakeGeolocator();
    final settings = SettingsService()..settings = Settings();
    final prefs = SharedPreferencesService();
    prefs.findMy = FakeFindMyPrefs(prefs);
    final http = HttpService();
    icloud = FakeICloudApi(http);
    http.icloud = icloud;
    GetIt.I
      ..registerSingleton<BaseLogger>(BaseLogger())
      ..registerSingleton<SettingsService>(settings)
      ..registerSingleton<SharedPreferencesService>(prefs)
      ..registerSingleton<EventDispatcher>(EventDispatcher())
      ..registerSingleton<HttpService>(http);
  });

  tearDown(() async {
    Get.reset();
    await GetIt.I.reset();
  });

  // Observed 2026-10-31 20:36: the phone POSTed /findmy/devices/refresh, the
  // Cloudflare tunnel tore the connection down ("Incoming request ended
  // abruptly: context canceled"), and the server finished the work 24.8 s
  // later into a socket nobody held. Dio's receive window for this one call is
  // apiTimeout x 12 = 6 minutes, so the await outlived any map the user was
  // waiting on. `fetching`/`fetching2` start true and are cleared only after
  // the await, so the map spun until the process was restarted.

  test("a friends fetch that never answers stops blocking the map", () {
    fakeAsync((async) {
      final controller = Get.put(FindMyController());
      async.flushMicrotasks();

      expect(controller.fetching2.value, isTrue, reason: "starts loading");

      // The tunnel dropped it: the response never arrives.
      async.elapse(const Duration(minutes: 2));

      expect(
        controller.fetching2.value,
        isNot(isTrue),
        reason: "a fetch that never answers must not pin the loading state forever",
      );
    });
  });

  test("a devices fetch that never answers stops blocking the map", () {
    fakeAsync((async) {
      final controller = Get.put(FindMyController());
      async.flushMicrotasks();
      icloud.answer("refreshFriends");
      async.flushMicrotasks();

      expect(controller.fetching.value, isTrue, reason: "devices still loading");

      // getDevices is never answered.
      async.elapse(const Duration(minutes: 2));

      expect(
        controller.fetching.value,
        isNot(isTrue),
        reason: "a devices fetch that never answers must not pin the loading state forever",
      );
    });
  });

  test("a manual refresh that never answers releases the refresh button", () {
    fakeAsync((async) {
      final controller = Get.put(FindMyController());
      async.flushMicrotasks();
      icloud.answer("refreshFriends");
      async.flushMicrotasks();
      icloud.answer("getDevices");
      async.elapse(const Duration(seconds: 31));

      controller.refreshing.value = true;
      controller.refreshing2.value = true;
      controller.getLocations(refreshDevices: true);
      async.flushMicrotasks();
      icloud.answer("refreshFriends");
      async.flushMicrotasks();

      // The device refresh is the slow call that got cancelled; never answer it.
      async.elapse(const Duration(minutes: 2));

      expect(controller.refreshing.value, isFalse, reason: "spinner must not hang");
      expect(controller.canRefresh.value, isTrue, reason: "user must be able to retry");
    });
  });
}
