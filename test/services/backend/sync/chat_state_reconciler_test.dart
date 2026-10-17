import 'package:bluebubbles/services/backend/sync/chat_state_reconciler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a newer authoritative snapshot repairs local state even when the baseline is unchanged', () {
    expect(
      desiredUnreadFromSnapshot(hasTrustedBaseline: true, baselineHasChat: true, serverRead: false, localUnread: false),
      isTrue,
    );
  });

  test('the first snapshot seeds without backfilling historical read state', () {
    expect(
      desiredUnreadFromSnapshot(
        hasTrustedBaseline: false,
        baselineHasChat: false,
        serverRead: false,
        localUnread: false,
      ),
      isNull,
    );
  });

  test('an authoritative snapshot does nothing when local state already matches', () {
    expect(
      desiredUnreadFromSnapshot(hasTrustedBaseline: true, baselineHasChat: true, serverRead: false, localUnread: true),
      isNull,
    );
  });


  test('recoverable delete resolution is gated behind complete valid non-stale validation', () async {
    var calls = 0;
    Future<Set<String>> resolve() async {
      calls++;
      return {'resolved'};
    }

    expect(
      await resolveRecoverableDeletesAfterValidation(
        isComplete: false,
        isValid: true,
        isStale: false,
        resolve: resolve,
      ),
      isEmpty,
    );
    expect(
      await resolveRecoverableDeletesAfterValidation(
        isComplete: true,
        isValid: false,
        isStale: false,
        resolve: resolve,
      ),
      isEmpty,
    );
    expect(
      await resolveRecoverableDeletesAfterValidation(
        isComplete: true,
        isValid: true,
        isStale: true,
        resolve: resolve,
      ),
      isEmpty,
    );
    expect(calls, 0);

    expect(
      await resolveRecoverableDeletesAfterValidation(
        isComplete: true,
        isValid: true,
        isStale: false,
        resolve: resolve,
      ),
      {'resolved'},
    );
    expect(calls, 1);
  });

  test('unconfirmed existing deferred deletions survive a journal draft handoff', () {
    expect(
      deferredDeletionsToCarryForward(
        queued: {'existing-unconfirmed', 'confirmed'},
        confirmed: {'confirmed'},
      ),
      {'existing-unconfirmed'},
    );
  });
}
