import 'package:bluebubbles/database/models.dart';

/// How long a refresh waits on friends to report fresh locations before it
/// stops showing progress. The server's friend refresh answers in 0.85-5 s and
/// Apple pushes each fix over the socket shortly after; a friend still silent
/// after this is not going to report in this refresh.
const Duration findMyRefreshWindow = Duration(seconds: 30);

String? _usable(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// One refresh of friends' locations: which friends it is waiting on and
/// which have reported since it started.
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

  FindMyRefreshProgress withUsableEvent(String? id) {
    final usableId = _usable(id);
    if (!active || usableId == null) return this;
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
