import 'dart:async';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:collection/collection.dart';

import 'search_models.dart';

/// The chats whose name or participants (contact name or address) match [term],
/// newest activity first, like the Conversations section of iOS Messages search.
List<Chat> matchConversations(String term, Iterable<Chat> chats, {int limit = 8}) {
  final query = term.trim().toLowerCase();
  if (query.isEmpty) return [];
  // A phone number typed with punctuation, e.g. "(555) 123-4567", matches by digits.
  final digits = RegExp(r'^[\d\s()+.\-]+$').hasMatch(query) ? query.replaceAll(RegExp(r'\D'), '') : '';
  bool matches(String? value) {
    if (value == null || value.isEmpty) return false;
    if (value.toLowerCase().contains(query)) return true;
    return digits.length >= 3 && value.replaceAll(RegExp(r'\D'), '').contains(digits);
  }

  final seen = <String>{};
  return chats
      .where((c) => c.dateDeleted == null && seen.add(c.guid))
      .where((c) => matches(c.displayName) || c.handles.any((h) => matches(h.displayName) || matches(h.address)))
      .sorted((a, b) => (b.dbOnlyLatestMessageDate ?? DateTime(0)).compareTo(a.dbOnlyLatestMessageDate ?? DateTime(0)))
      .take(limit)
      .toList();
}

/// Searches start at three characters, ignoring surrounding spaces.
bool isSearchableTerm(String term) => term.trim().length >= 3;

/// Search starts on this device: it is instant and works without the Mac.
SearchMode defaultSearchMode() => SearchMode.local;

/// Runs a search once typing pauses, with the latest text only.
class SearchDebouncer {
  SearchDebouncer({this.delay = const Duration(milliseconds: 300)});

  final Duration delay;
  Timer? _timer;

  void call(String term, void Function(String term) search) {
    _timer?.cancel();
    _timer = Timer(delay, () => search(term));
  }

  void cancel() => _timer?.cancel();
}

class SearchQueryHelper {
  static Future<List<SearchResultItem>> runLocal({
    required String term,
    required Chat? selectedChat,
    required Handle? selectedHandle,
    required bool isFromMe,
    required bool isNotFromMe,
    required DateTime? sinceDate,
  }) async {
    final results = await findLocal(
      term: term,
      selectedChat: selectedChat,
      selectedHandle: selectedHandle,
      isFromMe: isFromMe,
      isNotFromMe: isNotFromMe,
      sinceDate: sinceDate,
    );

    final items = <SearchResultItem>[];
    for (final message in results) {
      final chat = message.chat.target;
      if (chat == null) continue;
      unawaited(message.fetchAssociatedMessages());
      items.add(SearchResultItem(chat: chat, message: message));
    }
    return items;
  }

  /// The messages [runLocal] shows, newest first: text containing [term]
  /// (ASCII case folded), no reactions, not deleted, with a date
  /// (MessagingStore.searchMessages).
  static Future<List<Message>> findLocal({
    required String term,
    required Chat? selectedChat,
    required Handle? selectedHandle,
    required bool isFromMe,
    required bool isNotFromMe,
    required DateTime? sinceDate,
    int limit = 50,
  }) {
    return MessagingStore.current.searchMessages(
      term,
      chatId: selectedChat?.id,
      isFromMe: isFromMe ? true : (isNotFromMe ? false : null),
      senderRowId: isFromMe || isNotFromMe ? null : selectedHandle?.originalROWID,
      since: sinceDate,
      limit: limit,
    );
  }

  static Future<List<SearchResultItem>> runNetwork({
    required String term,
    required Chat? selectedChat,
    required Handle? selectedHandle,
    required bool isFromMe,
    required bool isNotFromMe,
    required DateTime? sinceDate,
  }) async {
    final whereClause = <Map<String, dynamic>>[
      {
        'statement': 'message.text LIKE :term COLLATE NOCASE',
        'args': {'term': "%$term%"}
      },
      {'statement': 'message.associated_message_guid IS NULL', 'args': null}
    ];

    if (selectedChat != null) {
      whereClause.add({
        'statement': 'chat.guid = :guid',
        'args': {'guid': selectedChat.guid}
      });
    }

    if (isFromMe) {
      whereClause.add({
        'statement': 'message.is_from_me = :isFromMe',
        'args': {'isFromMe': 1}
      });
    } else if (isNotFromMe) {
      whereClause.add({
        'statement': 'message.is_from_me = :isFromMe',
        'args': {'isFromMe': 0}
      });
    } else if (selectedHandle != null) {
      whereClause.add({
        'statement': 'handle.id = :addr',
        'args': {'addr': selectedHandle.address}
      });
    }

    final results = await MessagesService.getMessages(
      limit: 50,
      after: sinceDate?.millisecondsSinceEpoch,
      withChats: true,
      withHandles: true,
      withAttachments: true,
      withChatParticipants: true,
      where: whereClause,
    );

    final itemChats = <Chat>[];
    final itemMessages = <Message>[];
    for (final item in results) {
      itemChats.add(Chat.fromMap(item['chats'][0]));
      itemMessages.add(Message.fromMap(item));
    }

    final chatGuids = itemChats.map((e) => e.guid).toList();
    final dbChats = await MessagingStore.current.chatsByGuids(chatGuids);

    final items = <SearchResultItem>[];
    for (int i = 0; i < itemChats.length; i++) {
      final chat = dbChats.firstWhereOrNull((e) => e.guid == itemChats[i].guid) ?? itemChats[i];
      items.add(SearchResultItem(chat: chat, message: itemMessages[i]));
    }
    return items;
  }
}

/// The part of [text] a search result previews: the line holding [term], cut
/// to 50 characters either side of it, split around the match. The preview
/// shows only a line or two, so a match below the first lines must lead it.
/// Null when [text] doesn't contain [term].
({String before, String match, String after})? searchSnippet(String text, String term) {
  final start = text.toLowerCase().indexOf(term.toLowerCase());
  if (term.isEmpty || start < 0) return null;
  final end = start + term.length;
  final lineStart = text.lastIndexOf('\n', start) + 1;
  final lineEnd = text.indexOf('\n', end);
  final from = (start - 50).clamp(lineStart, start);
  final to = (end + 50).clamp(end, lineEnd < 0 ? text.length : lineEnd);
  return (
    before: text.substring(from, start).trimLeft(),
    match: text.substring(start, end),
    after: text.substring(end, to).trimRight(),
  );
}
