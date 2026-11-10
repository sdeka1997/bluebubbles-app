// The app's update check reads the newest GitHub release tag. Upstream now
// tags releases per platform (`v2.1.6+desktop.96`, `v2.1.5+android.95`), and
// parsing "desktop.96" as a number threw at every launch: "Failure during app
// initialization: FormatException: Invalid radix-10 number ... desktop.96".
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a desktop-only release tag', () {
    final tag = ReleaseTag.parse('v2.1.6+desktop.96');
    expect([tag.version, tag.code, tag.platform], ['2.1.6', 96, 'desktop']);
    expect(tag.isFor(desktop: false), isFalse);
    expect(tag.isFor(desktop: true), isTrue);
  });

  test('an Android-only release tag', () {
    final tag = ReleaseTag.parse('v2.1.5+android.95');
    expect([tag.version, tag.code, tag.platform], ['2.1.5', 95, 'android']);
    expect(tag.isFor(desktop: false), isTrue);
    expect(tag.isFor(desktop: true), isFalse);
  });

  test('a release tag shared by every platform', () {
    final tag = ReleaseTag.parse('v2.1.2+92');
    expect([tag.version, tag.code, tag.platform], ['2.1.2', 92, null]);
    expect(tag.isFor(desktop: false), isTrue);
  });

  test('a tag with no build number does not throw', () {
    expect(ReleaseTag.parse('v2.1.7').code, isNull);
  });
}
