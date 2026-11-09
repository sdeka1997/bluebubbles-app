// Switch plan commit 9: a startup from "no file" to the first chat page, on
// the store Android selects. The copy is made, judged current, opened as this
// isolate's SQLite store, and the chat list and a chat's newest page read from
// it hold what ObjectBox held (participants, attachments, reactions).
import 'dart:io';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/storage_state.dart';
import 'package:bluebubbles/services/backend/sync/sync_marker.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';

import 'objectbox_sqlite_copy_test.dart' show Fixture;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory obDir;
  late Directory appDir;
  late Fixture fixture;
  late StorageFiles files;

  setUp(() {
    obDir = Directory.systemTemp.createTempSync('bb_cold_ob_');
    appDir = Directory.systemTemp.createTempSync('bb_cold_app_');
    fixture = Fixture(obDir)..seed();
    files = StorageFiles(appDir);
  });

  tearDown(() async {
    await closeSelectedStore();
    fixture.close();
    obDir.deleteSync(recursive: true);
    appDir.deleteSync(recursive: true);
  });

  test('no file: copy, then SQLite serves the chat list and the first chat page', () async {
    const marker = '1700000000000:4000';
    final current = CopyFingerprint(objectBoxMarker: marker, store: fixture.store, install: 'install-1');
    expect((await inspectStorage(files, current: current)).state, StorageState.noFile);
    expect(decideStorage(StorageState.noFile).waitForCopy, isTrue);

    final progress = <double>[];
    expect(
        await runStorageStartup(
            store: fixture.store,
            files: files,
            log: (_) {},
            objectBoxMarker: marker,
            install: 'install-1',
            onProgress: progress.add),
        StorageState.ready);
    expect(progress.last, 1.0);
    expect((await inspectStorage(files, current: current)).state, StorageState.ready);

    final store = await openSelectedStore(
        read: () async => (await inspectStorage(files, current: current)).state,
        onMain: true,
        files: files,
        decide: decideStorage);
    expect(store.kind, ActiveStore.sqlite);

    final chats = await store.allChats();
    expect(chats.map((c) => c.guid), containsAll([fixture.alice.guid, fixture.group.guid]));
    final group = chats.singleWhere((c) => c.guid == fixture.group.guid);
    expect(group.handles.map((h) => h.address), unorderedEquals([fixture.aliceHandle.address, fixture.bobHandle.address]));
    final alice = chats.singleWhere((c) => c.guid == fixture.alice.guid);
    expect(alice.handles.single.contactsV2.single.displayName, 'Alice');

    final page = await store.olderMessagePage(alice.id!, alice.handles.toList(), loadedRows: 0, limit: 25);
    final shown = await store.messagesByIds(page.ids);
    final expected = fixture.store
        .box<Message>()
        .getAll()
        .where((m) =>
            m.chat.targetId == alice.id && m.dateDeleted == null && m.associatedMessageGuid == null && m.dateCreated != null)
        .toList()
      ..sort((a, b) => b.dateCreated!.compareTo(a.dateCreated!));
    expect(shown.map((m) => m.guid), expected.take(25).map((m) => m.guid));
    expect(shown.where((m) => m.handleRelation.targetId != 0).every((m) => m.handleRelation.target != null), isTrue,
        reason: 'every sender arrives with its message');

    // The reaction on m2 arrives with its target, as the chat list preview needs.
    final reaction = await store.messageByGuid('r1');
    expect(reaction!.reactionTarget?.guid, 'm2');
  });
}
