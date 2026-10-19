import 'package:bluebubbles/database/models.dart';
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

  test('deletion application rechecks suppression and otherwise remains fail-open', () async {
    final suppressed = Chat(id: 1, guid: 'suppressed');
    final ordinary = Chat(id: 2, guid: 'ordinary');
    final deleted = <String>[];

    for (final chat in <Chat>[suppressed, ordinary]) {
      await ChatStateReconciler.applyDeletionCandidate(
        chat,
        <String>{'suppressed', 'ordinary'},
        isRecoverableDeleteSuppressed: (guid) => guid == 'suppressed',
        hasLocalWork: (_) => false,
        softDelete: (chat) async => deleted.add(chat.guid),
      );
    }
    expect(deleted, <String>['ordinary']);

    deleted.clear();
    for (final chat in <Chat>[suppressed, ordinary]) {
      await ChatStateReconciler.applyDeletionCandidate(
        chat,
        <String>{'suppressed', 'ordinary'},
        isRecoverableDeleteSuppressed: (_) => false,
        hasLocalWork: (_) => false,
        softDelete: (chat) async => deleted.add(chat.guid),
      );
    }
    expect(deleted, <String>['suppressed', 'ordinary'], reason: 'degraded suppression fails open');

    deleted.clear();
    final candidates = <String>{'suppressed'};
    var suppressionAppeared = false;
    bool suppressionAtApplication(String _) => suppressionAppeared;
    suppressionAppeared = true;
    await ChatStateReconciler.applyDeletionCandidate(
      suppressed,
      candidates,
      isRecoverableDeleteSuppressed: suppressionAtApplication,
      hasLocalWork: (_) => false,
      softDelete: (chat) async => deleted.add(chat.guid),
    );
    expect(deleted, isEmpty, reason: 'suppression is checked at the application boundary');
  });
}
