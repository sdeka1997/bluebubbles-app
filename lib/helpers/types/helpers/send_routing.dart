import 'package:bluebubbles/helpers/types/classes/chat_service_type.dart';
import 'package:collection/collection.dart';

// Which of a thread's Apple chats a message goes out on, as the iPhone does
// it (measured on this Mac's history):
//
// 1. iMessage when every member is on iMessage.
// 2. Otherwise a text: RCS when the thread's latest text was RCS, else SMS.
// 3. Within a service, the copy that last received a message; with none yet,
//    the most recently active copy.
//
// The server sends to the exact chat named and never picks one itself.

/// One of a thread's Apple chats.
class SendCopy {
  const SendCopy({required this.guid, required this.service, this.lastIncoming, this.lastActivity});

  final String guid;
  final ChatServiceType service;
  final DateTime? lastIncoming;
  final DateTime? lastActivity;
}

/// A thread member and whether they're on iMessage (null while unknown).
typedef SendMember = ({String address, bool? iMessage});

/// Where to send: [guid] is the Apple chat, or null with [createIMessageChat]
/// when a 1:1 should get a new iMessage chat first, as the iPhone would.
class SendTarget {
  const SendTarget(this.guid, {this.createIMessageChat = false});

  final String? guid;
  final bool createIMessageChat;
}

SendTarget pickSendTarget({
  required List<SendCopy> copies,
  required bool isGroup,
  required List<SendMember> members,
  required ChatServiceType? latestService,
  ChatServiceType? latestTextService,
}) {
  // An email only reaches iMessage; an unknown answer follows the thread.
  bool? onIMessage(SendMember m) => m.address.contains('@') ? true : m.iMessage;
  final answers = members.map(onIMessage).toList();
  final bool useIMessage;
  if (answers.isNotEmpty && answers.every((a) => a == true)) {
    useIMessage = true;
  } else if (answers.any((a) => a == false)) {
    useIMessage = false;
  } else {
    useIMessage = latestService == null || latestService == ChatServiceType.iMessage;
  }

  final List<ChatServiceType> wanted;
  if (useIMessage) {
    if (!isGroup && answers.isNotEmpty && answers.every((a) => a == true) && !copies.any((c) => c.service.isIMessageService)) {
      return const SendTarget(null, createIMessageChat: true);
    }
    wanted = [ChatServiceType.iMessage];
  } else {
    // RCS vs SMS follows the latest text, not the latest message overall.
    final lastText = latestTextService ?? (latestService?.isIMessageService == false ? latestService : null);
    wanted = lastText == ChatServiceType.rcs
        ? [ChatServiceType.rcs, ChatServiceType.sms]
        : [ChatServiceType.sms, ChatServiceType.rcs];
  }

  for (final service in wanted) {
    final best = _best(copies.where((c) => c.service == service));
    if (best != null) return SendTarget(best.guid);
  }
  return SendTarget(_best(copies)?.guid);
}

SendCopy? _best(Iterable<SendCopy> copies) {
  int byDate(DateTime? a, DateTime? b) => (a ?? DateTime(0)).compareTo(b ?? DateTime(0));
  final received = copies.where((c) => c.lastIncoming != null);
  if (received.isNotEmpty) return received.sorted((a, b) => byDate(b.lastIncoming, a.lastIncoming)).first;
  return copies.sorted((a, b) => byDate(b.lastActivity, a.lastActivity)).firstOrNull;
}
