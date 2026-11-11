# Database Rules — SQLite (drift + raw SQL)

The app's data lives in one SQLite file, `bluebubbles.db`, opened by
`lib/database/sqlite/storage.dart`. Every isolate has its own connection (`Db`).

## Layers

| Layer | Where | Role |
|-------|-------|------|
| Schema | `lib/database/sqlite/app_database.dart` | drift tables, indexes, the FTS index, `schemaVersion` + `onUpgrade` |
| Connection | `lib/database/sqlite/db.dart` | `Db.read` / `Db.snapshot` / `Db.write`; change events for the main isolate |
| Repositories | `lib/database/sqlite/*_repo.dart` | SQL per table group; return entities with relations filled (`RelationFill`) |
| Row mapping | `lib/database/sqlite/sqlite_row_mappers.dart` | entity ⇄ row; the only place that knows column names |
| Store | `lib/database/store/messaging_store.dart` + `store/sqlite/` | `MessagingStore.current`, everything Actions and Interfaces read and write |
| Entities | `lib/database/io/` | plain Dart classes; relations are `Rel` / `RelList` (`io/relations.dart`) |

## Reads and writes

- **Reads run on the calling isolate** through `MessagingStore.current`. Return entities, not ids:
  don't read ids on one isolate and re-read the rows on another.
- **Writes go through `Db.write`** (`BEGIN IMMEDIATE`). Never call drift's `transaction()`, `batch()`,
  `customStatement()` or `into()` outside `db.dart` / `app_database.dart`
  (`test/database/sqlite/write_path_lint_test.dart` enforces this).
- Inside a `Db.write` callback, await **only the database**: no HTTP, files, platform calls or address
  formatting. The write lock is held across every await.
- Writes and sync that move many rows run in the background isolates (`GlobalIsolate`,
  `IncrementalSyncIsolate`); committed changes reach the main isolate as `DbChanges`
  (`db_change_events.dart`), which the services re-read.
- Use `db.snapshot` when several reads must see the same state.
- Batch `IN (...)` lists in chunks of 500.

## Relations

- `Rel<T>` (one) and `RelList<T>` (many) are plain holders filled by the repositories. They never load
  lazily: a relation is empty unless the read that produced the entity filled it.
- To link on write, set `rel.target` / `rel.targetId` (or the list) and save the owning entity.

## Schema changes

1. Change the table in `app_database.dart`, run `dart run build_runner build`
   (never edit `app_database.g.dart` by hand).
2. Bump `schemaVersion` and add an `if (from < N)` step to `onUpgrade`. A step must be safe to run
   again after a kill midway (`IF NOT EXISTS`, idempotent `UPDATE`s, chunked by id).
3. Update `messageToRow` / `messageFromRow` (or the matching mapper) and
   `test/database/sqlite/sqlite_row_mappers_test.dart`.
4. Test the upgrade from a file at the previous version (see `schema_v2_test.dart`, `schema_v4_test.dart`).

## Serialization

Every entity has `fromMap` / `toMap` for the server API. Complex fields are stored as JSON columns
through the mappers. Schema v4 stores a plain-text `attributedBody` (one run over the whole text,
message part 0) and an empty `messageSummaryInfo` as NULL; the mapper rebuilds them on read.

## Platform guard

Web has no database. Guard DB entry points with `kIsWeb` (`flutter/foundation.dart`).

## Rollback safety

The `objectbox/` folder of pre-SQLite builds is never opened or changed, and the app writes only its
own `sqlite*` sync-marker keys (`sync_marker.dart`), so installing an older build still works.
