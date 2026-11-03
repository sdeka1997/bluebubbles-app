import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final stored = Message(id: 42, guid: 'm1', dateCreated: DateTime(2026, 10, 30, 20, 22));

  test('a message from a server event is matched to the stored copy by guid', () {
    // Server payloads carry the Mac's row id as originalROWID, never a local id.
    final fromEvent = Message.fromMap({'guid': 'm1', 'originalROWID': 9001, 'dateCreated': stored.dateCreated!.millisecondsSinceEpoch});
    expect(fromEvent.id, isNull);
    expect(latestMessageToStore(fromEvent, (guid) => guid == 'm1' ? stored : null)?.id, 42);
  });

  test('a stored message is kept as is', () {
    expect(latestMessageToStore(stored, (_) => null), same(stored));
  });

  test('a message this phone has not stored yet is not stored as latest', () {
    expect(latestMessageToStore(Message(guid: 'm2', dateCreated: DateTime(2026)), (_) => null), isNull);
  });
}
