import 'package:bluebubbles/services/backend/sync/sync_windows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('syncWindowsDone when the app leaves the foreground', () {
    test('stops after the window in hand so the checkpoint is the resume point', () {
      expect(syncWindowsDone(seen: 10, total: 3000, cursor: 2000, emptyRun: 0, paused: true), isTrue);
    });

    test('keeps going while the app is open', () {
      expect(syncWindowsDone(seen: 10, total: 3000, cursor: 2000, emptyRun: 0, paused: false), isFalse);
    });
  });

  group('shouldReportSyncFailure', () {
    test('a failure while backgrounded is not reported: Android cut the app off', () {
      expect(shouldReportSyncFailure(backgroundedDuringSync: true), isFalse);
    });

    test('a failure while the app stayed open is reported', () {
      expect(shouldReportSyncFailure(backgroundedDuringSync: false), isTrue);
    });
  });

  group('syncProgress for the progress bar', () {
    test('is the share of messages synced so far', () {
      expect(syncProgress(seen: 21662, total: 401275), closeTo(0.054, 0.001));
    });

    test('never exceeds one, even if messages arrive during the sync', () {
      expect(syncProgress(seen: 3100, total: 3000), 1.0);
    });

    test('is unknown before anything is counted', () {
      expect(syncProgress(seen: 0, total: 0), isNull);
    });
  });

  test('the progress label counts messages with thousands separators', () {
    expect(syncProgressLabel(seen: 21662, total: 401275), 'Updating messages… 21,662 of 401,275');
    expect(syncProgressLabel(seen: 0, total: 950), 'Updating messages… 0 of 950');
  });

  group('showSyncProgressBar', () {
    test('shows only for a sync longer than one batch', () {
      expect(showSyncProgressBar(total: 401275, batchSize: 1000), isTrue);
      expect(showSyncProgressBar(total: 40, batchSize: 1000), isFalse);
    });
  });

  group('catchUpProgress across pauses', () {
    test('a fresh catch-up records its size and starts at zero', () {
      expect(catchUpProgress(saved: null, seenThisRun: 0, remainingThisRun: 381870),
          (done: 0, total: 381870));
    });

    test('a resumed catch-up counts what earlier runs already synced', () {
      // Live: paused with 336,223 left of the 381,870 the catch-up began with.
      expect(catchUpProgress(saved: 381870, seenThisRun: 22816, remainingThisRun: 336223),
          (done: 45647 + 22816, total: 381870));
    });

    test('messages that arrive during the catch-up grow the total instead of going negative', () {
      expect(catchUpProgress(saved: 1000, seenThisRun: 0, remainingThisRun: 1500), (done: 0, total: 1500));
    });

    test('a short sync starts a new catch-up rather than continuing an old one', () {
      expect(catchUpProgress(saved: null, seenThisRun: 10, remainingThisRun: 40), (done: 10, total: 40));
    });
  });
}
