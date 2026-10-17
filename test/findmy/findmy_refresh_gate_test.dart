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

/// Holds every Find My request open until the test answers it.
class FakeICloudApi extends iCloudApi {
  FakeICloudApi(super.svc);

  final Map<String, List<Completer<Response>>> requests = {};

  Future<Response> _request(String name) {
    final completer = Completer<Response>();
    requests.putIfAbsent(name, () => []).add(completer);
    return completer.future;
  }

  void answer(String name) => requests[name]!
      .removeAt(0)
      .complete(
        Response(
          requestOptions: RequestOptions(path: ""),
          statusCode: 200,
          data: {"data": []},
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

  /// Opens the page and lets its initial load and refresh window run out.
  FindMyController openIdlePage(FakeAsync async) {
    final controller = Get.put(FindMyController());
    async.flushMicrotasks();
    icloud.answer("refreshFriends");
    async.flushMicrotasks();
    icloud.answer("getDevices");
    async.elapse(const Duration(seconds: 31));
    expect(controller.canRefresh.value, isTrue);
    return controller;
  }

  test("manual refresh shows progress for one window that starts with the refresh", () {
    fakeAsync((async) {
      final controller = openIdlePage(async);

      controller.getLocations(refreshDevices: true);
      expect(controller.canRefresh.value, isFalse);

      async.flushMicrotasks();
      icloud.answer("refreshFriends");
      async.elapse(const Duration(seconds: 23));
      expect(controller.canRefresh.value, isFalse);
      expect(controller.friendRefreshProgress.value.active, isTrue);

      icloud.answer("refreshDevices");
      async.elapse(const Duration(seconds: 6));
      expect(controller.canRefresh.value, isFalse);

      async.elapse(const Duration(seconds: 1));
      expect(controller.canRefresh.value, isTrue);
      expect(controller.friendRefreshProgress.value.active, isFalse);
    });
  });

  test("a cached-roster refresh shows progress at once and still asks the server to push friends", () {
    fakeAsync((async) {
      final controller = openIdlePage(async);

      controller.getLocations(refreshFriends: false);
      expect(controller.canRefresh.value, isFalse);

      async.flushMicrotasks();
      icloud.answer("getFriends");
      async.elapse(const Duration(seconds: 23));
      icloud.answer("getDevices");
      async.flushMicrotasks();
      expect(icloud.requests["refreshFriends"], hasLength(1));
      expect(controller.friendRefreshProgress.value.active, isTrue);

      async.elapse(const Duration(seconds: 7));
      expect(controller.canRefresh.value, isTrue);
      expect(controller.friendRefreshProgress.value.active, isFalse);
    });
  });

  test("a cached-roster refresh that outlasts its window does not reopen progress", () {
    fakeAsync((async) {
      final controller = openIdlePage(async);

      controller.getLocations(refreshFriends: false);
      async.flushMicrotasks();
      icloud.answer("getFriends");
      async.elapse(const Duration(seconds: 31));
      expect(controller.canRefresh.value, isTrue);

      icloud.answer("getDevices");
      async.flushMicrotasks();
      expect(icloud.requests["refreshFriends"], hasLength(1));
      expect(controller.canRefresh.value, isTrue);
      expect(controller.friendRefreshProgress.value.active, isFalse);
    });
  });
}
