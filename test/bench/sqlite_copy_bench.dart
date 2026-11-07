// Phone-sized ObjectBox -> SQLite copy bench. Not part of `flutter test` (no _test
// suffix); run explicitly: flutter test test/bench/sqlite_copy_bench.dart
// Env BB_BENCH_MESSAGES (default 450000). Writes to the system temp dir and
// deletes it afterwards. Needs the ObjectBox C library (lib/libobjectbox.dylib).
import 'dart:io';
import 'dart:math';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/sqlite_copy_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phone-sized copy check', () async {
    final total = int.tryParse(Platform.environment['BB_BENCH_MESSAGES'] ?? '') ?? 450000;
    final directory = Directory.systemTemp.createTempSync('bb_copy_bench_');
    final store = Store(getObjectBoxModel(), directory: '${directory.path}/objectbox', maxDBSizeInKB: 8 * 1024 * 1024);
    try {
      final random = Random(7);
      final clock = Stopwatch()..start();
      final handles = List.generate(900, (i) => Handle(address: '+1555${i.toString().padLeft(7, '0')}', originalROWID: i + 1));
      store.box<Handle>().putMany(handles);
      final contacts = List.generate(600, (i) => ContactV2(displayName: 'Contact $i', nativeContactId: 'n$i')..handles.add(handles[i]));
      store.box<ContactV2>().putMany(contacts);
      final chats = List.generate(1775, (i) {
        final chat = Chat(guid: 'iMessage;-;chat$i', chatIdentifier: 'chat$i', isArchived: i % 9 == 0 ? null : false);
        chat.handles.add(handles[i % handles.length]);
        if (i % 50 == 0) chat.handles.add(handles[(i + 1) % handles.length]);
        return chat;
      });
      store.box<Chat>().putMany(chats);
      final group = CustomGroup(name: 'Family')..chats.addAll(chats.take(5));
      store.box<CustomGroup>().put(group);

      // One 75k-message chat, the rest spread; 15% reactions; old history saved last.
      final latest = <int, Message>{};
      final base = 1500000000000;
      var made = 0;
      final lateHistory = min(8000, total ~/ 50);
      while (made < total) {
        final batch = <Message>[];
        final attachments = <Attachment>[];
        for (var i = 0; i < 5000 && made < total; i++, made++) {
          final isLate = made >= total - lateHistory;
          final chat = made % 6 == 0 ? chats[0] : chats[random.nextInt(chats.length)];
          final created = isLate ? base - (total - made) * 60000 : base + made * 60000;
          final m = Message(
            guid: 'bench-$made',
            text: 'message body $made ${'x' * random.nextInt(120)}',
            dateCreated: DateTime.fromMillisecondsSinceEpoch(created),
            dateDelivered: made % 30 == 0 ? DateTime.fromMillisecondsSinceEpoch(created - 2000) : null,
            isFromMe: made.isEven,
            associatedMessageGuid: made % 7 == 0 && made > 0 ? 'bench-${made - 1}' : null,
            associatedMessageType: made % 7 == 0 && made > 0 ? 'love' : null,
            hasAttachments: made % 15 == 0,
            metadata: made % 40 == 0 ? {'k': made} : null,
          );
          m.chat.target = chat;
          m.handleRelation.target = handles[made % handles.length];
          batch.add(m);
          if (!isLate) latest[chat.id!] = m;
        }
        store.box<Message>().putMany(batch);
        for (final m in batch.where((m) => m.hasAttachments)) {
          attachments.add(Attachment(guid: 'att-${m.guid}', mimeType: 'image/jpeg', totalBytes: 1000)..message.target = m);
        }
        store.box<Attachment>().putMany(attachments);
      }
      for (final chat in chats) {
        final m = latest[chat.id];
        if (m == null) continue;
        chat.dbLatestMessage.target = m;
        chat.dbOnlyLatestMessageDate = m.dateCreated;
      }
      store.box<Chat>().putMany(chats);
      final obxMb = File('${directory.path}/objectbox/data.mdb').lengthSync() / (1024 * 1024);
      // ignore: avoid_print
      print('BENCH seeded messages=$total in ${clock.elapsedMilliseconds}ms objectboxMb=${obxMb.toStringAsFixed(1)}');

      final lines = <String>[];
      void log(String line) {
        lines.add(line);
        // ignore: avoid_print
        print(line);
      }

      final file = File('${directory.path}/bluebubbles.db');
      final ok = await runSqliteCopyCheck(store: store, file: file, log: log);
      expect(ok, isTrue);

      // A later launch with 50 new messages: the cheap top-up.
      store.box<Message>().putMany(List.generate(
          50, (i) => Message(guid: 'later-$i', dateCreated: DateTime.now())..chat.target = chats[1]));
      expect(await runSqliteCopyCheck(store: store, file: file, log: log), isTrue);
    } finally {
      store.close();
      directory.deleteSync(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}
