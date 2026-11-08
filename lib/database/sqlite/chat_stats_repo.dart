import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/services/ui/chat/chat_stats/chat_stats_models.dart';

/// The chat-stats queries of `ChatStatsQueries` on SQLite, as aggregates over
/// one chat's rows: same results, without loading a `Message` per row.
///
/// "Real" messages ([_real]) are the rows `ChatStatsQueries.realMessages` keeps:
/// not deleted, dated, no reaction or sticker, no group event. Those are rows
/// of the partial messages_timeline index, so every query on them reads one
/// chat's slice of it; the rest read messages_chat_time. Timestamps are epoch
/// milliseconds and participants local handle ids, as the stats screens use.
class ChatStatsRepo {
  ChatStatsRepo(this.db);

  final DbReader db;

  static const _real = 'FROM messages m INDEXED BY messages_timeline WHERE m.chat_id = ? '
      'AND m.associated_message_guid IS NULL AND m.date_deleted_us IS NULL '
      'AND m.date_created_us IS NOT NULL AND m.item_type = 0';
  static const _all = 'FROM messages m INDEXED BY messages_chat_time WHERE m.chat_id = ?';

  /// [_real] plus optional filters, with their arguments.
  static (String, List<Object?>) _realWhere(int chatId,
      {int? sinceMillis, int? afterMillis, bool? fromMe, int? participantId, List<String> also = const []}) {
    final sql = [
      _real,
      if (sinceMillis != null) 'm.date_created_us >= ?',
      if (afterMillis != null) 'm.date_created_us > ?',
      if (fromMe != null) 'm.is_from_me = ?',
      if (participantId != null) 'm.handle_relation_id = ?',
      ...also,
    ].join(' AND ');
    return (sql, [
      chatId,
      if (sinceMillis != null) sinceMillis * 1000,
      if (afterMillis != null) afterMillis * 1000,
      if (fromMe != null) fromMe ? 1 : 0,
      ?participantId,
    ]);
  }

  static int _ms(Object? us) => (us as int) ~/ 1000;

  /// Who sent [row]: [kMeParticipantId] for mine, else the local handle id, or
  /// [kUnattributedParticipantId] when the sender was never linked.
  static int _reactor(Map<String, Object?> row) =>
      row['is_from_me'] == 1 ? kMeParticipantId : (row['handle_relation_id'] as int? ?? kUnattributedParticipantId);

  Future<int> _count(int chatId,
      {int? sinceMillis, bool? fromMe, int? participantId, List<String> also = const []}) async {
    final (where, args) =
        _realWhere(chatId, sinceMillis: sinceMillis, fromMe: fromMe, participantId: participantId, also: also);
    return (await db.select('SELECT count(*) AS n $where', args)).single['n'] as int;
  }

  Future<int> totalMessages(int chatId) => _count(chatId);

  /// Cheap size probe for the adaptive detail tier.
  Future<int> messageCountForTier(int chatId) => totalMessages(chatId);

  Future<int> sentCount(int chatId) => _count(chatId, fromMe: true);

  Future<int> receivedCount(int chatId, {int? participantId}) =>
      _count(chatId, fromMe: false, participantId: participantId);

  Future<int> unattributedCount(int chatId, {int? sinceMillis}) =>
      _count(chatId, sinceMillis: sinceMillis, fromMe: false, also: ['m.handle_relation_id IS NULL']);

  Future<int> attachmentMessageCount(int chatId, {int? sinceMillis}) =>
      _count(chatId, sinceMillis: sinceMillis, also: ['m.has_attachments = 1']);

  /// Distinct local sender ids of the chat's incoming messages, departed
  /// members included, in order of their first message.
  Future<List<int>> participantHandleIds(int chatId, {int? sinceMillis}) async {
    final (where, args) =
        _realWhere(chatId, sinceMillis: sinceMillis, fromMe: false, also: ['m.handle_relation_id IS NOT NULL']);
    final rows = await db.select('SELECT m.handle_relation_id AS h $where', args);
    return {for (final r in rows) r['h'] as int}.toList();
  }

  /// Ascending creation times per participant ([kMeParticipantId] for mine).
  Future<Map<int, List<int>>> timestampsByParticipant(int chatId, {int? sinceMillis}) async {
    Future<List<int>> times({required bool fromMe, int? participantId}) async {
      final (where, args) = _realWhere(chatId, sinceMillis: sinceMillis, fromMe: fromMe, participantId: participantId);
      return [for (final r in await db.select('SELECT m.date_created_us AS t $where', args)) _ms(r['t'])]..sort();
    }

    return {
      kMeParticipantId: await times(fromMe: true),
      for (final handleId in await participantHandleIds(chatId, sinceMillis: sinceMillis))
        handleId: await times(fromMe: false, participantId: handleId),
    };
  }

  /// Read times of my messages that were read, ascending.
  Future<List<int>> readTimestamps(int chatId, {int? sinceMillis}) async {
    final (where, args) =
        _realWhere(chatId, sinceMillis: sinceMillis, fromMe: true, also: ['m.date_read_us IS NOT NULL']);
    return [for (final r in await db.select('SELECT m.date_read_us AS t $where', args)) _ms(r['t'])]..sort();
  }

  /// [participantId] narrows incoming edits to one sender (only with `fromMe: false`).
  Future<int> editedCount(int chatId, {bool? fromMe, int? participantId}) => _count(chatId,
      fromMe: fromMe, participantId: fromMe == false ? participantId : null, also: ['m.date_edited_us IS NOT NULL']);

  /// Edited messages that report a retracted (unsent) part.
  Future<int> unsentCount(int chatId, {bool? fromMe, int? participantId}) async {
    final (where, args) = _realWhere(chatId,
        fromMe: fromMe, participantId: fromMe == false ? participantId : null, also: ['m.date_edited_us IS NOT NULL']);
    final rows = await db.select('SELECT m.message_summary_info_json AS s $where', args);
    return rows.where((r) => (Message()..dbMessageSummaryInfo = r['s'] as String?).retractedParts.isNotEmpty).length;
  }

  /// The newest [limit] texts of one side, newest first; [participantId]
  /// narrows the incoming side to one sender.
  Future<List<String>> recentTexts(int chatId, {required bool fromMe, int? limit, int? participantId}) async {
    final (where, args) = _realWhere(chatId,
        fromMe: fromMe, participantId: fromMe ? null : participantId, also: ['m.text IS NOT NULL']);
    final rows = await db.select('SELECT m.text $where ORDER BY m.date_created_us DESC, m.id DESC LIMIT ?', [...args, limit ?? -1]);
    return [for (final r in rows) r['text'] as String];
  }

  /// Text lengths (UTF-16 code units, as Dart's `String.length`) of each
  /// participant's newest [limitPerParticipant] texted messages, newest first.
  Future<Map<int, List<int>>> textLengthsByParticipant(int chatId, {int? sinceMillis, int? limitPerParticipant}) async {
    Future<List<int>> lengths({required bool fromMe, int? participantId}) async {
      final (where, args) = _realWhere(chatId,
          sinceMillis: sinceMillis, fromMe: fromMe, participantId: participantId, also: ['m.text IS NOT NULL']);
      final rows = await db.select(
          'SELECT m.text $where ORDER BY m.date_created_us DESC, m.id DESC LIMIT ?', [...args, limitPerParticipant ?? -1]);
      return [for (final r in rows) (r['text'] as String).length];
    }

    return {
      kMeParticipantId: await lengths(fromMe: true),
      for (final handleId in await participantHandleIds(chatId, sinceMillis: sinceMillis))
        handleId: await lengths(fromMe: false, participantId: handleId),
    };
  }

  /// Share of real messages with `text`; 1.0 for a chat without messages.
  Future<double> textCoverage(int chatId) async {
    final total = await totalMessages(chatId);
    if (total == 0) return 1.0;
    return await _count(chatId, also: ['m.text IS NOT NULL']) / total;
  }

  /// Every reaction row not deleted: raw type (a `-` prefix means removed) and reactor.
  Future<List<({String type, int participantId})>> reactions(int chatId) async {
    final rows = await db.select(
        'SELECT m.associated_message_type AS t, m.is_from_me, m.handle_relation_id $_all '
        'AND m.date_deleted_us IS NULL AND m.associated_message_type IS NOT NULL',
        [chatId]);
    return [for (final r in rows) (type: r['t'] as String, participantId: _reactor(r))];
  }

  /// Mime types of the attachments of real messages (attachment-mix donut).
  Future<List<String>> attachmentMimeTypes(int chatId) async {
    final (where, args) = _realWhere(chatId, also: ['m.has_attachments = 1']);
    final rows = await db.select(
        'SELECT a.mime_type ${_withAttachments(where)} AND a.mime_type IS NOT NULL', args);
    return [for (final r in rows) r['mime_type'] as String];
  }

  /// [where] (a `FROM messages m ... WHERE` clause) joined to each matching
  /// message's attachments by attachments_message.
  static String _withAttachments(String where) => where.replaceFirst(
      'FROM messages m INDEXED BY messages_timeline WHERE',
      'FROM messages m INDEXED BY messages_timeline JOIN attachments a INDEXED BY attachments_message '
          'ON a.message_id = m.id WHERE');

  Future<List<String>> expressiveSendStyleIds(int chatId) async {
    final (where, args) = _realWhere(chatId, also: ['m.expressive_send_style_id IS NOT NULL']);
    return [for (final r in await db.select('SELECT m.expressive_send_style_id AS e $where', args)) r['e'] as String];
  }

  /// Audio attachments sent and received (mime type starting with `audio`,
  /// case-sensitive as ObjectBox's `startsWith`), and the share of received
  /// voice messages that were played.
  Future<({int sent, int received, double? playedOfReceived})> audioStats(int chatId) async {
    Future<int> audio(bool fromMe) async {
      final (where, args) = _realWhere(chatId, fromMe: fromMe, also: ['m.has_attachments = 1']);
      final rows = await db.select("SELECT count(*) AS n ${_withAttachments(where)} AND a.mime_type GLOB 'audio*'", args);
      return rows.single['n'] as int;
    }

    final sent = await audio(true);
    final received = await audio(false);
    final played = await _count(chatId, fromMe: false, also: ['m.date_played_us IS NOT NULL']);
    return (sent: sent, received: received, playedOfReceived: received == 0 ? null : played / received);
  }

  /// Group membership, name and photo events, oldest first.
  Future<List<GroupEventRecord>> groupEvents(int chatId) async {
    final rows = await db.select(
        'SELECT m.item_type, m.group_action_type, m.group_title, m.date_created_us, m.is_from_me, m.handle_relation_id '
        '$_all AND m.date_deleted_us IS NULL AND m.item_type != 0 AND m.date_created_us IS NOT NULL '
        'ORDER BY m.date_created_us, m.id',
        [chatId]);
    return [
      for (final r in rows)
        GroupEventRecord(
          itemType: r['item_type'] as int,
          groupActionType: r['group_action_type'] as int? ?? 0,
          groupTitle: r['group_title'] as String?,
          dateMillis: _ms(r['date_created_us']),
          senderId: _reactor(r),
        ),
    ];
  }

  /// Who reacted to whom since [sinceMillis] (exclusive): each real message's
  /// sender by guid, and each reaction row not deleted.
  Future<({List<ReactionMatrixRow> reactionRows, Map<String, int> guidToSender})> reactionMatrixData(int chatId,
      {required int sinceMillis}) async {
    final (where, args) = _realWhere(chatId, afterMillis: sinceMillis, also: ['m.guid IS NOT NULL']);
    final senders = await db.select('SELECT m.guid, m.is_from_me, m.handle_relation_id $where', args);
    final reactions = await db.select(
        'SELECT m.associated_message_guid AS g, m.associated_message_type AS t, m.is_from_me, m.handle_relation_id '
        '$_all AND m.date_deleted_us IS NULL AND m.associated_message_type IS NOT NULL '
        'AND m.associated_message_guid IS NOT NULL AND m.date_created_us > ?',
        [chatId, sinceMillis * 1000]);
    return (
      reactionRows: [
        for (final r in reactions) ReactionMatrixRow(targetGuid: r['g'] as String, reactorId: _reactor(r), type: r['t'] as String),
      ],
      guidToSender: {for (final r in senders) r['guid'] as String: _reactor(r)},
    );
  }

  /// The creation time of the chat's first real message, whatever the timeframe.
  Future<int?> firstMessageMillis(int chatId) async {
    final rows = await db.select('SELECT m.date_created_us AS t $_real ORDER BY m.date_created_us, m.id LIMIT 1', [chatId]);
    return rows.isEmpty ? null : _ms(rows.single['t']);
  }

  /// Changes whenever the chat gains or loses messages: the real-message count
  /// and the newest one's creation time (0 when none).
  Future<({int count, int latestMillis})> cacheKey(int chatId) async {
    final count = await totalMessages(chatId);
    final rows =
        await db.select('SELECT m.date_created_us AS t $_real ORDER BY m.date_created_us DESC, m.id DESC LIMIT 1', [chatId]);
    return (count: count, latestMillis: rows.isEmpty ? 0 : _ms(rows.single['t']));
  }
}
