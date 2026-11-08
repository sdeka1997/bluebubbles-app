import 'package:bluebubbles/database/models.dart';

/// Applies Messages' Spam verdicts from a capable server to matching local chats.
/// A missing key means an older server and must not clear an existing verdict.
List<Chat> updateSpamFlagsFromRemote(Iterable<Chat> localChats, Iterable<Map<String, dynamic>> remoteChats) {
  final localByGuid = {for (final chat in localChats) chat.guid: chat};
  final changed = <Chat>[];
  for (final remote in remoteChats) {
    if (!remote.containsKey('isFilteredAsSpam')) continue;
    final guid = remote['guid'];
    if (guid is! String) continue;
    final local = localByGuid[guid];
    if (local == null) continue;
    if (local.mergeSpamFlag(Chat.fromMap(remote))) changed.add(local);
  }
  return changed;
}
