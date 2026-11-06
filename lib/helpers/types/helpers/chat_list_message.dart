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
