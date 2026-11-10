import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:drift/native.dart' show SqliteException;

/// What the SQLite parts of the store share.
abstract interface class SqliteStorePart {
  Db get db;
}

/// A UNIQUE constraint failed.
bool isUniqueViolation(Object e) => e is SqliteException && e.extendedResultCode == 2067;

/// [items] in the order of [ids], skipping ids with no item.
List<T> inIdOrder<T>(List<int> ids, Map<int, T> items) => [for (final id in ids) ?items[id]];
