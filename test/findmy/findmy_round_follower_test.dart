import "package:bluebubbles/app/layouts/findmy/findmy_refresh_progress.dart";
import "package:bluebubbles/app/layouts/findmy/findmy_round_follower.dart";
import "package:bluebubbles/database/models.dart";
import "package:flutter_test/flutter_test.dart";

final roundStart = DateTime(2026, 11, 5, 12);

FindMyFriend friend(String address, {DateTime? at, bool locating = false}) => FindMyFriend(
  latitude: 33,
  longitude: -96,
  longAddress: null,
  shortAddress: null,
  title: null,
  subtitle: null,
  handle: null,
  handleAddress: address,
  lastUpdated: at,
  status: null,
  locatingInProgress: locating,
  favoriteOrder: null,
);

Map<String, dynamic> round(int id, {required bool collecting, DateTime? startedAt}) => <String, dynamic>{
  'id': id,
  'collecting': collecting,
  'startedAt': (startedAt ?? roundStart).millisecondsSinceEpoch,
};

void main() {
  late int pending;
  late FindMyRoundFollower follower;

  setUp(() {
    pending = 0;
    follower = FindMyRoundFollower(pendingRequests: () => pending);
  });

  final stale = friend("a@example.com", at: roundStart.subtract(const Duration(minutes: 5)));
  final fresh = friend("a@example.com", at: roundStart.add(const Duration(seconds: 3)));

  test("a socket round start waits on friends whose fix predates it", () {
    follower.socketRound(round(7, collecting: true), [stale]);
    expect(follower.progress.value.roundId, 7);
    expect(follower.progress.value.awaitedIds, {"a@example.com"});
  });

  test("the end of the followed round stops spinners even while Apple says locating", () {
    follower.socketRound(round(7, collecting: true), [friend("a@example.com", at: roundStart, locating: true)]);
    follower.socketRound(round(7, collecting: false), const []);
    expect(follower.progress.value.finished, isTrue);
    expect(findMyFriendRowSpinning(follower.progress.value, friend("a@example.com", locating: true)), isFalse);
  });

  test("a fresh fix settles to idle once nothing is pending", () {
    follower.socketRound(round(7, collecting: true), [stale]);
    pending = 1;
    follower.fix(fresh);
    expect(follower.progress.value.active, isTrue, reason: "a request is still out");
    pending = 0;
    follower.settleIfDone();
    expect(follower.progress.value.active, isFalse);
    expect(follower.progress.value.finished, isFalse, reason: "settling is not a server round end");
  });

  test("an answer for an older round neither rewinds nor ends the followed one", () {
    follower.socketRound(round(8, collecting: true), [stale]);
    follower.answer(FindMyRound.tryParse(round(7, collecting: false)), [stale]);
    expect(follower.progress.value.roundId, 8);
    expect(follower.progress.value.active, isTrue);
  });

  test("an answer for an ended round ends the wait", () {
    follower.begin(roundStart);
    follower.answer(FindMyRound.tryParse(round(9, collecting: false)), [stale]);
    expect(follower.progress.value.finished, isTrue);
  });

  test("an answer from a server without rounds keeps the session's own start", () {
    follower.begin(roundStart);
    follower.answer(null, [stale]);
    expect(follower.progress.value.startedAt, roundStart);
    expect(follower.progress.value.awaitedIds, {"a@example.com"});
  });

  test("the end of an older round leaves the followed one waiting", () {
    follower.socketRound(round(8, collecting: true), [stale]);
    follower.socketRound(round(7, collecting: false), const []);
    expect(follower.progress.value.active, isTrue);
    expect(follower.progress.value.roundId, 8);
  });

  test("a repeated start of the followed round keeps who already reported", () {
    follower.socketRound(round(7, collecting: true), [stale, friend("b@example.com")]);
    follower.fix(fresh);
    final before = follower.progress.value;
    follower.socketRound(round(7, collecting: true), [stale]);
    expect(identical(follower.progress.value, before), isTrue);
    expect(follower.progress.value.reportedIds, {"a@example.com"});
  });

  test("malformed round data is ignored", () {
    follower.begin(roundStart);
    final before = follower.progress.value;
    follower.socketRound("nonsense", [stale]);
    expect(identical(follower.progress.value, before), isTrue);
  });
}
