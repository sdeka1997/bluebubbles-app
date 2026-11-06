import "package:bluebubbles/app/layouts/findmy/findmy_controller.dart";
import "package:bluebubbles/app/layouts/findmy/findmy_selection.dart";
import "package:bluebubbles/database/models.dart";
import "package:fake_async/fake_async.dart";
import "package:flutter_test/flutter_test.dart" hide EventDispatcher;
import "package:get/get.dart" hide Response;
import "package:latlong2/latlong.dart";

import "findmy_test_support.dart";

FindMyFriend friend({String? address}) => FindMyFriend(
  latitude: 33,
  longitude: -96,
  longAddress: null,
  shortAddress: null,
  title: "Friend",
  subtitle: null,
  handle: null,
  handleAddress: address,
  lastUpdated: DateTime(2026),
  status: LocationStatus.shallow,
  locatingInProgress: false,
  favoriteOrder: null,
);

void main() {
  group("FindMySelection", () {
    test("a friend is selected by Apple's address and keeps it as the handle to track", () {
      final selection = FindMySelection.ofFriend(friend(address: "friend@example.com"));
      expect(selection.kind, FindMySelectionKind.friend);
      expect(selection.id, "friend@example.com");
      expect(selection.handle, "friend@example.com");
      expect(selection.markerKey, "friend-friend@example.com");
    });

    test("a friend without an address can be selected but has no handle to track", () {
      final selection = FindMySelection.ofFriend(friend());
      expect(selection.kind, FindMySelectionKind.friend);
      expect(selection.handle, isNull);
    });

    test("a real address that looks like a local identity still has a handle", () {
      final selection = FindMySelection.ofFriend(friend(address: "anonymous-x@icloud.com"));
      expect(selection.handle, "anonymous-x@icloud.com");
    });

    test("a device has no handle to track", () {
      const selection = FindMySelection.device("phone");
      expect(selection.markerKey, "device-phone");
      expect(selection.handle, isNull);
    });

    test("a marker key reads back as the selection it came from", () {
      expect(FindMySelection.fromMarkerKey("device-phone"), const FindMySelection.device("phone"));
      expect(FindMySelection.fromMarkerKey("friend-friend@example.com")?.id, "friend@example.com");
      expect(FindMySelection.fromMarkerKey("friend-friend@example.com")?.kind, FindMySelectionKind.friend);
    });

    test("keys that are not a person or product select nothing", () {
      expect(FindMySelection.fromMarkerKey("current"), isNull);
      expect(FindMySelection.fromMarkerKey("group:abc"), isNull);
      expect(FindMySelection.fromMarkerKey("device-"), isNull);
    });

    test("two selections of the same friend are equal, whatever object they came from", () {
      final a = FindMySelection.ofFriend(friend(address: "friend@example.com"));
      final b = FindMySelection.ofFriend(friend(address: "friend@example.com"));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const FindMySelection.device("friend@example.com")));
    });
  });

  group("FindMyController selection", () {
    setUp(registerFindMyServices);
    tearDown(resetFindMyServices);

    test("selecting a friend exposes the handle to track; selecting a device clears it", () {
      fakeAsync((async) {
        final controller = Get.put(FindMyController(reportScreen: (_, _) {}));
        async.flushMicrotasks();

        controller.select(FindMySelection.ofFriend(friend(address: "friend@example.com")), const LatLng(33, -96));
        expect(controller.selectedFriendHandle, "friend@example.com");

        controller.select(const FindMySelection.device("phone"), const LatLng(33, -96));
        expect(controller.selectedFriendHandle, isNull);
      });
    });

    test("a friend selected from their map pin still yields their address to track", () {
      fakeAsync((async) {
        final controller = Get.put(FindMyController(reportScreen: (_, _) {}));
        async.flushMicrotasks();
        final shown = friend(address: "friend@example.com");
        controller.friends.value = [shown];

        final fromPin = FindMySelection.fromMarkerKey(FindMySelection.ofFriend(shown).markerKey)!;
        controller.select(fromPin, const LatLng(33, -96));
        expect(controller.selectedFriendHandle, "friend@example.com");
      });
    });

    test("switching tabs clears the selection", () {
      fakeAsync((async) {
        final controller = Get.put(FindMyController(reportScreen: (_, _) {}));
        async.flushMicrotasks();
        controller.select(FindMySelection.ofFriend(friend(address: "friend@example.com")), const LatLng(33, -96));

        controller.tabIndex.value = 1;
        async.flushMicrotasks();
        expect(controller.selection.value, isNull);
        expect(controller.selectedFriendHandle, isNull);
      });
    });
  });
}
