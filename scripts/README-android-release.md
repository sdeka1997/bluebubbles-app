# Local Android release command

Run from the repository root on the MacBook Air:

```bash
./scripts/release_android.py <version-name> <flutter-build-number>
```

The default is a **dry run**: it runs every local gate, test, analysis, build, and APK validation step, but performs no GitHub write. It prints the tag and asset name it would use. Example:

```bash
./scripts/release_android.py 2.1.2-seq.56 60008999
# tag: v2.1.2-seq.56+android.80010999
# asset: BubbleBeam-v2.1.2-seq.56+android.80010999-alpha.apk
```

Publishing is opt-in and requires a GitHub token with Contents write access:

```bash
GH_TOKEN=... ./scripts/release_android.py 2.1.2-seq.56 60008999 --publish
```

The token is read only from the process environment and is never printed or stored. `--publish` creates a non-draft, non-prerelease GitHub release in `sdeka1997/bluebubbles-app` and uploads the validated APK. Do not add `--publish` when only checking a build.

## Enforced gates

The command refuses to proceed unless:

- the branch is `main`, the working tree is clean, `origin` is the BubbleBeam fork, and `HEAD` exactly equals freshly fetched `origin/main`;
- at least 15 GiB is free;
- the GitHub tag and release do not already exist;
- `flutter test` and `flutter analyze --no-fatal-infos` pass;
- the alpha release builds with `BB_REQUIRE_RELEASE_SIGNING=true`;
- Android SDK `aapt2` reports the exact package ID, version name, and computed version code;
- `apksigner` reports the staged signer SHA-256 digest.

Immediately before any publish, it cleans known Flutter-generated files, rechecks the git state and remote tag/release, then uploads only `build/app/outputs/flutter-apk/app-alpha-release.apk` under the printed `.apk` asset name.

The command supplies the repository's local Flutter/JDK/Gradle paths and defaults `JAVA_HOME` and `ANDROID_HOME` to the checked-in Mac build environment. Override `JAVA_HOME` or `ANDROID_HOME` in the process environment if those toolchains move.

Run the release-tool behavior tests without building an APK:

```bash
python3 -m unittest -v scripts.tests.test_release_android
```
