import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_attachment_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_chat_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_contact_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_custom_group_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_handle_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_message_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_send_target_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_storage_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_sync_store.dart';
import 'package:drift/native.dart' show SqliteException;

/// [MessagingStore] on SQLite: the repositories of lib/database/sqlite. Each
/// write is one [Db.write] holding exactly what one ObjectBox write
/// transaction held, with nothing but database calls inside it.
class SqliteMessagingStore extends MessagingStore
    with
        SqliteContactStore,
        SqliteStorageStore,
        SqliteSendTargetStore,
        SqliteHandleStore,
        SqliteCustomGroupStore,
        SqliteMessageStore,
        SqliteAttachmentStore,
        SqliteSyncStore,
        SqliteChatStore {
  SqliteMessagingStore(this.db);

  @override
  final Db db;

  @override
  ActiveStore get kind => ActiveStore.sqlite;
}

/// What the SQLite parts of the store share.
abstract interface class SqliteStorePart {
  Db get db;
}

/// A UNIQUE constraint failed: ObjectBox's UniqueViolationException.
bool isUniqueViolation(Object e) => e is SqliteException && e.extendedResultCode == 2067;

/// [items] in the order of [ids], skipping ids with no item.
List<T> inIdOrder<T>(List<int> ids, Map<int, T> items) => [for (final id in ids) ?items[id]];
