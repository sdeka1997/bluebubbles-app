# findmy/ — Find My Device Locator

## Files
- `findmy_page.dart` — main screen (map + list tabs); reads controller state only
- `findmy_controller.dart` — state and logic: one load pipeline (cached seed, parallel reads, background friend refresh, cancellable sessions), socket updates, markers, camera framing
- `findmy_load_state.dart` — per-source load state (`FindMyLoad` idle/loading/loaded/failed + error and update time)
- `findmy_location_cache.dart` — last known locations and the last friend/device lists, scoped to server + iCloud account, skipped in redacted mode; writes debounced
- `findmy_products.dart` — sorts devices into the Devices and Items tabs once per device list (AirPods part collapsing, audio products)
- `findmy_refresh_progress.dart` — refresh window: which friends are still being located, and when the refresh ends
- `findmy_round_follower.dart` — follows the server's locating rounds from socket events and refresh answers; owns the refresh progress
- `findmy_selection.dart` — the one selected friend or device, its marker key, and the Apple handle live tracking names
- `findmy_tiles.dart` — the one tile provider: retrying HTTP client and bounded reload of failed tiles
- `findmy_camera.dart` — camera framing, marker clustering, zoom constants and marker identity
- `findmy_panel.dart` — drawer and floating-button geometry, and the camera padding derived from it
- `findmy_friend_sort.dart` — coordinate validation, friend identity, and deterministic nearest-first friend ordering
- `findmy_format.dart` — distance and timestamp labels
- `findmy_contact.dart` — safe phone/email extraction for native-contact fallback matching
- `findmy_device_glyph.dart` — icon/emoji for a device or item, shared by map pins and list rows
- `findmy_scroll.dart` — post-animation selected-row positioning
- `findmy_location_clipper.dart` — custom `CustomClipper` for location shape
- `findmy_pin_clipper.dart` — custom `CustomClipper` for map pin shape

## Widgets (`widgets/`)
- `findmy_map_widget.dart` — interactive map view, mounted from the first frame
- `findmy_friend_list_tile.dart` — friend location list row
- `findmy_device_list_tile.dart` — device location list row
- `findmy_items_tab_view.dart` — tracked items tab
- `findmy_devices_tab_view.dart` — devices tab
- `findmy_friends_tab_view.dart` — friends tab
- `findmy_selected_card.dart` — card for the selected friend or device
- `findmy_raw_data_dialog.dart` — debug view of raw location payload

## Data Models
`lib/database/global/findmy_friend.dart`
`lib/database/global/findmy_device.dart`
