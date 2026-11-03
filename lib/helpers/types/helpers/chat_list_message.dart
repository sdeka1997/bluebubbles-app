import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:collection/collection.dart';

// Messages lists a thread by its newest ordinary item (item type 0): a
// message, attachment or reaction. Every other item type -- people added or
// removed, a rename or removed name, someone leaving, a group photo, location
// sharing and other status lines -- shows inside the thread but never becomes
// its preview or moves it in the list. Messages counts unread the same way.

/// Whether [message] can be its thread's preview and set its place in the list.
bool listsThread(Message message) => (message.itemType ?? 0) == 0;

/// [listsThread] as a database condition.
Condition<Message> get listsThreadCondition => Message_.itemType.isNull().or(Message_.itemType.equals(0));

/// The newest message, deleted ones excluded, of the local chat [chatId]. With
/// [listing], only a message that [listsThread].
Message? newestMessageIn(int chatId, {bool listing = true}) {
  final live = Message_.dateDeleted.isNull().and(Message_.dateCreated.notNull());
  final query = (Database.messages.query(listing ? live.and(listsThreadCondition) : live)
        ..link(Message_.chat, Chat_.id.equals(chatId))
        ..order(Message_.dateCreated, flags: Order.descending))
      .build();
  query.limit = 1;
  final result = query.findFirst();
  query.close();
  return result;
}

/// Points [thread] at the newest of [messages] that [listsThread]. A thread can
/// be a copy holding only a rename, and copies folded into it bring newer
/// messages, so its stored preview can be stale or a status item. A thread
/// holding only status items lists nothing. Returns whether [thread]
/// changed; the caller saves it.
bool refreshThreadLatest(Chat thread, Iterable<Message> messages) {
  final live = messages.where((m) => m.dateDeleted == null && m.dateCreated != null).toList();
  if (live.isEmpty) return false;
  final newest = live.where(listsThread).sortedBy<num>((m) => m.dateCreated!.millisecondsSinceEpoch).lastOrNull;
  final current = thread.dbLatestMessage.target;
  if (current?.guid == newest?.guid && (newest != null || thread.dbOnlyLatestMessageDate == null)) return false;
  thread.dbLatestMessage.target = newest;
  thread.dbOnlyLatestMessageDate = newest?.dateCreated;
  return true;
}

/// [refreshThreadLatest] against the local database for the chat [chat].
bool refreshThreadLatestFromDb(Chat chat) {
  final newest = newestMessageIn(chat.id!) ?? newestMessageIn(chat.id!, listing: false);
  return refreshThreadLatest(chat, [?newest]);
}

/// Chats still listed by a status item are pointed at their newest ordinary
/// item. Must run inside a write transaction. Returns the chats that changed.
List<Chat> relistChatsShownByEvents(Iterable<Chat> chats) {
  final changed = <Chat>[];
  for (final chat in chats) {
    final latest = chat.dbLatestMessage.target;
    if (chat.id == null || latest == null || listsThread(latest)) continue;
    if (refreshThreadLatestFromDb(chat)) changed.add(chat);
  }
  if (changed.isNotEmpty) Database.chats.putMany(changed);
  return changed;
}

/// Why [chat]'s place in the list disagrees with [newest], the newest message
/// that [listsThread] this phone holds for it, or null when it agrees. The
/// list sorts by the stored date, so any disagreement puts the thread in the
/// wrong place.
String? listingProblem(Chat chat, Message? newest) {
  if (newest == null) return null;
  final latest = chat.dbLatestMessage.target;
  final date = chat.dbOnlyLatestMessageDate;
  if (date == null || date.millisecondsSinceEpoch == 0) return 'no stored date';
  if (latest != null && latest.dateCreated != null && latest.dateCreated != date) return 'date does not match its message';
  if (date.isBefore(newest.dateCreated!)) return 'listed by something older than its newest message';
  if (latest?.guid != newest.guid && date.isAfter(newest.dateCreated!)) return 'listed by something newer than any message it holds';
  return null;
}

/// Points every chat whose place in the list disagrees with the messages this
/// phone holds back at its newest message, logging why. Returns the chats
/// that changed; the caller refreshes the list.
List<Chat> repairListing(Iterable<Chat> chats, void Function(String) log) {
  final changed = <Chat>[];
  for (final chat in chats) {
    if (chat.id == null || chat.dateDeleted != null) continue;
    final newest = newestMessageIn(chat.id!);
    final problem = listingProblem(chat, newest);
    if (problem == null) continue;
    final latest = chat.dbLatestMessage.target;
    log('${chat.guid} #${chat.id}: $problem; stored ${chat.dbOnlyLatestMessageDate?.toIso8601String()} '
        '(message #${latest?.id} type ${latest?.itemType} in chat #${latest?.chat.targetId}), '
        'newest ${newest!.dateCreated!.toIso8601String()} (message #${newest.id})');
    chat.dbLatestMessage.target = newest;
    chat.dbOnlyLatestMessageDate = newest.dateCreated;
    changed.add(chat);
  }
  if (changed.isNotEmpty) Database.chats.putMany(changed);
  return changed;
}
