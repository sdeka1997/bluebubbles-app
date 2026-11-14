import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The chat list's update banner, bound to the release [SettingsService] found.
class AppUpdateBanner extends StatelessWidget {
  const AppUpdateBanner({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
        final update = SettingsSvc.availableUpdate.value;
        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: update == null || SettingsSvc.updateBannerDismissed.value
              ? const SizedBox(width: double.infinity)
              : AppUpdateBannerView(
                  version: update.version,
                  progress: SettingsSvc.updateProgress.value,
                  failed: SettingsSvc.updateFailed.value,
                  onUpdate: SettingsSvc.installAppUpdate,
                  onDismiss: () => SettingsSvc.updateBannerDismissed.value = true,
                ),
        );
      });
}

/// Which version is waiting, an Update button and the download's progress. Swiping it away hides
/// it until the app is next opened.
class AppUpdateBannerView extends StatelessWidget {
  const AppUpdateBannerView({
    super.key,
    required this.version,
    required this.progress,
    required this.failed,
    required this.onUpdate,
    required this.onDismiss,
  });

  final String version;

  /// From 0 to 1 while the update downloads, otherwise null.
  final double? progress;
  final bool failed;
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final downloading = progress != null;
    final subtitle = downloading
        ? "Downloading… ${(progress! * 100).round()}%"
        : failed
            ? "Download failed"
            : "Version $version";

    return Dismissible(
      key: ValueKey('app-update-$version'),
      direction: downloading ? DismissDirection.none : DismissDirection.horizontal,
      onDismissed: (_) => onDismiss(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Material(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    Icon(Icons.system_update_rounded, color: colors.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Update available",
                              style: text.titleSmall?.copyWith(color: colors.onPrimaryContainer)),
                          Text(subtitle,
                              style: text.bodySmall?.copyWith(color: colors.onPrimaryContainer.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: downloading ? null : onUpdate,
                      child: Text(failed ? "Retry" : "Update"),
                    ),
                  ],
                ),
              ),
              if (downloading)
                LinearProgressIndicator(value: progress, minHeight: 3, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
