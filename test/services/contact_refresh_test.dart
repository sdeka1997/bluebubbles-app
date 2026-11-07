import 'package:bluebubbles/services/ui/contact_service_v2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('contactRefreshIsDue', () {
    final now = DateTime(2026, 11, 7, 12);

    test('never refreshed: due', () {
      expect(contactRefreshIsDue(lastRefreshed: null, now: now), isTrue);
    });

    test('refreshed seconds ago when the app opened: not due again', () {
      expect(contactRefreshIsDue(lastRefreshed: now.subtract(const Duration(seconds: 20)), now: now), isFalse);
    });

    test('refreshed over a minute ago: due', () {
      expect(contactRefreshIsDue(lastRefreshed: now.subtract(const Duration(seconds: 61)), now: now), isTrue);
    });
  });
}
