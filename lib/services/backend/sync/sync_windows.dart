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

/// The ROWID window after [cursor], ending no later than [endRowId].
({int after, int upTo}) nextSyncWindow({required int cursor, required int batchSize, int? endRowId}) {
  final upTo = cursor + batchSize;
  return (after: cursor, upTo: endRowId != null && endRowId < upTo ? endRowId : upTo);
}

/// Whether to stop walking windows: every message counted when the sync began
/// has been seen, the end ROWID was reached, or the gap is too long to walk.
bool syncWindowsDone({
  required int seen,
  required int total,
  required int cursor,
  required int emptyRun,
  int? endRowId,
}) =>
    seen >= total || (endRowId != null && cursor >= endRowId) || emptyRun >= maxEmptySyncWindows;

/// The bookmark to keep at the end of a sync: never behind a window already
/// checkpointed, never behind the highest ROWID synced.
int? syncBookmark({required int? checkpoint, required int? lastSyncedRowId}) {
  if (checkpoint == null) return lastSyncedRowId;
  if (lastSyncedRowId == null) return checkpoint;
  return lastSyncedRowId > checkpoint ? lastSyncedRowId : checkpoint;
}
