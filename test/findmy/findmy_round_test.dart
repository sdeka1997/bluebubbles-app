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
Map<String, dynamic> friendJson(DateTime at, {bool locating = false}) => {
  "coordinates": [33.02, -96.70],
  "short_address": "Plano, TX",
  "last_updated": at.millisecondsSinceEpoch,
  "is_locating_in_progress": locating,
};

/// A round as the server announces it; [id] is left out, as servers before round ids send it.
Map<String, dynamic> round({required bool collecting, DateTime? startedAt, int? id}) => {
  "collecting": collecting,
  "startedAt": (startedAt ?? roundStart).millisecondsSinceEpoch,
  "id": ?id,
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
      final friends = [friendJson(roundStart.subtract(const Duration(minutes: 9)), locating: true)];
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

  test("a round's end is matched by its id, not its start time", () {
    fakeAsync((async) {
      final friends = [friendJson(roundStart.subtract(const Duration(minutes: 9)))];
      final controller = open(async, friends);
      icloud.answer("refreshFriends", data: friends, metadata: round(collecting: true, id: 2));
      async.flushMicrotasks();

      // Round 1 started at the same moment, as far as clocks can tell; it is still not this round
      EventDispatcherSvc.emit("findmy-round", round(collecting: false, id: 1));
      async.flushMicrotasks();
      expect(spinning(controller), isTrue);

      EventDispatcherSvc.emit("findmy-round", round(collecting: false, id: 2));
      async.flushMicrotasks();
      expect(spinning(controller), isFalse);
    });
  });

  test("a new round after the last one ended spins the rows it waits on again", () {
    fakeAsync((async) {
      final friends = [friendJson(roundStart.subtract(const Duration(minutes: 9)))];
      final controller = open(async, friends);
      icloud.answer("refreshFriends", data: friends, metadata: round(collecting: true, id: 1));
      async.flushMicrotasks();
      EventDispatcherSvc.emit("findmy-round", round(collecting: false, id: 1));
      async.flushMicrotasks();
      expect(spinning(controller), isFalse);

      final next = roundStart.add(const Duration(minutes: 10));
      EventDispatcherSvc.emit("findmy-round", round(collecting: true, id: 2, startedAt: next));
      async.flushMicrotasks();
      expect(controller.friendRefreshProgress.value.startedAt, next);
      expect(spinning(controller), isTrue);
    });
  });

  test("a round announced again does not restart the wait", () {
    fakeAsync((async) {
      final friends = [friendJson(roundStart.subtract(const Duration(minutes: 9)))];
      final controller = open(async, friends);
      icloud.answer("refreshFriends", data: friends, metadata: round(collecting: true, id: 1));
      async.flushMicrotasks();
      final before = controller.friendRefreshProgress.value;

      EventDispatcherSvc.emit("findmy-round", round(collecting: true, id: 1));
      async.flushMicrotasks();
      expect(identical(controller.friendRefreshProgress.value, before), isTrue);
    });
  });

  test("a refresh answer from an older round cannot pull the page back to it", () {
    fakeAsync((async) {
      final friends = [friendJson(roundStart.subtract(const Duration(minutes: 9)))];
      final controller = open(async, friends);
      final next = roundStart.add(const Duration(minutes: 10));
      // Another client forced a new round; its socket event beat this page's own answer
      EventDispatcherSvc.emit("findmy-round", round(collecting: true, id: 2, startedAt: next));
      async.flushMicrotasks();
      icloud.answer("refreshFriends", data: friends, metadata: round(collecting: true, id: 1));
      async.flushMicrotasks();
      expect(controller.friendRefreshProgress.value.roundId, 2);

      EventDispatcherSvc.emit("findmy-round", round(collecting: false, id: 2, startedAt: next));
      async.flushMicrotasks();
      expect(spinning(controller), isFalse);
    });
  });

  test("an older round's end in a late refresh answer does not stop a newer round", () {
    fakeAsync((async) {
      final friends = [friendJson(roundStart.subtract(const Duration(minutes: 9)))];
      final controller = open(async, friends);
      final next = roundStart.add(const Duration(minutes: 10));
      EventDispatcherSvc.emit("findmy-round", round(collecting: true, id: 2, startedAt: next));
      async.flushMicrotasks();
      icloud.answer("refreshFriends", data: friends, metadata: round(collecting: false, id: 1));
      async.flushMicrotasks();

      expect(spinning(controller), isTrue);
    });
  });

  test("the end of a later round also ends the one this page follows", () {
    fakeAsync((async) {
      final friends = [friendJson(roundStart.subtract(const Duration(minutes: 9)))];
      final controller = open(async, friends);
      icloud.answer("refreshFriends", data: friends, metadata: round(collecting: true, id: 1));
      async.flushMicrotasks();

      // Rounds run one after another, so round 2 ending means round 1 is long over
      EventDispatcherSvc.emit("findmy-round", round(collecting: false, id: 2));
      async.flushMicrotasks();
      expect(spinning(controller), isFalse);
    });
  });

  test("a round start without an id, from an older server, changes nothing", () {
    fakeAsync((async) {
      final friends = [friendJson(roundStart.subtract(const Duration(minutes: 9)))];
      final controller = open(async, friends);
      icloud.answer("refreshFriends", data: friends, metadata: round(collecting: true));
      async.flushMicrotasks();
      final before = controller.friendRefreshProgress.value;

      EventDispatcherSvc.emit(
        "findmy-round",
        round(collecting: true, startedAt: roundStart.add(const Duration(minutes: 10))),
      );
      async.flushMicrotasks();
      expect(identical(controller.friendRefreshProgress.value, before), isTrue);
    });
  });
}
