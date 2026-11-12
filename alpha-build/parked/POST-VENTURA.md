# BlueBubbles — Post-Ventura Work

**Server Mac:** `MacBookPro13,2`, macOS **12.7.6** (21H1320), OCLP-patched, always-on
**Clients:** Pixel 10 (Alpha `com.bluebubbles.messaging.alpha`), iPhone 15 Pro Max (home anchor)
**Goal:** BlueBubbles behaves "like just another iPad client for iMessage"
**Last updated:** 2026-10-06

---

## Working today (deployed, verified on-device)

| Capability | Verification |
|---|---|
| Send/receive messages + attachments, both directions | Pre-existing |
| Apple → Android **read** sync, live + offline repair | v8.12.4 custom server + BlueBubbles+ daily build |
| Apple → Android **whole-chat deletion**, live + background-push routing | v8.12.4 + BlueBubbles+ `2.1.1-daily.6` |
| Find My list/sort/map fixes | BlueBubbles+ daily build |
| Conversation-list scroll fix | On-device |

Production runs **v8.12.4** (ASAR SHA-256 `57427ed5e18a9522554e3ad85b94287bc40a3aa60196fa84fa1dced89742e37d`).
The update lockout is active, the complete v8.12.3-at-swap rollback app and original v8.12.2 rollback material are retained, and the exact reconstruction archive lives at
`~/work/v812-deploy-audit/reconstruction/` on halo.

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

## Upstream and daily-client delivery status — complete

Current open upstream PRs:

- Server #854: Unicode attachment filenames
- Server #855: Find My SecureLocationCache refresh and address lookup
- Server #856: Apple → Android read and whole-chat deletion sync
- Client #3306: Find My list, grouping, map, and refresh UI
- Client #3309: Apple → Android read/deletion handling, including background `chat-deleted`

BlueBubbles+ `2.1.1-daily.6` is installed as the separate Alpha package
`com.bluebubbles.messaging.alpha`; the official Play Store package is untouched. The installed APK has version code
`60006097` and SHA-256 `9bd5b412727599f16e0b3de363cc75adc3110505f5bfb141eeb191180dc3a693`.
Its functional source is the union of client PRs #3306 and #3309, plus local-only BlueBubbles+ branding/build
metadata. The app was updated with `adb install -r`, preserving its configured data.

Live deletion has now been verified in normal use. A separate read-sync transport defect was observed on 2026-10-06:
the server detected and pushed two read events, but Alpha had no socket connection and its foreground FCM handler
dropped the events merely because the app process was alive. Reopening reconciled the state. Daily.6 and PR #3309
commit `e2ed0b12` correct the guard and route disconnected-socket read pushes through the reactive handler. A real
read during a naturally disconnected foreground socket remains the final acceptance check.

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
- Server canonical repository (halo): `~/work/bluebubbles-server`
- Server deployment/reconstruction archive (halo): `~/work/v812-deploy-audit/reconstruction/`
- Client Git object store (Air): `~/BlueBubbles-Alpha-Build/source`
- Daily client worktree (Air): `~/BlueBubbles-Alpha-Build/daily`
- Daily APK, complete Git bundle, and manifest (Air): `~/BlueBubbles-Alpha-Build/artifacts/`
- Daily APK, complete Git bundle, and manifest (halo): `~/work/v812-deploy-audit/reconstruction/`
- Required Alpha signing key (Air): `~/.android/debug.keystore` — **do not delete or regenerate**
- Flutter/JDK toolchain (Air): `~/BlueBubbles-Alpha-Build/toolchain/`
- Parked patch: `~/BlueBubbles-Alpha-Build/parked/android-to-apple-deletion-ux.patch`
- Server logs: `~/Library/Logs/bluebubbles-server/main.log`
- Client logs: `adb shell run-as com.bluebubbles.messaging.alpha` → `app_flutter/logs/bluebubbles-latest.log`
- SSH noise filter: `| grep -v "post-quantum\|store now\|openssh.com/pq"`

---

## macOS upgrade runbook — target Ventura 13

### Decision

**Agreed target: macOS Ventura 13 using the current stable OCLP release at upgrade time.**

This is the decision Swapnav explicitly accepted after the Monterey/Ventura/Sonoma/Sequoia comparison. The later
Sequoia 15.8.1 recommendation was inserted during a documentation cleanup without his agreement and is superseded.

Why Ventura:
- It is the minimum macOS release that enables edit, undo-send, and mark-unread in BlueBubbles.
- It retains the Monterey/Ventura Find My architecture used by our deployed SecureLocationCache reader.
- Sonoma and Sequoia add no required BlueBubbles capability for this server.
- Ventura requires less OCLP/root-patch complexity on `MacBookPro13,2` than Sonoma or Sequoia.
- The tradeoff was discussed and accepted: Ventura is outside Apple's current security-update stream. For this
  dedicated headless server, compatibility and unattended reliability were chosen over the newest supported OS.

Do not silently substitute Sonoma or Sequoia. Revisit the target with Swapnav first if security support or required
features materially change.

### Helper decision

**No BlueBubbles helper upgrade is required before the OS upgrade. Freeze the known-good v8.12.4 deployment.**

The only mandatory pre-upgrade component update is OCLP itself. Use the current stable OCLP release available in the
maintenance window; 2.5.1 was current when this runbook was prepared. The server package includes native modules
`better-sqlite3`, `node-mac-contacts`, and `node-mac-permissions`. Do not rebuild them speculatively. Rebuild only if
post-upgrade launch logs show a native-module ABI/load error.

The external private-API helper's live version is **UNKNOWN** until inspected on the physical server. Record its
path, version/hash, and permissions before upgrading. Expect to reinstall or reauthorize it after the OS change,
but do not replace a working helper before the rollback snapshot exists. The custom Find My reader/geocoder also
gets a post-upgrade compatibility test, not a preemptive replacement.

### Before the maintenance window

- [ ] Schedule physical access; this upgrade must not be attempted unattended over SSH.
- [ ] Confirm a current Time Machine or full-volume backup and a bootable recovery path.
- [ ] Create and test the OCLP Ventura installer USB before touching the internal disk.
- [ ] Inventory current OCLP app, booted OpenCore, root-patch, FileVault, SIP, and private-API-helper state.
- [ ] Verify the v8.12.4 reconstruction archive and v8.12.3/v8.12.2 rollback artifacts are readable from another machine.
- [ ] Back up BlueBubbles settings/data and `~/Library/Messages/chat.db` while Messages/BlueBubbles are stopped.
- [ ] Record Messages-in-iCloud state and the pending `sync_deleted_chats` tombstones.
- [ ] Preserve TCC permissions/screenshots for Full Disk Access, Accessibility, Automation, Contacts, and
      Screen Recording.
- [ ] Free at least **45 GB** on the server Mac as an operational safety target (coaching judgment, not an OCLP
      published minimum); record the actual free-space result.
- [ ] Disable BlueBubbles self-update and automatic macOS installation for the window.

### Upgrade procedure

Follow OCLP's official major-upgrade sequence:

1. Install/update the current stable OCLP application.
2. Rebuild and install OpenCore to the internal disk; verify the new bootloader actually boots once.
3. Build the Ventura 13 installer USB through OCLP.
4. Boot the installer through OpenCore. **Do not use Disk Utility or erase the volume.**
5. Complete the in-place macOS installation with physical access maintained.
6. Reinstall OCLP root patches and reboot.

### First boot — platform checks before BlueBubbles

- [ ] Confirm graphics acceleration, networking, Bluetooth, sleep/wake, and unattended boot reliability.
- [ ] Confirm OCLP reports the expected bootloader and root-patch versions.
- [ ] Open Messages and verify the iCloud account, history, send, receive, attachment, and read state.
- [ ] Check whether the existing CloudKit deletion tombstones flush; do not toggle Messages in iCloud during the
      initial observation period.
- [ ] Re-grant any lost TCC permissions to BlueBubbles and its helper.

### BlueBubbles bring-up

1. Start frozen v8.12.4 with networking local-only if practical; inspect the first launch log.
2. If a native module fails to load, rebuild only the named module set using the documented build recipe. If not,
   leave the packaged modules unchanged.
3. Inventory/reinstall the private-API helper only if its health check or a feature probe fails.
4. Verify `/api/v1/ping`, send/receive, attachments, contacts, notifications, and Find My before reopening remote
   access.
5. Confirm the update lockout still blocks official packages from overwriting the custom server.

### Feature retest order

1. Edit propagation
2. Unsend propagation
3. Mark-as-unread
4. Android → Apple whole-chat deletion
5. Android → Apple single-message deletion
6. Apple → Android live read/delete plus offline reconciliation
7. Find My friends/items/devices and map opening

The first three are expected to become testable because Ventura's Messages database/private APIs expose data absent
on Monterey; that is an expectation, not a guarantee. Preserve before/after schema and log evidence.

### Stop/rollback conditions

Stop before reopening remote access if Messages history is missing, iCloud begins an uncontrolled full re-sync,
BlueBubbles cannot read `chat.db`, the private API mutates the wrong chat/message, or core hardware/root patches
are unstable. Boot recovery/OCLP USB, restore the known-good system/data snapshot as needed, and redeploy the
archived v8.12.4 or v8.12.3 artifact. Do not treat an HTTP success response as proof of an Apple-side mutation;
confirm on the iPhone.
