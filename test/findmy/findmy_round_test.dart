import "package:bluebubbles/app/layouts/findmy/findmy_controller.dart";
import "package:bluebubbles/app/layouts/findmy/findmy_refresh_progress.dart";
import "package:bluebubbles/services/services.dart";
import "package:fake_async/fake_async.dart";
import "package:flutter_test/flutter_test.dart" hide EventDispatcher;
import "package:get/get.dart" hide Response;

import "findmy_test_support.dart";

/// When the server's round began, in these tests.
final roundStart = DateTime(2026, 11, 5, 1);

/// A friend whose fix was taken [at]. No address: one would need the handle database.
Map<String, dynamic> friendJson(DateTime at) => {
  "coordinates": [33.02, -96.70],
  "short_address": "Plano, TX",
  "last_updated": at.millisecondsSinceEpoch,
};

Map<String, dynamic> round({required bool collecting, DateTime? startedAt}) => {
  "collecting": collecting,
  "startedAt": (startedAt ?? roundStart).millisecondsSinceEpoch,
};

void main() {
  late FakeICloudApi icloud;

  setUp(() => icloud = registerFindMyServices());
  tearDown(resetFindMyServices);

  /// Opens the page and answers its reads, leaving its refreshes waiting.
  FindMyController open(FakeAsync async, List<Map<String, dynamic>> friends) {
    final controller = Get.put(FindMyController(reportScreen: (_) {}));
    async.flushMicrotasks();
    icloud.answer("getFriends", data: friends);
    icloud.answer("getDevices", data: [phoneJson]);
    async.flushMicrotasks();
    return controller;
  }

  bool spinning(FindMyController controller) =>
      findMyFriendRowSpinning(controller.friendRefreshProgress.value, controller.friends.single);

  test("rejoining a round, a friend who reported during it does not spin", () {
    fakeAsync((async) {
      // The page reopens 40 s into the server's round; this friend reported 10 s into it
      final friends = [friendJson(roundStart.add(const Duration(seconds: 10)))];
      final controller = open(async, friends);
      icloud.answer("refreshFriends", data: friends, metadata: round(collecting: true));
      async.flushMicrotasks();

      expect(controller.friendRefreshProgress.value.startedAt, roundStart, reason: "the round's start, not the reopen");
      expect(spinning(controller), isFalse);
    });
  });

  test("rejoining a round, a friend with no location from it spins", () {
    fakeAsync((async) {
      final friends = [friendJson(roundStart.subtract(const Duration(minutes: 9)))];
      final controller = open(async, friends);
      icloud.answer("refreshFriends", data: friends, metadata: round(collecting: true));
      async.flushMicrotasks();

      expect(spinning(controller), isTrue);
    });
  });

  test("the round ending stops the rows still waiting", () {
    fakeAsync((async) {
      final friends = [friendJson(roundStart.subtract(const Duration(minutes: 9)))];
      final controller = open(async, friends);
      icloud.answer("refreshFriends", data: friends, metadata: round(collecting: true));
      async.flushMicrotasks();
      expect(spinning(controller), isTrue);

      EventDispatcherSvc.emit("findmy-round", round(collecting: false));
      async.flushMicrotasks();
      expect(controller.friendRefreshProgress.value.active, isFalse);
      expect(spinning(controller), isFalse);
    });
  });

  test("the end of an older round does not stop a newer one", () {
    fakeAsync((async) {
      final friends = [friendJson(roundStart.subtract(const Duration(minutes: 9)))];
      final controller = open(async, friends);
      icloud.answer("refreshFriends", data: friends, metadata: round(collecting: true));
      async.flushMicrotasks();

      EventDispatcherSvc.emit(
        "findmy-round",
        round(collecting: false, startedAt: roundStart.subtract(const Duration(minutes: 3))),
      );
      async.flushMicrotasks();
      expect(spinning(controller), isTrue);
    });
  });

  test("a round that has already ended spins nobody", () {
    fakeAsync((async) {
      final friends = [friendJson(roundStart.subtract(const Duration(minutes: 9)))];
      final controller = open(async, friends);
      icloud.answer("refreshFriends", data: friends, metadata: round(collecting: false));
      async.flushMicrotasks();

      expect(spinning(controller), isFalse);
    });
  });
}
