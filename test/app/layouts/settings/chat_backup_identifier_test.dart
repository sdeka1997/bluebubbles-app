import 'package:bluebubbles/app/layouts/settings/pages/server/chat_backup_identifier.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

const person = '+15551110000';

/// A merged iMessage/SMS DM: one chat.db chat linked to both of the person's handles.
Chat mergedDm() =>
    Chat(guid: 'any;-;$person', chatIdentifier: person, style: 45)
      ..handles.addAll([Handle(address: person, service: 'iMessage'), Handle(address: person, service: 'SMS')]);

void main() {
  test('a merged DM is exported as a DM with its one address', () {
    expect(ChatBackupIdentifier.export(mergedDm()), {
      'type': 'dm',
      'displayName': null,
      'participants': [person],
    });
  });

  test('an older backup that saved a merged DM as a group naming it twice still restores', () {
    final chat = mergedDm();
    final match = ChatBackupIdentifier.resolve(
      {
        'type': 'group',
        'displayName': null,
        'participants': [person, person],
      },
      [chat],
    );

    expect(match.skipReason, isNull);
    expect(match.match, same(chat));
  });
}
