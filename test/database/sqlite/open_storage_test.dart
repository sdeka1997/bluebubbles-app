// Startup with SQLite as the only store (stage S5): open bluebubbles.db, or
// create it empty, and never read, copy or change the old objectbox/ folder,
// which stays on disk for a rollback to a pre-SQLite build.
import 'dart:io';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/storage.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../store/store_fixture.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late File objectBoxData;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('bb_open_');
    objectBoxData = File(p.join(dir.path, 'objectbox', 'data.mdb'))
      ..createSync(recursive: true)
      ..writeAsStringSync('old store');
  });

  tearDown(() async {
    await closeStorage();
    dir.deleteSync(recursive: true);
  });

  void expectObjectBoxUntouched() {
    expect(objectBoxData.readAsStringSync(), 'old store');
    expect(Directory(p.join(dir.path, 'objectbox')).listSync().map((e) => p.basename(e.path)), ['data.mdb']);
  }

  test('no file: an empty bluebubbles.db is created and opened', () async {
    final store = await openStorage(dir, onMain: true);
    expect(await store.allChats(), isEmpty);
    expect(await store.allMessageIds(), isEmpty);
    expect(File(p.join(dir.path, 'bluebubbles.db')).existsSync(), isTrue, reason: 'created by the first read');
    expectObjectBoxUntouched();
  });

  test('an existing file is opened as it is, with no copy', () async {
    final first = await openStorage(dir, onMain: true);
    final id = await first.saveHandle(Handle(address: 'ana@example.com', service: 'iMessage'),
        updateColor: false, matchOnOriginalROWID: false);
    await closeStorage();

    final again = await openStorage(dir, onMain: true);
    expect((await again.handleById(id!))?.address, 'ana@example.com');
    expect(dir.listSync().map((e) => p.basename(e.path)).where((n) => n.contains('partial') || n.contains('lock')),
        isEmpty);
    expectObjectBoxUntouched();
  });

  group('clearing messaging data', () {
    storeTests((fixture) {
      test('empties chats, messages, attachments, handles, contacts and groups; keeps themes', () async {
        final ana = await fixture().handle('ana@example.com');
        final chat = await fixture().chat('iMessage;-;ana@example.com', handles: [ana]);
        final m = await fixture().message('m1', chat, t0, from: ana);
        await fixture().attachment('a1', m);
        await fixture().contact('n1', 'Ana', handles: [ana]);
        await fixture().store.createCustomGroup('Friends', {chat.guid});
        await fixture().db.write((tx) => tx.execute(
            "INSERT INTO themes (name, gradient_bg, google_font, data_json) VALUES ('Mine', 0, 'Default', '{}')"));

        await fixture().store.clearMessagingData();

        final s = fixture().store;
        expect(await s.allChats(), isEmpty);
        expect(await s.allMessageIds(), isEmpty);
        expect(await s.findAttachmentIds(null), isEmpty);
        expect(await s.allHandleIds(), isEmpty);
        expect(await s.allContactIds(), isEmpty);
        expect(await s.customGroupIds(), isEmpty);
        expect(await fixture().db.select('SELECT COUNT(*) AS n FROM messages_fts'), [
          {'n': 0}
        ]);
        expect(await fixture().db.select('SELECT name FROM themes'), [
          {'name': 'Mine'}
        ]);
      });
    });
  });
}
