import "package:bluebubbles/app/layouts/findmy/findmy_controller.dart";
import "package:bluebubbles/app/layouts/findmy/findmy_load_state.dart";
import "package:bluebubbles/app/layouts/findmy/findmy_refresh_progress.dart";
import "package:bluebubbles/services/services.dart";
import "package:fake_async/fake_async.dart";
import "package:flutter_test/flutter_test.dart" hide EventDispatcher;
import "package:get/get.dart" hide Response;

import "findmy_test_support.dart";

/// A friend whose saved fix is from well before any refresh in these tests.
Map<String, dynamic> staleFriendJson() => {
  "coordinates": [33.02, -96.70],
  "short_address": "Plano, TX",
  "last_updated": DateTime(2026).millisecondsSinceEpoch,
};

void main() {
  late FakeICloudApi icloud;
  late List<bool> screenReports;

  setUp(() {
    icloud = registerFindMyServices();
    screenReports = [];
  });
  tearDown(resetFindMyServices);

  FindMyController open() => Get.put(FindMyController(reportScreen: screenReports.add));

  /// Answers the reads the page opens with.
  void answerReads(FakeAsync async) {
    icloud.answer("getFriends", data: [staleFriendJson()]);
    icloud.answer("getDevices", data: [phoneJson]);
    async.flushMicrotasks();
  }

  test("opening the page asks the server to refresh friends and devices", () {
    fakeAsync((async) {
      open();
      async.flushMicrotasks();
      answerReads(async);

      expect(icloud.pending("refreshFriends"), 1);
      expect(icloud.pending("refreshDevices"), 1, reason: "there is no refresh button, so opening covers devices too");
    });
  });

  test("rows keep spinning past 30 seconds: no clock ends a refresh", () {
    fakeAsync((async) {
      final controller = open();
      async.flushMicrotasks();
      answerReads(async);
      icloud.answer("refreshFriends", data: [staleFriendJson()]);
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 45));
      expect(controller.friendRefreshProgress.value.active, isTrue);
      expect(findMyFriendRowSpinning(controller.friendRefreshProgress.value, controller.friends.single), isTrue);
    });
  });

  test("the page tells the server when its screen opens and closes", () {
    fakeAsync((async) {
      open();
      async.flushMicrotasks();
      expect(screenReports, [true]);

      Get.delete<FindMyController>();
      async.flushMicrotasks();
      expect(screenReports, [true, false]);
    });
  });

  test("coming back to the app refreshes friends and devices again", () {
    fakeAsync((async) {
      final controller = open();
      async.flushMicrotasks();
      answerReads(async);
      icloud.answer("refreshFriends");
      icloud.answer("refreshDevices", data: [phoneJson]);
      async.flushMicrotasks();

      controller.onAppResumed();
      async.flushMicrotasks();
      expect(icloud.pending("refreshFriends"), 1);
      expect(icloud.pending("refreshDevices"), 1);
      expect(screenReports.last, isTrue, reason: "the screen is reported open again after a resume");
    });
  });

  test("a failed load retries by itself when the connection to the server comes back", () {
    fakeAsync((async) {
      final controller = open();
      async.flushMicrotasks();
      icloud.fail("getDevices");
      async.flushMicrotasks();
      expect(controller.devicesState.value.load, FindMyLoad.failed);

      controller.onConnectionRestored();
      async.flushMicrotasks();
      expect(icloud.requests["getDevices"], hasLength(2));
    });
  });

  test("a reconnect with nothing failed reports the screen open again and loads nothing", () {
    fakeAsync((async) {
      final controller = open();
      async.flushMicrotasks();
      answerReads(async);
      icloud.answer("refreshFriends");
      icloud.answer("refreshDevices", data: [phoneJson]);
      async.flushMicrotasks();
      screenReports.clear();

      controller.onConnectionRestored();
      async.flushMicrotasks();
      expect(screenReports, [true], reason: "the server knows each connection separately");
      expect(icloud.requests["getDevices"], hasLength(1));
      expect(icloud.requests["refreshDevices"], hasLength(1));
    });
  });

  test("devices the server pushes replace the list as they arrive", () {
    fakeAsync((async) {
      final controller = open();
      async.flushMicrotasks();
      expect(controller.devices, isEmpty);

      EventDispatcherSvc.emit("findmy-devices-updated", [phoneJson]);
      async.flushMicrotasks();
      expect(controller.devices.map((device) => device.id), ["phone"]);
    });
  });
}
