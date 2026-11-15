import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/sync/incremental_sync_manager.dart';
import 'package:flutter_test/flutter_test.dart';

Message photoEvent(int action) => Message(
      guid: 'photo-$action',
      itemType: 3,
      groupActionType: action,
      isFromMe: false,
    );

void main() {
  test('3/3 is silent photo state while 3/1 and 3/2 remain visible events', () {
    expect(photoEvent(3).isGroupPhotoState, isTrue);
    expect(photoEvent(3).isTranscriptVisible, isFalse);
    expect(photoEvent(3).isGroupPhotoEvent, isTrue, reason: 'it still updates the stored chat icon state');

    expect(photoEvent(1).isGroupPhotoState, isFalse);
    expect(photoEvent(1).isTranscriptVisible, isTrue);
    expect(photoEvent(1).buildGroupEventText('Alex'), 'Alex changed the group photo.');

    expect(photoEvent(2).isGroupPhotoState, isFalse);
    expect(photoEvent(2).isTranscriptVisible, isTrue);
    expect(photoEvent(2).buildGroupEventText('Alex'), 'Alex removed the group photo.');
  });

  test('incremental sync dispatches only transcript-visible message ids', () {
    final changed = photoEvent(1)..id = 1;
    final state = photoEvent(3)..id = 2;
    final link = Message(id: 3, guid: 'link', itemType: 0);

    expect(visibleMessageIds([changed, state, link]), [1, 3]);
  });
}
