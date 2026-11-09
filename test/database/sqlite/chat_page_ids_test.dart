// The chat list loads in pages of ids (ChatActions.getChatsAsync ->
// chatPageIds); the main isolate then reads those chats with their relations.
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sqlite_seed.dart';

void main() {
  late Db db;
  late MessagingStore store;

  setUp(() async {
    db = Db.memory();
    store = MessagingStore.forStore(ActiveStore.sqlite, db: db);
    final seed = Seed();
    for (var h = 1; h <= 3; h++) {
      seed.handle(h, address: 'h$h@x.com', contacts: [h]);
      seed.contact(h, 'Contact $h');
    }
    for (var id = 1; id <= 250; id++) {
      // Every fifth chat has no messages yet (listed last); one is deleted.
      seed.chat(id,
          latestMs: id % 5 == 0 ? null : baseMs + (id * 7919) % 1000 * 1000,
          deleted: id == 42,
          handles: [1 + id % 3]);
    }
    await seed.into(db);
  });
  tearDown(() => db.close());

  test('pages of chat ids follow the chat list order, with no gap or repeat', () async {
    final listed = [for (final c in await ChatRepo(db).listPage(limit: 1000)) c.id!];
    final paged = <int>[];
    for (var offset = 0; offset < 300; offset += 100) {
      paged.addAll(await store.chatPageIds(limit: 100, offset: offset, ids: const []));
    }
    expect(paged, listed);
    expect(paged, hasLength(249));
    expect(paged, isNot(contains(42)));
    expect(paged.skip(199), everyElement(predicate<int>((id) => id % 5 == 0)), reason: 'chats with no messages last');
  });

  test('a page of chat ids is one query that reads no relations', () async {
    final statements = await db.recordStatements(() => store.chatPageIds(limit: 100, offset: 200, ids: const []));
    expect(statements.map((s) => s.$1), hasLength(1));
    expect(statements.single.$1, isNot(matches(RegExp('chat_handles|contact|messages|SELECT \\*'))));
  });
}
