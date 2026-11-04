import 'dart:async';
import 'dart:convert';

import 'package:bluebubbles/app/layouts/findmy/findmy_friend_sort.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';

/// A location Find My reported earlier, kept for when Apple later has no fix.
class FindMyCachedLocation {
  const FindMyCachedLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.label,
    this.fullAddress,
  });

  final double latitude;
  final double longitude;

  /// When Apple located it, in milliseconds since epoch.
  final int timestamp;
  final String? label;
  final String? fullAddress;

  DateTime get updatedAt => DateTime.fromMillisecondsSinceEpoch(timestamp);

  static FindMyCachedLocation? fromJson(Map<String, dynamic> json) {
    final latitude = (json['lat'] as num?)?.toDouble();
    final longitude = (json['lon'] as num?)?.toDouble();
    final timestamp = (json['ts'] as num?)?.toInt();
    if (timestamp == null || !isUsableFindMyCoordinate(latitude, longitude)) return null;
    return FindMyCachedLocation(
      latitude: latitude!,
      longitude: longitude!,
      timestamp: timestamp,
      label: json['label'] as String?,
      fullAddress: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lon': longitude,
    'ts': timestamp,
    if (label != null) 'label': label,
    if (fullAddress != null) 'address': fullAddress,
  };
}

/// Returns [friend] showing [cached] in place of its missing location.
FindMyFriend friendWithCachedLocation(FindMyFriend friend, FindMyCachedLocation cached) => FindMyFriend(
  latitude: cached.latitude,
  longitude: cached.longitude,
  longAddress: cached.fullAddress,
  shortAddress: cached.label,
  title: friend.title,
  subtitle: friend.subtitle,
  handle: friend.handle,
  handleAddress: friend.handleAddress,
  lastUpdated: cached.updatedAt,
  status: null,
  locatingInProgress: false,
  favoriteOrder: friend.favoriteOrder,
);

/// Points [device] at [cached] in place of its missing location.
void applyCachedDeviceLocation(FindMyDevice device, FindMyCachedLocation cached) {
  device.location = Location(
    positionType: null,
    verticalAccuracy: null,
    longitude: cached.longitude,
    floorLevel: null,
    isInaccurate: null,
    isOld: true,
    horizontalAccuracy: null,
    latitude: cached.latitude,
    timeStamp: cached.timestamp,
    altitude: null,
    locationFinished: true,
  );
  device.address = Address(
    subAdministrativeArea: null,
    label: cached.label,
    streetAddress: null,
    countryCode: null,
    stateCode: null,
    administrativeArea: null,
    streetName: null,
    formattedAddressLines: const [],
    mapItemFullAddress: cached.fullAddress,
    fullThroroughfare: null,
    areaOfInterest: const [],
    locality: null,
    country: null,
  );
  device.lastKnownLocationAt = cached.updatedAt;
}

/// How long the cache waits for more changes before writing. An opening load
/// and the friend refresh after it land within a second or two of each other,
/// and socket updates for several friends arrive in bursts.
const Duration findMyLocationCacheSaveDelay = Duration(seconds: 2);

/// Last known location per friend and per logical device or item.
///
/// Holds one account at a time: the cache is tied to the server and iCloud
/// account it was filled from, and starts empty when either changes so one
/// account's locations never show up under another.
class FindMyLocationCache {
  FindMyLocationCache(
    this.server,
    this.account, [
    Map<String, FindMyCachedLocation>? entries,
    List<Map<String, dynamic>>? friends,
    List<Map<String, dynamic>>? devices,
  ]) : _entries = entries ?? {},
       _friends = friends ?? const [],
       _devices = devices ?? const [];

  /// The layout written by [save]. The saved friend and device lists are only
  /// read back from this version; an older cache keeps its locations and
  /// simply opens without them.
  static const int version = 2;

  final String server;
  final String account;
  final Map<String, FindMyCachedLocation> _entries;
  List<Map<String, dynamic>> _friends;
  List<Map<String, dynamic>> _devices;
  bool _dirty = false;

  /// The last friend list and device list the server sent, as it sent them,
  /// so the page can show them before any network answer.
  List<Map<String, dynamic>> get friends => _friends;
  List<Map<String, dynamic>> get devices => _devices;

  /// Whether friends' coordinates may be written to disk at all. Redacted
  /// mode exists so the device can be shown to others without exposing
  /// contacts; other people's locations are the clearest case of that.
  static bool get persistenceAllowed => !SettingsSvc.settings.redactedMode.value;

  static FindMyLocationCache load() {
    final server = SettingsSvc.settings.serverAddress.value;
    final account = SettingsSvc.settings.iCloudAccount.value;
    if (!persistenceAllowed) {
      // Drop anything written before redaction was turned on.
      unawaited(PrefsSvc.findMy.removeLocationCache());
      return FindMyLocationCache(server, account);
    }
    try {
      final raw = PrefsSvc.findMy.getLocationCache();
      if (raw == null) return FindMyLocationCache(server, account);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final savedAccount = json['account'] as String? ?? '';
      // The iCloud account is only known once server details have loaded, so an
      // empty value on either side means "unknown", not "different account".
      final sameAccount = savedAccount.isEmpty || account.isEmpty || savedAccount == account;
      if (json['server'] != server || !sameAccount) {
        // A different server or account: the stored locations belong to
        // someone else's friends, so delete them rather than leave them on disk.
        unawaited(PrefsSvc.findMy.removeLocationCache());
        return FindMyLocationCache(server, account);
      }
      final entries = <String, FindMyCachedLocation>{};
      for (final entry in (json['entries'] as Map<String, dynamic>).entries) {
        final location = FindMyCachedLocation.fromJson(entry.value as Map<String, dynamic>);
        if (location != null) entries[entry.key] = location;
      }
      List<Map<String, dynamic>>? list(String key) =>
          json['version'] == version ? (json[key] as List?)?.cast<Map<String, dynamic>>() : null;
      return FindMyLocationCache(
        server,
        account.isNotEmpty ? account : savedAccount,
        entries,
        list('friends'),
        list('devices'),
      );
    } catch (e, s) {
      Logger.warn("Failed to read the Find My location cache", error: e, trace: s, tag: 'FindMyLocationCache');
      return FindMyLocationCache(server, account);
    }
  }

  FindMyCachedLocation? operator [](String key) => _entries[key];

  /// Stores [location] unless the cache already holds a newer fix for [key].
  void remember(String key, FindMyCachedLocation location) {
    final existing = _entries[key];
    if (existing != null && existing.timestamp > location.timestamp) return;
    _entries[key] = location;
    _dirty = true;
  }

  void rememberFriends(List<Map<String, dynamic>> raw) {
    _friends = raw;
    _dirty = true;
  }

  void rememberDevices(List<Map<String, dynamic>> raw) {
    _devices = raw;
    _dirty = true;
  }

  Future<void> save() async {
    if (!_dirty) return;
    _dirty = false;
    if (!persistenceAllowed) return;
    await PrefsSvc.findMy.setLocationCache(
      jsonEncode({
        'version': version,
        'server': server,
        'account': account,
        'entries': _entries.map((key, value) => MapEntry(key, value.toJson())),
        'friends': _friends,
        'devices': _devices,
      }),
    );
  }
}
