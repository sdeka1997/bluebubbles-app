// MessageOriginRepair: messages an older build moved into a thread without
// recording their Apple chat get it from the server once, and the database
// files them. Only the smaller copies are downloaded, and a run cut short
// resumes with the threads it had not done.
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/app_database.dart' show originRepairPending;
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
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
  late List<String> paged;

  final ana = person('ana@example.com', rowId: 7);
  final bo = person('bo@example.com', rowId: 8);
  final imessage = chatMap('iMessage;-;ana@example.com', [ana]);
  final sms = chatMap('SMS;-;ana@example.com', [ana]);
  final boIMessage = chatMap('iMessage;-;bo@example.com', [bo]);
  final boSms = chatMap('SMS;-;bo@example.com', [bo]);
  final other = chatMap('iMessage;-;cy@example.com', [person('cy@example.com', rowId: 9)]);

  // What the server holds: each message in the Apple chat it came through.
  // Fresh for every test; tests change it.
  late Map<String, List<String>> server;
  Map<String, List<String>> serverAtStart() => {
    'iMessage;-;ana@example.com': ['i1', 'i2', 'i3'],
    'SMS;-;ana@example.com': ['s1', 's2'],
    'iMessage;-;bo@example.com': ['b1', 'b2'],
    'SMS;-;bo@example.com': ['bs1'],
    'iMessage;-;cy@example.com': ['o1'],
  };

  Future<List<String>> fromServer(String chat, int offset, int limit) async {
    paged.add(chat);
    return (server[chat] ?? const <String>[]).skip(offset).take(limit).toList();
  }

  Future<int> totalOf(String chat) async => server[chat]?.length ?? 0;

  setUpAll(() {
    if (!GetIt.I.isRegistered<BaseLogger>()) GetIt.I.registerSingleton<BaseLogger>(BaseLogger());
  });

  setUp(() async {
    db = Db.memory();
    MessagingStore.use(MessagingStore(db));
    paged = [];
    server = serverAtStart();
    await SqliteSyncBatch.bulkSyncData(db, {
      'messagesData': [
        msgMap('i1', baseMs + 1000, chat: imessage, from: ana),
        msgMap('s1', baseMs + 2000, chat: sms, from: ana),
        msgMap('s2', baseMs + 3000, chat: sms, from: ana),
        msgMap('i2', baseMs + 4000, chat: imessage, from: ana),
        msgMap('i3', baseMs + 5000, chat: imessage, from: ana),
        msgMap('b1', baseMs + 6000, chat: boIMessage, from: bo),
        msgMap('bs1', baseMs + 7000, chat: boSms, from: bo),
        msgMap('b2', baseMs + 8000, chat: boIMessage, from: bo),
        msgMap('o1', baseMs + 9000, chat: other),
      ],
    });
    // What a pre-K15 build left: every message of a thread was moved into its
    // shown chat, and the v6 upgrade assumed that was its Apple chat.
    await db.write((tx) async {
      for (final thread in [
        ['iMessage;-;ana@example.com', 'SMS;-;ana@example.com'],
        ['iMessage;-;bo@example.com', 'SMS;-;bo@example.com'],
      ]) {
        final shown = (await tx.select(
          'SELECT guid FROM chats WHERE guid IN (?, ?) ORDER BY id LIMIT 1',
          thread,
        ))
            .single['guid'];
        await tx.execute(
          'UPDATE messages SET apple_chat_guid = ? WHERE apple_chat_guid IN (?, ?)',
          [shown, ...thread],
        );
      }
    });
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

  Future<void> expectRealOrigins() async {
    for (final MapEntry(key: chat, value: guids) in server.entries) {
      for (final guid in guids) {
        expect(await appleChat(guid), chat, reason: guid);
      }
    }
  }

  test('records the real Apple chat of every message, downloading only the smaller copies', () async {
    await MessageOriginRepair.run(fetch: fromServer, total: totalOf);
    await expectRealOrigins();
    expect(paged.toSet(), {'SMS;-;ana@example.com', 'SMS;-;bo@example.com'},
        reason: 'the biggest copy of each thread and unthreaded chats are never paged');
    expect(await MessagingStore.current.threadsAwaitingOriginRepair(), isNull);

    paged.clear();
    await MessageOriginRepair.run(fetch: fromServer, total: totalOf);
    expect(paged, isEmpty, reason: 'the repair runs once');
  });

  test('the biggest copy need not be the shown one', () async {
    // Ana's SMS copy is the big one on the server.
    server['SMS;-;ana@example.com'] = ['s1', 's2', 'x1', 'x2', 'x3'];
    await MessageOriginRepair.run(fetch: fromServer, total: totalOf);
    expect(paged, contains('iMessage;-;ana@example.com'));
    expect(paged, isNot(contains('SMS;-;ana@example.com')));
    for (final guid in ['i1', 'i2', 'i3']) {
      expect(await appleChat(guid), 'iMessage;-;ana@example.com', reason: guid);
    }
    expect(await appleChat('s1'), 'SMS;-;ana@example.com');
    expect(await appleChat('s2'), 'SMS;-;ana@example.com');
  });

  test('after the repair, a copy that leaves the thread takes its messages back', () async {
    await MessageOriginRepair.run(fetch: fromServer, total: totalOf);
    final smsId = await idOf(sms['guid']);
    await db.write((tx) async {
      await tx.execute('DELETE FROM chat_handles WHERE chat_id = ?', [smsId]);
      await tx.execute("UPDATE chats SET chat_identifier = 'someone-else' WHERE id = ?", [smsId]);
    });
    expect(await filedUnder('s1'), smsId);
    expect(await filedUnder('s2'), smsId);
    expect(await filedUnder('i1'), await idOf(imessage['guid']));
  });

  test('a run cut short keeps finished threads and resumes with the rest', () async {
    var failBo = true;
    await MessageOriginRepair.run(
      fetch: (chat, offset, limit) async {
        if (failBo && chat.contains('bo@')) throw StateError('offline');
        return fromServer(chat, offset, limit);
      },
      total: totalOf,
    );
    expect(await appleChat('s1'), 'SMS;-;ana@example.com', reason: "Ana's thread finished before the failure");
    expect(await appleChat('bs1'), 'iMessage;-;bo@example.com', reason: "Bo's thread is still pending");
    final pending = await MessagingStore.current.threadsAwaitingOriginRepair();
    expect([for (final t in pending!) t.copies.toSet()], [
      {'iMessage;-;bo@example.com', 'SMS;-;bo@example.com'},
    ]);

    failBo = false;
    paged.clear();
    await MessageOriginRepair.run(fetch: fromServer, total: totalOf);
    expect(paged, ['SMS;-;bo@example.com'], reason: "Ana's thread is not asked about again");
    await expectRealOrigins();
    expect(await MessagingStore.current.threadsAwaitingOriginRepair(), isNull);
  });

  test('a server that does not report a total leaves the thread pending', () async {
    await MessageOriginRepair.run(
      fetch: fromServer,
      total: (_) async => throw StateError('The server did not report how many messages'),
    );
    expect(await appleChat('s1'), 'iMessage;-;ana@example.com');
    expect(await MessagingStore.current.threadsAwaitingOriginRepair(), hasLength(2));
  });

  test('pages through a copy with more messages than one page', () async {
    server['SMS;-;ana@example.com'] = [for (var i = 0; i < MessageOriginRepair.pageSize + 5; i++) 's1'];
    server['iMessage;-;ana@example.com'] = [for (var i = 0; i < MessageOriginRepair.pageSize * 2; i++) 'i1'];
    final pages = <int>[];
    await MessageOriginRepair.run(
      fetch: (chat, offset, limit) async {
        if (chat == 'SMS;-;ana@example.com') pages.add(offset);
        return fromServer(chat, offset, limit);
      },
      total: totalOf,
    );
    expect(pages, [0, MessageOriginRepair.pageSize]);
  });

  test('a message that arrives while the copies are downloaded keeps its chat', () async {
    server['SMS;-;ana@example.com'] = ['s1', 's2', 'x1', 'x2', 'x3'];
    await MessageOriginRepair.run(
      fetch: (chat, offset, limit) async {
        if (chat == 'iMessage;-;ana@example.com' && offset == 0) {
          final m = Message(guid: 'new', dateCreated: DateTime.now().add(const Duration(seconds: 1)), isFromMe: true);
          m.chat.targetId = await idOf(imessage['guid']);
          await db.write((tx) => tx.insert('messages', messageToRow(m)..['id'] = null));
        }
        return fromServer(chat, offset, limit);
      },
      total: totalOf,
    );
    expect(await appleChat('new'), 'iMessage;-;ana@example.com');
  });

  test('a message still sending is not given an origin', () async {
    await db.write((tx) => tx.execute(
        "UPDATE messages SET guid = 'temp-abc' WHERE guid = 'i3'"));
    server['SMS;-;ana@example.com'] = ['s1', 's2', 'x1', 'x2', 'x3'];
    await MessageOriginRepair.run(fetch: fromServer, total: totalOf);
    expect(await appleChat('temp-abc'), 'iMessage;-;ana@example.com');
  });

  test('a database with no pending repair asks the server nothing', () async {
    await MessagingStore.current.finishOriginRepair();
    var counted = 0;
    await MessageOriginRepair.run(fetch: fromServer, total: (c) async {
      counted++;
      return totalOf(c);
    });
    expect(paged, isEmpty);
    expect(counted, 0);
  });
}
