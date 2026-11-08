import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a message remembers the Apple chat it came through', () {
    final m = Message.fromMap({
      'guid': 'm1',
      'chats': [
        {'guid': 'iMessage;+;chat17'}
      ],
    });
    expect(m.appleChatGuid, 'iMessage;+;chat17');
    expect(Message.fromMap(m.toMap()).appleChatGuid, 'iMessage;+;chat17');
  });

  test('a stored value round-trips without the chats list', () {
    expect(Message.fromMap({'guid': 'm1', 'appleChatGuid': 'SMS;-;+15550000001'}).appleChatGuid, 'SMS;-;+15550000001');
  });

  test('a message without chats has no Apple chat', () {
    expect(Message.fromMap({'guid': 'm1'}).appleChatGuid, isNull);
  });

  test('merging keeps the first Apple chat seen', () {
    final stored = Message(guid: 'm1', appleChatGuid: 'iMessage;+;a');
    Message.merge(stored, Message(guid: 'm1'));
    expect(stored.appleChatGuid, 'iMessage;+;a');
    final empty = Message(guid: 'm2');
    Message.merge(empty, Message(guid: 'm2', appleChatGuid: 'iMessage;+;b'));
    expect(empty.appleChatGuid, 'iMessage;+;b');
  });
}
