// MessageOriginRepair: messages an older build moved into a thread without
// recording their Apple chat get it from the server once, and the database
// files them; a failed run stays pending.
import 'package:bluebubbles/database/sqlite/app_database.dart' show originRepairPending;
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/sync_batch_writer.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/services/backend/sync/message_origin_repair.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../database/sqlite/sqlite_seed.dart';
import '../../../database/sqlite/sync_batch_test.dart' show chatMap, msgMap, person;

void main() {
  late Db db;
  late List<String> asked;

  final ana = person('ana@example.com', rowId: 7);
  final imessage = chatMap('iMessage;-;ana@example.com', [ana]);
  final sms = chatMap('SMS;-;ana@example.com', [ana]);
  final other = chatMap('iMessage;-;bo@example.com', [person('bo@example.com', rowId: 8)]);

  // What the server holds: each message in the Apple chat it came through.
  const server = {
    'iMessage;-;ana@example.com': ['i1'],
    'SMS;-;ana@example.com': ['s1', 's2'],
  };

  Future<List<String>> fromServer(String chat, int offset, int limit) async {
    asked.add(chat);
    final all = server[chat] ?? const <String>[];
    return all.skip(offset).take(limit).toList();
  }

  setUpAll(() {
    if (!GetIt.I.isRegistered<BaseLogger>()) GetIt.I.registerSingleton<BaseLogger>(BaseLogger());
  });

  setUp(() async {
    db = Db.memory();
    MessagingStore.use(MessagingStore(db));
    asked = [];
    await SqliteSyncBatch.bulkSyncData(db, {
      'messagesData': [
        msgMap('i1', baseMs + 1000, chat: imessage, from: ana),
        msgMap('s1', baseMs + 2000, chat: sms, from: ana),
        msgMap('s2', baseMs + 3000, chat: sms, from: ana),
        msgMap('o1', baseMs + 4000, chat: other),
      ],
    });
    // What a pre-K15 build left: the SMS copy's messages were moved into the
    // iMessage copy and the v6 upgrade assumed that was their Apple chat.
    await db.write((tx) => tx.execute(
        "UPDATE messages SET apple_chat_guid = 'iMessage;-;ana@example.com' WHERE guid IN ('s1', 's2')"));
    await db.write((tx) => tx.execute(originRepairPending));
  });
  tearDown(() async {
    MessagingStore.use(null);
    await db.close();
  });

  Future<String?> appleChat(String guid) async =>
      (await db.select('SELECT apple_chat_guid FROM messages WHERE guid = ?', [guid])).single['apple_chat_guid'] as String?;

  Future<int?> filedUnder(String guid) async =>
      (await db.select('SELECT chat_id FROM messages WHERE guid = ?', [guid])).single['chat_id'] as int?;

  Future<int> idOf(String guid) async =>
      (await db.select('SELECT id FROM chats WHERE guid = ?', [guid])).single['id'] as int;

  test('records the real Apple chat of every message in a multi-copy thread, once', () async {
    await MessageOriginRepair.run(fetch: fromServer);
    expect(await appleChat('s1'), 'SMS;-;ana@example.com');
    expect(await appleChat('s2'), 'SMS;-;ana@example.com');
    expect(await appleChat('i1'), 'iMessage;-;ana@example.com');
    expect(asked.toSet(), {'iMessage;-;ana@example.com', 'SMS;-;ana@example.com'},
        reason: 'only chats in a thread with copies are asked about');

    asked.clear();
    await MessageOriginRepair.run(fetch: fromServer);
    expect(asked, isEmpty, reason: 'the repair runs once');
  });

  test('after the repair, a copy that leaves the thread takes its messages back', () async {
    await MessageOriginRepair.run(fetch: fromServer);
    final smsId = await idOf(sms['guid']);
    await db.write((tx) async {
      await tx.execute('DELETE FROM chat_handles WHERE chat_id = ?', [smsId]);
      await tx.execute("UPDATE chats SET chat_identifier = 'someone-else' WHERE id = ?", [smsId]);
    });
    expect(await filedUnder('s1'), smsId);
    expect(await filedUnder('s2'), smsId);
    expect(await filedUnder('i1'), await idOf(imessage['guid']));
  });

  test('a server failure leaves the repair pending for the next sync', () async {
    await MessageOriginRepair.run(fetch: (_, __, ___) async => throw StateError('offline'));
    expect(await appleChat('s1'), 'iMessage;-;ana@example.com');
    expect(await MessagingStore.current.chatsAwaitingOriginRepair(), isNotEmpty);

    await MessageOriginRepair.run(fetch: fromServer);
    expect(await appleChat('s1'), 'SMS;-;ana@example.com');
    expect(await MessagingStore.current.chatsAwaitingOriginRepair(), isEmpty);
  });

  test('pages through a chat with more messages than one page', () async {
    final many = [for (var i = 0; i < MessageOriginRepair.pageSize + 5; i++) 's1'];
    final pages = <int>[];
    await MessageOriginRepair.run(fetch: (chat, offset, limit) async {
      if (chat == 'SMS;-;ana@example.com') pages.add(offset);
      return chat == 'SMS;-;ana@example.com' ? many.skip(offset).take(limit).toList() : const [];
    });
    expect(pages, [0, MessageOriginRepair.pageSize]);
  });

  test('a database with no pending repair asks the server nothing', () async {
    await MessagingStore.current.finishOriginRepair();
    await MessageOriginRepair.run(fetch: fromServer);
    expect(asked, isEmpty);
  });
}
