import 'package:bluebubbles/database/models.dart';

/// Chooses the friend carrying the newest fix. Apple's shallow/live status
/// describes the fix; it must never make older coordinates win.
FindMyFriend newestFindMyFriend(FindMyFriend existing, FindMyFriend incoming) {
  final existingAt = existing.lastUpdated;
  final incomingAt = incoming.lastUpdated;
  if (incomingAt == null) return existing;
  if (existingAt == null || incomingAt.isAfter(existingAt)) return incoming;
  return existing;
}

bool shouldAcceptFindMyFriendUpdate(FindMyFriend existing, FindMyFriend incoming) =>
    identical(newestFindMyFriend(existing, incoming), incoming);
