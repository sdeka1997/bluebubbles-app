import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Chat.fromMap keeps the Messages group id', () {
    final chat = Chat.fromMap({'guid': 'RCS;-;+15550001111', 'groupId': 'F203DA0D'});

    expect(chat.groupId, 'F203DA0D');
    expect(Chat.fromMap(chat.toMap()).groupId, 'F203DA0D');
  });

  test('a server without group ids leaves it unknown', () {
    expect(Chat.fromMap({'guid': 'SMS;-;+15550001111'}).groupId, isNull);
  });
}
