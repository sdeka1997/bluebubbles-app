// Older messages start loading a few messages before the top of what is
// loaded, not when the spinner at the very top is built, so the page is usually
// there by the time you scroll to it.
import 'package:bluebubbles/app/layouts/conversation_view/pages/messages_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the next page starts loading 12 messages before the top', () {
    expect(needsOlderPage(index: 100 - 13, loaded: 100), isFalse);
    expect(needsOlderPage(index: 100 - 12, loaded: 100), isTrue);
    expect(needsOlderPage(index: 99, loaded: 100), isTrue);
  });

  test('the spinner at the top still starts a load', () {
    expect(needsOlderPage(index: 100, loaded: 100), isTrue);
  });

  test('the lead is smaller than a page, so one page does not chain into the next', () {
    expect(olderPageLead, lessThan(25));
  });
}
