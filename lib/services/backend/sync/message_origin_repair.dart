import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter/foundation.dart';

/// One page of a chat's message guids from the server, oldest first.
typedef MessageGuidPage = Future<List<String>> Function(String chatGuid, int offset, int limit);

/// Builds before K15 moved a twin's messages into its thread without
/// recording the Apple chat each came through, so the v6 upgrade could only
/// assume the chat they were on. Once (schema v7 marks it), this asks the
/// server which chat every message of a multi-copy thread belongs to and
/// records it; the database files them. A failed run stays pending and runs
/// again after the next sync.
class MessageOriginRepair {
  static const pageSize = 1000;

  static Future<void> run({MessageGuidPage? fetch}) async {
    if (kIsWeb) return;
    final store = MessagingStore.current;
    final chats = await store.chatsAwaitingOriginRepair();
    if (chats.isEmpty) return;
    final page = fetch ?? _serverPage;
    try {
      var changed = 0;
      for (final chat in chats) {
        final guids = <String>[];
        for (var offset = 0;; offset += pageSize) {
          final batch = await page(chat, offset, pageSize);
          guids.addAll(batch);
          if (batch.length < pageSize) break;
        }
        changed += await store.recordAppleChat(chat, guids);
      }
      await store.finishOriginRepair();
      Logger.info('Recorded the Apple chat of $changed message(s) across ${chats.length} chats',
          tag: 'MessageOriginRepair');
    } catch (error, trace) {
      Logger.warn('Message origin repair will retry after the next sync',
          error: error, trace: trace, tag: 'MessageOriginRepair');
    }
  }

  static Future<List<String>> _serverPage(String chatGuid, int offset, int limit) async {
    final response = await HttpSvc.chat.getMessages(chatGuid, sort: 'ASC', offset: offset, limit: limit);
    return [
      for (final message in (response.data['data'] as List).cast<Map<String, dynamic>>())
        if (message['guid'] is String) message['guid'] as String,
    ];
  }
}
