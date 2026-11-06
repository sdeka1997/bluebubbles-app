import 'package:bluebubbles/services/backend/settings/actions/shared_preferences_theme_actions.dart';
import 'dart:async';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/settings/actions/shared_preferences_findmy_actions.dart';
import 'package:bluebubbles/services/network/api/icloud_api.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:dio/dio.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_it/get_it.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Location permission that is denied, so no fix ever arrives.
class DeniedGeolocator extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.denied;

  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.deniedForever;
}

class FakeConnectivity extends ConnectivityPlatform with MockPlatformInterfaceMixin {
  final StreamController<List<ConnectivityResult>> changes = StreamController.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => [ConnectivityResult.wifi];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => changes.stream;
}

/// Starts with no saved locations and drops whatever is saved.
/// No theme chosen, so spinners take the plain colours.
class FakeThemePrefs extends SharedPreferencesThemeActions {
  FakeThemePrefs(super.service);

  @override
  String? getSelectedLightTheme() => null;

  @override
  String? getSelectedDarkTheme() => null;
}

class FakeFindMyPrefs extends SharedPreferencesFindMyActions {
  FakeFindMyPrefs(super.service);

  String? saved;
  int writes = 0;

  @override
  String? getLocationCache() => saved;

  @override
  Future<void> setLocationCache(String json) async {
    writes++;
    saved = json;
  }

  @override
  Future<void> removeLocationCache() async => saved = null;
}

/// Holds every Find My request open until the test answers it, so a request
/// that the tunnel cancelled mid-flight can be modelled as one that simply
/// never completes.
class FakeICloudApi extends iCloudApi {
  FakeICloudApi(super.svc);

  final Map<String, List<Completer<Response>>> requests = {};
  final Map<String, List<CancelToken?>> tokens = {};

  /// Off models a transport that never noticed the cancel, so a request can
  /// still answer after the page gave up on it.
  bool honourCancel = true;

  Future<Response> _request(String name, CancelToken? cancelToken) {
    final completer = Completer<Response>();
    requests.putIfAbsent(name, () => []).add(completer);
    tokens.putIfAbsent(name, () => []).add(cancelToken);
    cancelToken?.whenCancel.then((_) {
      if (!honourCancel || completer.isCompleted) return;
      completer.completeError(
        DioException.requestCancelled(requestOptions: RequestOptions(path: name), reason: 'cancelled'),
      );
    });
    return completer.future;
  }

  int pending(String name) => requests[name]?.where((c) => !c.isCompleted).length ?? 0;

  void answer(String name, {Object data = const [], Map<String, dynamic>? metadata}) => requests[name]!
      .firstWhere((c) => !c.isCompleted)
      .complete(
        Response(
          requestOptions: RequestOptions(path: ""),
          statusCode: 200,
          data: {"data": data, "metadata": ?metadata},
        ),
      );

  void fail(String name) => requests[name]!
      .firstWhere((c) => !c.isCompleted)
      .completeError(DioException.connectionError(requestOptions: RequestOptions(path: name), reason: 'offline'));


  @override
  Future<Response> getFriends({CancelToken? cancelToken}) => _request("getFriends", cancelToken);


  @override
  Future<Response> getDevices({CancelToken? cancelToken}) => _request("getDevices", cancelToken);
}

/// Registers the services the Find My controller reads, with requests that
/// wait for the test and a location permission that is denied.
FakeICloudApi registerFindMyServices({FakeFindMyPrefs Function(SharedPreferencesService)? prefs}) {
  GeolocatorPlatform.instance = DeniedGeolocator();
  final settings = SettingsService()..settings = Settings();
  final sharedPrefs = SharedPreferencesService();
  sharedPrefs.findMy = (prefs ?? FakeFindMyPrefs.new)(sharedPrefs);
  sharedPrefs.theme = FakeThemePrefs(sharedPrefs);
  final http = HttpService();
  final icloud = FakeICloudApi(http);
  http.icloud = icloud;
  GetIt.I
    ..registerSingleton<BaseLogger>(BaseLogger())
    ..registerSingleton<SettingsService>(settings)
    ..registerSingleton<SharedPreferencesService>(sharedPrefs)
    ..registerSingleton<EventDispatcher>(EventDispatcher())
    ..registerSingleton<HttpService>(http)
    ..registerSingleton<ThemesService>(ThemesService());
  return icloud;
}

Future<void> resetFindMyServices() async {
  Get.reset();
  await GetIt.I.reset();
}

/// A device as the server sends it, with a usable location.
const Map<String, dynamic> phoneJson = {
  "id": "phone",
  "name": "Phone",
  "deviceClass": "iPhone",
  "location": {"latitude": 32.78, "longitude": -96.80, "timeStamp": 1790000000000},
};
