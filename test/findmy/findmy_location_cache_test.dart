import "package:bluebubbles/app/layouts/findmy/findmy_controller.dart";
import "package:bluebubbles/app/layouts/findmy/findmy_location_cache.dart";
import "package:bluebubbles/database/models.dart";
import "package:bluebubbles/services/services.dart";
import "package:fake_async/fake_async.dart";
import "package:flutter_test/flutter_test.dart" hide EventDispatcher;
import "package:get/get.dart" hide Response;

import "findmy_test_support.dart";

void main() {
  late FakeICloudApi icloud;

  setUp(() => icloud = registerFindMyServices());
  tearDown(resetFindMyServices);

  FakeFindMyPrefs prefs() => PrefsSvc.findMy as FakeFindMyPrefs;

  test("a burst of answers is written to disk once", () {
    fakeAsync((async) {
      Get.put(FindMyController());
      async.flushMicrotasks();

      icloud.answer("getDevices", data: [phoneJson]);
      icloud.answer("getFriends");
      async.flushMicrotasks();
      icloud.answer("refreshFriends");
      icloud.answer("refreshDevices", data: [phoneJson]);
      async.flushMicrotasks();
      expect(prefs().writes, 0, reason: "writes wait for the burst to settle");

      async.elapse(findMyLocationCacheSaveDelay);
      expect(prefs().writes, 1);
      expect(prefs().saved, contains("phone"));
    });
  });

  test("an undated friend fix is not cacheable", () {
    final undated = FindMyFriend(
      latitude: 44,
      longitude: -77,
      longAddress: null,
      shortAddress: null,
      title: null,
      subtitle: null,
      handle: null,
      handleAddress: "friend@example.com",
      lastUpdated: null,
      status: LocationStatus.live,
      locatingInProgress: false,
      favoriteOrder: null,
    );

    expect(cachedLocationForFriend(undated), isNull);
  });

  test("leaving the page writes what is still waiting", () {
    fakeAsync((async) {
      Get.put(FindMyController());
      async.flushMicrotasks();
      icloud.answer("getDevices", data: [phoneJson]);
      async.flushMicrotasks();
      expect(prefs().writes, 0);

      Get.delete<FindMyController>();
      async.flushMicrotasks();
      expect(prefs().writes, 1);
      async.elapse(findMyLocationCacheSaveDelay);
      expect(prefs().writes, 1);
    });
  });
}
