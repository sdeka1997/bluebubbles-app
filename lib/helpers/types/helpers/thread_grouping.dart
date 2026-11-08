// How Messages shows chats as one thread, learned from an iPhone's and a Mac's
// own databases and checked against what they display:
//
// 1. Copies of one chat on iMessage, SMS and RCS share a chat identifier.
// 2. Copies that share a group id, current, original or old, are one
//    conversation; this survives renames and members being added.
// 3. Groups with the same people and the same name show as one thread. No name
//    counts as a name, so a named and an unnamed group stay apart.
// 4. One-to-one chats with the same person are one thread, where "person" is a
//    contact card, so someone's email and phone number count as one.
//
// Links chain: if A joins B and B joins C, all three are one thread.

/// What [threadKeys] needs to know about one chat.
class ChatKeys {
  const ChatKeys({
    required this.guid,
    required this.chatIdentifier,
    required this.isGroup,
    required this.groupIds,
    required this.people,
    required this.name,
  });

  final String guid;
  final String? chatIdentifier;
  final bool isGroup;

  /// Current, original and old group ids.
  final Set<String> groupIds;

  /// One id per participant: the contact card they're on, or their address
  /// when they're on none.
  final Set<String> people;

  /// The group's current name; "" when it has none.
  final String name;
}

/// Each chat's guid mapped to the key of the thread it shows in. Chats with
/// the same key are one thread. The key is the smallest guid in the thread,
/// so it doesn't depend on the order of [chats].
Map<String, String> threadKeys(List<ChatKeys> chats) {
  final parent = <String, String>{};
  String find(String x) {
    var root = x;
    while (parent[root] != root) {
      root = parent[root]!;
    }
    // Path compression keeps repeated lookups flat.
    var node = x;
    while (parent[node] != root) {
      final next = parent[node]!;
      parent[node] = root;
      node = next;
    }
    return root;
  }

  void union(String x, String y) {
    final rx = find(x), ry = find(y);
    if (rx != ry) parent[ry] = rx;
  }

  void link(String guid, String key) {
    parent.putIfAbsent(key, () => key);
    union('chat:$guid', key);
  }

  for (final chat in chats) {
    parent.putIfAbsent('chat:${chat.guid}', () => 'chat:${chat.guid}');
    final identifier = chat.chatIdentifier?.replaceAll('(filtered)', '').trim();
    if (identifier != null && identifier.isNotEmpty) link(chat.guid, 'id:$identifier');
    for (final groupId in chat.groupIds) {
      if (groupId.trim().isNotEmpty) link(chat.guid, 'group:$groupId');
    }
    if (chat.people.isEmpty) continue;
    final people = (chat.people.toList()..sort()).join('\u0000');
    if (chat.isGroup) {
      link(chat.guid, 'members:$people\u0001${chat.name.trim()}');
    } else {
      link(chat.guid, 'person:$people');
    }
  }

  final smallest = <String, String>{};
  for (final chat in chats) {
    final root = find('chat:${chat.guid}');
    final current = smallest[root];
    if (current == null || chat.guid.compareTo(current) < 0) smallest[root] = chat.guid;
  }
  return {for (final chat in chats) chat.guid: smallest[find('chat:${chat.guid}')]!};
}
