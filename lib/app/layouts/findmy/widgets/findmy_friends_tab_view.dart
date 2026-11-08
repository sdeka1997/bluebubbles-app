import 'package:bluebubbles/app/layouts/findmy/findmy_controller.dart';
import 'package:bluebubbles/app/layouts/findmy/findmy_load_state.dart';
import 'package:bluebubbles/app/layouts/findmy/widgets/findmy_friend_list_tile.dart';
import 'package:bluebubbles/app/layouts/settings/widgets/settings_widgets.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FindMyFriendsTabView extends StatelessWidget {
  final FindMyController controller;

  const FindMyFriendsTabView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
          // A failure is shown even over saved rows, so stale data never passes as current.
          if (controller.friends.isEmpty || controller.friendsState.value.load == FindMyLoad.failed)
            _buildEmptyState(context, controller.friendsState.value),
          if (controller.friendsWithLocation.isNotEmpty)
            SettingsHeader(iosSubtitle: iosSubtitle, materialSubtitle: materialSubtitle, text: "Friends"),
          if (controller.friendsWithLocation.isNotEmpty)
            SettingsSection(
              backgroundColor: context.tileColor,
              children: [
                Material(
                  color: Colors.transparent,
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, i) => FindMyFriendListTile(
                      item: controller.friendsWithLocation[i],
                      controller: controller,
                      withLocation: true,
                    ),
                    itemCount: controller.friendsWithLocation.length,
                  ),
                ),
              ],
            ),
          if (controller.friendsWithoutLocation.isNotEmpty)
            SettingsHeader(
              iosSubtitle: iosSubtitle,
              materialSubtitle: materialSubtitle,
              text: "Friends without locations",
            ),
          if (controller.friendsWithoutLocation.isNotEmpty)
            SettingsSection(
              backgroundColor: context.tileColor,
              children: [
                Material(
                  color: Colors.transparent,
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, i) => FindMyFriendListTile(
                      item: controller.friendsWithoutLocation[i],
                      controller: controller,
                      withLocation: false,
                    ),
                    itemCount: controller.friendsWithoutLocation.length,
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
                  FindMyLoad.loaded => "You have no friends.",
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
