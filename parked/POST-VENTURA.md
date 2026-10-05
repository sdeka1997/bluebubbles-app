# BlueBubbles — Post-Ventura Work

**Server Mac:** `MacBookPro13,2`, macOS **12.7.6** (21H1320), OCLP-patched, always-on
**Clients:** Pixel 10 (Alpha `com.bluebubbles.messaging.alpha`), iPhone 15 Pro Max (home anchor)
**Goal:** BlueBubbles behaves "like just another iPad client for iMessage"
**Last updated:** 2026-10-05

---

## Working today (deployed, verified on-device)

| Capability | Verification |
|---|---|
| Send/receive messages + attachments, both directions | Pre-existing |
| Apple → Android **read** sync, live + offline repair | v8.11 |
| Apple → Android **whole-chat deletion**, live | `SMS;-;85893`, `SMS;-;34012` |
| Conversation-list scroll fix | On-device |

Production runs **v8.11** (asar integrity `c38776fe…`). v8.10 retained for rollback.

---

## Blocked on Monterey — retest after Ventura

Four of the five remaining gaps are OS-level, not missing code.

### 1. Edit / unsend propagation — **no code needed**

Monterey's `message` table has **75 columns and neither `date_edited` nor `date_retracted`.**
Verified directly:

```
$ sqlite3 ~/Library/Messages/chat.db "PRAGMA table_info(message);" | grep -iE "edit|retract"
(no rows)
$ ... "SELECT COUNT(*) FROM message WHERE date_retracted != 0;"
Error: no such column: date_retracted
```

The data has nowhere to live, which is why edits and unsends silently no-op.

Upstream already polls for both — `packages/server/src/server/databases/imessage/pollers/MessagePoller.ts:43,48`:

```ts
(e.dateEdited?.getTime() ?? 0) >= afterTime ||
(e.dateRetracted?.getTime() ?? 0) >= afterTime ||
```

**Expectation:** Ventura adds the columns, these lines start returning rows, feature works with zero new code.
**Retest:** edit and unsend a message on the iPhone; confirm both reach the Pixel.

### 2. Mark-as-unread — **no code needed**

Hard-gated upstream at `chatInterface.ts:464`. Our read-pointer detector is already deployed in v8.11 but
inert: Monterey never writes `chat.last_read_message_timestamp` on an unread action.

**Known bug to fix regardless of OS:** `markUnread` skips the private API when not on Ventura but emits the
success event anyway — reporting success for an operation that did not happen.

```ts
static async markUnread(chatGuid: string): Promise<void> {
    if (isMinVentura) {
        await Server().privateApi.chat.markUnread(chatGuid);
    }
    // emits CHAT_READ_STATUS_CHANGED unconditionally  <-- false success
```

**Retest:** mark a thread unread on the iPhone; confirm the pointer moves and the Pixel shows unread.

### 3. Android → Apple whole-chat deletion — **reverted, patch parked**

Reverted to stock on 2026-10-05. Patch: `~/BlueBubbles-Alpha-Build/parked/android-to-apple-deletion-ux.patch` (231 lines, on the Mac).

Current stock behavior: deleting on the Pixel is **local-only**. The thread stays on the Mac and iPhone.

**The earlier diagnosis was wrong.** `_chat_remove:` is *not* registry-local — it correctly writes a
CloudKit tombstone. Verified in `chat.db`:

```
$ sqlite3 ~/Library/Messages/chat.db "SELECT * FROM sync_deleted_chats ORDER BY ROWID DESC;"
14|SMS;+;chat74903684870218217|8a576d97…|0
13|SMS;-;34012|d884842b…|812667773225554944   <- 2026-10-02 21:02:53 UTC
12|SMS;-;+185****0536|5fb5f70d…|812587284638641920
11|SMS;-;85893|25a7d1e5…|812305533159484032   <- queued 2026-09-28, still pending
10|SMS;-;98945|51d2fc72…|812435225104208000
 9|SMS;-;+120****1511|5f20fe8d…|812310069554584064
 8|SMS;-;94870|923ed574…|812568996348916480
```

Seven tombstones with real CloudKit record IDs, oldest from Sept 28, none flushed. Messages in iCloud **is**
enabled (`CloudKitSyncingEnabled = 1`, `IMCloudKitAccountStatusKey = 3`), last sync `2026-10-04 23:21:10 UTC`.

**Unresolved — diagnosis stalled.** `CloudKitMetaData/` is empty, and the unified log returns **zero lines**
for `imagent`, `cloudd`, and `IMCloudKit` over 6–24h despite those processes running. No observability on
this OCLP install, so "sync is stuck" vs. "sync is idle" cannot be distinguished.

**Untried next steps, cheapest first:**
1. Toggle Messages in iCloud off/on in Messages → Settings on the Mac. If the queue flushes, all 7 tombstones
   land and the feature works with no code. Caveat: a full re-sync of a **1 GB `chat.db`** on a dual-core 2016
   machine could run for hours and disrupt the live server — do not start casually.
2. Restart `imagent` / `cloudd`. Briefly drops BlueBubbles' link to Messages.
3. Ventura reworked Messages-in-iCloud alongside Recently Deleted; may resolve on its own.

### 4. Android → Apple single-message deletion

`delete-message` reports success but deletes nothing — **not even locally on the Mac.**
Probe: `5D108D1B-9A9F-CCF8-8ACF-77D2C176F457` in `SMS;-;97707` survived 30s with no log output.
Needs re-probing after Ventura before assuming a dylib fix is required.

---

## Deliberately dropped

**Apple → Android single-message deletion** (the "sync engine") — killed 2026-10-05, never deployed.

Would have fingerprinted each chat's message-GUID set (SHA-256 over sorted GUIDs) and diffed consecutive
snapshots to spot individual messages disappearing. Reverted because:

- It helps with **none** of the four blocked items above — it only detects *GUIDs disappearing*
- Cost: `GROUP_CONCAT` over the message table per chat, **2,438 chats every poll cycle**, on a 2016 dual-core
- Required a permanent v4 snapshot schema fork, carried through every future upstream merge
- Never device-tested — a projected capability, not a demonstrated one

Design notes live in session `20260915_150821_d62389cc` if ever revisited. Note it would **not** catch
unsends-while-offline: a retracted message keeps its row, so the GUID set is unchanged.

**Tier 3 features** — pins, mute sync, Recently Deleted, visual parity. Agreed low value.

---

## Upstream PR #3306 — needs splitting before shipping

Branch `fix/findmy-list-order-and-inset` on the Mac at `~/BlueBubbles-Alpha-Build/source`.
After the 2026-10-05 revert: **~19 files**, `dart analyze lib/` reports **0 errors, 0 warnings**.

**PR A — read/delete sync (client).** Pure Apple→Android observation, no Monterey-specific mutation:
- `lib/services/backend/sync/chat_state_reconciler.dart`, `chat_state_transition.dart` (new)
- `action_handler.dart` +20, `sync_service.dart` +34
- `server_api.dart` +17, `socket_service.dart` +1, `services.dart` +1
- `shared_preferences_database_actions.dart` +5
- `chats_service.dart` — `setChatHasUnreadFromServer`, `setChatArchivedFromServer`

**PR B — Find My (unrelated, ~8 files / ~220 lines).** Friend sort, map widget, device tiles,
`findmy_friend_sort.dart`. What the branch was originally named for. Ship separately.

**Must NOT ship:** `macos/Flutter/*.xcconfig`, `macos/Podfile`, `ios/Flutter/ephemeral/` — local build artifacts.

### Sequencing constraint

PR A consumes `chat-deleted`, an event **only our server emits** (added in v8.11). Upstream's server has no
such event, so the client PR is inert until the server change lands — and that's a different repo.
**Server PR must go first.**

---

## Reference

### Verified facts worth not re-deriving
- Monterey can neither **perform** nor **observe** mark-unread
- `Chat.findOne` does **not** filter `dateDeleted` — query all matching rows when deleting
- `chat_state_reconciler.dart` is **delete-only**; no code path restores a chat, so a local soft-delete
  is never resurrected by reconciliation (`:255`, `:278`, `:282`)
- Read-pointer invariant: treat `last_read_message_timestamp` only as an ordered transition token across two
  observations of the same chat. Never compare to message timestamps, never infer from absolute value, never
  emit on first observation. Keep it a decimal string end-to-end with a length-plus-lexicographic comparator.
  Unread evidence wins; deletion wins over a simultaneous pointer/read change.
- Server-side "success" is **not** acceptance: the delete endpoint only verifies the row left the Mac's
  database. Any Apple-side mutation must be confirmed by **iPhone observation**.

### Known-divergent state
- `SMS;-;34012` — deleted from Mac + Pixel, **still on iPhone**. Permanent divergence.
- `SMS;-;98945` — stale tile in Alpha (`+1 98945`, BetMGM code). Forward-only sync cannot recover it;
  needs one manual delete on the Pixel.
- `SMS;+;chat74903684870218217` (`963bd0`) — on Mac + Pixel, never on iPhone. Rejected as a test candidate.

### Paths
- Server source (halo): `~/.hermes/work/bluebubbles-readsync-v199/packages/server` — **58/58 tests pass**
- Client canonical (**Mac only**): `~/BlueBubbles-Alpha-Build/source` — never build Flutter on halo
- Toolchain: `~/BlueBubbles-Alpha-Build/toolchain/flutter/bin/{flutter,dart}`, `jdk21`
- Parked patch: `~/BlueBubbles-Alpha-Build/parked/android-to-apple-deletion-ux.patch`
- Logs: `~/Library/Logs/bluebubbles-server/main.log`; client via
  `adb shell run-as com.bluebubbles.messaging.alpha` → `app_flutter/logs/bluebubbles-latest.log`
- SSH noise filter: `| grep -v "post-quantum\|store now\|openssh.com/pq"`

---

## Ventura upgrade (OCLP) — not yet scoped

Requires **physical recovery access** to the MacBook; cannot be done unattended over SSH.
Scope, risk, and rollback still need writing up before committing to a date.

**Retest order after upgrade:** edit → unsend → mark-unread → Android→Apple chat delete → Android→Apple
message delete. The first three should work with **no new code**.
