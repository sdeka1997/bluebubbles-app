import 'package:bluebubbles/app/layouts/findmy/findmy_friend_update.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

FindMyFriend friend({
  required DateTime? updated,
  required LocationStatus status,
  required double latitude,
}) =>
    FindMyFriend(
      latitude: latitude,
      longitude: -96,
      longAddress: null,
      shortAddress: null,
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
}
