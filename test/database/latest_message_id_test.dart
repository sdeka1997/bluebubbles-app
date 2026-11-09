import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a stored message is saved as latest as-is', () {
    final stored = Message(id: 42, guid: 'm1', dateCreated: DateTime(2026, 10, 30, 20, 22));
    expect(latestMessageToStore(stored), same(stored));
  });

  test('a message with no local id needs its stored copy first', () {
    expect(latestMessageToStore(Message(guid: 'm2', dateCreated: DateTime(2026))), isNull);
  });
}
