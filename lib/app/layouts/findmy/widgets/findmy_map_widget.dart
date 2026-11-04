import 'dart:async';

import 'package:bluebubbles/app/layouts/findmy/findmy_camera.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_controller.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_device_glyph.dart';
import 'package:bluebubbles/app/layouts/findmy/widgets/findmy_items_tab_view.dart';
import 'package:bluebubbles/app/wrappers/trackpad_bug_wrapper.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class FindMyMapWidget extends StatefulWidget {
  final FindMyController controller;

  const FindMyMapWidget({super.key, required this.controller});

  @override
  State<FindMyMapWidget> createState() => _FindMyMapWidgetState();
}

class _FindMyMapWidgetState extends State<FindMyMapWidget> {
  FindMyController get controller => widget.controller;

  /// Member marker keys of each group marker currently on the map.
  final Map<String, List<String>> _groupMembers = {};

  late final AppLifecycleListener _lifecycle;
  StreamSubscription<List<ConnectivityResult>>? _connectivity;

  @override
  void initState() {
    super.initState();
    // Tiles that failed while the app was away or offline get another try.
    _lifecycle = AppLifecycleListener(onResume: () => controller.tiles.reload());
    _connectivity = Connectivity().onConnectivityChanged.listen(
      (results) {
        if (results.any((result) => result != ConnectivityResult.none)) controller.tiles.reload();
      },
      // Throws on Linux without NetworkManager; tiles then retry on resume only.
      onError: (Object e) => Logger.warn("Connectivity updates unavailable", error: e, tag: 'FindMyMap'),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _connectivity?.cancel();
    super.dispose();
  }

  /// Where the map opens: around whatever is already known for the current
  /// tab, otherwise on the whole world. Locations that arrive later reframe
  /// it through the controller, so the map never waits on one to appear.
  MapOptions _options(bool bugDetected) {
    final focus = controller.cameraFocusForTab();
    return MapOptions(
      initialCenter: findMyWorldCenter,
      initialZoom: findMyWorldZoom,
      initialCameraFit: focus.isEmpty
          ? null
          : CameraFit.coordinates(coordinates: focus, padding: controller.cameraPadding, maxZoom: findMyDetailZoom),
      minZoom: findMyWorldZoom,
      maxZoom: findMyMaxZoom,
      onTap: (_, _) {
        controller.popupController.hideAllPopups();
        controller.clearSelection();
      },
      onPositionChanged: (_, hasGesture) {
        if (hasGesture) controller.noteCameraGesture();
      },
      keepAlive: true,
      interactionOptions: InteractionOptions(
        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        forceOnlySinglePinchGesture: bugDetected,
      ),
      onMapReady: () {
        if (!controller.completer.isCompleted) {
          controller.completer.complete();
        }
        controller.fitCameraToTab();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TrackpadBugWrapper(
      builder: (context, bugDetected) {
        // The map stays mounted for the life of the page, whatever is or is
        // not known yet; only the markers and the empty-state note change.
        return Stack(
          children: [
            FlutterMap(
              mapController: controller.mapController,
              options: _options(bugDetected),
              children: [
                // The same widget every build, so marker and GPS updates never rebuild it.
                controller.tiles.layer,
                Obx(() {
                  final visibleMarkers = _visibleMarkers();
                  final tab = controller.tabIndex.value;
                  return Builder(
                    builder: (context) {
                      final markerGroups = tab == 0
                          ? visibleMarkers.map((marker) => [marker]).toList()
                          : groupFindMyMarkersForZoom(visibleMarkers, MapCamera.of(context));
                      final renderedMarkers = markerGroups
                          .map((group) => group.length == 1 ? group.single : _buildGroupMarker(context, group))
                          .toList();
                      return PopupMarkerLayer(
                        options: PopupMarkerLayerOptions(
                          popupController: controller.popupController,
                          markers: renderedMarkers,
                          markerTapBehavior: MarkerTapBehavior.custom((popupSpec, _, _) {
                            _handleMarkerTap(popupSpec.marker);
                          }),
                        ),
                      );
                    },
                  );
                }),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                    ),
                  ],
                ),
              ],
            ),
            Obx(() {
              final isLoading = controller.friendsState.value.isLoading || controller.devicesState.value.isLoading;
              if (isLoading || controller.cameraFocusForTab().isNotEmpty) return const SizedBox.shrink();
              return IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text("Location unavailable"),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  /// The markers of the current tab; Devices and Items show only their own
  /// logical products.
  List<Marker> _visibleMarkers() {
    final tab = controller.tabIndex.value;
    if (tab == 0) return controller.visibleMarkers;
    final products = tab == 1 ? findMyDeviceProducts(controller.devices) : findMyItemProducts(controller.devices);
    final productIds = products.map(controller.markerIdentityForDevice).toSet();
    return controller.visibleMarkers.where((marker) {
      final key = _markerKey(marker);
      return key.startsWith('device-') && productIds.contains(key.substring('device-'.length));
    }).toList();
  }

  void _handleMarkerTap(Marker marker) {
    final key = _markerKey(marker);
    if (key.startsWith('group:')) {
      final members = _groupMembers[key.substring('group:'.length)] ?? const <String>[];
      final points = members
          .map((member) => controller.markers[member.replaceFirst('device-', '')]?.point)
          .whereType<LatLng>()
          .toList();
      if (points.isNotEmpty) controller.focusMarkerGroup(points);
      return;
    }
    if (key == 'current') return;
    controller.selectMarker(key, marker.point);
  }

  /// One zoom-dependent collision capsule: show up to two member icons,
  /// then `+N` for the additional products hidden at this zoom.
  Marker _buildGroupMarker(BuildContext context, List<Marker> group) {
    final memberKeys = group.map(_markerKey).toList();
    final groupKey = memberKeys.join('|');
    _groupMembers[groupKey] = memberKeys;
    final summary = summarizeFindMyGroup(memberKeys);
    final width = 8.0 + summary.visible.length * 27 + (summary.remaining > 0 ? 34 : 0);
    return Marker(
      key: ValueKey('group:$groupKey'),
      point: group.first.point,
      width: width,
      height: 35,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final key in summary.visible)
              SizedBox(width: 27, height: 27, child: Center(child: _buildProductGlyph(context, key))),
            if (summary.remaining > 0)
              Container(
                constraints: const BoxConstraints(minWidth: 27, minHeight: 27),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: context.theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+${summary.remaining}',
                  style: context.theme.textTheme.labelMedium!.copyWith(
                    color: context.theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGlyph(BuildContext context, String markerKey) {
    if (!markerKey.startsWith('device-')) return const Icon(Icons.devices, color: Colors.black, size: 22);
    final id = markerKey.substring('device-'.length);
    final item = controller.devices.firstWhereOrNull((device) => device.id == id);
    if (item == null) return const Icon(Icons.devices, color: Colors.black, size: 22);
    final glyph = findMyGlyph(item);
    if (glyph.emoji != null) {
      return Text(glyph.emoji!, style: context.theme.textTheme.titleMedium!.copyWith(fontFamily: 'Apple Color Emoji'));
    }
    return Icon(glyph.icon, color: Colors.black, size: 22);
  }

  static String _markerKey(Marker marker) => (marker.key as ValueKey?)?.value as String? ?? '';
}
