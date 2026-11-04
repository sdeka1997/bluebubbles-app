import "package:bluebubbles/app/layouts/findmy/findmy_controller.dart";
import "package:bluebubbles/app/layouts/findmy/findmy_load_state.dart";
import "package:fake_async/fake_async.dart";
import "package:flutter_test/flutter_test.dart" hide EventDispatcher;
import "package:get/get.dart" hide Response;

import "findmy_test_support.dart";

void main() {
  late FakeICloudApi icloud;

  setUp(() => icloud = registerFindMyServices());
  tearDown(resetFindMyServices);

  // Observed 2026-10-31 20:36: the phone POSTed /findmy/devices/refresh, the
  // Cloudflare tunnel tore the connection down ("Incoming request ended
  // abruptly: context canceled"), and the server finished the work 24.8 s
  // later into a socket nobody held. Dio's receive window for this one call is
  // apiTimeout x 12 = 6 minutes, so a request that never answers has to be
  // bounded by the page itself.

  test("a read that never answers fails at its deadline and is cancelled", () {
    fakeAsync((async) {
      final controller = Get.put(FindMyController());
      async.flushMicrotasks();
      expect(controller.friendsState.value.load, FindMyLoad.loading);
      expect(controller.devicesState.value.load, FindMyLoad.loading);

      async.elapse(FindMyController.readDeadline);

      expect(controller.friendsState.value.load, FindMyLoad.failed);
      expect(controller.devicesState.value.load, FindMyLoad.failed);
      expect(controller.devicesState.value.error, isNotNull);
      expect(icloud.tokens["getDevices"]!.single!.isCancelled, isTrue);
    });
  });

  test("a device refresh that never answers releases the refresh button", () {
    fakeAsync((async) {
      final controller = Get.put(FindMyController());
      async.flushMicrotasks();
      icloud.answer("getFriends");
      icloud.answer("getDevices");
      async.flushMicrotasks();
      icloud.answer("refreshFriends");
      async.elapse(const Duration(minutes: 1));
      expect(controller.isRefreshing, isFalse);

      controller.refreshLocations(refreshDevices: true);
      async.flushMicrotasks();
      icloud.answer("refreshFriends");
      async.elapse(FindMyController.deviceRefreshDeadline);

      expect(controller.devicesState.value.load, FindMyLoad.failed);
      expect(controller.isRefreshing, isFalse, reason: "the user must be able to try again");
      expect(icloud.tokens["refreshDevices"]!.single!.isCancelled, isTrue);
    });
  });

  test("an answer that arrives after its deadline is ignored", () {
    fakeAsync((async) {
      icloud.honourCancel = false;
      final controller = Get.put(FindMyController());
      async.flushMicrotasks();
      async.elapse(FindMyController.readDeadline);
      expect(controller.devicesState.value.load, FindMyLoad.failed);

      icloud.answer("getDevices", data: [phoneJson]);
      async.flushMicrotasks();

      expect(controller.devices, isEmpty);
      expect(controller.devicesState.value.load, FindMyLoad.failed);
    });
  });

  test("a manual refresh cancels the opening load and ignores its late answers", () {
    fakeAsync((async) {
      icloud.honourCancel = false;
      final controller = Get.put(FindMyController());
      async.flushMicrotasks();

      controller.refreshLocations(refreshDevices: true);
      async.flushMicrotasks();
      expect(icloud.tokens["getDevices"]!.single!.isCancelled, isTrue);
      expect(icloud.tokens["getFriends"]!.single!.isCancelled, isTrue);

      icloud.answer("getDevices", data: [phoneJson]);
      async.flushMicrotasks();
      expect(controller.devices, isEmpty, reason: "the superseded load must not write state");
      expect(controller.devicesState.value.load, FindMyLoad.loading);

      icloud.answer("refreshDevices", data: [phoneJson]);
      async.flushMicrotasks();
      expect(controller.devices.map((d) => d.id), ["phone"]);
      expect(controller.devicesState.value.load, FindMyLoad.loaded);
    });
  });

  test("closing the page cancels what is in flight", () {
    fakeAsync((async) {
      Get.put(FindMyController());
      async.flushMicrotasks();
      Get.delete<FindMyController>();
      async.flushMicrotasks();

      expect(icloud.tokens["getFriends"]!.single!.isCancelled, isTrue);
      expect(icloud.tokens["getDevices"]!.single!.isCancelled, isTrue);
    });
  });
}
