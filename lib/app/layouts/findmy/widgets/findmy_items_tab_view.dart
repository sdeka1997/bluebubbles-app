import 'package:bluebubbles/app/layouts/findmy/findmy_controller.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_load_state.dart';
import 'package:bluebubbles/app/layouts/findmy/widgets/findmy_device_list_tile.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/settings_widgets.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

bool _hasDisplayLocation(FindMyDevice item) {
  final label = item.address?.label?.trim();
  final address = item.address?.mapItemFullAddress?.trim();
  return (label?.isNotEmpty ?? false) || (address?.isNotEmpty ?? false);
}

class FindMyItemsTabView extends StatelessWidget {
  final FindMyController controller;

  const FindMyItemsTabView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.products.value.items;
      final itemsWithLocation = items.where(_hasDisplayLocation).toList();
      final itemsWithoutLocation = items.where((item) => !_hasDisplayLocation(item)).toList();

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
          if (items.isEmpty || controller.devicesState.value.load == FindMyLoad.failed)
            _buildEmptyState(context, controller.devicesState.value),
          if (itemsWithLocation.isNotEmpty)
            SettingsHeader(iosSubtitle: iosSubtitle, materialSubtitle: materialSubtitle, text: "Items"),
          if (itemsWithLocation.isNotEmpty)
            SettingsSection(
              backgroundColor: context.tileColor,
              children: [
                Material(
                  color: Colors.transparent,
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, i) =>
                        FindMyDeviceListTile(item: itemsWithLocation[i], controller: controller, isItem: true),
                    itemCount: itemsWithLocation.length,
                  ),
                ),
              ],
            ),
          if (itemsWithoutLocation.isNotEmpty)
            SettingsHeader(
              iosSubtitle: iosSubtitle,
              materialSubtitle: materialSubtitle,
              text: "Items without locations",
            ),
          if (itemsWithoutLocation.isNotEmpty)
            SettingsSection(
              backgroundColor: context.tileColor,
              children: [
                Material(
                  color: Colors.transparent,
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, i) =>
                        FindMyDeviceListTile(item: itemsWithoutLocation[i], controller: controller, isItem: true),
                    itemCount: itemsWithoutLocation.length,
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
                  FindMyLoad.loaded => "You have no accessories.",
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
