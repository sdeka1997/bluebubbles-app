import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter/foundation.dart';

/// One page of a chat's message guids from the server, oldest first.
typedef MessageGuidPage = Future<List<String>> Function(String chatGuid, int offset, int limit);

/// How many messages the server holds for a chat.
typedef MessageTotal = Future<int> Function(String chatGuid);

/// Builds before K15 moved a twin's messages into its thread without
/// recording the Apple chat each came through, so the v6 upgrade could only
/// assume the thread's shown chat. Once (schema v7 marks it), this asks the
/// server which chat those messages belong to and records it; the database
/// files them.
///
/// Per thread it downloads only the smaller copies: every assumed message not
/// in one of them belongs to the biggest copy, which for a long iMessage
/// thread is tens of thousands of messages it never pages. Each thread is
/// marked done as it finishes, so a run cut short (app closed, server
/// unreachable) resumes after the next sync with the threads it had not done.
class MessageOriginRepair {
  static const pageSize = 1000;

  static Future<void> run({MessageGuidPage? fetch, MessageTotal? total}) async {
    if (kIsWeb) return;
    final store = MessagingStore.current;
    final threads = await store.threadsAwaitingOriginRepair();
    if (threads == null) return;
    final page = fetch ?? _serverPage;
    final count = total ?? _serverTotal;
    try {
      var recorded = 0;
      for (final thread in threads) {
        final sizes = {for (final chat in thread.copies) chat: await count(chat)};
        final biggest = thread.copies.reduce((a, b) => sizes[b]! > sizes[a]! ? b : a);
        // A message stored after this is filed by its Apple chat on arrival (K15).
        final asOf = DateTime.now();
        final fetched = <String, List<String>>{};
        for (final chat in thread.copies) {
          if (chat == biggest || sizes[chat] == 0) continue;
          final guids = fetched[chat] = <String>[];
          for (var offset = 0;; offset += pageSize) {
            final batch = await page(chat, offset, pageSize);
            guids.addAll(batch);
            if (batch.length < pageSize) break;
          }
        }
        recorded += await store.recordThreadOrigin(thread, biggest: biggest, fetched: fetched, asOf: asOf);
      }
      await store.finishOriginRepair();
      Logger.info('Recorded the Apple chat of $recorded message(s) across ${threads.length} threads',
          tag: 'MessageOriginRepair');
    } catch (error, trace) {
      Logger.warn('Message origin repair continues after the next sync',
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

  static Future<int> _serverTotal(String chatGuid) async {
    final response = await HttpSvc.chat.getMessages(chatGuid, limit: 1);
    final total = response.data['metadata']?['total'];
    // Without a total the biggest copy is unknown; guessing would file messages wrong.
    if (total is! num) throw StateError('The server did not report how many messages $chatGuid has');
    return total.toInt();
  }
}
