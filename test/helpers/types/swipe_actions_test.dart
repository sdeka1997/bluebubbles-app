import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Archive is the only way to hide a conversation on Android.
  test('the swipe action picker offers Archive and no Delete', () {
    expect(MaterialSwipeAction.offered, contains(MaterialSwipeAction.archive));
    expect(MaterialSwipeAction.offered, isNot(contains(MaterialSwipeAction.delete)));
  });

  test('a saved Delete swipe becomes Archive', () {
    expect(MaterialSwipeAction.fromSaved(MaterialSwipeAction.delete.index), MaterialSwipeAction.archive);
    final s = Settings.fromMap({
      'materialLeftAction': MaterialSwipeAction.delete.index,
      'materialRightAction': MaterialSwipeAction.delete.index,
    });
    expect(s.materialLeftAction.value, MaterialSwipeAction.archive);
    expect(s.materialRightAction.value, MaterialSwipeAction.archive);
  });

  test('other saved swipes are kept', () {
    for (final action in MaterialSwipeAction.offered) {
      expect(MaterialSwipeAction.fromSaved(action.index), action);
    }
  });
}
