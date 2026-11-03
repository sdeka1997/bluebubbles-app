import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:collection/collection.dart';

// Messages lists a thread by its newest message or reaction. Group events --
// people added or removed (item type 1), a rename or removed name (2), someone
// leaving or a new group photo (3) -- show inside the thread but never become
// its preview or move it in the list.
const _groupEventItemTypes = [1, 2, 3];

/// Whether [message] can be its thread's preview and set its place in the list.
bool listsThread(Message message) => !_groupEventItemTypes.contains(message.itemType ?? 0);

/// [listsThread] as a database condition.
Condition<Message> get listsThreadCondition =>
    Message_.itemType.isNull().or(Message_.itemType.notOneOf(_groupEventItemTypes));

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
/// messages, so its stored preview can be stale or a group event. A thread
/// whose messages are all group events lists nothing. Returns whether [thread]
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

/// Chats still listed by a group event are pointed at their newest real
/// message. Must run inside a write transaction. Returns the chats that changed.
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
