import 'package:bluebubbles/app/layouts/findmy/findmy_device_glyph.dart';
import 'dart:async';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:sliding_up_panel2/sliding_up_panel2.dart';
import 'package:universal_io/io.dart';
import 'package:flutter/foundation.dart';
import 'package:bluebubbles/app/components/avatars/contact_avatar_widget.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_camera.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_contact.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_friend_sort.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_format.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_load_state.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_location_cache.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_panel.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_refresh_progress.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_scroll.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_tiles.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_products.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_location_clipper.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_pin_clipper.dart';
import 'package:bluebubbles/helpers/helpers.dart';

class FindMyController extends GetxController {
  FindMyController({FindMyTileLoader? tiles, void Function(bool open)? reportScreen})
      : tiles = tiles ?? FindMyTileLoader(),
        _reportScreen = reportScreen ?? _reportScreenToServer;

  /// Tells the server whether this screen is open; see [_reportScreenToServer].
  final void Function(bool open) _reportScreen;

  /// The map's one tile layer and HTTP client, for the life of the page.
  final FindMyTileLoader tiles;

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

  /// [devices] sorted into the Devices and Items tabs, once per device list.
  final Rx<FindMyProducts> products = FindMyProducts.empty.obs;
  final RxList<FindMyFriend> friends = <FindMyFriend>[].obs;
  final RxList<FindMyFriend> friendsWithLocation = <FindMyFriend>[].obs;
  final RxList<FindMyFriend> friendsWithoutLocation = <FindMyFriend>[].obs;
  final RxMap<String, Marker> markers = <String, Marker>{}.obs;
  final RxnString selectedMarkerKey = RxnString();
  final Map<String, GlobalKey> _rowKeys = <String, GlobalKey>{};
  final Map<String, Future<ContactV2?>> _contactLookups = <String, Future<ContactV2?>>{};
  final Set<String> _friendMarkerKeys = <String>{};
  final Set<String> _deviceMarkerKeys = <String>{};
  final Rxn<Position> location = Rxn<Position>();
  final Rx<FindMyRefreshProgress> friendRefreshProgress = FindMyRefreshProgress.idle().obs;

  /// Insets of the map area the opening camera frames; see [findMyCameraPadding].
  EdgeInsets cameraPadding = const EdgeInsets.all(findMyCameraMargin);
  bool _cameraMovedByUser = false;

  /// Bumped by everything that can change the opening framing: the tab, a new
  /// friend or device list, the first location fix and the map becoming
  /// ready. The camera frames once they settle.
  final RxInt _framingChanged = 0.obs;
  Worker? _framingWorker;
  late final FindMyLocationCache _locationCache = FindMyLocationCache.load();
  Worker? _tabWorker;

  /// Reverse-geocoded addresses for friends whose server payload carries none
  /// (the macOS 14.4+ decryption path can't persist address strings). Keyed by
  /// the friend's stable id; populated asynchronously by [resolveFriendAddress].
  final RxMap<String, String> friendAddresses = <String, String>{}.obs;

  /// ~100m location cells already attempted this controller lifetime, so the 30s
  /// poll doesn't re-hit the platform geocoder for the same spot.
  final Set<String> _geocodeAttempts = {};

  StreamSubscription? locationSub;
  Timer? _cacheSave;
  Worker? _socketWorker;
  StreamSubscription? _redactedModeListener;
  StreamSubscription? _hideContactInfoListener;
  StreamSubscription? _findMyLocationListener;

  @override
  void onInit() {
    super.onInit();
    unawaited(_startLocationUpdates());
    _reportScreen(true);
    _open();

    // Listen via the event dispatcher rather than the socket itself — the socket is
    // torn down and rebuilt on every restart (backgrounding, a server URL refresh),
    // and a listener bound to the old instance would just stop receiving updates.
    _findMyLocationListener = EventDispatcherSvc.stream.listen((event) {
      if (event.type == 'new-findmy-location') _handleNewFindMyLocation(event.data);
      if (event.type == 'findmy-devices-updated') _handleDevicesUpdated(event.data);
    });

    if (GetIt.I.isRegistered<SocketService>()) {
      _socketWorker = ever(SocketSvc.state, (SocketState state) {
        if (state == SocketState.connected) onConnectionRestored();
      });
    }

    _setupRedactionListeners();

    _framingWorker = debounce(_framingChanged, (_) => _maybeFitCamera(), time: findMyCameraSettle);
    completer.future.then((_) => _framingChanged.value++);

    // Each tab opens on its own framing, as Find My does.
    _tabWorker = ever(tabIndex, (_) {
      clearSelection();
      _cameraMovedByUser = false;
      _framingChanged.value++;
    });
  }

  bool get _isAlive => !isClosed;

  /// Ends the refresh window once the session's requests have settled and
  /// every friend it waits on has reported.
  void _finishRefreshWhenDone() {
    final progress = friendRefreshProgress.value;
    if (!progress.active || _pendingRequests.value > 0 || !progress.allReported) return;
    _finishRefresh();
  }

  void _finishRefresh() {
    friendRefreshProgress.value = friendRefreshProgress.value.finish();
  }

  /// While this screen is open, the server keeps publishing locations as Find
  /// My writes them; once it closes, the server finishes its refresh and quits
  /// Find My. Servers without this event ignore it.
  static void _reportScreenToServer(bool open) {
    if (!GetIt.I.isRegistered<SocketService>()) return;
    SocketSvc.sendMessage('findmy-screen', {'open': open}).then(
      (_) {},
      onError: (Object e) => Logger.info("Find My screen state not delivered: $e"),
    );
  }

  /// Coming back to the app counts as opening the screen again.
  void onAppResumed() {
    if (!_isAlive) return;
    _reportScreen(true);
    refreshLocations();
  }

  /// Leaving the app counts as closing the screen.
  void onAppPaused() {
    if (_isAlive) _reportScreen(false);
  }

  /// The server knows each connection separately, so a new one is told the
  /// screen is open; a load that failed while offline is tried again.
  void onConnectionRestored() {
    if (!_isAlive) return;
    _reportScreen(true);
    final failed = friendsState.value.load == FindMyLoad.failed || devicesState.value.load == FindMyLoad.failed;
    if (failed) _startSession(manual: false);
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

  String markerIdentityForFriend(FindMyFriend friend) => findMyFriendIdentity(friend);

  String markerIdentityForDevice(FindMyDevice device) =>
      findMyMarkerIdentity(stableId: device.id, fallbackObject: device);

  LatLng markerPointForFriend(FindMyFriend friend) => resolveFindMyMarkerPoint(
    stableKey: markerIdentityForFriend(friend),
    latitude: friend.latitude!,
    longitude: friend.longitude!,
  );

  /// The friend's display address: the payload's own address when present, otherwise
  /// a reverse-geocoded one once [resolveFriendAddress] has populated it.
  String? addressForFriend(FindMyFriend friend, {bool preferLong = false}) {
    final own = preferLong
        ? friend.longAddress ?? friend.shortAddress
        : friend.shortAddress ?? friend.longAddress;
    return own ?? friendAddresses[findMyFriendIdentity(friend)];
  }

  /// Reverse-geocodes a friend's coordinates when the server sent no address.
  /// Best-effort: unsupported platforms and geocoder failures leave the map empty.
  Future<void> resolveFriendAddress(FindMyFriend friend) async {
    if (friend.shortAddress != null || friend.longAddress != null) return;
    if (shouldRedactFindMyContactInfo()) return;
    final lat = friend.latitude;
    final lng = friend.longitude;
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return;
    // The geocoding plugin implements Android/iOS/macOS only.
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) return;

    final key = findMyFriendIdentity(friend);
    if (friendAddresses.containsKey(key)) return;
    if (!_geocodeAttempts.add('${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}')) return;

    try {
      final geocoding = Geocoding();
      if (!await geocoding.isPresent()) return;
      final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
      if (!_isAlive || placemarks.isEmpty) return;
      final address = formatPlacemarkAddress(placemarks.first);
      if (address.isNotEmpty) friendAddresses[key] = address;
    } catch (e, s) {
      Logger.warn("Failed to reverse-geocode Find My friend location", error: e, trace: s, tag: 'FindMyController');
    }
  }

  LatLng markerPointForDevice(FindMyDevice device) => resolveFindMyMarkerPoint(
    stableKey: markerIdentityForDevice(device),
    latitude: device.location!.latitude!,
    longitude: device.location!.longitude!,
  );

  /// The locations the current tab's opening camera should frame.
  List<LatLng> _cameraPointsForTab() {
    switch (tabIndex.value) {
      case 0:
        return friendsWithLocation.map(markerPointForFriend).toList();
      default:
        return products.value
            .of(tabIndex.value)
            .where((e) => isUsableFindMyCoordinate(e.location?.latitude, e.location?.longitude))
            .map(markerPointForDevice)
            .toList();
    }
  }

  /// What the current tab's opening camera frames. Only the People tab is
  /// framed around the user's own location; Devices and Items are framed
  /// around the things themselves. Empty when nothing is known yet.
  List<LatLng> cameraFocusForTab() {
    final current = location.value;
    final anchor =
        tabIndex.value == 0 && current != null && isUsableFindMyCoordinate(current.latitude, current.longitude)
        ? LatLng(current.latitude, current.longitude)
        : null;
    return selectFindMyCameraFocus(_cameraPointsForTab(), anchor: anchor);
  }

  /// Frames the current tab's locations, unless the user has since moved the
  /// map themselves.
  void _maybeFitCamera() {
    if (!_isAlive || !completer.isCompleted || _cameraMovedByUser) return;
    final focus = cameraFocusForTab();
    if (focus.isEmpty) return;
    try {
      mapController.fitCamera(
        CameraFit.coordinates(coordinates: focus, padding: cameraPadding, maxZoom: findMyDetailZoom),
      );
    } catch (e, s) {
      Logger.warn("Failed to frame the Find My map", error: e, trace: s, tag: 'FindMyController');
    }
  }

  /// Resolves a saved phone contact even when Find My's exact iMessage
  /// handle was not hydrated with its ContactV2 relationship.
  Future<ContactV2?> nativeContactForFriend(FindMyFriend friend) {
    final linked = friend.handle?.contactsV2.where((contact) => contact.isNative).firstOrNull;
    if (linked != null) return Future.value(linked);
    final address = findMyContactLookupAddress(friend);
    if (address == null) return Future.value(null);
    return _contactLookups.putIfAbsent(friend.stableId ?? address, () async {
      final contact = await ContactsSvcV2.getContact(address);
      return contact?.isNative == true ? contact : null;
    });
  }

  /// Distance from the user's own location to [point] in Find My's format,
  /// or null when the user's location is unknown or contact info is hidden.
  String? distanceLabelTo(LatLng point) {
    final current = location.value;
    if (current == null || !isUsableFindMyCoordinate(current.latitude, current.longitude)) return null;
    if (shouldRedactFindMyContactInfo()) return null;
    final meters = Geolocator.distanceBetween(current.latitude, current.longitude, point.latitude, point.longitude);
    final countryCode = WidgetsBinding.instance.platformDispatcher.locale.countryCode;
    return formatFindMyDistance(meters, useMiles: findMyUsesMiles(countryCode));
  }

  GlobalKey rowKeyFor(String markerKey) => _rowKeys.putIfAbsent(markerKey, GlobalKey.new);

  bool isSelected(String markerKey) => selectedMarkerKey.value == markerKey;

  void clearSelection() {
    if (selectedMarkerKey.value == null) return;
    selectedMarkerKey.value = null;
    _rebuildAllMarkers();
  }

  /// Selects one logical entity from either its map marker or drawer row.
  Future<void> selectMarker(String markerKey, LatLng point) async {
    final selectedTab = tabIndex.value;
    bool selectionIsCurrent() => _isAlive && selectedMarkerKey.value == markerKey && tabIndex.value == selectedTab;

    selectedMarkerKey.value = markerKey;
    _rebuildAllMarkers();
    popupController.hideAllPopups();
    await completer.future;
    if (!selectionIsCurrent()) return;
    if (panelController.isAttached) await panelController.animatePanelToSnapPoint();
    if (!selectionIsCurrent()) return;
    focusMap(point);
    final rowKey = _rowKeys[markerKey];
    if (rowKey != null) {
      unawaited(ensureFindMyRowVisibleAfterExpansion(rowKey, isCurrent: selectionIsCurrent));
    }
  }

  /// Returns the current tab to its opening camera after a row selection or
  /// manual pan/zoom.
  void resetMapToTab() {
    clearSelection();
    _cameraMovedByUser = false;
    popupController.hideAllPopups();
    _framingChanged.value++;
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
    mapController.fitCamera(
      CameraFit.coordinates(coordinates: [point], padding: cameraPadding, maxZoom: findMyDetailZoom),
    );
  }

  /// Zooms into a capsule until its logical products become individual markers.
  void focusMarkerGroup(List<LatLng> points) {
    clearSelection();
    popupController.hideAllPopups();
    _cameraMovedByUser = true;
    final latitude = points.map((point) => point.latitude).reduce((a, b) => a + b) / points.length;
    final longitude = points.map((point) => point.longitude).reduce((a, b) => a + b) / points.length;
    mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: [LatLng(latitude, longitude)],
        padding: cameraPadding,
        maxZoom: findMyDetailZoom,
      ),
    );
  }

  /// Records friends' current locations and shows each friend at the newest
  /// location known for them, which may be a saved one.
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
      }
      return newestFriendLocation(friend, _locationCache['friend:$key']);
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
      friendRefreshProgress.value = friendRefreshProgress.value.withUsableEvent(friend.stableId);
      _finishRefreshWhenDone();
      _withCachedFriendLocations([friend]);
      _saveCacheSoon();

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
        unawaited(resolveFriendAddress(friend));
      }
    } catch (e, s) {
      Logger.warn("Failed to fetch FindMy locations", error: e, trace: s, tag: 'FindMyController');
    }
  }

  /// How long a read of the server's stored friends or devices may take. The
  /// server answers these from memory (devices measured at 30 ms), so this only
  /// has to ride out a slow tunnel, and fails fast enough that the user is left
  /// looking at saved pins rather than a spinner.
  static const Duration readDeadline = Duration(seconds: 20);

  /// How long asking the server to locate friends may take: measured at
  /// 0.85-5 s, so six times the slowest.
  static const Duration friendRefreshDeadline = Duration(seconds: 30);

  /// How long asking the server to locate devices may take. Measured at 24.8 s
  /// and 25.3 s; a little over twice that lets a slow iCloud round land, well
  /// inside Dio's own six-minute window for this call, which a tunnel that
  /// drops the connection silently would otherwise leave the page waiting on.
  static const Duration deviceRefreshDeadline = Duration(seconds: 60);

  final Rx<FindMySourceState> friendsState = FindMySourceState.idle.obs;
  final Rx<FindMySourceState> devicesState = FindMySourceState.idle.obs;

  /// Each load is one session; answers from an older one are ignored.
  int _generation = 0;
  bool _manualSession = false;
  final List<CancelToken> _sessionTokens = [];
  final RxInt _pendingRequests = 0.obs;

  /// Asks the server to locate friends and devices. Ignored while one such
  /// request is still waiting on the server; otherwise replaces whatever load
  /// is running.
  void refreshLocations() {
    if (_manualSession && _pendingRequests.value > 0) return;
    _startSession(manual: true);
  }

  /// The opening load: shows what was saved last time at once, reads the
  /// server's stored friends and devices side by side, rendering each as it
  /// arrives, then asks the server to locate both in the background.
  void _open() {
    _showSaved();
    _startSession(manual: false);
  }

  /// One load of friends and devices. A refresh has no time limit: each
  /// friend's row spins until their new location arrives over the socket, or
  /// until the screen closes, since Apple reports people over minutes.
  void _startSession({required bool manual}) {
    if (!_isAlive) return;
    _cancelSession();
    final generation = ++_generation;
    _manualSession = manual;
    _pendingRequests.value = 0;
    // Start progress before awaiting anything, so it shows for the whole
    // session. Only events from this session can count.
    friendRefreshProgress.value = FindMyRefreshProgress.start(DateTime.now());

    friendsState.value = friendsState.value.loading();
    devicesState.value = devicesState.value.loading();
    void locateFriends() => _request(
      generation,
      friendsState,
      HttpSvc.icloud.refreshFriends,
      friendRefreshDeadline,
      _applyFriends(refreshed: true),
    );
    void locateDevices() =>
        _request(generation, devicesState, HttpSvc.icloud.refreshDevices, deviceRefreshDeadline, _applyDevices);
    if (manual) {
      locateFriends();
      locateDevices();
      return;
    }
    _request(generation, friendsState, HttpSvc.icloud.getFriends, readDeadline, (response) {
      _applyFriends(refreshed: false)(response);
      // Fresh fixes also arrive one by one over the socket while this runs.
      if (friendsState.value.load == FindMyLoad.loaded) locateFriends();
    });
    _request(generation, devicesState, HttpSvc.icloud.getDevices, readDeadline, (response) {
      _applyDevices(response);
      if (devicesState.value.load == FindMyLoad.loaded) locateDevices();
    });
  }

  void _cancelSession() {
    for (final token in _sessionTokens) {
      token.cancel('superseded');
    }
    _sessionTokens.clear();
  }

  /// Sends one request of session [generation] and hands its answer to
  /// [onResponse], unless the session has since been replaced. A request with
  /// no answer by [deadline] is cancelled and counts as failed.
  void _request(
    int generation,
    Rx<FindMySourceState> state,
    Future<Response> Function({CancelToken? cancelToken}) send,
    Duration deadline,
    void Function(Response response) onResponse,
  ) {
    final token = CancelToken();
    _sessionTokens.add(token);
    _pendingRequests.value++;
    bool current() => _isAlive && generation == _generation;

    send(cancelToken: token)
        .timeout(
          deadline,
          onTimeout: () {
            token.cancel('deadline');
            throw FindMyDeadlineException(deadline);
          },
        )
        .then(
          (response) {
            if (!current()) return;
            _pendingRequests.value--;
            onResponse(response);
            _finishRefreshWhenDone();
          },
          onError: (Object e, StackTrace s) {
            if (!current()) return;
            _pendingRequests.value--;
            Logger.warn("Find My ${state == friendsState ? 'friends' : 'devices'} request failed", error: e, tag: 'FindMyController');
            state.value = state.value.failed(describeFindMyError(e));
            _finishRefreshWhenDone();
          },
        );
  }

  /// The list a Find My response carries, or null when it carries none (the
  /// device refresh endpoint of some server versions answers without data).
  List? _dataOf(Response response) => response.data is Map ? response.data['data'] as List? : null;

  void Function(Response) _applyFriends({required bool refreshed}) => (response) {
    try {
      final data = _dataOf(response);
      if (data != null) {
        final roster = data.map((e) => FindMyFriend.fromJson(e)).toList();
        _locationCache.rememberFriends(data.cast<Map<String, dynamic>>());
        if (refreshed) {
          friendRefreshProgress.value = friendRefreshProgress.value.withRoster(roster);
        }
        _showFriends(roster);
        _saveCacheSoon();
      }
      friendsState.value = friendsState.value.loaded(DateTime.now());
    } catch (e, s) {
      Logger.error("Failed to parse FindMy Friends location data!", error: e, trace: s);
      friendsState.value = friendsState.value.failed(describeFindMyError(e));
    }
  };

  void _applyDevices(Response response) => _applyDeviceList(() => _dataOf(response));

  /// Devices the server pushed because Find My wrote newer ones.
  void _handleDevicesUpdated(dynamic data) {
    if (_isAlive && data is List) _applyDeviceList(() => data);
  }

  void _applyDeviceList(List? Function() read) {
    try {
      final data = read();
      if (data != null) {
        final parsed = data.map((e) => FindMyDevice.fromJson(e)).toList();
        _locationCache.rememberDevices(data.cast<Map<String, dynamic>>());
        _showDevices(parsed);
        _saveCacheSoon();
      }
      devicesState.value = devicesState.value.loaded(DateTime.now());
    } catch (e, s) {
      Logger.error("Failed to parse FindMy Devices location data!", error: e, trace: s);
      devicesState.value = devicesState.value.failed(describeFindMyError(e));
    }
  }

  /// Writes the location cache once a burst of answers and socket updates
  /// has settled, rather than re-encoding all of it for each one.
  void _saveCacheSoon() {
    _cacheSave?.cancel();
    _cacheSave = Timer(findMyLocationCacheSaveDelay, _saveCache);
  }

  void _saveCache() => unawaited(_locationCache.save());

  /// Puts the friends and devices saved last time on the map, before any
  /// network answer.
  void _showSaved() {
    try {
      final savedFriends = _locationCache.friends.map(FindMyFriend.fromJson).toList();
      final savedDevices = _locationCache.devices.map(FindMyDevice.fromJson).toList();
      if (savedFriends.isNotEmpty) _showFriends(savedFriends);
      if (savedDevices.isNotEmpty) _showDevices(savedDevices);
    } catch (e, s) {
      Logger.warn("Failed to show saved Find My locations", error: e, trace: s, tag: 'FindMyController');
    }
  }

  void _showFriends(List<FindMyFriend> roster) {
    friends.value = _withCachedFriendLocations(roster);
    _updateFriendLists();
    _clearFriendMarkers();
    for (final friend in friends.where(hasUsableFindMyLocation)) {
      buildFriendMarker(friend);
      unawaited(resolveFriendAddress(friend));
    }
    _framingChanged.value++;
  }

  void _showDevices(List<FindMyDevice> source) {
    // Apply safe location name as the display label once, here rather than during build.
    for (final device in source) {
      if (device.safeLocations.isNotEmpty && device.safeLocations.first.name != null) {
        device.address?.label = device.safeLocations.first.name;
      }
    }
    _applyCachedDeviceLocations(source);
    devices.value = source;
    products.value = FindMyProducts.of(source);
    _clearDeviceMarkers();
    for (final device in source.where((e) => isUsableFindMyCoordinate(e.location?.latitude, e.location?.longitude))) {
      buildDeviceMarker(device);
    }
    _framingChanged.value++;
  }

  /// How long the first location fix may take before the page stops waiting
  /// on it; the position stream still delivers one when it comes.
  static const Duration _firstFixTimeLimit = Duration(seconds: 10);

  /// Follows the user's own location, started once per page and independent
  /// of the network, so a slow permission prompt or GPS fix never holds up
  /// Find My data and a refresh never asks for a fix again.
  Future<void> _startLocationUpdates() async {
    if (Platform.isLinux && !kIsWeb) return;
    try {
      var granted = await Geolocator.checkPermission();
      if (!_isAlive) return;
      if (granted == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
        if (!_isAlive) return;
      }
      if (granted != LocationPermission.whileInUse && granted != LocationPermission.always) return;
    } catch (e, s) {
      Logger.warn("Failed to check location permission", error: e, trace: s, tag: 'FindMyController');
      return;
    }

    // The phone's last known position frames the map at once; the fresh fix replaces it.
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (!_isAlive) return;
      if (lastKnown != null && location.value == null) _onPosition(lastKnown, frame: true);
    } catch (e) {
      Logger.debug("No last known location", error: e, tag: 'FindMyController');
    }

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: _firstFixTimeLimit),
      );
      if (!_isAlive) return;
      _onPosition(current, frame: true);
    } catch (e) {
      Logger.warn("Failed to get current location", error: e, tag: 'FindMyController');
      if (!_isAlive) return;
    }

    if (!kIsDesktop) {
      locationSub = Geolocator.getPositionStream().listen((event) {
        if (_isAlive) _onPosition(event);
      });
    }
  }

  /// Records a new position of the user. Only the first fix (and a last known
  /// one before it) [frame]s the map; later ones just move the dot.
  void _onPosition(Position position, {bool frame = false}) {
    location.value = position;
    // The list is sorted by distance from here, so every fix would reorder
    // rows under the user's finger. Re-sort only when the device has moved
    // far enough to change anything visible; refreshes re-sort unconditionally.
    if (_shouldResortForMove(position)) _updateFriendLists();
    buildLocationMarker(position);
    if (frame) _framingChanged.value++;
  }

  Position? _lastSortedPosition;

  /// How far the user must move before the friend list re-sorts by distance:
  /// about a city block, under which no friend's distance label changes much.
  static const double _resortDistanceMeters = 100;

  /// True when [next] is at least [_resortDistanceMeters] from the position the
  /// list was last sorted against (or there is none yet). Records [next] when it
  /// returns true.
  bool _shouldResortForMove(Position next) {
    final last = _lastSortedPosition;
    if (last == null) {
      _lastSortedPosition = next;
      return true;
    }
    final moved = Geolocator.distanceBetween(last.latitude, last.longitude, next.latitude, next.longitude);
    if (moved < _resortDistanceMeters) return false;
    _lastSortedPosition = next;
    return true;
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
    final visibleKeys = tabIndex.value == 0 ? _friendMarkerKeys : _deviceMarkerKeys;
    final visible = markers.entries
        .where((entry) => (tabIndex.value == 0 && entry.key == 'current') || visibleKeys.contains(entry.key))
        .map((entry) => entry.value)
        .toList();
    final selected = selectedMarkerKey.value;
    if (selected != null) {
      visible.sort((a, b) {
        final aSelected = (a.key as ValueKey?)?.value == selected;
        final bSelected = (b.key as ValueKey?)?.value == selected;
        return aSelected == bSelected ? 0 : (aSelected ? 1 : -1);
      });
    }
    return visible;
  }

  void buildDeviceMarker(FindMyDevice e) {
    final markerKey = markerIdentityForDevice(e);
    final selected = isSelected('device-$markerKey');
    _deviceMarkerKeys.add(markerKey);
    markers[markerKey] = Marker(
      key: ValueKey('device-$markerKey'),
      point: markerPointForDevice(e),
      width: selected ? 44 : 30,
      height: selected ? 51 : 35,
      child: Transform.scale(
        scale: selected ? 1.35 : 1,
        child: ClipShadowPath(
          clipper: const FindMyPinClipper(),
          shadow: const BoxShadow(color: Colors.black, blurRadius: 2),
          child: Container(
            color: Colors.white,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: findMyGlyph(e).emoji != null
                    ? Text(
                        findMyGlyph(e).emoji!,
                        style: Get.context!.theme.textTheme.bodyLarge!.copyWith(fontFamily: 'Apple Color Emoji'),
                      )
                    : Icon(findMyGlyph(e).icon, color: Colors.black, size: 20),
              ),
            ),
          ),
        ),
      ),
      alignment: Alignment.topCenter,
    );
  }

  void buildFriendMarker(FindMyFriend friend) {
    final markerKey = markerIdentityForFriend(friend);
    final selected = isSelected('friend-$markerKey');
    _friendMarkerKeys.add(markerKey);
    markers[markerKey] = Marker(
      key: ValueKey('friend-$markerKey'),
      point: markerPointForFriend(friend),
      width: selected ? 54 : 35,
      height: selected ? 54 : 35,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: Get.context!.theme.colorScheme.primary, width: 4) : null,
          boxShadow: selected ? const [BoxShadow(color: Colors.black26, blurRadius: 5)] : null,
        ),
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
    for (final markerKey in _deviceMarkerKeys) {
      markers.remove(markerKey);
    }
    _deviceMarkerKeys.clear();
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
    _reportScreen(false);
    _tabWorker?.dispose();
    _framingWorker?.dispose();
    _socketWorker?.dispose();
    _cancelSession();
    _cacheSave?.cancel();
    _saveCache();
    _redactedModeListener?.cancel();
    _hideContactInfoListener?.cancel();
    _findMyLocationListener?.cancel();
    locationSub?.cancel();
    if (!completer.isCompleted) completer.complete();
    mapController.dispose();
    tiles.dispose();
    popupController.dispose();
    tabController?.dispose();
    itemsController.dispose();
    devicesController.dispose();
    friendsController.dispose();
    super.onClose();
  }
}
