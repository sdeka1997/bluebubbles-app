import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/popup/details_menu_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Apple devices are the source of truth, so a message can't be deleted from Android.
  test('the message details menu offers no Delete', () {
    expect(DetailsMenuAction.values.map((a) => a.name), isNot(contains('Delete')));
  });

  test('the message details menu still offers Undo Send, Edit and Copy', () {
    expect(
      DetailsMenuAction.values,
      containsAll([DetailsMenuAction.UndoSend, DetailsMenuAction.Edit, DetailsMenuAction.CopyText]),
    );
  });
}
