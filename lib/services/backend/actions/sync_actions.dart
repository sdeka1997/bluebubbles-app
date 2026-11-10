import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/services/backend/sync/sync_marker.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter/foundation.dart';

/// The `uniqueAddressAndService` of the sender a server message payload names,
/// or null for a message from me or a payload without a sender.
String? payloadSenderKey(Map<String, dynamic> msgData) {
  final handle = msgData['handle'];
  if (msgData['isFromMe'] == true || handle is! Map) return null;
  return Handle.fromMap(handle.cast<String, dynamic>()).uniqueAddressAndService;
}

class SyncActions {
  // ---------------------------------------------------------------------------
  // Unified sync entrypoint
  // ---------------------------------------------------------------------------

  /// Syncs handles, chats, messages, and attachments from raw API maps in one
  /// atomic write transaction (MessagingStore.syncBatch).
  ///
  /// [data] keys:
  ///   - `chatData`               Map<String,dynamic>?  — top-level chat (optional)
  ///   - `messagesData`           List<Map<String,dynamic>> — raw server message maps
  ///
  /// Returns a map with `messageIds` (List<int>) and `chatIds` (List<int>) of updated chats.
  static Future<Map<String, dynamic>> bulkSyncData(dynamic data) async {
    if (kIsWeb) return {'messageIds': <int>[], 'chatIds': <int>[]};
    return MessagingStore.current.syncBatch(data);
  }

  // ---------------------------------------------------------------------------
  // Existing actions
  // ---------------------------------------------------------------------------

  /// Performs an incremental sync of chats
  static Future<List<int>> performIncrementalSync(dynamic data) async {
    try {
      final incrementalSyncManager =
          IncrementalSyncManager.resumingFrom(SyncMarker(SettingsSvc.settings));

      await incrementalSyncManager.start();
      return incrementalSyncManager.latestMessageIdPerChat.values.toList();
    } catch (ex, s) {
      Logger.error('Incremental sync failed!', error: ex, trace: s);
      rethrow;
    }
  }
}
