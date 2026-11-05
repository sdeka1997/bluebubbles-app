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
    required this.startedAt,
    required this.awaitedIds,
    required this.reportedIds,
  });

  factory FindMyRefreshProgress.idle() =>
      const FindMyRefreshProgress._(active: false, startedAt: null, awaitedIds: {}, reportedIds: {});

  factory FindMyRefreshProgress.start(DateTime startedAt) =>
      FindMyRefreshProgress._(active: true, startedAt: startedAt, awaitedIds: const {}, reportedIds: const {});

  final bool active;
  final DateTime? startedAt;

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
    startedAt: startedAt,
    awaitedIds: Set.unmodifiable(roster.where(_awaits).map((friend) => friend.stableId).whereType<String>()),
    reportedIds: reportedIds,
  );

  /// Records a pushed location. It ends [friend]'s wait only when its fix was
  /// taken after this refresh began, the same rule that decides who is waited on.
  FindMyRefreshProgress withEvent(FindMyFriend friend) {
    final usableId = _usable(friend.stableId);
    if (!active || usableId == null || _awaits(friend)) return this;
    return FindMyRefreshProgress._(
      active: active,
      startedAt: startedAt,
      awaitedIds: awaitedIds,
      reportedIds: Set.unmodifiable({...reportedIds, usableId}),
    );
  }

  FindMyRefreshProgress finish() =>
      FindMyRefreshProgress._(active: false, startedAt: startedAt, awaitedIds: awaitedIds, reportedIds: reportedIds);
}

/// Whether a friend's row shows a spinner where its distance goes. During a
/// refresh that lasts until a friend whose fix predates the refresh reports;
/// outside one, only while Apple is still locating them.
bool findMyFriendRowSpinning(FindMyRefreshProgress progress, FindMyFriend friend) {
  if (!progress.active) return friend.locatingInProgress;
  final id = friend.stableId;
  if (id != null && progress.reportedIds.contains(id)) return false;
  return progress._awaits(friend);
}
