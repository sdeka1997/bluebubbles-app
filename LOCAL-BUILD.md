# BlueBubbles+ daily build (local only — never push)

This branch is the reproducible source for the separately installed Android daily driver. The official Play Store package remains untouched.

## Installed build

- Package: `com.bluebubbles.messaging.alpha`
- App label: `BlueBubbles+`
- Version: `2.1.1-daily.7`
- Installed version code: `60006098`
- Build-number argument: `40004098`
- APK SHA-256: `a19cfc3b4e7a9fe86b5ed8800f37d7ddb43b2fa6de4d83df763991629cbf5490`
- Signing keystore: `~/.android/debug.keystore`
- Keystore SHA-256: `c831e6df330d6be1eaf6960f18de754b0b86d0f5cda02b8a055a9862dc2cc86c`
- Archived APK: `~/BlueBubbles-Alpha-Build/artifacts/BlueBubbles-Alpha-2.1.1-daily.7-v60006098.apk`

## Functional source

- Find My UI behavior from app PR #3306, head `3ceb10c0cf80745d7211fc31d2c2438b4be3ec74`.
- Apple read/delete synchronization from app PR #3309, head `daa3af5d7cde0373e220047c0f08738bdc575a19`.
- Local-only packaging: Alpha application ID/signing plus the `BlueBubbles+` label. Never include this branding in an upstream PR.
- Server dependency: custom server v8.12.4 / server PR #856 head `6254341a`; active ASAR `dc3540a64e65363aff4b9e4bb8caf4ec112abac79a6ec08c06a899edf23a7162`.

## Build on the MacBook Air

```bash
export PATH="$HOME/BlueBubbles-Alpha-Build/toolchain/flutter/bin:$HOME/BlueBubbles-Alpha-Build/toolchain/jdk21/Contents/Home/bin:$HOME/BlueBubbles-Alpha-Build/toolchain/gradle-8.14/bin:$PATH"
export JAVA_HOME="$HOME/BlueBubbles-Alpha-Build/toolchain/jdk21/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
cd "$HOME/BlueBubbles-Alpha-Build/daily"
flutter build apk --flavor alpha --release --build-name=2.1.1-daily.7 --build-number=40004098
```

For a later build, increase the build-number argument until the resulting installed version code is greater than `60006098`. Verify the APK's package, version, signer, and SHA-256 before installation; do not infer them from the command.

## Install without losing app data

```bash
"$HOME/Library/Android/sdk/platform-tools/adb" install -r build/app/outputs/flutter-apk/app-alpha-release.apk
```

Do not uninstall the Alpha package before an update. Do not touch `com.bluebubbles.messaging`.

## Generated files

Flutter/CocoaPods may modify macOS xcconfig files and create `ios/Flutter/ephemeral/` or `macos/Podfile`. Those files are unrelated to the Android artifact and are not part of the daily source snapshot.
