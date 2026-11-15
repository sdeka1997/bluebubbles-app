import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/incoming_message_handler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../database/store/store_fixture.dart';

void main() {
  storeTests((fixture) {
    test('same-guid photo state persists repairs and icon but never dispatches transcript UI', () async {
      final chat = await fixture().chat('photo-state-chat');
      final existing = await fixture().message(
        'photo-state',
        chat,
        t0 + 1000,
        itemType: 3,
        edit: (m) => m.groupActionType = 3,
      );
      final attachment = await fixture().attachment(
        'group-photo',
        existing,
        edit: (a) {
          a.transferName = 'old.jpg';
          a.totalBytes = 10;
        },
      );
      final incoming = Message(guid: 'photo-state', dateCreated: ms(t0 + 9000), itemType: 3, groupActionType: 3);
      var iconRefreshes = 0;
      var transcriptDispatches = 0;

      await applyUpdatedMessageEffects(
        message: incoming,
        persistMessage: () async {
          await fixture().store.replaceMessage(existing.guid, incoming);
        },
        persistAttachments: () async {
          await fixture().store.replaceAttachment(
            attachment.guid!,
            Attachment(guid: attachment.guid, mimeType: 'image/heic', transferName: 'repaired.heic', totalBytes: 200),
          );
        },
        refreshGroupPhotoIcon: () async => iconRefreshes++,
        dispatchTranscript: () async => transcriptDispatches++,
      );

      final storedMessage = (await fixture().store.messageByGuid('photo-state'))!;
      final storedAttachment = (await fixture().store.attachmentById(attachment.id!))!;
      expect(storedMessage.dateCreated, ms(t0 + 1000));
      expect(storedAttachment.transferName, 'repaired.heic');
      expect(storedAttachment.mimeType, 'image/heic');
      expect(storedAttachment.totalBytes, 200);
      expect(iconRefreshes, 1);
      expect(transcriptDispatches, 0);
    });
  });
}
