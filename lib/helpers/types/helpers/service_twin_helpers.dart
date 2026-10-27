import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:collection/collection.dart';

/// Applies group ids returned by a group-id-aware server to matching local chats.
/// A missing key means an older server and is deliberately ignored; an explicit
/// null means Messages removed the chat from a group and is applied.
List<Chat> updateGroupIdsFromRemote(Iterable<Chat> localChats, Iterable<Map<String, dynamic>> remoteChats) {
  final localByGuid = {for (final chat in localChats) chat.guid: chat};
  final changed = <Chat>[];
  for (final remote in remoteChats) {
    if (!remote.containsKey('groupId')) continue;
    final guid = remote['guid'];
    if (guid is! String) continue;
    final local = localByGuid[guid];
    if (local == null) continue;
    final groupId = remote['groupId'] as String?;
    if (local.groupId == groupId) continue;
    local.groupId = groupId;
    changed.add(local);
  }
  return changed;
}

// macOS Messages keeps one chat per service (iMessage, SMS, RCS) for the same
// conversation and ties them together with a shared group id. iPhone and Mac
// show them as one thread, and so does the app: the first of them stored
// locally is the thread, the others are folded into it.

/// The chat [chat] should be shown as, or null when [chat] is not a folded
/// twin. [chats] are the local chats sharing its group id.
Chat? canonicalTwinFor(Chat chat, Iterable<Chat> chats) {
  final groupId = chat.groupId;
  if (groupId == null || groupId.isEmpty) return null;
  final canonical = chats
      .where((c) => c.groupId == groupId && c.id != null && c.dateDeleted == null)
      .sortedBy<num>((c) => c.id!)
      .firstOrNull;
  if (canonical == null || canonical.guid == chat.guid) return null;
  if (chat.id != null && chat.id! < canonical.id! && chat.dateDeleted == null) return null;
  return canonical;
}

/// Guids of the chats in [chats] that are folded into another chat and so
/// stay out of the conversation list.
Set<String> foldedTwinGuids(Iterable<Chat> chats) {
  final byGroup = chats.where((c) => c.groupId?.isNotEmpty ?? false).groupListsBy((c) => c.groupId!);
  return {
    for (final group in byGroup.values.where((g) => g.length > 1))
      for (final c in group)
        if (canonicalTwinFor(c, group) != null) c.guid,
  };
}

/// Every chat Messages needs to mark read so the thread for [guid] reads as read.
List<String> guidsToMarkRead(String guid, Iterable<Chat> chats) {
  final groupId = chats.firstWhereOrNull((c) => c.guid == guid)?.groupId;
  if (groupId == null || groupId.isEmpty) return [guid];
  return [guid, ...chats.where((c) => c.groupId == groupId && c.guid != guid).map((c) => c.guid)];
}

List<Chat> _chatsInGroup(String? groupId) {
  if (groupId == null || groupId.isEmpty) return const [];
  final query = Database.chats.query(Chat_.groupId.equals(groupId)).build();
  final result = query.find();
  query.close();
  return result;
}

/// The local thread [chat] belongs to, or null when [chat] is its own thread.
Chat? findCanonicalTwin(Chat chat) => canonicalTwinFor(chat, _chatsInGroup(chat.groupId));

/// [guidsToMarkRead] against the local database.
List<String> findGuidsToMarkRead(String guid) {
  final chat = Chat.findOne(guid: guid);
  return guidsToMarkRead(guid, chat == null ? const [] : _chatsInGroup(chat.groupId));
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

/// Moves the messages of every folded twin in [chats] to its thread. Must run
/// inside a write transaction. Returns each folded twin's guid mapped to its thread.
Map<String, Chat> foldServiceTwins(Iterable<Chat> chats) {
  final folded = <String, Chat>{};
  for (final twin in [...chats, ..._shareGroupIds(chats)]) {
    final canonical = findCanonicalTwin(twin);
    if (canonical == null) continue;
    folded[twin.guid] = canonical;
    if (carryOverThreadSettings(canonical, [twin])) Database.chats.put(canonical);

    final query = (Database.messages.query()..link(Message_.chat, Chat_.id.equals(twin.id!))).build();
    final messages = query.find();
    query.close();
    if (messages.isEmpty) continue;
    for (final m in messages) {
      m.chat.target = canonical;
    }
    Database.messages.putMany(messages);
  }
  return folded;
}

/// Chats stored before the app kept group ids don't have one yet. Twins share
/// their chat identifier, so they pick up the group id of a twin as it syncs.
/// Returns the chats that got one.
List<Chat> _shareGroupIds(Iterable<Chat> chats) {
  final updated = <Chat>[];
  for (final chat in chats) {
    if ((chat.groupId?.isEmpty ?? true) || chat.chatIdentifier == null) continue;
    final query = Database.chats
        .query(Chat_.chatIdentifier.equals(chat.chatIdentifier!).and(Chat_.groupId.isNull()))
        .build();
    final twins = query.find();
    query.close();
    if (twins.isEmpty) continue;
    for (final twin in twins) {
      twin.groupId = chat.groupId;
    }
    Database.chats.putMany(twins);
    updated.addAll(twins);
  }
  return updated;
}
