// Rules for syncing messages in ROWID windows so an interrupted sync resumes.
//
// The server sorts query results by date, not ROWID, so the highest ROWID in
// a page says nothing about what is still missing below it. A window of
// `(after, upTo]` holds at most one batch of rows, comes back whole in one
// request, and once synced every row up to `upTo` is in: that is a safe
// bookmark.

/// Consecutive empty windows (a large ROWID gap) before handing the rest of the
/// sync to plain offset paging, which is correct but not resumable.
const int maxEmptySyncWindows = 50;

/// Set in the isolate running the sync when the app leaves (true) or returns
/// to (false) the foreground. Isolates share no memory, so the main isolate
/// sends it with an isolate request.
bool syncPausedForBackground = false;

/// The ROWID window after [cursor], ending no later than [endRowId].
({int after, int upTo}) nextSyncWindow({required int cursor, required int batchSize, int? endRowId}) {
  final upTo = cursor + batchSize;
  return (after: cursor, upTo: endRowId != null && endRowId < upTo ? endRowId : upTo);
}

/// Whether to stop walking windows: every message counted when the sync began
/// has been seen, the end ROWID was reached, the gap is too long to walk, or
/// the app left the foreground ([paused]). Android cuts a cached app off the
/// network, so a backgrounded sync stops at the window in hand; its
/// checkpoint is where the next sync picks up.
bool syncWindowsDone({
  required int seen,
  required int total,
  required int cursor,
  required int emptyRun,
  int? endRowId,
  bool paused = false,
}) =>
    paused || seen >= total || (endRowId != null && cursor >= endRowId) || emptyRun >= maxEmptySyncWindows;

/// Whether a failed sync is worth a toast. Android blocks a backgrounded
/// app's network, so a failure then says nothing about the connection, and the
/// next foreground sync resumes from the checkpoint anyway.
bool shouldReportSyncFailure({required bool backgroundedDuringSync}) => !backgroundedDuringSync;

/// Share of the messages counted at the start that have been synced, for the
/// progress bar; null before there is a count.
double? syncProgress({required int seen, required int total}) {
  if (total <= 0) return null;
  return seen >= total ? 1.0 : seen / total;
}

/// The progress bar's text, e.g. "Updating messages… 21,662 of 401,275".
String syncProgressLabel({required int seen, required int total}) =>
    'Updating messages… ${_thousands(seen)} of ${_thousands(total)}';

String _thousands(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// The progress bar is for long catch-ups only; a single batch finishes in moments.
bool showSyncProgressBar({required int total, required int batchSize}) => total > batchSize;

/// The bookmark to keep at the end of a sync: never behind a window already
/// checkpointed, never behind the highest ROWID synced.
int? syncBookmark({required int? checkpoint, required int? lastSyncedRowId}) {
  if (checkpoint == null) return lastSyncedRowId;
  if (lastSyncedRowId == null) return checkpoint;
  return lastSyncedRowId > checkpoint ? lastSyncedRowId : checkpoint;
}
