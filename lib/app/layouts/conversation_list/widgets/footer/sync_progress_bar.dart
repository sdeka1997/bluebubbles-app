import 'package:bluebubbles/services/backend/sync/sync_windows.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A bar under the conversation list while a long incremental sync catches up,
/// like the "Updating Messages" bar in Messages on iOS. Hidden for short syncs.
class SyncProgressBar extends StatelessWidget {
  const SyncProgressBar({super.key, this.batchSize = 1000});

  final int batchSize;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final seen = SyncSvc.incrementalSyncSeen.value;
      final total = SyncSvc.incrementalSyncTotal.value;
      if (!SyncSvc.isIncrementalSyncing.value || !showSyncProgressBar(total: total, batchSize: batchSize)) {
        return const SizedBox.shrink();
      }
      final theme = context.theme;
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                syncProgressLabel(seen: seen, total: total),
                style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.outline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: syncProgress(seen: seen, total: total),
                  minHeight: 3,
                  backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
