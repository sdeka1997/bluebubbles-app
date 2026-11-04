import 'package:bluebubbles/app/layouts/findmy/findmy_camera.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:geolocator/geolocator.dart';

bool isUsableFindMyCoordinate(double? latitude, double? longitude) {
  return latitude != null &&
      longitude != null &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      (latitude != 0 || longitude != 0);
}

bool hasUsableFindMyLocation(FindMyFriend friend) {
  return isUsableFindMyCoordinate(friend.latitude, friend.longitude);
}

/// One identity per friend, shared by map markers, saved locations, refresh
/// progress and list rows: Apple's address for them ([FindMyFriend.stableId]),
/// never the display name, which two friends can share. A friend with no
/// address keeps a process-local identity while that model object is alive.
String findMyFriendIdentity(FindMyFriend friend) =>
    findMyMarkerIdentity(stableId: friend.stableId, fallbackObject: friend);

/// Returns friends nearest to [originLatitude], [originLongitude] first.
///
/// The display name and stable ID make equal-distance results deterministic.
List<FindMyFriend> sortFindMyFriendsByDistance(
  Iterable<FindMyFriend> friends, {
  required double originLatitude,
  required double originLongitude,
}) {
  final sorted = friends.toList();
  sorted.sort((a, b) {
    final aDistance = Geolocator.distanceBetween(originLatitude, originLongitude, a.latitude!, a.longitude!);
    final bDistance = Geolocator.distanceBetween(originLatitude, originLongitude, b.latitude!, b.longitude!);
    final distanceComparison = aDistance.compareTo(bDistance);
    if (distanceComparison != 0) return distanceComparison;

    final nameComparison = _sortKey(a).compareTo(_sortKey(b));
    if (nameComparison != 0) return nameComparison;
    return (a.stableId ?? '').compareTo(b.stableId ?? '');
  });
  return sorted;
}

String _sortKey(FindMyFriend friend) => (friend.handle?.displayName ?? friend.title ?? '').toLowerCase();
