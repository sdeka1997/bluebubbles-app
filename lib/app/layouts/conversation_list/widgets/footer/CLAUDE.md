# conversation_list/widgets/footer/ — Samsung Footer

## Files
| File | Purpose |
|------|---------|
| `samsung_footer.dart` | Bottom navigation bar for the Samsung One UI skin; shows Home / Search / Settings tabs in a bottom nav style |

## Platform
Samsung One UI only. Not rendered on iOS or Material skins. Controlled via `ThemeSwitcher` in the parent conversation list pages.

## Related
- Samsung headers: `../header/CLAUDE.md`
- Parent list: `../../CLAUDE.md` (conversation_list)
- `sync_progress_bar.dart` — `SyncProgressBar`: "Updating messages… N of M" bar under the list during a long incremental sync (all skins, added in `conversation_list.dart`)
