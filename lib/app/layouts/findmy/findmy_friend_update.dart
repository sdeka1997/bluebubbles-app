import 'package:bluebubbles/database/models.dart';

/// Chooses the friend carrying the newest fix. Apple's shallow/live status
/// describes the fix; it must never make older coordinates win.
FindMyFriend newestFindMyFriend(FindMyFriend existing, FindMyFriend incoming) {
  final existingAt = existing.lastUpdated;
  final incomingAt = incoming.lastUpdated;
  if (incomingAt == null) return existing;
  if (existingAt == null || incomingAt.isAfter(existingAt)) return incoming;
  if (incomingAt.isAtSameMomentAs(existingAt)) {
    // The same fix resent once Apple stops locating settles the row's spinner.
    if (existing.locatingInProgress && !incoming.locatingInProgress) return incoming;
    // The server sends a fix at once and its address as a second update with the same time.
    if (incoming.shortAddress != existing.shortAddress || incoming.longAddress != existing.longAddress) return incoming;
  }
  return existing;
}

bool shouldAcceptFindMyFriendUpdate(FindMyFriend existing, FindMyFriend incoming) =>
    identical(newestFindMyFriend(existing, incoming), incoming);
