import 'package:flutter/foundation.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

enum LocationStatus { legacy, shallow, live }

class FindMyFriend {
  FindMyFriend({
    required this.latitude,
    required this.longitude,
    required this.longAddress,
    required this.shortAddress,
    required this.title,
    required this.subtitle,
    required this.handle,
    required this.handleAddress,
    required this.lastUpdated,
    required this.status,
    required this.locatingInProgress,
    required this.favoriteOrder,
  });

  final double? latitude;
  final double? longitude;
  final String? longAddress;
  final String? shortAddress;
  final String? title;
  final String? subtitle;
  final Handle? handle;
  // Raw address from the server — stable even when handle is not in the local DB.
  final String? handleAddress;
  final DateTime? lastUpdated;
  final LocationStatus? status;
  final bool locatingInProgress;
  final int? favoriteOrder;

  /// The address Apple identifies this friend by, for matching and keys.
  /// Roster entries and socket events may or may not hydrate a local [Handle],
  /// so this reads the provider address both forms share rather than the
  /// service-qualified handle key. Null when there is none: the display name
  /// is not an identity, since two friends can share one.
  String? get stableId => _usable(handleAddress) ?? _usable(handle?.address);

  static String? _usable(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// The address a friend's handle is matched by: Apple's address for them,
  /// else the title (Apple puts a bare address there for some friends).
  static String? lookupAddress(Map<String, dynamic> json) => json["handle"] ?? json["title"];

  /// [handles] maps [lookupAddress] to the stored iMessage handle, loaded
  /// before parsing ([findMyHandlesFor]); a friend with none has no handle.
  factory FindMyFriend.fromJson(Map<String, dynamic> json, {Map<String, Handle> handles = const {}}) => FindMyFriend(
        latitude: json["coordinates"]?[0].toDouble(),
        longitude: json["coordinates"]?[1].toDouble(),
        longAddress: json["long_address"],
        shortAddress: json["short_address"],
        title: json["title"],
        subtitle: json["subtitle"],
        handleAddress: json["handle"],
        handle: handles[lookupAddress(json)],
        lastUpdated:
            (json["last_updated"] ?? 0) == 0 ? null : DateTime.fromMillisecondsSinceEpoch(json["last_updated"]),
        status: LocationStatus.values.firstWhereOrNull((e) => e.name == json["status"]),
        locatingInProgress: json["is_locating_in_progress"] ?? false,
        favoriteOrder: (json["favorite_order"] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        "coordinates": [latitude, longitude],
        "long_address": longAddress,
        "short_address": shortAddress,
        "title": title,
        "subtitle": subtitle,
        "handle": handle?.toMap(),
        "last_updated": lastUpdated == null ? null : DateFormat("MMMM d, yyyy h:mm:ss a").format(lastUpdated!),
        "status": status?.name,
        "locating_in_progress": locatingInProgress,
        "favorite_order": favoriteOrder,
      };
}

/// The stored iMessage handles Find My [friends] JSON names, keyed by
/// [FindMyFriend.lookupAddress], for [FindMyFriend.fromJson].
/// Empty on web, which keeps no handles.
Future<Map<String, Handle>> findMyHandlesFor(Iterable<Map<String, dynamic>> friends) async {
  final addresses = friends.map(FindMyFriend.lookupAddress).whereType<String>().toSet().toList();
  if (kIsWeb || addresses.isEmpty) return {};
  return MessagingStore.current.handlesByAddresses(addresses, "iMessage");
}
