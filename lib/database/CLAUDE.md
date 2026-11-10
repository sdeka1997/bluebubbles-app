# lib/database/ — Data Persistence

See `docs/MODELS.md` for the consolidated cross-directory entity/DTO field reference.

## Platform Abstraction
| Directory | Platform | Role |
|-----------|----------|------|
| `io/` | Android, iOS, Desktop | ObjectBox `@Entity` classes |
| `html/` | Web (deprecated) | Stubs only — do not extend → `html/CLAUDE.md` |
| `global/` | All | Shared DTOs, no DB annotations |

Conditional imports resolve the correct implementation at compile time.

## Key Entities (`io/`) → `io/CLAUDE.md`
- `chat.dart`, `message.dart`, `attachment.dart`, `handle.dart`
- `contact_v2.dart`, `theme.dart`, `fcm_data.dart`, `launch_at_startup.dart`

## Key Shared Models (`global/`) → `global/CLAUDE.md`
- `settings.dart`, `message_part.dart`, `attributed_body.dart`
- `payload_data.dart`, `server_payload.dart`, `scheduled_message.dart`, `queue_items.dart`

## Code Generation
`generated/objectbox.g.dart` is auto-generated from `@Entity` annotations.
After editing entities in `io/`: `dart run build_runner build`

## Initialization
`database.dart` — `Database.init` opens (or creates) `bluebubbles.db` through
`sqlite/storage.dart` (`openStorage`) as this isolate's `MessagingStore`, loads
the themes (`store/sqlite/theme_store.dart`) and seeds the presets. The
`objectbox/` folder of builds before SQLite is never opened; it stays on disk
for a rollback.

## Storage
- `sqlite/` — `Db` (the connection), the drift schema (`app_database.dart`) and
  one repository per table group.
- `store/messaging_store.dart` — `MessagingStore`, everything the Actions and
  Interfaces read and write; its parts are the mixins in `store/sqlite/`.
