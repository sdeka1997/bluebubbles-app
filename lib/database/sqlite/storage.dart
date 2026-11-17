import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/db_change_events.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:path/path.dart';

/// The app's database file in the app's documents directory.
const storageFileName = 'bluebubbles.db';

({Db db, StreamSubscription<DbChanges> changes})? _open;

/// Opens this isolate's connection to `bluebubbles.db` in [directory],
/// creating an empty file when there is none. Committed writes reach the main
/// isolate's [DbChangeEvents]: directly on main, as `dbChanged` events from a
/// spawned isolate.
///
/// The `objectbox/` folder of builds before SQLite is never read or changed:
/// it stays as it was for a rollback to one of them.
Future<MessagingStore> openStorage(Directory directory, {required bool onMain}) async {
  await closeStorage();
  final path = join(directory.path, storageFileName);
  if (onMain) await Isolate.run(() => _migrate(path));
  final db = Db.file(File(path));
  _open = (db: db, changes: onMain ? DbChangeEvents.main.attachLocal(db) : DbChangeEvents.postFrom(db));
  return MessagingStore(db);
}

/// Opens [path] once off the main isolate, so a schema upgrade and the
/// compaction after it (seconds on a full phone) never hold up a frame, and
/// before any other isolate opens the file.
Future<void> _migrate(String path) async {
  final db = Db.file(File(path));
  try {
    await db.select('PRAGMA user_version');
    await db.vacuumIfPending();
  } finally {
    await db.close();
  }
}

Future<void> closeStorage() async {
  final open = _open;
  _open = null;
  if (open == null) return;
  await open.changes.cancel();
  await open.db.close();
}

/// Deletes `bluebubbles.db` and its WAL files in [directory] (an unfinished
/// setup starts from nothing). Call before [openStorage].
void deleteStorageFiles(Directory directory) {
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final file = File(join(directory.path, '$storageFileName$suffix'));
    if (file.existsSync()) file.deleteSync();
  }
}
