import 'package:bluebubbles/app/layouts/findmy/findmy_friend_update.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

FindMyFriend friend({
  required DateTime? updated,
  required LocationStatus status,
  required double latitude,
  String? shortAddress,
}) =>
    FindMyFriend(
      latitude: latitude,
      longitude: -96,
      longAddress: null,
      shortAddress: shortAddress,
      title: 'Friend',
      subtitle: null,
      handle: null,
      handleAddress: 'friend@example.com',
      lastUpdated: updated,
      status: status,
      locatingInProgress: false,
      favoriteOrder: null,
    );

void main() {
  test('a newer shallow fix replaces an older live fix', () {
    final old = friend(
      updated: DateTime(2026, 1, 1),
      status: LocationStatus.live,
      latitude: 33,
    );
    final newer = friend(
      updated: DateTime(2026, 1, 1, 0, 1),
      status: LocationStatus.shallow,
      latitude: 34,
    );

    expect(newestFindMyFriend(old, newer), same(newer));
  });

  test('an older live fix cannot replace a newer shallow fix', () {
    final newer = friend(
      updated: DateTime(2026, 1, 1, 0, 1),
      status: LocationStatus.shallow,
      latitude: 34,
    );
    final older = friend(
      updated: DateTime(2026, 1, 1),
      status: LocationStatus.live,
      latitude: 33,
    );

    expect(shouldAcceptFindMyFriendUpdate(newer, older), isFalse);
  });

  test('an equal timestamp does not prove the incoming fix is newer', () {
    final timestamp = DateTime(2026, 1, 1);
    final existing = friend(updated: timestamp, status: LocationStatus.shallow, latitude: 34);
    final incoming = friend(updated: timestamp, status: LocationStatus.live, latitude: 35);

    expect(shouldAcceptFindMyFriendUpdate(existing, incoming), isFalse);
  });

  test('the same fix resent with Apple no longer locating replaces the locating copy', () {
    final timestamp = DateTime(2026, 1, 1);
    final locating = FindMyFriend(
      latitude: 34,
      longitude: -96,
      longAddress: null,
      shortAddress: null,
      title: 'Friend',
      subtitle: null,
      handle: null,
      handleAddress: 'friend@example.com',
      lastUpdated: timestamp,
      status: LocationStatus.live,
      locatingInProgress: true,
      favoriteOrder: null,
    );
    final settled = friend(updated: timestamp, status: LocationStatus.live, latitude: 34);

    expect(shouldAcceptFindMyFriendUpdate(locating, settled), isTrue);
  });

  test('a fix without a timestamp cannot replace a dated fix', () {
    final dated = friend(
      updated: DateTime(2026, 1, 1),
      status: LocationStatus.shallow,
      latitude: 34,
    );
    final unknownAge = friend(
      updated: null,
      status: LocationStatus.live,
      latitude: 35,
    );

    expect(shouldAcceptFindMyFriendUpdate(dated, unknownAge), isFalse);
  });

  test('one undated fix cannot be proven newer than another', () {
    final existing = friend(updated: null, status: LocationStatus.shallow, latitude: 34);
    final incoming = friend(updated: null, status: LocationStatus.live, latitude: 35);

    expect(shouldAcceptFindMyFriendUpdate(existing, incoming), isFalse);
  });

  test('the address that follows a location replaces its coordinates', () {
    final at = DateTime(2026, 11, 6, 15);
    final coordinates = friend(updated: at, status: LocationStatus.shallow, latitude: 33, shortAddress: '33.0000, -96.0000');
    final named = friend(updated: at, status: LocationStatus.shallow, latitude: 33, shortAddress: 'Plano, TX');

    expect(newestFindMyFriend(coordinates, named), same(named));
  });

  test('a resend of the same location and address changes nothing', () {
    final at = DateTime(2026, 11, 6, 15);
    final first = friend(updated: at, status: LocationStatus.shallow, latitude: 33, shortAddress: 'Plano, TX');
    final again = friend(updated: at, status: LocationStatus.shallow, latitude: 33, shortAddress: 'Plano, TX');

    expect(newestFindMyFriend(first, again), same(first));
  });
}
