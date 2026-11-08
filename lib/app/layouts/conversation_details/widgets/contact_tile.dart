import 'package:bluebubbles/app/components/animated_dropdown_menu.dart';
import 'package:bluebubbles/app/components/copy_address_button.dart';
import 'package:bluebubbles/app/layouts/conversation_details/dialogs/address_picker.dart';
import 'package:bluebubbles/app/components/avatars/contact_avatar_widget.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_down_button/pull_down_button.dart';

class ContactTile extends StatelessWidget {
  final Handle handle;
  final Chat chat;

  bool _hasPhones(ContactV2? contact) {
    return contact?.addresses.any((addr) => !addr.contains('@')) ?? false;
  }

  bool _hasEmails(ContactV2? contact) {
    return contact?.addresses.any((addr) => addr.contains('@')) ?? false;
  }

  const ContactTile({
    super.key,
    required this.handle,
    required this.chat,
  });

  @override
  Widget build(BuildContext context) {
    final handleState = HandleSvc.getOrCreateHandleState(handle);
    final contact = handle.contactsV2.firstOrNull;
    return Obx(() {
      final String displayName = handleState.displayName.value ?? handle.address;
      final String address = handleState.formattedAddress.value ?? handle.address;
      final bool isEmail = handle.address.isEmail;
      final child = InkWell(
        mouseCursor: MouseCursor.defer,
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: handle.address));
          showCopiedToast("Address copied to clipboard");
        },
        onSecondaryTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: context.theme.colorScheme.surfaceContainerHighest,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (ctx) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outlined, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              displayName,
                              style: context.theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 8),
                    ListTile(
                      mouseCursor: MouseCursor.defer,
                      leading: const Icon(Icons.copy_outlined),
                      title: const Text("Copy address"),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        Clipboard.setData(ClipboardData(text: handle.address));
                        showCopiedToast("Address copied to clipboard");
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
        child: ListTile(
          title: RichText(
            text: TextSpan(
              children: MessageHelper.buildEmojiText(
                displayName,
                context.theme.textTheme.bodyLarge!,
              ),
            ),
          ),
          subtitle: contact == null
              ? null
              : Text(
                  address,
                  style: context.theme.textTheme.bodyMedium!.copyWith(color: context.theme.colorScheme.outline),
                ),
          leading: ContactAvatarWidget(
            key: Key("${handle.address}-contact-tile"),
            handle: handle,
            borderThickness: 0.1,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CopyAddressButton(address: handle.address),
              ),
              _buildTrailing(context, contact: contact, isEmail: isEmail),
            ],
          ),
        ),
      );

      return child;
    });
  }

  Widget _buildTrailing(BuildContext context, {required ContactV2? contact, required bool isEmail}) {
    final bool hasPhones = _hasPhones(contact);
    final bool hasEmails = _hasEmails(contact);

    if (kIsWeb || (kIsDesktop && !isEmail) || (!isEmail && !hasPhones)) {
      return Container(width: 2);
    }

    final bool showEmail = (contact == null && isEmail) || hasEmails;
    final bool showPhone = ((contact == null && !isEmail) || hasPhones) && !kIsWeb && !kIsDesktop;
    final bool showVideo = showPhone;

    if (!showEmail && !showPhone && !showVideo) {
      return Container(width: 2);
    }

    if (SettingsSvc.settings.skin.value == Skins.iOS) {
      return _buildCupertinoMenu(
        context,
        contact: contact,
        showEmail: showEmail,
        showPhone: showPhone,
        showVideo: showVideo,
      );
    }

    return _buildMaterialMenu(
      context,
      contact: contact,
      showEmail: showEmail,
      showPhone: showPhone,
      showVideo: showVideo,
    );
  }

  Widget _buildCupertinoMenu(
    BuildContext context, {
    required ContactV2? contact,
    required bool showEmail,
    required bool showPhone,
    required bool showVideo,
  }) {
    final itemTheme = PullDownMenuItemTheme(
      textStyle: TextStyle(
        color: context.theme.colorScheme.onSurface,
      ),
      onHoverTextColor: context.theme.colorScheme.onSurface,
      onHoverBackgroundColor: context.theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
    );

    return PullDownButton(
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: context.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
      ),
      itemBuilder: (context) => [
        if (showEmail)
          PullDownMenuItem(
            itemTheme: itemTheme,
            title: 'Email',
            icon: CupertinoIcons.mail,
            onTap: () => showAddressPicker(contact, handle, isEmail: true, context),
          ),
        if (showPhone)
          PullDownMenuItem(
            itemTheme: itemTheme,
            title: 'Call',
            icon: CupertinoIcons.phone,
            onTap: () => showAddressPicker(contact, handle, context),
          ),
        if (showVideo)
          PullDownMenuItem(
            itemTheme: itemTheme,
            title: 'FaceTime',
            icon: CupertinoIcons.video_camera,
            onTap: () => showAddressPicker(contact, handle, context, video: true),
          ),
      ],
      buttonBuilder: (context, showMenu) => ClipOval(
        child: Material(
          color: context.theme.colorScheme.primary.withValues(alpha: 0.15),
          child: SizedBox(
            width: 30,
            height: 30,
            child: InkWell(
              onTap: showMenu,
              child: Icon(
                CupertinoIcons.ellipsis,
                color: context.theme.colorScheme.primary,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialMenu(
    BuildContext context, {
    required ContactV2? contact,
    required bool showEmail,
    required bool showPhone,
    required bool showVideo,
  }) {
    return AnimatedDropdownMenu(
      menuWidth: 180,
      trigger: (context, showMenu) => ClipOval(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: showMenu,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                Icons.more_vert,
                color: context.theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ),
      ),
      menuBuilder: (overlayContext, hideMenu) => DropdownMenuCard(
        width: 180,
        children: [
          if (showEmail)
            MenuItemRow(
              icon: Icons.email_outlined,
              label: 'Email',
              onTap: () => hideMenu().then((_) => showAddressPicker(contact, handle, isEmail: true, overlayContext)),
            ),
          if (showPhone)
            MenuItemRow(
              icon: Icons.call_outlined,
              label: 'Call',
              onTap: () => hideMenu().then((_) => showAddressPicker(contact, handle, overlayContext)),
            ),
          if (showVideo)
            MenuItemRow(
              icon: Icons.video_call_outlined,
              label: 'Video',
              onTap: () => hideMenu().then((_) => showAddressPicker(contact, handle, overlayContext, video: true)),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
