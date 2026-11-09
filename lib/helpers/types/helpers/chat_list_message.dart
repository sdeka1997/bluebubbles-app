import 'package:bluebubbles/database/models.dart';
import 'package:collection/collection.dart';

// Messages lists a thread by its newest ordinary item (item type 0): a
// message, attachment or reaction. Every other item type -- people added or
// removed, a rename or removed name, someone leaving, a group photo, location
// sharing and other status lines -- shows inside the thread but never becomes
// its preview or moves it in the list. Messages counts unread the same way.

/// Whether [message] can be its thread's preview and set its place in the list.
bool listsThread(Message message) => (message.itemType ?? 0) == 0;

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

/// Points [thread] at the newest of [added] when it is newer than what
/// [thread] is listed by, or when [thread] is listed by nothing or by a status
/// item. Uses only [added], so the thread's other messages are never read: the
/// stored preview is kept up to date as messages arrive. Returns whether
/// [thread] changed; the caller saves it.
bool keepNewestOf(Chat thread, Iterable<Message> added) {
  final newest = added
      .where((m) => m.dateDeleted == null && m.dateCreated != null && listsThread(m))
      .sortedBy<num>((m) => m.dateCreated!.millisecondsSinceEpoch)
      .lastOrNull;
  if (newest == null) return false;
  final current = thread.dbLatestMessage.target;
  final listedAt = thread.dbOnlyLatestMessageDate;
  final currentCounts = current != null && listsThread(current) && current.dateDeleted == null && listedAt != null;
  if (currentCounts && !newest.dateCreated!.isAfter(listedAt)) return false;
  if (current?.guid == newest.guid && listedAt == newest.dateCreated) return false;
  thread.dbLatestMessage.target = newest;
  thread.dbOnlyLatestMessageDate = newest.dateCreated;
  return true;
}
