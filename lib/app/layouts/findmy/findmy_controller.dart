import 'package:bluebubbles/app/layouts/findmy/findmy_device_glyph.dart';
import 'package:bluebubbles/app/layouts/findmy/widgets/findmy_live_pulse.dart';
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
import 'package:bluebubbles/app/layouts/findmy/findmy_friend_update.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_format.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_load_state.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_location_cache.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_panel.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_scroll.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_selection.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_tiles.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_products.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_location_clipper.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_pin_clipper.dart';
import 'package:bluebubbles/helpers/helpers.dart';

class FindMyController extends GetxController {
  FindMyController({FindMyTileLoader? tiles, void Function(bool open, String? handle)? reportScreen})
      : tiles = tiles ?? FindMyTileLoader(),
        _reportScreen = reportScreen ?? _reportScreenToServer;

  /// Tells the server whether this screen is open and who is selected on it;
  /// see [_reportScreenToServer].
  final void Function(bool open, String? handle) _reportScreen;

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
  /// The selected person or product; see [FindMySelection].
  final Rxn<FindMySelection> selection = Rxn<FindMySelection>();
  final Map<String, GlobalKey> _rowKeys = <String, GlobalKey>{};
  final Map<String, Future<ContactV2?>> _contactLookups = <String, Future<ContactV2?>>{};
  final Set<String> _friendMarkerKeys = <String>{};
  final Set<String> _deviceMarkerKeys = <String>{};
  final Rxn<Position> location = Rxn<Position>();

  /// Apple's address for the selected friend as last reported to the server,
  /// which follows them live; null for nobody.
  String? _reported;

  /// The followed friend until a location newer than the tap arrives: their
  /// row spins, as Find My's does for a moment after clicking someone.
  final RxnString _awaitingLive = RxnString();
  DateTime? _awaitingSince;
  Timer? _awaitingLimit;

  /// The tapped friend once their first location after the tap has arrived:
  /// Apple is following them live. Null until then, and for nobody.
  final RxnString _liveFollowed = RxnString();

  /// How long a tapped friend's row may spin. Live location can take a few
  /// seconds to start on the Mac; a friend Apple has nothing new for stops
  /// spinning after this.
  static const Duration liveLocatingLimit = Duration(seconds: 45);

  /// Insets of the map area the opening camera frames; see [findMyCameraPadding].
  EdgeInsets cameraPadding = const EdgeInsets.all(findMyCameraMargin);
  bool _cameraMovedByUser = false;

  /// Whether the map keeps the selected person in view as they move: true
  /// once they are selected, until the user moves the map or deselects.
  bool _followSelected = false;

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
    _reportScreen(true, null);
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

  /// While this screen is open, Find My runs on the Mac, the server publishes
  /// locations as it writes them, and the person named by [handle] is followed
  /// live; once it closes, the server quits Find My, which also ends the
  /// follow. The server keeps no other state, so the whole of it is sent on
  /// every change. Servers without this event ignore it.
  static void _reportScreenToServer(bool open, String? handle) {
    if (!GetIt.I.isRegistered<SocketService>()) return;
    SocketSvc.sendMessage('findmy-screen', {'open': open, 'handle': handle}).then(
      (_) {},
      onError: (Object e) => Logger.info("Find My screen state not delivered: $e"),
    );
  }

  /// Coming back to the app counts as opening the screen again.
  void onAppResumed() {
    if (!_isAlive) return;
    _startSession();
    _reportOpen(locateAgain: true);
  }

  /// Leaving the app counts as closing the screen; Find My quitting on the
  /// Mac ends any follow with it.
  void onAppPaused() {
    if (!_isAlive) return;
    _reportScreen(false, null);
    _stopAwaitingLive();
    _setLiveFollowed(null);
  }

  /// The server knows each connection separately, so a new one is told the
  /// screen is open; a load that failed while offline is tried again.
  void onConnectionRestored() {
    if (!_isAlive) return;
    final failed = friendsState.value.load == FindMyLoad.failed || devicesState.value.load == FindMyLoad.failed;
    if (failed) _startSession();
    _reportOpen();
  }

  /// Reports the screen open with who is selected. [locateAgain] spins the
  /// selected friend's row again, for a Find My launched afresh.
  void _reportOpen({bool locateAgain = false}) {
    final selection = this.selection.value;
    _reported = selection?.kind == FindMySelectionKind.friend ? selectedFriendHandle : null;
    _reportScreen(true, _reported);
    if (locateAgain && _reported != null) _startAwaitingLive(_reported!);
  }

  /// Reports a new selection, unless the server already has it.
  void _reportSelection() {
    final selection = this.selection.value;
    final handle = selection?.kind == FindMySelectionKind.friend ? selectedFriendHandle : null;
    if (handle == _reported) return;
    _reported = handle;
    _reportScreen(true, handle);
    if (handle == null) {
      _stopAwaitingLive();
      _setLiveFollowed(null);
    } else {
      _startAwaitingLive(handle);
    }
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

  bool isSelected(FindMySelection candidate) => selection.value == candidate;

  /// Apple's address for the selected friend, which a live location request
  /// names; null when nobody, a device, or a friend without one is selected.
  /// A selection read back from a map pin carries only the identity, so the
  /// address comes from the friend shown under it.
  String? get selectedFriendHandle {
    final selected = selection.value;
    if (selected == null || selected.kind != FindMySelectionKind.friend) return null;
    if (selected.handle != null) return selected.handle;
    for (final friend in friends) {
      if (FindMySelection.ofFriend(friend) == selected) return friend.stableId;
    }
    return null;
  }

  void clearSelection() {
    if (selection.value == null) return;
    selection.value = null;
    _followSelected = false;
    _reportSelection();
    _rebuildAllMarkers();
  }

  /// Whether [friend]'s row spins: they were just tapped and no location
  /// newer than the tap has arrived yet.
  bool isLocatingLive(FindMyFriend friend) {
    final awaiting = _awaitingLive.value;
    return awaiting != null && friend.stableId == awaiting;
  }

  /// Whether [friend] is selected and being followed live: a location newer
  /// than the tap has arrived for them. Their pin rings and pulses meanwhile.
  bool isFollowedLive(FindMyFriend friend) {
    final followed = _liveFollowed.value;
    return followed != null && friend.stableId == followed;
  }

  void _setLiveFollowed(String? handle) {
    if (_liveFollowed.value == handle) return;
    _liveFollowed.value = handle;
    _rebuildAllMarkers();
  }

  void _startAwaitingLive(String handle) {
    _setLiveFollowed(null);
    _awaitingLive.value = handle;
    _awaitingSince = DateTime.now();
    _awaitingLimit?.cancel();
    _awaitingLimit = Timer(liveLocatingLimit, _stopAwaitingLive);
  }

  void _stopAwaitingLive() {
    _awaitingLimit?.cancel();
    _awaitingLimit = null;
    _awaitingLive.value = null;
  }

  /// Selects one logical entity from either its map marker or drawer row.
  Future<void> select(FindMySelection selected, LatLng point) async {
    final selectedTab = tabIndex.value;
    final markerKey = selected.markerKey;
    bool selectionIsCurrent() => _isAlive && selection.value == selected && tabIndex.value == selectedTab;

    selection.value = selected;
    _reportSelection();
    _rebuildAllMarkers();
    popupController.hideAllPopups();
    await completer.future;
    if (!selectionIsCurrent()) return;
    if (panelController.isAttached) await panelController.animatePanelToSnapPoint();
    if (!selectionIsCurrent()) return;
    focusMap(point);
    _followSelected = selected.kind == FindMySelectionKind.friend;
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
    _followSelected = false;
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
      final cacheable = cachedLocationForFriend(friend);
      if (cacheable != null) {
        _locationCache.remember('friend:$key', cacheable);
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
      onFriendLocation(FindMyFriend.fromJson(data));
    } catch (e, s) {
      Logger.warn("Failed to fetch FindMy locations", error: e, trace: s, tag: 'FindMyController');
    }
  }

  /// A location Find My wrote for one friend.
  void onFriendLocation(FindMyFriend friend) {
    if (!_isAlive) return;
    try {
      Logger.info("Received new location for ${friend.handle?.address}");
      // Keep the last known good location when Apple pushes a no-fix or malformed update.
      if (!hasUsableFindMyLocation(friend)) return;
      final since = _awaitingSince;
      final fresh = since != null && friend.lastUpdated != null && friend.lastUpdated!.isAfter(since);
      if (fresh && friend.stableId != null && friend.stableId == _awaitingLive.value) {
        _stopAwaitingLive();
        _liveFollowed.value = friend.stableId;
      }
      _withCachedFriendLocations([friend]);
      _saveCacheSoon();

      final existingFriendIndex = friends.indexWhere((e) => e.stableId != null && e.stableId == friend.stableId);
      final existingFriend = existingFriendIndex == -1 ? null : friends[existingFriendIndex];
      final shouldUpdate =
          existingFriend == null || shouldAcceptFindMyFriendUpdate(existingFriend, friend);

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
        if (_followSelected && completer.isCompleted && selection.value == FindMySelection.ofFriend(friend)) {
          focusMap(markerPointForFriend(friend));
        }
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

  final Rx<FindMySourceState> friendsState = FindMySourceState.idle.obs;
  final Rx<FindMySourceState> devicesState = FindMySourceState.idle.obs;

  /// Each load is one session; answers from an older one are ignored.
  int _generation = 0;
  final List<CancelToken> _sessionTokens = [];

  /// The opening load: shows what was saved last time at once, then reads
  /// the server's stored friends and devices side by side.
  void _open() {
    _showSaved();
    _startSession();
  }

  /// Reads the friends and devices the server has, rendering each as it
  /// arrives. Nothing is asked to refresh: Find My runs on the Mac while this
  /// screen is open, and what it writes follows over the socket.
  void _startSession() {
    if (!_isAlive) return;
    _cancelSession();
    final generation = ++_generation;
    friendsState.value = friendsState.value.loading();
    devicesState.value = devicesState.value.loading();
    _request(generation, friendsState, HttpSvc.icloud.getFriends, readDeadline, _applyFriends);
    _request(generation, devicesState, HttpSvc.icloud.getDevices, readDeadline, _applyDevices);
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
            if (current()) onResponse(response);
          },
          onError: (Object e, StackTrace s) {
            if (!current()) return;
            Logger.warn("Find My ${state == friendsState ? 'friends' : 'devices'} request failed", error: e, tag: 'FindMyController');
            state.value = state.value.failed(describeFindMyError(e));
          },
        );
  }

  /// The list a Find My response carries, or null when it carries none.
  List? _dataOf(Response response) => response.data is Map ? response.data['data'] as List? : null;

  void _applyFriends(Response response) {
    try {
      final data = _dataOf(response);
      if (data != null) {
        final roster = data.map((e) => FindMyFriend.fromJson(e)).toList();
        _locationCache.rememberFriends(data.cast<Map<String, dynamic>>());
        _showFriends(roster);
        _saveCacheSoon();
      }
      friendsState.value = friendsState.value.loaded(DateTime.now());
    } catch (e, s) {
      Logger.error("Failed to parse FindMy Friends location data!", error: e, trace: s);
      friendsState.value = friendsState.value.failed(describeFindMyError(e));
    }
  }

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
    final selected = selection.value?.markerKey;
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
    final selected = isSelected(FindMySelection.device(markerKey));
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
    final selected = isSelected(FindMySelection.ofFriend(friend));
    final live = selected && isFollowedLive(friend);
    final size = selected ? 54.0 : 35.0;
    _friendMarkerKeys.add(markerKey);
    final pin = Container(
      key: live ? const ValueKey('findmy-live-ring') : null,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: live ? Border.all(color: Get.context!.theme.colorScheme.primary, width: 4) : null,
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
    );
    // A live pin pulses outward; the marker is sized for the pulse so it is not clipped
    final markerSize = live ? size * findMyLivePulseScale : size;
    markers[markerKey] = Marker(
      key: ValueKey('friend-$markerKey'),
      point: markerPointForFriend(friend),
      width: markerSize,
      height: markerSize,
      child: live
          ? Stack(
              alignment: Alignment.center,
              children: [
                FindMyLivePulse(key: const ValueKey('findmy-live-pulse'), size: size, color: Get.context!.theme.colorScheme.primary),
                pin,
              ],
            )
          : pin,
      alignment: live ? Alignment.center : Alignment.topCenter,
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
    _reportScreen(false, null);
    _awaitingLimit?.cancel();
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
