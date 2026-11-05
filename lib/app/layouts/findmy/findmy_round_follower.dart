import 'package:bluebubbles/app/layouts/findmy/findmy_refresh_progress.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:get/get.dart';

/// Follows the server's locating rounds for the Find My screen: which round
/// the rows wait on, who has reported in it, and when they stop spinning.
/// Socket events and refresh answers travel separately, so either may arrive
/// first; this is the one place that reconciles them.
class FindMyRoundFollower {
  FindMyRoundFollower({required this.pendingRequests});

  /// How many of the screen's requests are still waiting on the server.
  final int Function() pendingRequests;

  final Rx<FindMyRefreshProgress> progress = FindMyRefreshProgress.idle().obs;

  /// A load of this screen began at [startedAt]; only fixes after it count
  /// until the server names its round.
  void begin(DateTime startedAt) => progress.value = FindMyRefreshProgress.start(startedAt);

  /// A location Apple pushed for one friend.
  void fix(FindMyFriend friend) {
    progress.value = progress.value.withEvent(friend);
    settleIfDone();
  }

  /// Returns to ordinary idle state once this app session has settled. This is
  /// not evidence that Apple's server round ended, so raw locating state stays.
  void settleIfDone() {
    final current = progress.value;
    if (!current.active || pendingRequests() > 0 || !current.allReported) return;
    progress.value = FindMyRefreshProgress.idle();
  }

  /// The server says a round started or ended. The end of the round this page
  /// is waiting on stops the rows still spinning: nothing more is coming. A
  /// new round (another client's, or one started after the last ended) waits
  /// again on everyone in [friends] whose fix predates it.
  void socketRound(dynamic data, Iterable<FindMyFriend> friends) {
    final round = FindMyRound.tryParse(data);
    if (round == null) return;
    final current = progress.value;
    if (round.collecting) {
      final startedAt = round.startedAt;
      if (round.id == null || startedAt == null || round.id == current.roundId) return;
      progress.value = FindMyRefreshProgress.start(startedAt, roundId: round.id).withRoster(friends);
      return;
    }
    if (current.active && current.isEndedBy(round)) _finishServerRound();
  }

  /// A refresh answer carrying [roster] and the server's [round], null from
  /// servers that do not say.
  void answer(FindMyRound? round, List<FindMyFriend> roster) {
    final current = progress.value;
    if (current.isOlderThanFollowed(round)) {
      // Built for a round the socket has since replaced: keep following the newer one
      progress.value = current.withRoster(roster);
      return;
    }
    // A round rejoined part-way is measured from its own start, so
    // friends who already reported in it do not spin again
    if (round?.startedAt != null) {
      progress.value = FindMyRefreshProgress.start(round!.startedAt!, roundId: round.id);
    }
    progress.value = progress.value.withRoster(roster);
    // A round that has ended sends nothing more, so no row should spin
    if (round?.collecting == false) _finishServerRound();
  }

  void _finishServerRound() => progress.value = progress.value.finishRound();
}
