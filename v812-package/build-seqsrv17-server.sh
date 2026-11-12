#!/bin/bash
# Build and stage Sequoia "seqsrv17": seqsrv16 + server/info reuses the time-server answer for 10 min
# and looks up the three account details together (wip/findmy-mirror 9b5583c3).
# Source worktree is OUTSIDE /tmp so it survives reboots (seqsrv3's /tmp tree was lost).
# Does not sign or install.
set -euo pipefail
export PATH=/nix/var/nix/profiles/default/bin:$PATH
W="$HOME/BlueBubbles-Worktrees/wgroup"
P="$HOME/BlueBubbles-v812-Package"
S="$HOME/BlueBubbles-Staging"
BASEAPP="$S/BlueBubbles-Custom-seqsrv16.app"
APP="$S/BlueBubbles-Custom-seqsrv17.app"
HELPER_SHA=a8ceaa802b3185706c9b88954d173b6f43ce14eca78d7c258f4e7afc3f796667

cd "$W"
[ -z "$(git status --porcelain)" ] || { echo DIRTY; git status --short; exit 2; }
git log --oneline -2
git merge-base --is-ancestor 9b5583c3 HEAD || { echo WRONG_HEAD; exit 6; }
# The commit being built must be on the fork, so the live build is reproducible from source.
git fetch forkpush --prune -q
git branch -r --contains "$(git rev-parse HEAD)" | grep -q forkpush/ || { echo "HEAD NOT PUSHED"; exit 3; }

[ -L node_modules ] && rm node_modules
nix shell nixpkgs#nodejs_22 -c npm ci --ignore-scripts --no-audit --no-fund >/tmp/seqsrv17-npm.log 2>&1
# @noble/ciphers is declared in packages/server/package.json; npm ci must have installed it.
[ -f node_modules/@noble/ciphers/package.json ] || { echo "NOBLE MISSING AFTER npm ci"; exit 4; }

cd "$W/packages/server"
nix shell nixpkgs#nodejs_22 -c ../../node_modules/.bin/rimraf .test-dist
# Compile tests to CommonJS and run them from .test-dist: this repo's tests are NOT runnable
# via --experimental-strip-types (they import without the .ts extension).
nix shell nixpkgs#nodejs_22 -c ../../node_modules/.bin/tsc --noEmit false --module commonjs \
  --target ES2022 --moduleResolution node --esModuleInterop --skipLibCheck --outDir .test-dist \
  test/dylibPlugins.test.ts test/reactions.test.ts test/chatLookup.test.ts test/chatReadAt.test.ts \
  test/chatStateChangeDetector.test.ts test/chatGroupIds.test.ts \
  test/latestGroupTitles.test.ts test/chatGroupingFields.test.ts test/chatStateSnapshot.test.ts \
  src/server/api/reactions.ts src/server/databases/imessage/snapshot/ChatStateSnapshot.ts \
  src/server/databases/imessage/pollers/ChatStateChangeDetector.ts src/server/api/privateApi/chatLookup.ts \
  src/server/api/privateApi/modes/dylibPlugins/injectedLibraries.ts \
  src/server/databases/transformers/MessageTypeTransformer.ts \
  src/server/api/serializers/chatGroupIds.ts src/server/databases/imessage/helpers/latestGroupTitles.ts \
  test/messagePage.test.ts test/messageGroupingFields.test.ts src/server/databases/imessage/helpers/messagePage.ts \
  test/findMyMirror.test.ts test/findMyLiveBridgeHost.test.ts src/server/api/lib/findmy/FindMyMirror.ts \
  test/cachedValue.test.ts src/server/helpers/cachedValue.ts \
  src/server/api/lib/findmy/FindMyLiveBridgeHost.ts
nix shell nixpkgs#nodejs_22 -c node --test .test-dist/test/dylibPlugins.test.js \
  .test-dist/test/reactions.test.js .test-dist/test/chatLookup.test.js .test-dist/test/chatReadAt.test.js \
  .test-dist/test/chatStateChangeDetector.test.js .test-dist/test/chatGroupIds.test.js \
  .test-dist/test/latestGroupTitles.test.js .test-dist/test/chatGroupingFields.test.js .test-dist/test/chatStateSnapshot.test.js \
  .test-dist/test/messagePage.test.js .test-dist/test/messageGroupingFields.test.js \
  .test-dist/test/findMyMirror.test.js .test-dist/test/findMyLiveBridgeHost.test.js .test-dist/test/cachedValue.test.js \
  >/tmp/seqsrv17-test.log 2>&1
nix shell nixpkgs#nodejs_22 -c ../../node_modules/.bin/rimraf .test-dist
grep -E "^# (tests|pass|fail)" /tmp/seqsrv17-test.log
grep -q "^# fail 0" /tmp/seqsrv17-test.log

cd "$W"
nix shell nixpkgs#nodejs_22 -c npm run build --workspace packages/server >/tmp/seqsrv17-build.log 2>&1 \
  || { tail -40 /tmp/seqsrv17-build.log; exit 1; }
grep -q "LegacyGroupIdentifiers" packages/server/dist/main.js
! grep -q "mergeKey" packages/server/dist/main.js
grep -q "readAt" packages/server/dist/main.js
grep -q "@noble/ciphers/chacha" packages/server/dist/main.js
grep -q "publishing locations as it writes them" packages/server/dist/main.js
grep -q "findmy-devices-updated" packages/server/dist/main.js
grep -q "findmy-screen" packages/server/dist/main.js
grep -q "finishedLaunching" packages/server/dist/main.js
grep -q "bluebubbles-findmy-live.sock" packages/server/dist/main.js
grep -q "BBFM_LIVE_TOKEN" packages/server/dist/main.js
grep -q "live location is unavailable in this Find My" packages/server/dist/main.js
grep -q "Find My live bridge timed out" packages/server/dist/main.js
grep -q "keepAfterCloseMs" packages/server/dist/main.js
grep -q "ECONNRESET" packages/server/dist/main.js
grep -q "findmy-warm" packages/server/dist/main.js
grep -q "SELECT ROWID FROM message WHERE is_read = 0 AND is_from_me = 0 AND item_type = 0" packages/server/dist/main.js
grep -q "No time offset in" packages/server/dist/main.js
! grep -q "labelWithin(locations, 3000)" packages/server/dist/main.js
# The packaged bridge must be the one that looks every second (no 15 s default left)
strings "$W/packages/server/appResources/macos/findmy-live/BlueBubblesFindMyBridge.dylib" | grep -q "manager scan count" 
! grep -q "joining the round started" packages/server/dist/main.js
! grep -q "findmy-round" packages/server/dist/main.js
! grep -q "not relaunching until" packages/server/dist/main.js
! grep -q "asked the Private API helper to locate every friend" packages/server/dist/main.js
shasum -a 256 packages/server/dist/main.js

cd "$P"
export NODE_PATH="$W/node_modules"
nix shell nixpkgs#nodejs_22 -c node repack-seqsrv17.js >/tmp/seqsrv17-repack.log 2>&1 \
  || { tail -30 /tmp/seqsrv17-repack.log; exit 1; }
grep -E 'markers_verified|output_sha256|electron_asar_integrity|base_files_unchanged' /tmp/seqsrv17-repack.log
INTEG=$(nix shell nixpkgs#nodejs_22 -c node -e '
const asar=require("@electron/asar"),crypto=require("crypto");
console.log(crypto.createHash("sha256").update(asar.getRawHeader(process.argv[1]).headerString).digest("hex"));' "$P/app.custom.seqsrv17.asar")

rm -rf "$APP"
ditto "$BASEAPP" "$APP"
R="$APP/Contents/Resources"
rm -f "$R/app.asar"
rm -rf "$R/app.asar.unpacked"
cp "$P/app.custom.seqsrv17.asar" "$R/app.asar"
ditto "$P/app.custom.seqsrv17.asar.unpacked" "$R/app.asar.unpacked"
# The Find My live bridge (built + ad-hoc signed by findmy-live/build.sh, committed); Find My loads it by path.
FL="$W/packages/server/appResources/macos/findmy-live"
mkdir -p "$R/appResources/macos/findmy-live"
cp "$FL/BlueBubblesFindMyBridge.dylib" "$FL/libBlueBubblesFindMyLive.dylib" "$R/appResources/macos/findmy-live/"
codesign --verify --strict "$R/appResources/macos/findmy-live/BlueBubblesFindMyBridge.dylib" "$R/appResources/macos/findmy-live/libBlueBubblesFindMyLive.dylib"
# Keep the proven helper dylib; the grouping work needs no helper change.
H="$W/packages/server/appResources/private-api/macos11"
D="$R/appResources/private-api/macos11"
cp "$H/BlueBubblesHelper.dylib" "$D/BlueBubblesHelper.dylib"
cp "$H/BlueBubblesHelper.dylib.md5" "$D/BlueBubblesHelper.dylib.md5"
cp "$H/BlueBubblesHelper.dylib.source.txt" "$D/BlueBubblesHelper.dylib.source.txt"
/usr/libexec/PlistBuddy -c "Set :ElectronAsarIntegrity:Resources/app.asar:hash $INTEG" "$APP/Contents/Info.plist"

ACTUAL=$(/usr/libexec/PlistBuddy -c 'Print :ElectronAsarIntegrity:Resources/app.asar:hash' "$APP/Contents/Info.plist")
[ "$ACTUAL" = "$INTEG" ]
[ "$(shasum -a 256 "$D/BlueBubblesHelper.dylib" | cut -d' ' -f1)" = "$HELPER_SHA" ]
if codesign --verify --deep --strict "$APP" 2>/dev/null; then echo UNEXPECTED_VALID_SIGNATURE; exit 1; else echo SIGNATURE_INVALID_AS_EXPECTED; fi
printf 'APP=%s\nINTEGRITY=%s\n' "$APP" "$INTEG"
shasum -a 256 "$R/app.asar" "$D/BlueBubblesHelper.dylib"
echo SEQSRV17_STAGED