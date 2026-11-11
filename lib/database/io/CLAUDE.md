# database/io/ — Entities (Native & Desktop)

Plain Dart classes read and written through `lib/database/sqlite/` (row mapping in
`sqlite/sqlite_row_mappers.dart`). No annotations, no generated code. Not used on web.

## Entities

| File | Key Fields | Relations |
|------|-----------|-----------|
| `chat.dart` | guid (unique), chatIdentifier, isArchived, isPinned, muteType, displayName | → dbLatestMessage (`Rel`), → handles (`RelList`) / participants |
| `message.dart` | guid (unique, nullable), text, dateCreated, isFromMe, error, hasDdResults | → chat (`Rel`), → handleRelation (`Rel`), → dbAttachments (`RelList`), associatedMessages (plain list: reactions, filled with each page) |
| `attachment.dart` | guid (unique), uti, mimeType, transferName, totalBytes | → message (`Rel`) |
| `handle.dart` | uniqueAddressAndService (unique, `"$address/$service"`), address, service, country | ↔ contactsV2 (`RelList`) |
| `contact_v2.dart` | displayName, nativeContactId (unique), avatarPath | ↔ handles (`RelList`) |
| `theme.dart` (`ThemeStruct`) | name (unique), serialized theme data, googleFont, gradientBg | — (stored by `store/sqlite/theme_store.dart`) |
| `fcm_data.dart` (`FCMData`) | FCM tokens and Firebase credentials | — (stored in SharedPreferences) |
| `launch_at_startup.dart` | plain static autostart helper (desktop only), nothing persisted | — |
| `relations.dart` | `Rel<T>` / `RelList<T>` | — |

## Rules
- Primary key: `int? id`, null until the first save assigns it.
- Relations are filled by the read that produced the entity; they never load lazily.
- Reactive (`Rx*`) state belongs in `lib/app/state/`, not on entities.
- A new persisted field needs a column, a mapper entry and a schema step: see `.claude/rules/database.md`.

## Platform Guard
```dart
if (kIsWeb) return; // before any MessagingStore call
```
