import "package:bluebubbles/app/layouts/findmy/findmy_controller.dart";
import "package:bluebubbles/app/layouts/findmy/findmy_refresh_progress.dart";
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

  setUp(() => icloud = registerFindMyServices());
  tearDown(resetFindMyServices);

  /// Opens the page and answers its reads, leaving its refreshes waiting.
  FindMyController open(FakeAsync async) {
    final controller = Get.put(FindMyController(reportScreen: (_) {}));
    async.flushMicrotasks();
    icloud.answer("getFriends", data: [staleFriendJson()]);
    icloud.answer("getDevices", data: [phoneJson]);
    async.flushMicrotasks();
    return controller;
  }

  bool spinning(FindMyController controller) =>
      findMyFriendRowSpinning(controller.friendRefreshProgress.value, controller.friends.single);

  test("opening the page leaves the cooldown to the server", () {
    fakeAsync((async) {
      open(async);

      expect(icloud.forced["refreshFriends"], [false]);
      expect(icloud.forced["refreshDevices"], [false]);
    });
  });

  test("coming back to the app leaves the cooldown to the server", () {
    fakeAsync((async) {
      final controller = open(async);
      icloud.answer("refreshFriends");
      icloud.answer("refreshDevices");
      async.flushMicrotasks();

      controller.onAppResumed();
      async.flushMicrotasks();
      expect(icloud.forced["refreshFriends"], [false, false]);
      expect(icloud.forced["refreshDevices"], [false, false]);
    });
  });

  test("the refresh button forces a relaunch for friends and devices", () {
    fakeAsync((async) {
      final controller = open(async);
      icloud.answer("refreshFriends");
      icloud.answer("refreshDevices");
      async.flushMicrotasks();

      controller.refreshLocations();
      async.flushMicrotasks();
      expect(icloud.forced["refreshFriends"], [false, true]);
      expect(icloud.forced["refreshDevices"], [false, true]);
    });
  });

  test("no row spins when the server says no new locations are coming", () {
    fakeAsync((async) {
      final controller = open(async);
      icloud.answer("refreshFriends", data: [staleFriendJson()], metadata: {"collecting": false});
      async.flushMicrotasks();

      expect(controller.friendRefreshProgress.value.active, isFalse);
      expect(spinning(controller), isFalse);
    });
  });

  test("rows spin while the server says new locations are coming", () {
    fakeAsync((async) {
      final controller = open(async);
      icloud.answer("refreshFriends", data: [staleFriendJson()], metadata: {"collecting": true});
      async.flushMicrotasks();

      expect(spinning(controller), isTrue);
    });
  });

  test("a server that does not say still has rows spin", () {
    fakeAsync((async) {
      final controller = open(async);
      icloud.answer("refreshFriends", data: [staleFriendJson()]);
      async.flushMicrotasks();

      expect(spinning(controller), isTrue);
    });
  });

  test("tapping refresh after a cooldown answer has rows spin again", () {
    fakeAsync((async) {
      final controller = open(async);
      icloud.answer("refreshFriends", data: [staleFriendJson()], metadata: {"collecting": false});
      icloud.answer("refreshDevices");
      async.flushMicrotasks();
      expect(spinning(controller), isFalse);

      controller.refreshLocations();
      async.flushMicrotasks();
      icloud.answer("refreshFriends", data: [staleFriendJson()], metadata: {"collecting": true});
      async.flushMicrotasks();
      expect(spinning(controller), isTrue);
    });
  });

  test("the refresh button is busy only while the server has yet to answer", () {
    fakeAsync((async) {
      final controller = open(async);
      icloud.answer("refreshFriends", data: [staleFriendJson()], metadata: {"collecting": true});
      icloud.answer("refreshDevices");
      async.flushMicrotasks();
      expect(controller.isRefreshing, isFalse, reason: "rows show who is still coming; the button does not");

      controller.refreshLocations();
      async.flushMicrotasks();
      expect(controller.isRefreshing, isTrue);
      icloud.answer("refreshFriends", data: [staleFriendJson()], metadata: {"collecting": true});
      icloud.answer("refreshDevices");
      async.flushMicrotasks();
      expect(controller.isRefreshing, isFalse);
    });
  });
}
