import "dart:async";

import "package:bluebubbles/app/layouts/findmy/findmy_controller.dart";
import "package:bluebubbles/app/layouts/findmy/findmy_load_state.dart";
import "package:bluebubbles/app/layouts/findmy/findmy_selection.dart";
import "package:bluebubbles/database/models.dart";
import "package:bluebubbles/services/services.dart";
import "package:fake_async/fake_async.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart" hide EventDispatcher;
import "package:get/get.dart" hide Response;
import "package:latlong2/latlong.dart";

import "findmy_test_support.dart";

/// A friend whose saved fix is old, and whom Apple says it is still locating.
Map<String, dynamic> staleFriendJson() => {
  "coordinates": [33.02, -96.70],
  "short_address": "Plano, TX",
  "last_updated": DateTime(2026).millisecondsSinceEpoch,
  "is_locating_in_progress": true,
};

/// A friend with Apple's address for them, built directly: parsing one from
/// JSON would look the address up in the handle database.
FindMyFriend friend(String address, {DateTime? at}) => FindMyFriend(
  latitude: 33,
  longitude: -96,
  longAddress: null,
  shortAddress: "Plano, TX",
  title: "Friend",
  subtitle: null,
  handle: null,
  handleAddress: address,
  lastUpdated: at ?? DateTime(2026),
  status: LocationStatus.shallow,
  locatingInProgress: false,
  favoriteOrder: null,
);

void main() {
  late FakeICloudApi icloud;
  /// Each findmy-screen report: null when the screen closed, else who is selected ("" for nobody).
  late List<String?> screenReports;

  setUp(() {
    icloud = registerFindMyServices();
    screenReports = [];
  });
  tearDown(resetFindMyServices);

  FindMyController open() => Get.put(
    FindMyController(reportScreen: (open, handle) => screenReports.add(open ? handle ?? "" : null)),
  );

  /// Answers the reads the page opens with.
  void answerReads(FakeAsync async, {List<Map<String, dynamic>> friends = const []}) {
    icloud.answer("getFriends", data: friends);
    icloud.answer("getDevices", data: [phoneJson]);
    async.flushMicrotasks();
  }

  /// Opens the page inside an app, as a selected pin reads the theme, with
  /// [shown] on it and the reads answered.
  Future<FindMyController> openWith(WidgetTester tester, List<FindMyFriend> shown) async {
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));
    final controller = open();
    await tester.pump();
    icloud.answer("getFriends");
    icloud.answer("getDevices", data: [phoneJson]);
    await tester.pump();
    controller.friends.value = shown;
    return controller;
  }

  /// Closes the page and lets its timers run out, so none is left pending.
  Future<void> close(WidgetTester tester) async {
    if (Get.isRegistered<FindMyController>()) Get.delete<FindMyController>();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 1));
  }

  Future<void> tap(WidgetTester tester, FindMyController controller, FindMyFriend person) async {
    unawaited(controller.select(FindMySelection.ofFriend(person), const LatLng(33, -96)));
    await tester.pump();
  }


  group("opening and closing", () {
    test("opening reads what the server has and asks it for nothing else", () {
      fakeAsync((async) {
        final controller = open();
        async.flushMicrotasks();
        answerReads(async, friends: [staleFriendJson()]);
        async.elapse(const Duration(minutes: 2));

        expect(icloud.requests.keys.toSet(), {"getFriends", "getDevices"});
        expect(controller.friendsState.value.load, FindMyLoad.loaded);
        expect(controller.devices.map((d) => d.id), ["phone"]);
      });
    });

    test("no row spins on opening, even for a friend Apple is still locating", () {
      fakeAsync((async) {
        final controller = open();
        async.flushMicrotasks();
        answerReads(async, friends: [staleFriendJson()]);

        expect(controller.isLocatingLive(controller.friends.single), isFalse);
      });
    });

    test("the page tells the server when its screen opens and closes", () {
      fakeAsync((async) {
        open();
        async.flushMicrotasks();
        expect(screenReports, [""]);

        Get.delete<FindMyController>();
        async.flushMicrotasks();
        expect(screenReports, ["", null]);
      });
    });

    test("coming back to the app reports the screen open and reads again", () {
      fakeAsync((async) {
        final controller = open();
        async.flushMicrotasks();
        answerReads(async);

        controller.onAppPaused();
        controller.onAppResumed();
        async.flushMicrotasks();
        expect(screenReports, ["", null, ""]);
        expect(icloud.pending("getFriends"), 1);
        expect(icloud.pending("getDevices"), 1);
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
        screenReports.clear();

        controller.onConnectionRestored();
        async.flushMicrotasks();
        expect(screenReports, [""], reason: "the server knows each connection separately");
        expect(icloud.requests["getDevices"], hasLength(1));
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
  });

  group("tapping a person", () {
    testWidgets("tells the server who is selected, which it follows live", (tester) async {
      final mom = friend("mom@example.com");
      final dad = friend("dad@example.com");
      final controller = await openWith(tester, [mom, dad]);

      await tap(tester, controller, mom);
      await tap(tester, controller, dad);
      expect(screenReports.skip(1), ["mom@example.com", "dad@example.com"]);
      expect(icloud.requests.keys.toSet(), {"getFriends", "getDevices"}, reason: "the selection rides on the screen report");
      await close(tester);
    });

    testWidgets("their row spins until their next location arrives", (tester) async {
      final mom = friend("mom@example.com");
      final controller = await openWith(tester, [mom]);

      await tap(tester, controller, mom);
      expect(controller.isLocatingLive(mom), isTrue);

      controller.onFriendLocation(friend("mom@example.com", at: DateTime.now().add(const Duration(seconds: 1))));
      expect(controller.isLocatingLive(controller.friends.single), isFalse);
      await close(tester);
    });

    testWidgets("only the tapped person's row spins", (tester) async {
      final mom = friend("mom@example.com");
      final dad = friend("dad@example.com");
      final controller = await openWith(tester, [mom, dad]);

      await tap(tester, controller, mom);
      expect(controller.isLocatingLive(mom), isTrue);
      expect(controller.isLocatingLive(dad), isFalse);

      controller.onFriendLocation(friend("dad@example.com", at: DateTime(2026, 6)));
      expect(controller.isLocatingLive(mom), isTrue, reason: "someone else's update does not count");
      await close(tester);
    });

    testWidgets("a location from before the tap does not stop the spinner", (tester) async {
      final mom = friend("mom@example.com", at: DateTime(2026, 6));
      final controller = await openWith(tester, [mom]);

      await tap(tester, controller, mom);
      controller.onFriendLocation(friend("mom@example.com", at: DateTime(2026, 6)));
      expect(controller.isLocatingLive(mom), isTrue);
      await close(tester);
    });

    testWidgets("the spinner stops by itself if no location comes, as Find My's does", (tester) async {
      final mom = friend("mom@example.com");
      final controller = await openWith(tester, [mom]);

      await tap(tester, controller, mom);
      await tester.pump(FindMyController.liveLocatingLimit);
      expect(controller.isLocatingLive(mom), isFalse);
      expect(screenReports.last, "mom@example.com", reason: "she stays selected, and followed");
      await close(tester);
    });

    testWidgets("selecting a device, clearing the selection or switching tabs selects nobody", (tester) async {
      final mom = friend("mom@example.com");
      final controller = await openWith(tester, [mom]);

      await tap(tester, controller, mom);
      unawaited(controller.select(const FindMySelection.device("phone"), const LatLng(33, -96)));
      await tester.pump();
      expect(screenReports.last, "");
      expect(controller.isLocatingLive(mom), isFalse);

      await tap(tester, controller, mom);
      controller.clearSelection();
      await tester.pump();
      expect(screenReports.last, "");

      await tap(tester, controller, mom);
      controller.tabIndex.value = 1;
      await tester.pump();
      expect(screenReports.last, "");
      await close(tester);
    });

    testWidgets("tapping the selected person again reports nothing new", (tester) async {
      final mom = friend("mom@example.com");
      final controller = await openWith(tester, [mom]);

      await tap(tester, controller, mom);
      await tap(tester, controller, mom);
      expect(screenReports, ["", "mom@example.com"]);
      await close(tester);
    });

    testWidgets("a friend Apple gave no address can be selected, but names nobody to follow", (tester) async {
      final unnamed = FindMyFriend.fromJson(staleFriendJson());
      final controller = await openWith(tester, [unnamed]);

      await tap(tester, controller, unnamed);
      expect(screenReports, [""]);
      expect(controller.isLocatingLive(unnamed), isFalse);
      await close(tester);
    });

    testWidgets("closing the page reports the screen closed: quitting Find My ends the follow", (tester) async {
      final mom = friend("mom@example.com");
      final controller = await openWith(tester, [mom]);
      await tap(tester, controller, mom);

      await close(tester);
      expect(screenReports, ["", "mom@example.com", null]);
    });

    testWidgets("leaving and coming back reports the selected person again with the screen", (tester) async {
      final mom = friend("mom@example.com");
      final controller = await openWith(tester, [mom]);
      await tap(tester, controller, mom);

      controller.onAppPaused();
      expect(controller.isLocatingLive(mom), isFalse, reason: "Find My quit on the Mac");
      controller.onAppResumed();
      await tester.pump();
      expect(screenReports, ["", "mom@example.com", null, "mom@example.com"]);
      expect(controller.isLocatingLive(mom), isTrue, reason: "a fresh Find My locates her again");
      await close(tester);
    });

    testWidgets("a reconnect reports the selected person again with the screen", (tester) async {
      final mom = friend("mom@example.com");
      final controller = await openWith(tester, [mom]);
      await tap(tester, controller, mom);

      controller.onConnectionRestored();
      await tester.pump();
      expect(screenReports, ["", "mom@example.com", "mom@example.com"]);
      await close(tester);
    });
  });
}
