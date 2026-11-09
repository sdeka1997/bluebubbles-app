import 'dart:io';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/db_change_events.dart';
import 'package:bluebubbles/database/sqlite/storage_state.dart';
import 'package:bluebubbles/services/backend/sync/sync_marker.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';

// Switch plan commit 9, part 1: each isolate opens the store the startup plan
// selects. On SQLite that is the isolate's own connection to bluebubbles.db,
// and its committed writes reach the main isolate's DbChangeEvents.

StoragePlan sqliteWhenReady(StorageState s) => switch (s) {
      StorageState.ready => (store: ActiveStore.sqlite, step: CopyStep.none, waitForCopy: false),
      StorageState.failed => (store: ActiveStore.objectBox, step: CopyStep.none, waitForCopy: false),
      _ => (store: ActiveStore.sqlite, step: CopyStep.copy, waitForCopy: true),
    };

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late StorageFiles files;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('bb_select_');
    files = StorageFiles(dir);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('with ObjectBox selected in every state, no file is read or opened', () async {
    var reads = 0;
    final store = await openSelectedStore(read: () async {
      reads++;
      return StorageState.ready;
    }, onMain: true, files: files);
    expect(store.kind, ActiveStore.objectBox);
    expect(reads, 0);
    expect(files.ready.existsSync(), isFalse);
  });

  test('a ready file under a SQLite plan: its own connection; its writes reach DbChangeEvents on main', () async {
    final seed = Db.file(files.ready);
    await seed.select('SELECT 1');
    await seed.close();

    final store = await openSelectedStore(
        read: () async => StorageState.ready, onMain: true, files: files, decide: sqliteWhenReady);
    expect(store.kind, ActiveStore.sqlite);
    final changed = DbChangeEvents.main.on('handles').first;
    final id = await store.saveHandle(Handle(address: 'a@example.com', service: 'iMessage'),
        updateColor: false, matchOnOriginalROWID: false);
    expect(await changed.timeout(const Duration(seconds: 5)), contains(id));
    await closeSelectedStore();
  });

  test('while the copy is still running, a worker isolate opens nothing: ObjectBox stand-in', () async {
    final store = await openSelectedStore(
        read: () async => StorageState.partial, onMain: false, files: files, decide: sqliteWhenReady);
    expect(store.kind, ActiveStore.objectBox);
    expect(files.ready.existsSync(), isFalse);
  });

  test('a failed copy stays on ObjectBox even under a SQLite plan', () async {
    final store = await openSelectedStore(
        read: () async => StorageState.failed, onMain: true, files: files, decide: sqliteWhenReady);
    expect(store.kind, ActiveStore.objectBox);
  });

  test('deleteAll removes both SQLite files and their -wal/-shm/-journal', () {
    for (final f in [files.ready, files.partial]) {
      for (final suffix in ['', '-wal', '-shm', '-journal']) {
        File('${f.path}$suffix').writeAsStringSync('x');
      }
    }
    files.deleteAll();
    expect(dir.listSync().where((e) => e.path.contains('bluebubbles.db')), isEmpty);
  });

  group('wiring', () {
    final database = File('lib/database/database.dart').readAsStringSync();
    final init = database.substring(database.indexOf('static Future<void> init()'),
        database.indexOf('static Future<void> waitForInit()'));

    test('Database.init selects the store after the startup plan, on every isolate', () {
      expect(init, contains('openSelectedStore('));
      expect(init, contains('MessagingStore.select('));
      expect(init.indexOf('openSelectedStore('), greaterThan(init.indexOf('StorageStartup.start()')));
    });

    test('an unfinished setup clears the SQLite files along with the ObjectBox boxes', () {
      final reset = init.substring(init.indexOf('if (!setupFinished && !isIsolate)'));
      expect(reset.substring(0, reset.indexOf('} catch')), contains('.deleteAll()'));
    });
  });
}
