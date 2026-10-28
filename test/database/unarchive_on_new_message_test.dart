import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Archive is the only way to hide a conversation, so a new message brings it back.
  test('a fresh install unarchives a conversation when a new message arrives', () {
    expect(Settings().unarchiveOnNewMessage.value, isTrue);
  });

  test('settings saved before the toggle existed unarchive on a new message', () {
    expect(Settings.fromMap({}).unarchiveOnNewMessage.value, isTrue);
  });

  test('a saved choice to keep conversations archived is kept', () {
    expect(Settings.fromMap({'unarchiveOnNewMessage': false}).unarchiveOnNewMessage.value, isFalse);
  });
}
