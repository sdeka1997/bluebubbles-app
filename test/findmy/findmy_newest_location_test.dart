import "package:bluebubbles/app/layouts/findmy/findmy_location_cache.dart";
import "package:bluebubbles/database/models.dart";
import "package:flutter_test/flutter_test.dart";

final yesterday = DateTime(2026, 11, 3, 18);
final today = DateTime(2026, 11, 4, 10, 20);

FindMyFriend friend({double? latitude, double? longitude, DateTime? lastUpdated}) => FindMyFriend(
  latitude: latitude,
  longitude: longitude,
  longAddress: null,
  shortAddress: latitude == null ? null : "Old place",
  title: "Alice",
  subtitle: null,
  handle: null,
  handleAddress: "alice",
  lastUpdated: lastUpdated,
  status: null,
  locatingInProgress: false,
  favoriteOrder: 2,
);

FindMyCachedLocation cachedAt(DateTime when) => FindMyCachedLocation(
  latitude: 33.02,
  longitude: -96.70,
  timestamp: when.millisecondsSinceEpoch,
  label: "New place",
);

void main() {
  test("a saved fix newer than the friend's own replaces it", () {
    final shown = newestFriendLocation(friend(latitude: 32.78, longitude: -96.80, lastUpdated: yesterday), cachedAt(today));

    expect(shown.latitude, 33.02);
    expect(shown.longitude, -96.70);
    expect(shown.lastUpdated, today);
    expect(shown.shortAddress, "New place");
    expect(shown.title, "Alice");
    expect(shown.favoriteOrder, 2);
  });

  test("the friend's own fix stays when it is the newer one", () {
    final own = friend(latitude: 32.78, longitude: -96.80, lastUpdated: today);

    expect(newestFriendLocation(own, cachedAt(yesterday)), same(own));
  });

  test("a fix with the same time as the saved one stays as sent", () {
    final own = friend(latitude: 32.78, longitude: -96.80, lastUpdated: today);

    expect(newestFriendLocation(own, cachedAt(today)), same(own));
  });

  test("a friend with no location shows the saved one", () {
    final shown = newestFriendLocation(friend(), cachedAt(yesterday));

    expect(shown.latitude, 33.02);
    expect(shown.lastUpdated, yesterday);
  });

  test("a fix with no time is not second-guessed", () {
    final own = friend(latitude: 32.78, longitude: -96.80);

    expect(newestFriendLocation(own, cachedAt(today)), same(own));
  });

  test("with nothing saved the friend is shown as sent", () {
    final own = friend(latitude: 32.78, longitude: -96.80, lastUpdated: yesterday);

    expect(newestFriendLocation(own, null), same(own));
    expect(newestFriendLocation(friend(), null).latitude, isNull);
  });
}
