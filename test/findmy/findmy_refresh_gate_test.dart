import "dart:async";
import "dart:convert";

import "package:bluebubbles/app/layouts/findmy/findmy_controller.dart";
import "package:bluebubbles/app/layouts/findmy/findmy_load_state.dart";
import "package:bluebubbles/services/services.dart";
import "package:fake_async/fake_async.dart";
import "package:flutter/services.dart" show PlatformException;
import "package:flutter_test/flutter_test.dart" hide EventDispatcher;
import "package:geolocator_platform_interface/geolocator_platform_interface.dart";
import "package:get/get.dart" hide Response;
import "package:plugin_platform_interface/plugin_platform_interface.dart";

import "findmy_test_support.dart";

class ThrowingGeolocator extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  @override
  Future<LocationPermission> checkPermission() async => throw PlatformException(code: "unavailable");
}

/// A permission prompt the user never answers.
class SilentGeolocator extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  @override
  Future<LocationPermission> checkPermission() => Completer<LocationPermission>().future;
}

void main() {
  late FakeICloudApi icloud;

  setUp(() => icloud = registerFindMyServices());
  tearDown(resetFindMyServices);

  /// Opens the page and answers its opening load and refresh.
  FindMyController openIdlePage(FakeAsync async) {
    final controller = Get.put(FindMyController());
    async.flushMicrotasks();
    icloud.answer("getFriends");
    icloud.answer("getDevices");
    async.flushMicrotasks();
    icloud.answer("refreshFriends");
    icloud.answer("refreshDevices");
    async.flushMicrotasks();
    expect(controller.friendRefreshProgress.value.active, isFalse);
    return controller;
  }

  test("opening reads friends and devices at once, then refreshes both in the background", () {
    fakeAsync((async) {
      final controller = Get.put(FindMyController());
      async.flushMicrotasks();

      expect(icloud.pending("getFriends"), 1);
      expect(icloud.pending("getDevices"), 1);
      expect(icloud.requests["refreshFriends"], isNull);
      expect(icloud.requests["refreshDevices"], isNull);

      icloud.answer("getDevices", data: [phoneJson]);
      async.flushMicrotasks();
      expect(controller.devices.map((d) => d.id), ["phone"], reason: "each source renders as it arrives");
      expect(controller.friendsState.value.load, FindMyLoad.loading);
      expect(icloud.pending("refreshDevices"), 1);

      icloud.answer("getFriends");
      async.flushMicrotasks();
      expect(controller.friendsState.value.load, FindMyLoad.loaded);
      expect(icloud.pending("refreshFriends"), 1);
    });
  });

  test("Find My data does not wait on the location permission prompt", () {
    fakeAsync((async) {
      GeolocatorPlatform.instance = SilentGeolocator();
      Get.put(FindMyController());
      async.flushMicrotasks();

      expect(icloud.pending("getFriends"), 1);
      expect(icloud.pending("getDevices"), 1);
    });
  });

  test("a location permission check that throws does not hold up Find My data", () {
    fakeAsync((async) {
      GeolocatorPlatform.instance = ThrowingGeolocator();
      Get.put(FindMyController());
      async.flushMicrotasks();

      expect(icloud.pending("getFriends"), 1);
      expect(icloud.pending("getDevices"), 1);
    });
  });

  test("saved pins are on the map before the server answers", () {
    fakeAsync((async) {
      registerSavedCache({
        "version": 2,
        "server": "",
        "account": "",
        "entries": {},
        "devices": [phoneJson],
      });
      final controller = Get.put(FindMyController());

      expect(controller.devices.map((d) => d.id), ["phone"]);
      expect(controller.markers.keys, contains("phone"));
      expect(controller.devicesState.value.load, FindMyLoad.loading);
      async.flushMicrotasks();
    });
  });

  test("a cache from an older version still opens, without its roster", () {
    fakeAsync((async) {
      registerSavedCache({"server": "", "account": "", "entries": {}, "devices": [phoneJson]});
      final controller = Get.put(FindMyController());

      expect(controller.devices, isEmpty);
      async.flushMicrotasks();
      expect(icloud.pending("getDevices"), 1);
    });
  });

  test("a failed read shows as failed with its reason, not as an empty list", () {
    fakeAsync((async) {
      final controller = Get.put(FindMyController());
      async.flushMicrotasks();

      icloud.fail("getDevices");
      async.flushMicrotasks();

      expect(controller.devicesState.value.load, FindMyLoad.failed);
      expect(controller.devicesState.value.error, isNotEmpty);
      expect(controller.friendsState.value.load, FindMyLoad.loading);
    });
  });

  test("a devices response that fails to parse does not block friends", () {
    fakeAsync((async) {
      final controller = Get.put(FindMyController());
      async.flushMicrotasks();

      icloud.answer("getDevices", data: "not a list");
      async.flushMicrotasks();
      expect(controller.devicesState.value.load, FindMyLoad.failed);

      icloud.answer("getFriends");
      async.flushMicrotasks();
      expect(controller.friendsState.value.load, FindMyLoad.loaded);
    });
  });

  test("a refresh asks the server to refresh friends and devices together", () {
    fakeAsync((async) {
      final controller = openIdlePage(async);

      controller.refreshLocations();
      async.flushMicrotasks();
      expect(icloud.pending("refreshFriends"), 1);
      expect(icloud.pending("refreshDevices"), 1);
      expect(controller.friendsState.value.load, FindMyLoad.loading);
      expect(controller.devicesState.value.load, FindMyLoad.loading);

      icloud.answer("refreshFriends");
      icloud.answer("refreshDevices");
      async.flushMicrotasks();
      expect(controller.friendsState.value.load, FindMyLoad.loaded);
      expect(controller.devicesState.value.load, FindMyLoad.loaded);
    });
  });

  test("a second refresh while one is running does not start another", () {
    fakeAsync((async) {
      final controller = openIdlePage(async);

      controller.refreshLocations();
      async.flushMicrotasks();
      controller.refreshLocations();
      async.flushMicrotasks();

      expect(icloud.requests["refreshDevices"], hasLength(2), reason: "one from opening, one from the refresh");
      expect(icloud.tokens["refreshDevices"]!.last!.isCancelled, isFalse);
      icloud.answer("refreshFriends");
      icloud.answer("refreshDevices");
      async.flushMicrotasks();
    });
  });

  test("a friends response that fails to parse still loads devices", () {
    fakeAsync((async) {
      final controller = openIdlePage(async);

      controller.refreshLocations();
      async.flushMicrotasks();
      icloud.answer("refreshFriends", data: "not a list");
      icloud.answer("refreshDevices", data: [phoneJson]);
      async.flushMicrotasks();

      expect(controller.friendsState.value.load, FindMyLoad.failed);
      expect(controller.devices.map((d) => d.id), ["phone"]);
    });
  });

  test("a refresh ends as soon as the server has answered and nobody is left to report", () {
    fakeAsync((async) {
      final controller = Get.put(FindMyController());
      async.flushMicrotasks();
      icloud.answer("getFriends");
      icloud.answer("getDevices");
      async.flushMicrotasks();
      icloud.answer("refreshFriends");
      async.flushMicrotasks();
      expect(controller.friendRefreshProgress.value.active, isTrue, reason: "the device refresh is still out");

      icloud.answer("refreshDevices");
      async.flushMicrotasks();
      expect(controller.friendRefreshProgress.value.active, isFalse);
    });
  });
}

/// Puts [json] where the location cache reads it from.
void registerSavedCache(Map<String, dynamic> json) {
  (PrefsSvc.findMy as FakeFindMyPrefs).saved = jsonEncode(json);
}

