import 'dart:async';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide Response;
import 'package:latlong2/latlong.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:bluebubbles/app/components/avatars/contact_avatar_widget.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_camera.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_friend_sort.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_location_cache.dart';
import 'package:bluebubbles/app/layouts/findmy/widgets/findmy_items_tab_view.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_location_clipper.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_pin_clipper.dart';
import 'package:bluebubbles/helpers/helpers.dart';

class FindMyController extends GetxController {
  // Scroll Controllers
  final ScrollController devicesController = ScrollController();
  final ScrollController itemsController = ScrollController();
  final ScrollController friendsController = ScrollController();

  // Map & Panel Controllers
  final PopupController popupController = PopupController();
  final MapController mapController = MapController();
  final PanelController panelController = PanelController();
  final completer = Completer<void>();

  // Tab Controller (needs to be created with vsync in the widget)
  TabController? tabController;

  // Observable state variables
  final RxInt tabIndex = 0.obs;
  final RxList<FindMyDevice> devices = <FindMyDevice>[].obs;
  final RxList<FindMyFriend> friends = <FindMyFriend>[].obs;
  final RxList<FindMyFriend> friendsWithLocation = <FindMyFriend>[].obs;
  final RxList<FindMyFriend> friendsWithoutLocation = <FindMyFriend>[].obs;
  final RxMap<String, Marker> markers = <String, Marker>{}.obs;
  final Set<String> _friendMarkerKeys = <String>{};
  final Set<String> _deviceMarkerKeys = <String>{};
  final Set<String> _itemMarkerKeys = <String>{};
  final Rxn<Position> location = Rxn<Position>();
  final Rxn<bool> fetching = Rxn<bool>(true);
  final RxBool refreshing = false.obs;
  final Rxn<bool> fetching2 = Rxn<bool>(true);
  final RxBool refreshing2 = false.obs;
  final RxBool canRefresh = false.obs;
  final RxBool hasMovedToCurrentLocation = false.obs;
  final RxBool resolvingCurrentLocation = true.obs;

  /// Insets of the map area the opening camera frames. On phones this is the
  /// part left visible with the drawer at its halfway point, so the framing
  /// stays put however the drawer is dragged.
  EdgeInsets cameraPadding = const EdgeInsets.all(40);
  bool _cameraMovedByUser = false;
  late final FindMyLocationCache _locationCache = FindMyLocationCache.load();
  Worker? _tabWorker;

  StreamSubscription? locationSub;
  Timer? _refreshTimer;
  StreamSubscription? _redactedModeListener;
  StreamSubscription? _hideContactInfoListener;
  StreamSubscription? _findMyLocationListener;

  @override
  void onInit() {
    super.onInit();
    getLocations();

    // Listen via the event dispatcher rather than the socket itself — the socket is
    // torn down and rebuilt on every restart (backgrounding, a server URL refresh),
    // and a listener bound to the old instance would just stop receiving updates.
    _findMyLocationListener = EventDispatcherSvc.stream.listen((event) {
      if (event.type == 'new-findmy-location') _handleNewFindMyLocation(event.data);
    });

    _scheduleRefreshGate();
    _setupRedactionListeners();

    // Each tab opens on its own framing, as Find My does.
    _tabWorker = ever(tabIndex, (_) {
      _cameraMovedByUser = false;
      fitCameraToTab();
    });
  }

  bool get _isAlive => !isClosed;

  void _scheduleRefreshGate() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(seconds: 30), () {
      if (!_isAlive) return;
      canRefresh.value = true;
    });
  }

  void _setupRedactionListeners() {
    _redactedModeListener?.cancel();
    _hideContactInfoListener?.cancel();
    _redactedModeListener = SettingsSvc.settings.redactedMode.listen((_) => _rebuildAllMarkers());
    _hideContactInfoListener = SettingsSvc.settings.hideContactInfo.listen((_) => _rebuildAllMarkers());
  }

  void _rebuildAllMarkers() {
    if (!_isAlive) return;
    for (final friend in friends.where(hasUsableFindMyLocation)) {
      buildFriendMarker(friend);
    }
    for (final device in devices.where((e) => isUsableFindMyCoordinate(e.location?.latitude, e.location?.longitude))) {
      buildDeviceMarker(device);
    }
    markers.refresh();
  }

  LatLng markerPointForFriend(FindMyFriend friend) => resolveFindMyMarkerPoint(
    stableKey: friend.stableId ?? friend.title ?? 'friend',
    latitude: friend.latitude!,
    longitude: friend.longitude!,
  );

  LatLng markerPointForDevice(FindMyDevice device) => resolveFindMyMarkerPoint(
    stableKey: device.id ?? device.name ?? 'device',
    latitude: device.location!.latitude!,
    longitude: device.location!.longitude!,
  );

  /// The locations the current tab's opening camera should frame.
  List<LatLng> _cameraPointsForTab() {
    switch (tabIndex.value) {
      case 0:
        return friendsWithLocation.map(markerPointForFriend).toList();
      case 1:
        return devices
            .where(
              (e) => !e.isConsideredAccessory && isUsableFindMyCoordinate(e.location?.latitude, e.location?.longitude),
            )
            .map(markerPointForDevice)
            .toList();
      default:
        // One point per product, so a pair of AirPods counts once rather than three times.
        return collapseFindMyAccessoryComponents(devices.where((e) => e.isConsideredAccessory).toList())
            .where((e) => isUsableFindMyCoordinate(e.location?.latitude, e.location?.longitude))
            .map(markerPointForDevice)
            .toList();
    }
  }

  /// Frames the current tab's locations, unless the user has since moved the
  /// map themselves. Only the People tab is framed around the user's own
  /// location; Devices and Items are framed around the things themselves.
  void fitCameraToTab() {
    if (!_isAlive || !completer.isCompleted || _cameraMovedByUser) return;
    final current = location.value;
    final anchor =
        tabIndex.value == 0 && current != null && isUsableFindMyCoordinate(current.latitude, current.longitude)
        ? LatLng(current.latitude, current.longitude)
        : null;
    final focus = selectFindMyCameraFocus(_cameraPointsForTab(), anchor: anchor);
    if (focus.isEmpty) return;
    try {
      // The zoom cap keeps a single location at neighbourhood scale.
      mapController.fitCamera(CameraFit.coordinates(coordinates: focus, padding: cameraPadding, maxZoom: 16));
    } catch (e, s) {
      Logger.warn("Failed to frame the Find My map", error: e, trace: s, tag: 'FindMyController');
    }
  }

  void noteCameraGesture() {
    _cameraMovedByUser = true;
    popupController.hideAllPopups();
  }

  /// Shows one selected person or product at street level while respecting the
  /// same halfway-drawer viewport as the opening camera.
  void focusMap(LatLng point) {
    _cameraMovedByUser = true;
    popupController.hideAllPopups();
    mapController.fitCamera(CameraFit.coordinates(coordinates: [point], padding: cameraPadding, maxZoom: 16));
  }

  /// Records friends' current locations and fills in a missing one from the
  /// last known location.
  List<FindMyFriend> _withCachedFriendLocations(List<FindMyFriend> source) {
    return source.map((friend) {
      final key = friend.stableId;
      if (key == null) return friend;
      if (hasUsableFindMyLocation(friend)) {
        _locationCache.remember(
          'friend:$key',
          FindMyCachedLocation(
            latitude: friend.latitude!,
            longitude: friend.longitude!,
            timestamp: (friend.lastUpdated ?? DateTime.now()).millisecondsSinceEpoch,
            label: friend.shortAddress,
            fullAddress: friend.longAddress,
          ),
        );
        return friend;
      }
      final cached = _locationCache['friend:$key'];
      return cached == null ? friend : friendWithCachedLocation(friend, cached);
    }).toList();
  }

  /// Records devices' current locations and fills in a missing one from the
  /// last known location.
  void _applyCachedDeviceLocations(List<FindMyDevice> source) {
    for (final device in source) {
      final id = device.id;
      if (id == null || id.isEmpty) continue;
      final location = device.location;
      if (isUsableFindMyCoordinate(location?.latitude, location?.longitude)) {
        _locationCache.remember(
          'device:$id',
          FindMyCachedLocation(
            latitude: location!.latitude!,
            longitude: location.longitude!,
            timestamp: location.timeStamp ?? DateTime.now().millisecondsSinceEpoch,
            label: device.address?.label,
            fullAddress: device.address?.mapItemFullAddress,
          ),
        );
        continue;
      }
      final cached = _locationCache['device:$id'];
      if (cached != null) applyCachedDeviceLocation(device, cached);
    }
  }

  void _handleNewFindMyLocation(dynamic data) {
    if (!_isAlive) return;
    try {
      final friend = FindMyFriend.fromJson(data);
      Logger.info("Received new location for ${friend.handle?.address}");
      // Keep the last known good location when Apple pushes a no-fix or malformed update.
      if (!hasUsableFindMyLocation(friend)) return;
      _withCachedFriendLocations([friend]);
      _locationCache.save();

      final existingFriendIndex = friends.indexWhere((e) => e.stableId != null && e.stableId == friend.stableId);
      final existingFriend = existingFriendIndex == -1 ? null : friends[existingFriendIndex];

      final shouldUpdate =
          existingFriend == null ||
          existingFriend.status == null ||
          friend.locatingInProgress ||
          LocationStatus.values.indexOf(existingFriend.status!) <=
              LocationStatus.values.indexOf(friend.status ?? LocationStatus.legacy);

      if (shouldUpdate) {
        Logger.info("Updating map for ${friend.stableId}");
        if (existingFriendIndex == -1) {
          friends.add(friend);
        } else {
          friends[existingFriendIndex] = friend;
        }

        _updateFriendLists();

        buildFriendMarker(friend);
      }
    } catch (e, s) {
      Logger.warn("Failed to fetch FindMy locations", error: e, trace: s, tag: 'FindMyController');
    }
  }

  /// Fetches the FindMy data from the server.
  /// The toggles for refresh friends & devices are separate due to an inconsistency in the server API.
  /// As of v1.9.7 (server), the refresh devices endpoint doesn't return the devices data,
  /// however, the refresh friends endpoint does. The way this was coded assumes that the server
  /// will return the data for both endpoints. A server update will fix this, but for now,
  /// we will "patch" it by only "refreshing" devices when the user manually refreshes the data.
  Future<void> getLocations({bool refreshFriends = true, bool refreshDevices = false}) async {
    if (!_isAlive) return;

    if (!(Platform.isLinux && !kIsWeb)) {
      LocationPermission granted = await Geolocator.checkPermission();
      if (!_isAlive) return;
      if (granted == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
        if (!_isAlive) return;
      }

      if (granted == LocationPermission.whileInUse || granted == LocationPermission.always) {
        Geolocator.getCurrentPosition(locationSettings: const LocationSettings(timeLimit: Duration(seconds: 10)))
            .then((loc) {
              if (!_isAlive) return;
              location.value = loc;
              _updateFriendLists();
              buildLocationMarker(location.value!);
              fitCameraToTab();
              if (!kIsDesktop && locationSub == null) {
                locationSub = Geolocator.getPositionStream().listen((event) async {
                  if (!_isAlive) return;
                  location.value = event;
                  _updateFriendLists();
                  buildLocationMarker(event);

                  if (!hasMovedToCurrentLocation.value) {
                    if (!completer.isCompleted) await completer.future;
                    if (!_isAlive) return;
                    fitCameraToTab();
                    hasMovedToCurrentLocation.value = true;
                  }
                });
              }
            })
            .catchError((e) {
              Logger.warn("Failed to get current location", error: e, tag: 'FindMyController');
            })
            .whenComplete(() => resolvingCurrentLocation.value = false);
      } else {
        resolvingCurrentLocation.value = false;
      }
    } else {
      resolvingCurrentLocation.value = false;
    }

    // Fetch friends data
    final response2 = refreshFriends
        ? await HttpSvc.icloud.refreshFriends().catchError((_) async {
            if (!_isAlive) return Response(requestOptions: RequestOptions(path: ''));
            refreshing2.value = false;
            showSnackbar("Error", "Something went wrong refreshing FindMy Friends data!", type: SnackbarType.error);
            return Response(requestOptions: RequestOptions(path: ''));
          })
        : await HttpSvc.icloud.getFriends().catchError((_) async {
            if (!_isAlive) return Response(requestOptions: RequestOptions(path: ''));
            fetching2.value = null;
            return Response(requestOptions: RequestOptions(path: ''));
          });
    if (!_isAlive) return;

    if (response2.statusCode == 200 && response2.data['data'] != null) {
      try {
        friends.value = _withCachedFriendLocations(
          (response2.data['data'] as List).map((e) => FindMyFriend.fromJson(e)).toList().cast<FindMyFriend>(),
        );
        _locationCache.save();

        _updateFriendLists();

        _clearFriendMarkers();
        for (FindMyFriend e in friends.where(hasUsableFindMyLocation)) {
          buildFriendMarker(e);
        }
        fitCameraToTab();
        fetching2.value = false;
        refreshing2.value = false;
      } catch (e, s) {
        Logger.error("Failed to parse FindMy Friends location data!", error: e, trace: s);
        fetching2.value = null;
        refreshing2.value = false;
        return;
      }
    } else {
      fetching2.value = false;
      refreshing2.value = false;
    }

    // Fetch devices data
    final response = refreshDevices
        ? await HttpSvc.icloud.refreshDevices().catchError((_) async {
            if (!_isAlive) return Response(requestOptions: RequestOptions(path: ''));
            refreshing.value = false;
            showSnackbar("Error", "Something went wrong refreshing FindMy Devices data!", type: SnackbarType.error);
            return Response(requestOptions: RequestOptions(path: ''));
          })
        : await HttpSvc.icloud.getDevices().catchError((_) async {
            if (!_isAlive) return Response(requestOptions: RequestOptions(path: ''));
            fetching.value = null;
            return Response(requestOptions: RequestOptions(path: ''));
          });
    if (!_isAlive) return;

    if (response.statusCode == 200 && response.data['data'] != null) {
      try {
        devices.value = (response.data['data'] as List)
            .map((e) => FindMyDevice.fromJson(e))
            .toList()
            .cast<FindMyDevice>();

        // Apply safe location name as the display label once, here rather than during build.
        for (final device in devices) {
          if (device.safeLocations.isNotEmpty && device.safeLocations.first.name != null) {
            device.address?.label = device.safeLocations.first.name;
          }
        }
        _applyCachedDeviceLocations(devices);
        _locationCache.save();

        _clearDeviceMarkers();
        for (FindMyDevice e in devices.where(
          (e) => isUsableFindMyCoordinate(e.location?.latitude, e.location?.longitude),
        )) {
          buildDeviceMarker(e);
        }
        fitCameraToTab();
        fetching.value = false;
        refreshing.value = false;
      } catch (e, s) {
        Logger.error("Failed to parse FindMy Devices location data!", error: e, trace: s);
        fetching.value = null;
        refreshing.value = false;
        return;
      }
    } else {
      fetching.value = false;
      refreshing.value = false;
    }

    // Call the FindMy Friends refresh anyways so that new data comes through the socket
    if (!refreshFriends) {
      HttpSvc.icloud.refreshFriends();
    } else {
      canRefresh.value = false;
      _scheduleRefreshGate();
    }
  }

  void _updateFriendLists() {
    List<FindMyFriend> favoritesFirst(Iterable<FindMyFriend> source) {
      final favorites = source.where((friend) => friend.favoriteOrder != null).toList()
        ..sort((a, b) => a.favoriteOrder!.compareTo(b.favoriteOrder!));
      final regular = source.where((friend) => friend.favoriteOrder == null).toList();
      return [...favorites, ...regular];
    }

    final currentLocation = location.value;
    final regularWithLocation = friends
        .where((friend) => friend.favoriteOrder == null && hasUsableFindMyLocation(friend))
        .toList();
    final sortedRegular = currentLocation == null
        ? regularWithLocation
        : sortFindMyFriendsByDistance(
            regularWithLocation,
            originLatitude: currentLocation.latitude,
            originLongitude: currentLocation.longitude,
          );
    final favoriteWithLocation =
        friends.where((friend) => friend.favoriteOrder != null && hasUsableFindMyLocation(friend)).toList()
          ..sort((a, b) => a.favoriteOrder!.compareTo(b.favoriteOrder!));
    friendsWithLocation.value = [...favoriteWithLocation, ...sortedRegular];
    friendsWithoutLocation.value = favoritesFirst(friends.where((friend) => !hasUsableFindMyLocation(friend)));
  }

  List<Marker> get visibleMarkers {
    final visibleKeys = switch (tabIndex.value) {
      0 => _friendMarkerKeys,
      1 => _deviceMarkerKeys,
      _ => _itemMarkerKeys,
    };
    return markers.entries
        .where((entry) => (tabIndex.value == 0 && entry.key == 'current') || visibleKeys.contains(entry.key))
        .map((entry) => entry.value)
        .toList();
  }

  void buildDeviceMarker(FindMyDevice e) {
    final markerKey = e.id ?? randomString(6);
    _deviceMarkerKeys.remove(markerKey);
    _itemMarkerKeys.remove(markerKey);
    (e.isConsideredAccessory ? _itemMarkerKeys : _deviceMarkerKeys).add(markerKey);
    markers[markerKey] = Marker(
      key: ValueKey('device-$markerKey'),
      point: markerPointForDevice(e),
      width: 30,
      height: 35,
      child: ClipShadowPath(
        clipper: const FindMyPinClipper(),
        shadow: const BoxShadow(color: Colors.black, blurRadius: 2),
        child: Container(
          color: Colors.white,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5.0),
              child: (e.isAppleAudioAccessory || (e.modelDisplayName?.toLowerCase().contains('airpods') ?? false))
                  ? const Icon(Icons.headphones, color: Colors.black, size: 20)
                  : e.role?['emoji'] != null
                  ? Text(
                      e.role!['emoji'],
                      style: Get.context!.theme.textTheme.bodyLarge!.copyWith(fontFamily: 'Apple Color Emoji'),
                    )
                  : Icon(
                      (e.isMac ?? false)
                          ? Icons.computer
                          : e.isConsideredAccessory
                          ? Icons.headphones
                          : Icons.phone_iphone,
                      color: Colors.black,
                      size: 20,
                    ),
            ),
          ),
        ),
      ),
      alignment: Alignment.topCenter,
    );
  }

  void buildFriendMarker(FindMyFriend friend) {
    final markerKey = friend.stableId ?? randomString(6);
    _friendMarkerKeys.add(markerKey);
    markers[markerKey] = Marker(
      key: ValueKey('friend-$markerKey'),
      point: markerPointForFriend(friend),
      width: 35,
      height: 35,
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ContactAvatarWidget(
              editable: false,
              handle: friend.handle ?? Handle(address: friend.title ?? "Unknown"),
            ),
          ),
        ),
      ),
      alignment: Alignment.topCenter,
    );
  }

  void _clearFriendMarkers() {
    for (final markerKey in _friendMarkerKeys) {
      markers.remove(markerKey);
    }
    _friendMarkerKeys.clear();
  }

  void _clearDeviceMarkers() {
    for (final markerKey in {..._deviceMarkerKeys, ..._itemMarkerKeys}) {
      markers.remove(markerKey);
    }
    _deviceMarkerKeys.clear();
    _itemMarkerKeys.clear();
  }

  void buildLocationMarker(Position pos) {
    markers['current'] = Marker(
      key: const ValueKey('current'),
      point: LatLng(pos.latitude, pos.longitude),
      width: 25,
      height: 55,
      // Taps pass through to anything underneath, such as a group of devices at home.
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (pos.heading.isFinite)
              Transform.rotate(
                angle: pos.heading,
                child: ClipPath(
                  clipper: const FindMyLocationClipper(),
                  child: Container(
                    width: 25,
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentDirectional.center,
                        end: Alignment.topCenter,
                        colors: [
                          Get.context!.theme.colorScheme.primary,
                          Get.context!.theme.colorScheme.primary.withAlpha(50),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Container(
              width: 25,
              height: 25,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              padding: const EdgeInsets.all(5),
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: Get.context!.theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
      alignment: Alignment.topCenter,
    );
  }

  @override
  void onClose() {
    _tabWorker?.dispose();
    _refreshTimer?.cancel();
    _redactedModeListener?.cancel();
    _hideContactInfoListener?.cancel();
    _findMyLocationListener?.cancel();
    locationSub?.cancel();
    if (!completer.isCompleted) completer.complete();
    mapController.dispose();
    popupController.dispose();
    tabController?.dispose();
    itemsController.dispose();
    devicesController.dispose();
    friendsController.dispose();
    super.onClose();
  }
}
