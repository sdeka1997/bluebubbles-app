import 'package:bluebubbles/app/layouts/findmy/findmy_controller.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_friend_sort.dart';
import 'package:bluebubbles/app/layouts/findmy/widgets/findmy_raw_data_dialog.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:maps_launcher/maps_launcher.dart';

class FindMyDeviceListTile extends StatelessWidget {
  final FindMyDevice item;
  final FindMyController controller;
  final bool isItem;

  const FindMyDeviceListTile({super.key, required this.item, required this.controller, this.isItem = false});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hideContactInfo = shouldRedactFindMyContactInfo();

      final displayName = hideContactInfo
          ? (isItem ? "Item" : "Device")
          : (item.displayName ?? (isItem ? "Unknown Item" : "Unknown Device"));

      final hasUsableCoordinates = isUsableFindMyCoordinate(item.location?.latitude, item.location?.longitude);
      final displayLocation = hideContactInfo
          ? "Location"
          : (item.address?.label ??
                item.address?.mapItemFullAddress ??
                (hasUsableCoordinates ? "Locating…" : "No location found"));
      final lastKnownAt = item.lastKnownLocationAt;
      final subtitle = hideContactInfo || lastKnownAt == null
          ? displayLocation
          : "$displayLocation\nLast updated ${buildDate(lastKnownAt)}";
      final fullAddress = item.address?.mapItemFullAddress?.trim();
      final hasFullAddress = fullAddress?.isNotEmpty ?? false;
      final markerPoint = hasUsableCoordinates ? controller.markerPointForDevice(item) : null;
      final canOpenMaps = markerPoint != null || hasFullAddress;
      final markerKey = 'device-${controller.markerIdentityForDevice(item)}';
      final selected = controller.isSelected(markerKey);
      final selectedLocation = hideContactInfo ? 'Location' : (item.address?.mapItemFullAddress ?? displayLocation);
      final selectedSubtitle = lastKnownAt == null
          ? selectedLocation
          : '$selectedLocation\nLast updated ${buildDate(lastKnownAt)}';

      return AnimatedContainer(
        key: controller.rowKeyFor(markerKey),
        duration: const Duration(milliseconds: 180),
        color: selected ? context.theme.colorScheme.primaryContainer.withValues(alpha: 0.35) : Colors.transparent,
        child: ListTile(
          selected: selected,
          mouseCursor: MouseCursor.defer,
          title: Text(displayName),
          subtitle: Text(selected ? selectedSubtitle : subtitle),
          isThreeLine: selected,
          onTap: markerPoint != null
              ? () async {
                  await controller.completer.future;
                  await controller.selectMarker(markerKey, markerPoint);
                }
              : null,
          trailing: selected && canOpenMaps
              ? ButtonTheme(
                  minWidth: 1,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: context.theme.colorScheme.primaryContainer,
                    ),
                    onPressed: () async {
                      if (markerPoint != null) {
                        await MapsLauncher.launchCoordinates(markerPoint.latitude, markerPoint.longitude);
                      } else {
                        await MapsLauncher.launchQuery(fullAddress!);
                      }
                    },
                    child: const Icon(Icons.directions, size: 20),
                  ),
                )
              : null,
          onLongPress: hideContactInfo
              ? null
              : () async {
                  showDialog(
                    context: context,
                    builder: (context) => FindMyRawDataDialog(item: item),
                  );
                },
        ),
      );
    });
  }
}
