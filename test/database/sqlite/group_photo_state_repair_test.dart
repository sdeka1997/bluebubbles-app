import 'dart:io';

import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sqlite_seed.dart';

void main() {
  test('offline open repairs silent photo pointers, ordering, previews, and only provably stale unread', () async {
    final directory = await Directory.systemTemp.createTemp('bb_photo_state_repair_');
    addTearDown(() async {
      await closeStorage();
      await directory.delete(recursive: true);
    });
    final file = File('${directory.path}/bluebubbles.db');
    final seedDb = Db.file(file);
    await (Seed()
          ..chat(1, latestMessageId: 12, latestMs: baseMs + 9000, unread: true)
          ..message(11, 1, baseMs + 1000, guid: 'one-visible-read', isFromMe: false, readMs: baseMs + 1500)
          ..message(12, 1, baseMs + 9000, guid: 'one-state', itemType: 3, groupActionType: 3)
          ..chat(2, latestMessageId: 22, latestMs: baseMs + 8000)
          ..message(21, 2, baseMs + 2000, guid: 'two-visible', isFromMe: true)
          ..message(22, 2, baseMs + 8000, guid: 'two-state', itemType: 3, groupActionType: 3)
          ..chat(3, latestMessageId: 32, latestMs: baseMs + 7000, unread: true)
          ..message(31, 3, baseMs + 3000, guid: 'three-unread', isFromMe: false)
          ..message(32, 3, baseMs + 7000, guid: 'three-state', itemType: 3, groupActionType: 3))
        .into(seedDb);
    await seedDb.close();

    final store = await openStorage(directory, onMain: true);
    final page = await ChatRepo(store.db).listPage();

    expect(page.map((chat) => chat.id), [3, 2, 1]);
    expect(page.map((chat) => chat.latestMessage?.guid), ['three-unread', 'two-visible', 'one-visible-read']);
    expect(page.map((chat) => chat.dbOnlyLatestMessageDate?.millisecondsSinceEpoch), [
      baseMs + 3000,
      baseMs + 2000,
      baseMs + 1000,
    ]);
    expect(
      page.singleWhere((chat) => chat.id == 1).hasUnreadMessage,
      isFalse,
      reason: 'no visible incoming unread message exists',
    );
    expect(
      page.singleWhere((chat) => chat.id == 3).hasUnreadMessage,
      isTrue,
      reason: 'a genuine visible incoming unread message must be preserved',
    );

    final reopened = await openStorage(directory, onMain: true);
    final reopenedPage = await ChatRepo(reopened.db).listPage();
    expect(reopenedPage.map((chat) => chat.id), [3, 2, 1], reason: 'the repair is idempotent');
    expect(reopenedPage.map((chat) => chat.latestMessage?.guid), ['three-unread', 'two-visible', 'one-visible-read']);
  });
}
