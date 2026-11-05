import "package:bluebubbles/app/layouts/findmy/findmy_friend_sort.dart";
import "package:bluebubbles/app/layouts/findmy/findmy_refresh_progress.dart";
import "package:bluebubbles/database/models.dart";
import "package:flutter_test/flutter_test.dart";

final startedAt = DateTime(2026, 11, 4, 12);
final before = startedAt.subtract(const Duration(minutes: 5));
final after = startedAt.add(const Duration(seconds: 3));

FindMyFriend friend({
  String? rawAddress,
  String? hydratedAddress,
  String? title,
  DateTime? lastUpdated,
  bool locating = false,
}) => FindMyFriend(
  latitude: null,
  longitude: null,
  longAddress: null,
  shortAddress: null,
  title: title,
  subtitle: null,
  handle: hydratedAddress == null ? null : Handle(address: hydratedAddress),
  handleAddress: rawAddress,
  lastUpdated: lastUpdated,
  status: null,
  locatingInProgress: locating,
  favoriteOrder: null,
);

/// A pushed location for [address] whose fix was taken at [at] (after the refresh began unless given).
FindMyFriend push(String? address, {DateTime? at, bool locating = false}) =>
    friend(rawAddress: address, lastUpdated: at ?? after, locating: locating);

void main() {
  group("findMyFriendIdentity", () {
    test("is the provider address, raw or hydrated", () {
      expect(findMyFriendIdentity(friend(rawAddress: "alice", hydratedAddress: "alice")), "alice");
      expect(findMyFriendIdentity(friend(hydratedAddress: "alice")), "alice");
      expect(findMyFriendIdentity(friend(rawAddress: " alice ")), "alice");
      expect(findMyFriendIdentity(friend(rawAddress: " ", hydratedAddress: "alice")), "alice");
    });

    test("never uses the display name, so two unnamed-address friends stay apart", () {
      final first = friend(title: "Alex");
      final second = friend(title: "Alex");
      expect(findMyFriendIdentity(first), isNot("Alex"));
      expect(findMyFriendIdentity(first), findMyFriendIdentity(first));
      expect(findMyFriendIdentity(first), isNot(findMyFriendIdentity(second)));
      expect(first.stableId, isNull);
    });
  });

  test("waits only on friends whose fix predates the refresh", () {
    final progress = FindMyRefreshProgress.start(startedAt).withRoster([
      friend(rawAddress: "stale", lastUpdated: before),
      friend(rawAddress: "fresh", lastUpdated: after),
      friend(rawAddress: "unknown"),
    ]);

    expect(progress.allReported, isFalse);
    expect(progress.withEvent(push("stale")).allReported, isFalse);
    expect(progress.withEvent(push("stale")).withEvent(push("unknown")).allReported, isTrue);
  });

  test("a friend Apple is still locating is waited on even with a fresh fix", () {
    final progress = FindMyRefreshProgress.start(startedAt).withRoster([
      friend(rawAddress: "locating", lastUpdated: after, locating: true),
    ]);
    expect(progress.allReported, isFalse);
    expect(progress.withEvent(push("locating")).allReported, isTrue);
  });

  test("counts an event that arrives before the roster", () {
    final progress = FindMyRefreshProgress.start(
      startedAt,
    ).withEvent(push("alice")).withRoster([friend(rawAddress: "alice", lastUpdated: before)]);
    expect(progress.allReported, isTrue);
  });

  test("ignores blank identifiers and friends without an address", () {
    final progress = FindMyRefreshProgress.start(startedAt)
        .withRoster([friend(title: "No address", lastUpdated: before)])
        .withEvent(push(""))
        .withEvent(push(null));
    expect(progress.allReported, isTrue);
  });

  test("a row spins only while its friend's fix predates the refresh", () {
    final stale = friend(rawAddress: "stale", lastUpdated: before);
    final fresh = friend(rawAddress: "fresh", lastUpdated: after);
    final never = friend(rawAddress: "never");
    final progress = FindMyRefreshProgress.start(startedAt).withRoster([stale, fresh, never]);

    expect(findMyFriendRowSpinning(progress, stale), isTrue);
    expect(findMyFriendRowSpinning(progress, never), isTrue);
    expect(findMyFriendRowSpinning(progress, fresh), isFalse);
    // A stale fix that has reported in this refresh shows its distance.
    expect(findMyFriendRowSpinning(progress.withEvent(push("stale")), stale), isFalse);
  });

  test("outside a refresh, a row spins only while Apple is still locating", () {
    final finished = FindMyRefreshProgress.start(startedAt).finish();
    expect(findMyFriendRowSpinning(finished, friend(rawAddress: "bob", lastUpdated: before)), isFalse);
    expect(findMyFriendRowSpinning(finished, friend(rawAddress: "bob", locating: true)), isTrue);
    expect(findMyFriendRowSpinning(FindMyRefreshProgress.idle(), friend(rawAddress: "alice")), isFalse);
  });

  test("matches a hydrated-only roster entry with a raw-only event", () {
    final progress = FindMyRefreshProgress.start(startedAt)
        .withRoster([friend(hydratedAddress: "alice", lastUpdated: before)])
        .withEvent(push("alice"));
    expect(progress.allReported, isTrue);
  });

  test("a pushed fix older than the refresh does not end that friend's wait", () {
    final stale = friend(rawAddress: "stale", lastUpdated: before);
    final progress = FindMyRefreshProgress.start(startedAt).withRoster([stale]).withEvent(push("stale", at: before));
    expect(progress.allReported, isFalse);
    expect(findMyFriendRowSpinning(progress, stale), isTrue);
  });

  test("a pushed fix Apple is still locating does not end that friend's wait", () {
    final stale = friend(rawAddress: "stale", lastUpdated: before);
    final progress = FindMyRefreshProgress.start(
      startedAt,
    ).withRoster([stale]).withEvent(push("stale", locating: true));
    expect(progress.allReported, isFalse);
    expect(findMyFriendRowSpinning(progress, stale), isTrue);
  });

  test("a pushed fix newer than the refresh ends that friend's wait", () {
    final stale = friend(rawAddress: "stale", lastUpdated: before);
    final progress = FindMyRefreshProgress.start(startedAt).withRoster([stale]).withEvent(push("stale"));
    expect(progress.allReported, isTrue);
    expect(findMyFriendRowSpinning(progress, stale), isFalse);
  });

  group("a round rejoined part-way", () {
    // The server's round began at [startedAt]; the page reopened 40 s later
    final dad = friend(rawAddress: "dad", lastUpdated: startedAt.add(const Duration(seconds: 10)));
    final mom = friend(rawAddress: "mom", lastUpdated: before);
    FindMyRefreshProgress rejoined() => FindMyRefreshProgress.start(startedAt).withRoster([dad, mom]);

    test("only friends with no location from the round spin", () {
      final progress = rejoined();
      expect(findMyFriendRowSpinning(progress, dad), isFalse);
      expect(findMyFriendRowSpinning(progress, mom), isTrue);
      expect(progress.awaitedIds, {"mom"});
    });

    test("a location from the round ends the wait of a friend still spinning", () {
      final progress = rejoined().withEvent(push("mom", at: startedAt.add(const Duration(seconds: 50))));
      expect(findMyFriendRowSpinning(progress, mom), isFalse);
      expect(progress.allReported, isTrue);
    });
  });
}
