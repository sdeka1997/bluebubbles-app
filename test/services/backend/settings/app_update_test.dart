// The app checks BubbleBeam's GitHub releases for a newer Android build: our fork, not upstream.
// Android releases are tagged `v<version>+android.<version code>`, for example
// `v2.1.2-seq.56+android.80010999`, and offered when that version code is above the installed one.
// The version code is the one Android itself compares when installing over the app.
import 'dart:io';

import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github/github.dart';

void main() {
  test('releases come from our fork', () {
    expect(updateRepository.fullName, 'sdeka1997/bluebubbles-app');
  });

  test('a BubbleBeam Android release tag', () {
    final tag = ReleaseTag.parse('v2.1.2-seq.56+android.80010999');
    expect([tag.version, tag.code, tag.platform], ['2.1.2-seq.56', 80010999, 'android']);
  });

  group('offered to an Android install', () {
    final newer = ReleaseTag.parse('v2.1.2-seq.56+android.80010999');

    test('when its build number is above the installed one', () {
      expect(offersAndroidUpdate(newer, installedCode: 80010992, dismissedCode: null), isTrue);
    });

    test('compares the whole version code, not its last four digits', () {
      // The old rule compared the tag with the installed code's last four digits (0992), so every
      // release with a longer code looked newer, including older ones.
      expect(offersAndroidUpdate(ReleaseTag.parse('v2.1.2-seq.55+android.80010900'), installedCode: 80010992,
              dismissedCode: null),
          isFalse);
    });

    test('not when it is the installed build or older', () {
      expect(offersAndroidUpdate(newer, installedCode: 80010999, dismissedCode: null), isFalse);
      expect(offersAndroidUpdate(newer, installedCode: 80011000, dismissedCode: null), isFalse);
    });

    test('not after OK was pressed on it', () {
      expect(offersAndroidUpdate(newer, installedCode: 80010992, dismissedCode: '80010999'), isFalse);
    });

    test('not for a desktop release or a tag without a build number', () {
      expect(offersAndroidUpdate(ReleaseTag.parse('v2.1.6+desktop.70000000'), installedCode: 1, dismissedCode: null),
          isFalse);
      expect(offersAndroidUpdate(ReleaseTag.parse('v2.1.7'), installedCode: 1, dismissedCode: null), isFalse);
    });
  });

  group('Download', () {
    test('goes straight to the APK', () {
      final release = Release(htmlUrl: 'https://github.com/r/releases/tag/t', assets: [
        ReleaseAsset(name: 'notes.txt', browserDownloadUrl: 'https://x/notes.txt'),
        ReleaseAsset(name: 'BubbleBeam-2.1.2-seq.56.apk', browserDownloadUrl: 'https://x/BubbleBeam.apk'),
      ]);
      expect(downloadUrl(release), 'https://x/BubbleBeam.apk');
    });

    test('opens the release page when it has no APK', () {
      expect(downloadUrl(Release(htmlUrl: 'https://github.com/r/releases/tag/t', assets: [])),
          'https://github.com/r/releases/tag/t');
    });
  });

  group('update checks repeat', () {
    final now = DateTime(2026, 11, 14, 12);

    test('the first time', () {
      expect(updateCheckDue(null, now), isTrue);
    });

    test('once an hour has passed since the last check', () {
      expect(updateCheckDue(now.subtract(const Duration(hours: 1)), now), isTrue);
      expect(updateCheckDue(now.subtract(const Duration(days: 2)), now), isTrue);
    });

    test('not sooner', () {
      expect(updateCheckDue(now.subtract(const Duration(minutes: 59)), now), isFalse);
      expect(updateCheckDue(now, now), isFalse);
    });

    test('on resume as well as at startup', () {
      // The app stays alive in the background for days, so a release published after it started
      // was never offered until the process happened to restart.
      final source = File('lib/helpers/backend/startup_tasks.dart').readAsStringSync();
      final resume = source.substring(source.indexOf('static Future<void> onAppResume'));
      expect(resume, contains('_runUpdateChecks('));
      final startup = source.substring(
          source.indexOf('static Future<void> onStartup'), source.indexOf('static Future<void> onAppResume'));
      expect(startup, contains('_runUpdateChecks'));
    });
  });

  test('the check uses these rules', () {
    final source = File('lib/services/backend/settings/settings_service.dart').readAsStringSync();
    final check = source.substring(source.indexOf('Future<Map<String, dynamic>> getAppUpdateDict'),
        source.indexOf('/// Store listings lag behind'));
    expect(check, contains('listReleases(updateRepository)'));
    expect(check, contains('offersAndroidUpdate('));
    expect(check, isNot(contains('lastChars(')));
    // Any install that isn't from Play (adb, a browser download, a file manager) checks GitHub.
    expect(check, isNot(contains('IS_INSTALLED_FROM_LOCAL_SOURCE')));
  });
}
