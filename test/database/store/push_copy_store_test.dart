// A push the server trimmed to fit FCM's 4 KB limit is completed in place by
// the next full copy of the message, an edit never keeps formatting written
// for the old text, and a trimmed copy never overwrites a full one.
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/constants.dart' as constants show PayloadType;
import 'package:flutter_test/flutter_test.dart';

import 'store_fixture.dart';

AttributedBody _richBody(String text) => AttributedBody(
  string: text,
  runs: [
    Run(
      range: [0, text.length],
      attributes: Attributes(messagePart: 0, mention: 'mailto:person@example.com'),
    ),
  ],
);

MessageSummaryInfo _summary() => MessageSummaryInfo(
  retractedParts: [1],
  editedContent: const {},
  originalTextRange: const {},
  editedParts: const [0],
);

void main() {
  storeTests((fixture) {
    test('a full copy fills what a trimmed push left out, in place', () async {
      final chat = await fixture().chat('push-chat');
      final pushed = await fixture().message(
        'push-guid',
        chat,
        t0 + 1000,
        text: 'hello',
        edit: (m) {
          m.attributedBody = [];
          m.messageSummaryInfo = [];
          m.payloadData = null;
          m.metadata = null;
          m.hasAttachments = true;
        },
      );
      final pushedAttachment = await fixture().attachment('push-attachment', pushed, edit: (a) => a.metadata = null);

      await fixture().store.replaceMessage(
        pushed.guid,
        Message(
          guid: pushed.guid,
          text: 'hello',
          dateCreated: pushed.dateCreated,
          attributedBody: [_richBody('hello')],
          messageSummaryInfo: [_summary()],
          payloadData: PayloadData(type: constants.PayloadType.url),
          metadata: {'message': 'full'},
        ),
      );
      await fixture().store.replaceAttachment(
        pushedAttachment.guid!,
        Attachment(guid: pushedAttachment.guid, metadata: {'width': 640}),
      );

      final stored = (await fixture().store.messageByGuid(pushed.guid!))!;
      expect(await fixture().db.select('SELECT id FROM messages WHERE guid = ?', [pushed.guid]), hasLength(1));
      expect(stored.id, pushed.id);
      expect(stored.dateCreated, pushed.dateCreated);
      expect(stored.attributedBody.single.toMap(), _richBody('hello').toMap());
      expect(stored.messageSummaryInfo.single.toJson(), _summary().toJson());
      expect(stored.payloadData, isNotNull);
      expect(stored.metadata, {'message': 'full'});
      final attachment = (await fixture().store.attachmentById(pushedAttachment.id!))!;
      expect(attachment.metadata, {'width': 640});
      expect(attachment.mimeType, pushedAttachment.mimeType, reason: 'fields the full copy omits are kept');
    });

    test('a trimmed copy never overwrites a full one', () async {
      final chat = await fixture().chat('full-chat');
      final full = await fixture().message(
        'full-guid',
        chat,
        t0 + 2000,
        text: 'complete',
        edit: (m) {
          m.attributedBody = [_richBody('complete')];
          m.messageSummaryInfo = [_summary()];
          m.metadata = {'message': 'full'};
        },
      );

      await fixture().store.replaceMessage(
        full.guid,
        Message(guid: full.guid, text: 'complete', dateCreated: full.dateCreated),
      );

      final stored = (await fixture().store.messageByGuid(full.guid!))!;
      expect(stored.attributedBody.single.toMap(), _richBody('complete').toMap());
      expect(stored.messageSummaryInfo.single.toJson(), _summary().toJson());
      expect(stored.metadata, {'message': 'full'});
    });

    test('an edit drops formatting written for the old text', () async {
      final chat = await fixture().chat('edit-chat');
      final original = await fixture().message(
        'edit-guid',
        chat,
        t0 + 3000,
        text: 'before',
        edit: (m) {
          m.attributedBody = [_richBody('before')];
          m.dateEdited = ms(t0 + 3500);
        },
      );

      // An edit arriving by push: the new text without its (trimmed) formatting.
      await fixture().store.replaceMessage(
        original.guid,
        Message(guid: original.guid, text: 'after', dateCreated: original.dateCreated, dateEdited: ms(t0 + 4000)),
      );

      final edited = (await fixture().store.messageByGuid(original.guid!))!;
      expect(edited.text, 'after');
      expect(edited.attributedBody, isEmpty, reason: 'mention ranges for "before" would mislabel "after"');
      expect(edited.dateCreated, original.dateCreated);
    });
  });
}
