import 'package:bluebubbles/database/models.dart';

String? _usable(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// One refresh of friends' locations: which friends it is waiting on and
/// which have reported since it started. It has no time limit: Apple reports
/// people over minutes, so a row spins until its friend reports or the screen
/// closes.
class FindMyRefreshProgress {
  const FindMyRefreshProgress._({
    required this.active,
    required this.finished,
    required this.startedAt,
    required this.awaitedIds,
    required this.reportedIds,
    this.roundId,
  });

  factory FindMyRefreshProgress.idle() =>
      const FindMyRefreshProgress._(active: false, finished: false, startedAt: null, awaitedIds: {}, reportedIds: {});

  /// [roundId] is the server's round this refresh follows, once known; null
  /// for a refresh the server has not yet answered, or a server without ids.
  factory FindMyRefreshProgress.start(DateTime startedAt, {int? roundId}) => FindMyRefreshProgress._(
    active: true,
    finished: false,
    startedAt: startedAt,
    awaitedIds: const {},
    reportedIds: const {},
    roundId: roundId,
  );

  final bool active;
  final bool finished;
  final DateTime? startedAt;
  final int? roundId;

  /// Friends whose location predated this refresh, or whom Apple was still
  /// locating, when the roster arrived.
  final Set<String> awaitedIds;
  final Set<String> reportedIds;

  /// Whether every friend this refresh waits on has reported.
  bool get allReported => awaitedIds.every(reportedIds.contains);

  /// Whether this refresh would wait on [friend] were it in the roster.
  bool _awaits(FindMyFriend friend) {
    if (friend.locatingInProgress) return true;
    final updated = friend.lastUpdated;
    return updated == null || startedAt == null || updated.isBefore(startedAt!);
  }

  FindMyRefreshProgress withRoster(Iterable<FindMyFriend> roster) => FindMyRefreshProgress._(
    active: active,
    finished: finished,
    startedAt: startedAt,
    awaitedIds: Set.unmodifiable(roster.where(_awaits).map((friend) => friend.stableId).whereType<String>()),
    reportedIds: reportedIds,
    roundId: roundId,
  );

  /// Records a pushed location. It ends [friend]'s wait only when its fix was
  /// taken after this refresh began, the same rule that decides who is waited on.
  FindMyRefreshProgress withEvent(FindMyFriend friend) {
    final usableId = _usable(friend.stableId);
    if (!active || usableId == null || _awaits(friend)) return this;
    return FindMyRefreshProgress._(
      active: active,
      finished: finished,
      startedAt: startedAt,
      awaitedIds: awaitedIds,
      reportedIds: Set.unmodifiable({...reportedIds, usableId}),
      roundId: roundId,
    );
  }

  /// The server authoritatively ended this round; cached Apple locating flags
  /// from its final payload must not keep rows spinning.
  FindMyRefreshProgress finishRound() => FindMyRefreshProgress._(
    active: false,
    finished: true,
    startedAt: startedAt,
    awaitedIds: awaitedIds,
    reportedIds: reportedIds,
    roundId: roundId,
  );

  /// Whether the server's [round] ending is the end of the round this
  /// refresh follows. Rounds run one after another, so by id the end of this
  /// round or any later one counts; without ids, a round that started before
  /// this refresh is an older one.
  bool isEndedBy(FindMyRound round) {
    if (round.collecting) return false;
    if (round.id != null && roundId != null) return round.id! >= roundId!;
    final roundStart = round.startedAt;
    return roundStart == null || startedAt == null || !roundStart.isBefore(startedAt!);
  }

  /// Whether [round] is older than the one this refresh already follows: a
  /// refresh answer and socket events travel separately, so an answer built
  /// for an older round can land after a newer round has started.
  bool isOlderThanFollowed(FindMyRound? round) => round?.id != null && roundId != null && round!.id! < roundId!;
}

/// Whether a friend's row shows a spinner where its distance goes. A server
/// round's finish is authoritative; outside a round, Apple's raw locating flag
/// is still shown independently.
bool findMyFriendRowSpinning(FindMyRefreshProgress progress, FindMyFriend friend) {
  if (progress.finished) return false;
  if (!progress.active) return friend.locatingInProgress;
  final id = friend.stableId;
  if (id != null && progress.reportedIds.contains(id)) return false;
  return progress._awaits(friend);
}

/// One round of locating on the server: whether new locations are on their
/// way, and since when. A location newer than [startedAt] is from the round.
/// [id] grows by one per round and [endedBy] says why it stopped (everyone,
/// quiet, failed or superseded); both are null from servers before round ids.
class FindMyRound {
  const FindMyRound({required this.collecting, required this.startedAt, this.id, this.endedBy});

  final bool collecting;
  final DateTime? startedAt;
  final int? id;
  final String? endedBy;

  /// Null unless [data] says whether the round is collecting.
  static FindMyRound? tryParse(dynamic data) {
    if (data is! Map || data['collecting'] is! bool) return null;
    final startedAt = data['startedAt'];
    final id = data['id'];
    final endedBy = data['endedBy'];
    return FindMyRound(
      collecting: data['collecting'] as bool,
      startedAt: startedAt is num ? DateTime.fromMillisecondsSinceEpoch(startedAt.toInt()) : null,
      id: id is num ? id.toInt() : null,
      endedBy: endedBy is String ? endedBy : null,
    );
  }
}
