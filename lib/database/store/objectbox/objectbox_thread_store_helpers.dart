import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/chat_list_message.dart';
import 'package:bluebubbles/helpers/types/helpers/service_twin_helpers.dart';

/// `listsThread` as an ObjectBox condition.
Condition<Message> get listsThreadCondition => Message_.itemType.isNull().or(Message_.itemType.equals(0));

List<Chat> _chatsInThread(String? key) {
  if (key == null || key.isEmpty) return const [];
  final query = Database.chats.query(Chat_.threadKey.equals(key)).build();
  final result = query.find();
  query.close();
  return result;
}

/// The stored thread [chat] is folded into, or null when it is its own thread.
Chat? objectBoxCanonicalTwin(Chat chat) => canonicalTwinFor(chat, _chatsInThread(chat.threadKey));

/// ObjectBox implementation of the legacy service-twin fold. The body is the
/// former service_twin_helpers.dart write path, kept behind MessagingStore.
Map<String, Chat> foldServiceTwinsObjectBox(Iterable<Chat> chats) {
  final regrouped = assignThreadKeys(Database.chats.getAll());
  if (regrouped.isNotEmpty) Database.chats.putMany(regrouped);
  final folded = <String, Chat>{};
  final threads = <int, Chat>{};
  final touched = {for (final c in [...chats, ...regrouped]) c.guid: c};
  final keys = {for (final c in touched.values) c.threadKey}..remove(null);
  for (final key in keys) {
    for (final c in _chatsInThread(key)) {
      touched.putIfAbsent(c.guid, () => c);
    }
  }
  final candidates = touched.values;
  for (final twin in candidates) {
    final stored = twin.id == null ? Chat.findOne(guid: twin.guid) : twin;
    if (stored == null) continue;
    stored.threadKey ??= twin.threadKey;
    final found = objectBoxCanonicalTwin(stored);
    if (found == null) continue;
    final canonical = threads.putIfAbsent(found.id!, () => found);
    folded[twin.guid] = canonical;
    if (carryOverThreadSettings(canonical, [stored])) Database.chats.put(canonical);

    final query = (Database.messages.query()..link(Message_.chat, Chat_.id.equals(stored.id!))).build();
    final messages = query.find();
    query.close();
    if (messages.isEmpty) continue;
    for (final message in messages) {
      message.appleChatGuid ??= stored.guid;
      message.chat.target = canonical;
    }
    Database.messages.putMany(messages);
    if (keepNewestOf(canonical, messages)) Database.chats.put(canonical);
  }
  return folded;
}

Message? _newestMessageIn(int chatId, {bool listing = true}) {
  final live = Message_.dateDeleted.isNull().and(Message_.dateCreated.notNull());
  final condition = listing ? live.and(listsThreadCondition) : live;
  final query = (Database.messages.query(condition)
        ..link(Message_.chat, Chat_.id.equals(chatId))
        ..order(Message_.dateCreated, flags: Order.descending))
      .build();
  query.limit = 1;
  final result = query.findFirst();
  query.close();
  return result;
}

bool _refreshThreadLatest(Chat chat) {
  final newest = _newestMessageIn(chat.id!) ?? _newestMessageIn(chat.id!, listing: false);
  return refreshThreadLatest(chat, [?newest]);
}

/// ObjectBox implementation of the legacy latest-pointer repair. The body is
/// the former chat_list_message.dart write path, kept behind MessagingStore.
List<Chat> relistChatsShownByEventsObjectBox(Iterable<Chat> chats) {
  final changed = <Chat>[];
  for (final chat in chats) {
    final latest = chat.dbLatestMessage.target;
    if (chat.id == null || latest == null || listsThread(latest)) continue;
    if (_refreshThreadLatest(chat)) changed.add(chat);
  }
  if (changed.isNotEmpty) Database.chats.putMany(changed);
  return changed;
}
