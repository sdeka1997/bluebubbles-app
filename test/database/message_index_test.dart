import 'package:bluebubbles/database/sqlite/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reactions are looked up by an indexed column', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final rows = await database.customSelect("SELECT sql FROM sqlite_master WHERE type = 'index' AND name = 'messages_assoc'").get();
    expect(rows.single.data['sql'], contains('associated_message_guid'),
        reason: 'without it every reaction lookup reads every message on the phone');
  });
}
