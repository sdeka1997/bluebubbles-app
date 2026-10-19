import 'dart:async';

import 'package:bluebubbles/helpers/network/network_tasks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('incremental sync waits for recoverable-delete recovery', () async {
    final recovery = Completer<void>();
    final calls = <String>[];

    final operation = NetworkTasks.recoverPendingDeletesBeforeSync(
      recoverPendingDeletes: () {
        calls.add('recovery');
        return recovery.future;
      },
      startIncrementalSync: () => calls.add('sync'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(calls, <String>['recovery']);
    recovery.complete();
    await operation;
    expect(calls, <String>['recovery', 'sync']);
  });

  test('incremental sync still starts once when recovery fails', () async {
    var syncStarts = 0;

    await NetworkTasks.recoverPendingDeletesBeforeSync(
      recoverPendingDeletes: () => Future<void>.error(StateError('recovery failed')),
      startIncrementalSync: () => syncStarts++,
    );

    expect(syncStarts, 1);
  });
}
