import 'package:bluebubbles/app/layouts/findmy/findmy_controller.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_load_state.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_friend_sort.dart';
import 'package:bluebubbles/app/layouts/findmy/widgets/findmy_device_list_tile.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/settings_widgets.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FindMyDevicesTabView extends StatelessWidget {
  final FindMyController controller;

  const FindMyDevicesTabView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final allDevices = controller.products.value.devices;

      bool hasUsableLocation(FindMyDevice item) {
        final hasCoordinates = isUsableFindMyCoordinate(item.location?.latitude, item.location?.longitude);
        final fullAddress = item.address?.mapItemFullAddress?.trim();
        return hasCoordinates || (fullAddress?.isNotEmpty ?? false);
      }

      List<FindMyDevice> withUnavailableLast(Iterable<FindMyDevice> devices) => [
        ...devices.where(hasUsableLocation),
        ...devices.where((item) => !hasUsableLocation(item)),
      ];

      final ownPrsIds = allDevices
          .where((item) => item.thisDevice == true)
          .map((item) => item.prsId)
          .whereType<String>()
          .toSet();
      final ownDevices = allDevices
          .where((item) => item.thisDevice == true || (item.prsId != null && ownPrsIds.contains(item.prsId)))
          .toList();
      final myDevices = withUnavailableLast(ownDevices);
      final otherDevices = withUnavailableLast(allDevices.where((item) => !ownDevices.contains(item)));

      final iosSubtitle = context.theme.textTheme.labelLarge!.copyWith(
        color: context.theme.colorScheme.onSurface.withValues(alpha: 0.6),
        fontWeight: FontWeight.w300,
      );
      final materialSubtitle = context.theme.textTheme.labelLarge!.copyWith(
        color: context.theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      );

      return SliverList(
        delegate: SliverChildListDelegate([
          if (allDevices.isEmpty || controller.devicesState.value.load == FindMyLoad.failed)
            _buildEmptyState(context, controller.devicesState.value),
          if (myDevices.isNotEmpty)
            SettingsHeader(iosSubtitle: iosSubtitle, materialSubtitle: materialSubtitle, text: "My Devices"),
          if (myDevices.isNotEmpty)
            SettingsSection(
              backgroundColor: context.tileColor,
              children: [
                Material(
                  color: Colors.transparent,
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, i) => FindMyDeviceListTile(item: myDevices[i], controller: controller),
                    itemCount: myDevices.length,
                  ),
                ),
              ],
            ),
          if (otherDevices.isNotEmpty)
            SettingsHeader(iosSubtitle: iosSubtitle, materialSubtitle: materialSubtitle, text: "Other Devices"),
          if (otherDevices.isNotEmpty)
            SettingsSection(
              backgroundColor: context.tileColor,
              children: [
                Material(
                  color: Colors.transparent,
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, i) => FindMyDeviceListTile(item: otherDevices[i], controller: controller),
                    itemCount: otherDevices.length,
                  ),
                ),
              ],
            ),
        ]),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context, FindMySourceState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                switch (state.load) {
                  FindMyLoad.failed => "Something went wrong: ${state.error}",
                  FindMyLoad.loaded => "You have no devices.",
                  _ => "Getting FindMy data...",
                },
                style: context.theme.textTheme.labelLarge,
                textAlign: TextAlign.center,
              ),
            ),
            if (state.isLoading) buildProgressIndicator(context, size: 15),
          ],
        ),
      ),
    );
  }
}
