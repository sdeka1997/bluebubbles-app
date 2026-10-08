import 'package:bluebubbles/app/layouts/findmy/findmy_camera.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_controller.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_friend_sort.dart';
import 'package:bluebubbles/app/layouts/findmy/widgets/findmy_items_tab_view.dart';
import 'package:bluebubbles/app/wrappers/trackpad_bug_wrapper.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class FindMyMapWidget extends StatelessWidget {
  final FindMyController controller;

  const FindMyMapWidget({super.key, required this.controller});

  /// Member marker keys of each group marker currently on the map.
  static final Map<String, List<String>> _groupMembers = {};

  @override
  Widget build(BuildContext context) {
    return TrackpadBugWrapper(
      builder: (context, bugDetected) {
        return Obx(() {
          final tab = controller.tabIndex.value;
          final logicalItems = tab == 2
              ? collapseFindMyAccessoryComponents(
                  controller.devices.where((item) => item.isConsideredAccessory).toList(),
                )
              : const <FindMyDevice>[];
          final products = switch (tab) {
            1 => controller.devices.where((item) => !item.isConsideredAccessory).toList(),
            2 => logicalItems,
            _ => const <FindMyDevice>[],
          };
          // Friends always remain individual. Devices and items group only by
          // Apple owner plus physical place, independent of the map zoom.
          final markerGroups = tab == 0
              ? controller.visibleMarkers.map((marker) => [marker]).toList()
              : _groupProductMarkers(products);
          final visibleMarkers = markerGroups.expand((group) => group).toList();
          final renderedMarkers = markerGroups
              .map((group) => group.length == 1 ? group.single : _buildGroupMarker(context, group))
              .toList();
          final currentLocation = controller.location.value;
          final currentCenter =
              tab == 0 && isUsableFindMyCoordinate(currentLocation?.latitude, currentLocation?.longitude)
              ? LatLng(currentLocation!.latitude, currentLocation.longitude)
              : null;
          LatLng? markerCenter;
          for (final marker in visibleMarkers) {
            if (isUsableFindMyCoordinate(marker.point.latitude, marker.point.longitude)) {
              markerCenter = marker.point;
              break;
            }
          }
          // Wait for GPS before falling back to a marker, so the map doesn't open elsewhere and then jump.
          final initialCenter = currentCenter ?? (controller.resolvingCurrentLocation.value ? null : markerCenter);

          if (initialCenter == null) {
            final isLoading =
                controller.resolvingCurrentLocation.value ||
                controller.fetching.value == true ||
                controller.fetching2.value == true;
            return Center(child: isLoading ? const CircularProgressIndicator() : const Text("Location unavailable"));
          }

          return FlutterMap(
            mapController: controller.mapController,
            options: MapOptions(
              initialZoom: currentCenter != null ? 10.0 : 5.0,
              minZoom: 1.0,
              maxZoom: 18.0,
              initialCenter: initialCenter,
              onTap: (_, _) => controller.popupController.hideAllPopups(),
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
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bluebubbles.app',
              ),
              PopupMarkerLayer(
                options: PopupMarkerLayerOptions(
                  popupController: controller.popupController,
                  markers: renderedMarkers,
                  popupDisplayOptions: PopupDisplayOptions(
                    builder: (context, marker) => _buildMarkerPopup(context, marker),
                  ),
                ),
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                  ),
                ],
              ),
            ],
          );
        });
      },
    );
  }

  List<List<Marker>> _groupProductMarkers(List<FindMyDevice> products) {
    final points = <FindMyProductPoint>[];
    for (final product in products) {
      final id = product.id;
      final location = product.location;
      if (id == null || !isUsableFindMyCoordinate(location?.latitude, location?.longitude)) continue;
      points.add(
        FindMyProductPoint(
          id: id,
          ownerId: product.prsId,
          location: controller.markerPointForDevice(product),
          accuracyMeters: location!.horizontalAccuracy ?? 50,
        ),
      );
    }
    return groupFindMyProductsByOwnerAndPlace(points)
        .map((group) => group.map((point) => controller.markers[point.id]).whereType<Marker>().toList())
        .where((group) => group.isNotEmpty)
        .toList();
  }

  /// One marker standing in for multiple products owned by one person at one
  /// physical place, drawn as the first product with a total-count badge.
  Marker _buildGroupMarker(BuildContext context, List<Marker> group) {
    final memberKeys = group.map(_markerKey).toList();
    _groupMembers[memberKeys.join('|')] = memberKeys;
    final top = group.first;
    return Marker(
      key: ValueKey('group:${memberKeys.join('|')}'),
      point: top.point,
      width: top.width + 14,
      height: top.height + 14,
      alignment: top.alignment,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, bottom: 0, width: top.width, height: top.height, child: top.child),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: context.theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '${group.length}',
                style: context.theme.textTheme.labelSmall!.copyWith(
                  color: context.theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _markerKey(Marker marker) => (marker.key as ValueKey?)?.value as String? ?? '';

  Widget _buildGroupPopup(BuildContext context, List<String> memberKeys) {
    return Obx(() {
      final hideContactInfo = shouldRedactFindMyContactInfo();
      final rows = <Widget>[];
      for (final keyStr in memberKeys) {
        String? title;
        String? subtitle;
        if (keyStr.startsWith("device-")) {
          final item = controller.devices.firstWhereOrNull((e) => (e.id ?? '') == keyStr.substring("device-".length));
          if (item == null) continue;
          title = hideContactInfo ? "Device" : (item.displayName ?? "Unknown Device");
          subtitle = hideContactInfo ? null : (item.address?.label ?? item.address?.mapItemFullAddress);
        } else if (keyStr.startsWith("friend-")) {
          final item = controller.friends.firstWhereOrNull((e) => e.stableId == keyStr.substring("friend-".length));
          if (item == null) continue;
          final handleState = item.handle != null ? HandleSvc.getOrCreateHandleState(item.handle!) : null;
          title = hideContactInfo
              ? (handleState?.fakeName ?? 'Contact')
              : (item.handle?.displayName ?? item.title ?? "Unknown Friend");
          subtitle = hideContactInfo ? null : item.shortAddress;
        } else {
          continue;
        }
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.theme.textTheme.labelLarge),
                if (subtitle != null) Text(subtitle, style: context.theme.textTheme.bodySmall),
              ],
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260, maxHeight: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: context.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
          ),
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: rows),
          ),
        ),
      );
    });
  }

  Widget _buildMarkerPopup(BuildContext context, Marker marker) {
    final ValueKey? key = marker.key as ValueKey?;
    final keyStr = key?.value as String? ?? '';
    if (keyStr == "current") return const SizedBox();

    if (keyStr.startsWith("group:")) {
      final members = _groupMembers[keyStr.substring("group:".length)];
      return members == null ? const SizedBox() : _buildGroupPopup(context, members);
    }

    if (keyStr.startsWith("device-")) {
      final deviceId = keyStr.substring("device-".length);
      final item = controller.devices.firstWhereOrNull((e) => (e.id ?? '') == deviceId);
      if (item == null) return const SizedBox();
      return _buildDevicePopup(context, item);
    } else if (keyStr.startsWith("friend-")) {
      final stableId = keyStr.substring("friend-".length);
      final item = controller.friends.firstWhereOrNull((e) => e.stableId == stableId);
      if (item == null) return const SizedBox();
      return _buildFriendPopup(context, item);
    }

    return const SizedBox();
  }

  Widget _buildDevicePopup(BuildContext context, FindMyDevice item) {
    return Obx(() {
      final hideContactInfo = shouldRedactFindMyContactInfo();
      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: context.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hideContactInfo ? "Device" : (item.displayName ?? "Unknown Device"),
                style: context.theme.textTheme.labelLarge,
              ),
              Text(
                hideContactInfo
                    ? "Location"
                    : (item.address?.label ?? item.address?.mapItemFullAddress ?? "No location found"),
                style: context.theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFriendPopup(BuildContext context, FindMyFriend item) {
    return Obx(() {
      final hideContactInfo = shouldRedactFindMyContactInfo();
      final handleState = item.handle != null ? HandleSvc.getOrCreateHandleState(item.handle!) : null;
      final displayName = hideContactInfo
          ? (handleState?.fakeName ?? 'Contact')
          : (item.handle?.displayName ?? item.title ?? "Unknown Friend");

      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: context.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: context.theme.textTheme.labelLarge),
              Text(
                hideContactInfo ? "Location" : (item.longAddress ?? "No location found"),
                style: context.theme.textTheme.bodySmall,
              ),
              if (item.lastUpdated != null && item.status != LocationStatus.live)
                Text("Last updated ${buildDate(item.lastUpdated)}", style: context.theme.textTheme.bodySmall),
              if (item.status != null)
                Text("${item.status!.name.capitalize!} Location", style: context.theme.textTheme.bodySmall),
            ],
          ),
        ),
      );
    });
  }
}
