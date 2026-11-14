import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

// The chat list italicises previews the app writes ("1 Photo", "You loved …",
// "Unsent message") so they don't read like text someone typed.
void main() {
  setUpAll(() {
    if (!GetIt.I.isRegistered<BaseLogger>()) GetIt.I.registerSingleton<BaseLogger>(BaseLogger());
  });

  final cases = <String, Message Function()>{
    'typed text': () => Message(guid: 't', text: 'see you soon', dateCreated: DateTime(2026)),
    'typed text with a subject': () =>
        Message(guid: 's', subject: 'Plans', text: 'see you soon', dateCreated: DateTime(2026)),
    'a photo': () => Message(guid: 'p', hasAttachments: true, dateCreated: DateTime(2026))
      ..dbAttachments.add(Attachment(guid: 'a', mimeType: 'image/jpeg')),
    'a photo with a caption': () =>
        Message(guid: 'pc', text: 'look', hasAttachments: true, dateCreated: DateTime(2026))
          ..dbAttachments.add(Attachment(guid: 'a', mimeType: 'image/jpeg')),
    'an attachment that has not loaded yet': () => Message(guid: 'l', hasAttachments: true, dateCreated: DateTime(2026)),
    'a reaction': () => Message(
          guid: 'r',
          isFromMe: true,
          associatedMessageGuid: 'target',
          associatedMessageType: 'love',
          text: 'Loved “hello”',
          dateCreated: DateTime(2026),
        )..reactionTarget = Message(guid: 'target', text: 'hello there', dateCreated: DateTime(2026)),
    'a reaction whose message is not loaded': () => Message(
          guid: 'r2',
          isFromMe: true,
          associatedMessageGuid: 'target',
          associatedMessageType: 'love',
          text: 'Loved “hello”',
          dateCreated: DateTime(2026),
        ),
    'an unsent message': () => Message(guid: 'u', dateCreated: DateTime(2026), dateEdited: DateTime(2026)),
    'an empty message': () => Message(guid: 'e', dateCreated: DateTime(2026)),
    'invisible ink': () => Message(
          guid: 'i',
          text: 'secret',
          expressiveSendStyleId: 'com.apple.MobileSMS.expressivesend.invisibleink',
          dateCreated: DateTime(2026),
        ),
    'an iMessage app message': () => Message(
          guid: 'g',
          balloonBundleId: 'com.apple.messages.MSMessageExtensionBalloonPlugin:0000000000:com.apple.Handwriting.HandwritingProvider',
          dateCreated: DateTime(2026),
        ),
    'a group rename': () => Message(guid: 'n', itemType: 2, groupTitle: 'Hoops', dateCreated: DateTime(2026)),
  };

  const typed = {'typed text', 'typed text with a subject'};

  for (final entry in cases.entries) {
    final described = !typed.contains(entry.key);
    test('${entry.key} ${described ? 'is' : 'is not'} described by the app', () {
      expect(entry.value().previewIsDescribed, described);
    });
  }

  // Keeps the cheap check in step with the preview text: only a preview that is
  // exactly what the person typed counts as typed.
  for (final entry in cases.entries) {
    test('${entry.key}: described exactly when the preview is not the typed text', () {
      final m = entry.value();
      expect(m.previewIsDescribed, m.getNotificationText() != m.fullText);
    });
  }
}
