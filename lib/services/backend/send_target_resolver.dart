import 'dart:async';

import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/send_routing.dart';
import 'package:bluebubbles/helpers/types/helpers/service_twin_helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

/// Finds the Apple chat a message in [thread] goes out on (see send_routing.dart).
class SendTargetResolver {
  static const _tag = 'SendTarget';
  static const _recentMessages = 50;
  static const _answerTtl = Duration(days: 1);
  static final Map<String, ({bool? available, DateTime at})> _iMessage = {};

  /// [anchorGuid] is the message a tapback or reply points at; those go to
  /// the Apple chat that message is in, which is where Messages looks for it.
  static Future<Chat> resolve(Chat thread, {String? anchorGuid}) async {
    if (kIsWeb) return thread;
    try {
      final copies = findThreadChats(thread);
      if (anchorGuid != null) {
        final anchorChat = Message.findOne(guid: anchorGuid)?.appleChatGuid;
        return copies.firstWhereOrNull((c) => c.guid == anchorChat) ?? thread;
      }
      final hasIMessage = copies.any((c) => c.service.isIMessageService);
      // One chat and nothing to make: nothing to choose between.
      if (copies.length <= 1 && (thread.isGroup || hasIMessage)) return thread;

      final query =
          (Database.messages.query()
                ..link(Message_.chat, Chat_.id.equals(thread.id!))
                ..order(Message_.dateCreated, flags: Order.descending))
              .build()
            ..limit = _recentMessages;
      final recent = query.find();
      query.close();

      final described = describeThread(threadGuid: thread.guid, copies: copies, recent: recent);
      // Ask the Mac only when the answer can change the pick: the thread has
      // chats on several services, or it's a 1:1 that may need an iMessage chat.
      final ask = copies.map((c) => c.service).toSet().length > 1 || (!thread.isGroup && !hasIMessage);
      final addresses = (thread.handles.isEmpty ? thread.participants : thread.handles).map((h) => h.address).toList();
      final answers = await Future.wait(addresses.map((a) async => ask ? await _isOnIMessage(a) : null));
      final members = [for (var i = 0; i < addresses.length; i++) (address: addresses[i], iMessage: answers[i])];
      final target = pickSendTarget(
        copies: described.copies,
        isGroup: thread.isGroup,
        members: members,
        latestService: described.latestService,
        latestTextService: described.latestTextService,
      );
      // A 1:1 on iMessage without an iMessage chat: send to its iMessage
      // address; the Mac opens that chat for the person, as the iPhone would.
      if (target.createIMessageChat && addresses.length == 1) {
        Logger.debug('Sending ${thread.guid} through a new iMessage chat', tag: _tag);
        return newIMessageChat(addresses.first);
      }
      final guid = target.guid;
      final chosen = copies.firstWhereOrNull((c) => c.guid == guid) ?? thread;
      if (chosen.guid != thread.guid) Logger.debug('Sending ${thread.guid} through ${chosen.guid}', tag: _tag);
      return chosen;
    } catch (e, s) {
      Logger.warn('Could not pick a send target for ${thread.guid}', error: e, trace: s, tag: _tag);
      return thread;
    }
  }

  /// The 1:1 iMessage chat for [address], before the Mac has made it.
  @visibleForTesting
  static Chat newIMessageChat(String address) => Chat.fromMap({
        'guid': 'iMessage;-;$address',
        'chatIdentifier': address,
        'serviceName': 'iMessage',
        'style': 45,
        'participants': [
          {'address': address}
        ],
      });

  /// The Mac's iMessage answer for [address], cached a day; null when unknown.
  static Future<bool?> _isOnIMessage(String address) async {
    final cached = _iMessage[address];
    if (cached != null && DateTime.now().difference(cached.at) < _answerTtl) return cached.available;
    try {
      final response = await HttpSvc.handle.handleiMessageState(address).timeout(const Duration(seconds: 3));
      final available = response.data['data']['available'] as bool?;
      _iMessage[address] = (available: available, at: DateTime.now());
      return available;
    } catch (e) {
      Logger.debug('No iMessage answer for $address: $e', tag: _tag);
      return cached?.available;
    }
  }
}
