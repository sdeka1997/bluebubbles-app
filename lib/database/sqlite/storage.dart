import 'dart:async';
import 'dart:io';

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
  final db = Db.file(File(join(directory.path, storageFileName)));
  _open = (db: db, changes: onMain ? DbChangeEvents.main.attachLocal(db) : DbChangeEvents.postFrom(db));
  return MessagingStore(db);
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
