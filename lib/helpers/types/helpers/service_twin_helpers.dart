import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/chat_keys.dart';
import 'package:bluebubbles/helpers/types/helpers/thread_grouping.dart';
import 'package:collection/collection.dart';

/// Applies the grouping fields returned by a grouping-aware server (group id,
/// original and old group ids, newest rename) to matching local chats. A
/// missing key means an older server and is deliberately ignored; an explicit
/// null means Messages cleared it and is applied.
List<Chat> updateGroupIdsFromRemote(Iterable<Chat> localChats, Iterable<Map<String, dynamic>> remoteChats) {
  final localByGuid = {for (final chat in localChats) chat.guid: chat};
  final changed = <Chat>[];
  for (final remote in remoteChats) {
    final guid = remote['guid'];
    if (guid is! String) continue;
    final local = localByGuid[guid];
    if (local == null) continue;
    var dirty = false;
    if (remote.containsKey('groupId') && local.groupId != remote['groupId']) {
      local.groupId = remote['groupId'] as String?;
      dirty = true;
    }
    if (remote.containsKey('originalGroupId') && local.originalGroupId != remote['originalGroupId']) {
      local.originalGroupId = remote['originalGroupId'] as String?;
      dirty = true;
    }
    if (remote.containsKey('legacyGroupIds')) {
      final legacy = (remote['legacyGroupIds'] as List?)?.whereType<String>().toList();
      if (!const ListEquality<String>().equals(local.legacyGroupIds, legacy)) {
        local.legacyGroupIds = legacy;
        dirty = true;
      }
    }
    if (remote.containsKey('latestGroupTitle') && local.latestGroupTitle != remote['latestGroupTitle']) {
      local.latestGroupTitle = remote['latestGroupTitle'] as String?;
      dirty = true;
    }
    if (dirty) changed.add(local);
  }
  return changed;
}

// Messages shows several of its stored chats as one thread (see
// thread_grouping.dart). The app does the same: each chat carries the key of
// its thread, the first chat stored for a key is the thread, and the others
// are folded into it.

/// Sets [Chat.threadKey] on [chats] from the grouping rule. [chats] should be
/// every local chat, since any of them can join a thread. Returns the chats
/// whose key changed.
List<Chat> assignThreadKeys(Iterable<Chat> chats) {
  final list = chats.toList();
  final keys = threadKeys([for (final c in list) chatKeysFor(c)]);
  final changed = <Chat>[];
  for (final chat in list) {
    final key = keys[chat.guid];
    if (chat.threadKey == key) continue;
    chat.threadKey = key;
    changed.add(chat);
  }
  return changed;
}

/// The chat [chat] should be shown as, or null when [chat] is not folded.
/// [chats] are the local chats sharing its thread key.
Chat? canonicalTwinFor(Chat chat, Iterable<Chat> chats) {
  final key = chat.threadKey;
  if (key == null || key.isEmpty) return null;
  final canonical = chats
      .where((c) => c.threadKey == key && c.id != null && c.dateDeleted == null)
      .sortedBy<num>((c) => c.id!)
      .firstOrNull;
  if (canonical == null || canonical.guid == chat.guid) return null;
  if (chat.id != null && chat.id! < canonical.id! && chat.dateDeleted == null) return null;
  return canonical;
}

/// Guids of the chats in [chats] that are folded into another chat and so
/// stay out of the conversation list.
Set<String> foldedTwinGuids(Iterable<Chat> chats) {
  final byThread = chats.where((c) => c.threadKey?.isNotEmpty ?? false).groupListsBy((c) => c.threadKey!);
  return {
    for (final thread in byThread.values.where((t) => t.length > 1))
      for (final c in thread)
        if (canonicalTwinFor(c, thread) != null) c.guid,
  };
}

/// Every chat Messages needs to mark read so the thread for [guid] reads as read.
List<String> guidsToMarkRead(String guid, Iterable<Chat> chats) {
  final key = chats.firstWhereOrNull((c) => c.guid == guid)?.threadKey;
  if (key == null || key.isEmpty) return [guid];
  return [guid, ...chats.where((c) => c.threadKey == key && c.guid != guid).map((c) => c.guid)];
}

List<Chat> _chatsInThread(String? key) {
  if (key == null || key.isEmpty) return const [];
  final query = Database.chats.query(Chat_.threadKey.equals(key)).build();
  final result = query.find();
  query.close();
  return result;
}

/// The local thread [chat] belongs to, or null when [chat] is its own thread.
Chat? findCanonicalTwin(Chat chat) => canonicalTwinFor(chat, _chatsInThread(chat.threadKey));

/// Every local chat in [chat]'s thread, [chat] included.
List<Chat> findThreadChats(Chat chat) {
  final chats = _chatsInThread(chat.threadKey).where((c) => c.dateDeleted == null).toList();
  return chats.any((c) => c.guid == chat.guid) ? chats : [chat, ...chats];
}

/// [guidsToMarkRead] against the local database.
List<String> findGuidsToMarkRead(String guid) {
  final chat = Chat.findOne(guid: guid);
  return guidsToMarkRead(guid, chat == null ? const [] : _chatsInThread(chat.threadKey));
}

/// Pin, mute, archive and a custom name set on a twin before it was folded
/// carry over to its thread, without overriding anything the thread has.
/// Returns whether [thread] changed.
bool carryOverThreadSettings(Chat thread, Iterable<Chat> twins) {
  var changed = false;
  for (final twin in twins) {
    if ((twin.isPinned ?? false) && !(thread.isPinned ?? false)) {
      thread.isPinned = true;
      thread.pinIndex = twin.pinIndex;
      changed = true;
    }
    if (twin.muteType != null && thread.muteType == null) {
      thread.muteType = twin.muteType;
      thread.muteArgs = twin.muteArgs;
      changed = true;
    }
    if ((twin.isArchived ?? false) && !(thread.isArchived ?? false)) {
      thread.isArchived = true;
      changed = true;
    }
    if (twin.lockChatName && !thread.lockChatName) {
      thread.displayName = twin.displayName;
      thread.lockChatName = true;
      changed = true;
    }
  }
  return changed;
}

/// Points [thread] at the newest of [messages], its own and those of the
/// chats folded into it. A thread can be a copy holding only a rename, so its
/// stored preview may be older than messages that just moved in. Returns
/// whether [thread] changed; the caller saves it.
bool refreshThreadLatest(Chat thread, Iterable<Message> messages) {
  final newest = messages
      .where((m) => m.dateDeleted == null && m.dateCreated != null)
      .sortedBy<num>((m) => m.dateCreated!.millisecondsSinceEpoch)
      .lastOrNull;
  if (newest == null || thread.dbLatestMessage.target?.guid == newest.guid) return false;
  thread.dbLatestMessage.target = newest;
  thread.dbOnlyLatestMessageDate = newest.dateCreated;
  return true;
}

/// Regroups every local chat, then moves the messages of each folded chat in
/// [chats], or whose thread changed, to its thread. Must run inside a write
/// transaction. Returns each folded chat's guid mapped to its thread.
Map<String, Chat> foldServiceTwins(Iterable<Chat> chats) {
  final regrouped = assignThreadKeys(Database.chats.getAll());
  if (regrouped.isNotEmpty) Database.chats.putMany(regrouped);
  final folded = <String, Chat>{};
  final threads = <int, Chat>{};
  // A thread's first chat can change when a chat joins it, so every chat in a
  // touched thread is checked, not only the ones whose key changed.
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
    final found = findCanonicalTwin(stored);
    if (found == null) continue;
    // One instance per thread, so the preview refresh below reaches the caller.
    final canonical = threads.putIfAbsent(found.id!, () => found);
    folded[twin.guid] = canonical;
    if (carryOverThreadSettings(canonical, [stored])) Database.chats.put(canonical);

    final query = (Database.messages.query()..link(Message_.chat, Chat_.id.equals(stored.id!))).build();
    final messages = query.find();
    query.close();
    if (messages.isEmpty) continue;
    for (final m in messages) {
      // Keep where it really came from, so replies can go back through it.
      m.appleChatGuid ??= stored.guid;
      m.chat.target = canonical;
    }
    Database.messages.putMany(messages);
  }
  for (final thread in threads.values) {
    final query = (Database.messages.query(Message_.dateDeleted.isNull())
          ..link(Message_.chat, Chat_.id.equals(thread.id!))
          ..order(Message_.dateCreated, flags: Order.descending))
        .build();
    query.limit = 1;
    final newest = query.find();
    query.close();
    if (refreshThreadLatest(thread, newest)) Database.chats.put(thread);
  }
  return folded;
}
