import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:collection/collection.dart';

// A chat's page of newest messages without sorting its whole history. The phone
// numbers messages as it saves them, so the newest messages are almost always the
// highest-numbered ones: only those are loaded and sorted by date. When that may be
// wrong -- the chat's stored newest message is not among them, as after old history
// is saved again -- the caller sorts the whole chat instead.

/// Extra messages loaded beyond the page, so a few saved out of order still sort
/// into place.
const pageSlack = 100;

/// The ids to load for the page at [offset], from [chatIds] (every id in the chat),
/// or null when the newest-numbered ids cannot be trusted to hold it. [latestId] is
/// the chat's stored newest message.
List<int>? newestPageWindow(List<int> chatIds, {required int offset, required int limit, required int? latestId}) {
  if (latestId == null || latestId == 0) return null;
  final byNumber = chatIds.sorted((a, b) => b.compareTo(a));
  if (!byNumber.take(limit + pageSlack).contains(latestId)) return null;
  return byNumber.take(offset + limit + pageSlack).toList();
}

/// The page at [offset] of [window], newest first, or null when [window] holds too
/// few usable messages to fill it while the chat has more ([chatSize]).
List<Message>? pageByDate(List<Message> window,
    {required int offset, required int limit, required int chatSize, bool includeDeleted = false}) {
  final usable = window
      .where((m) => m.dateCreated != null && (includeDeleted || m.dateDeleted == null))
      .sorted((a, b) => b.dateCreated!.compareTo(a.dateCreated!));
  if (usable.length < offset + limit && window.length < chatSize) return null;
  return usable.skip(offset).take(limit).toList();
}

/// [newestPageWindow] and [pageByDate] against the local database. Null means the
/// caller must sort the whole chat. Must run inside a read transaction.
List<Message>? newestMessagesPage(int chatId, {required int offset, required int limit, bool includeDeleted = false}) {
  final chat = Database.chats.get(chatId);
  if (chat == null) return null;
  final query = Database.messages.query(Message_.chat.equals(chatId)).build();
  final ids = query.findIds();
  query.close();
  final window = newestPageWindow(ids, offset: offset, limit: limit, latestId: chat.dbLatestMessage.targetId);
  if (window == null) return null;
  final loaded = Database.messages.getMany(window).whereType<Message>().toList();
  return pageByDate(loaded, offset: offset, limit: limit, chatSize: ids.length, includeDeleted: includeDeleted);
}
