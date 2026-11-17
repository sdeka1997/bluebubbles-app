import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

// Preview text reads the linked rows the repository filled with the message,
// never the database.
void main() {
  setUpAll(() {
    if (!GetIt.I.isRegistered<BaseLogger>()) GetIt.I.registerSingleton<BaseLogger>(BaseLogger());
  });

  test('a reaction previews the text of the message it reacts to', () {
    final reaction = Message(guid: 'r', isFromMe: true, associatedMessageGuid: 'target', associatedMessageType: 'love',
        text: 'Loved “hello”', dateCreated: DateTime(2026))
      ..reactionTarget.target = Message(guid: 'target', text: 'hello there', dateCreated: DateTime(2026));
    expect(reaction.getNotificationText(), 'You loved “hello there”');
  });

  test('a reaction whose message is not loaded falls back to its own text', () {
    final reaction = Message(guid: 'r', isFromMe: true, associatedMessageGuid: 'target', associatedMessageType: 'love',
        text: 'Loved “hello”', dateCreated: DateTime(2026));
    expect(reaction.getNotificationText(), 'You Loved “hello”');
  });

  test('a participant event names the other person from the loaded handle', () {
    final added = Message(guid: 'a', isFromMe: true, itemType: 1, groupActionType: 0, otherHandle: 7, dateCreated: DateTime(2026))
      ..otherParticipant.target = Handle(address: 'bob@example.com', formattedAddress: 'bob@example.com');
    expect(added.buildGroupEventText('You'), 'You added bob@example.com to the conversation.');
    expect((added..otherParticipant.target = null).buildGroupEventText('You'), 'You added someone to the conversation.');
  });
}
