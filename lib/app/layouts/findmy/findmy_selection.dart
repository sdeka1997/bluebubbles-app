import 'package:bluebubbles/app/layouts/findmy/findmy_friend_sort.dart';
import 'package:bluebubbles/database/models.dart';

enum FindMySelectionKind { friend, device }

/// The one person or product selected on the map or in the drawer, as Find
/// My on the Mac has one selection at a time. A friend is identified by
/// Apple's address for them, never their display name; that address is also
/// the handle a live location request names.
class FindMySelection {
  const FindMySelection._(this.kind, this.id, this.handle);

  const FindMySelection.device(String id) : this._(FindMySelectionKind.device, id, null);

  FindMySelection.ofFriend(FindMyFriend friend)
    : this._(FindMySelectionKind.friend, findMyFriendIdentity(friend), friend.stableId);

  final FindMySelectionKind kind;
  final String id;

  /// Apple's address for a selected friend, taken from the friend itself;
  /// null for devices and for friends Apple gave no address, whose identity
  /// is only local to this screen.
  final String? handle;

  static const _friendPrefix = 'friend-';
  static const _devicePrefix = 'device-';

  /// The key of this selection's map marker and drawer row.
  String get markerKey => '${kind == FindMySelectionKind.friend ? _friendPrefix : _devicePrefix}$id';

  /// The selection a marker key belongs to; null for markers that are not one
  /// person or product (the user's own location, grouped capsules). A key
  /// carries only the identity, so a friend read back from one has no
  /// [handle]; it still equals the selection made from the friend itself.
  static FindMySelection? fromMarkerKey(String key) {
    for (final (prefix, kind) in [
      (_friendPrefix, FindMySelectionKind.friend),
      (_devicePrefix, FindMySelectionKind.device),
    ]) {
      if (key.startsWith(prefix) && key.length > prefix.length) {
        return FindMySelection._(kind, key.substring(prefix.length), null);
      }
    }
    return null;
  }

  /// Equal when they name the same person or product, however they were made.
  @override
  bool operator ==(Object other) => other is FindMySelection && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'FindMySelection($markerKey)';
}
