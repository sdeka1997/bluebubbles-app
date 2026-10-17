import 'package:bluebubbles/services/backend/settings/actions/shared_preferences_database_actions.dart';
import 'package:bluebubbles/services/backend/settings/shared_preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recoverable delete journal write throws when preferences returns false', () async {
    final actions = SharedPreferencesDatabaseActions(SharedPreferencesService(), writeString: (_, _) async => false);

    await expectLater(actions.setRecoverableDeleteJournal('{}'), throwsStateError);
  });

  test('recoverable delete journal write propagates a thrown preferences failure', () async {
    final actions = SharedPreferencesDatabaseActions(
      SharedPreferencesService(),
      writeString: (_, _) async => throw StateError('disk failure'),
    );

    await expectLater(actions.setRecoverableDeleteJournal('{}'), throwsStateError);
  });
}
