import 'package:bluebubbles/app/layouts/conversation_list/pages/search/search_models.dart';
import 'package:bluebubbles/app/layouts/conversation_list/pages/search/search_query_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a search starts at three characters, ignoring surrounding spaces', () {
    expect(isSearchableTerm('so'), isFalse);
    expect(isSearchableTerm('  so '), isFalse);
    expect(isSearchableTerm('soc'), isTrue);
  });

  test('search defaults to the messages on this device', () {
    expect(defaultSearchMode(), SearchMode.local);
  });

  testWidgets('typing searches once the user pauses, with the latest text', (tester) async {
    final searched = <String>[];
    final debouncer = SearchDebouncer(delay: const Duration(milliseconds: 300));
    debouncer('soc', searched.add);
    await tester.pump(const Duration(milliseconds: 100));
    debouncer('socc', searched.add);
    await tester.pump(const Duration(milliseconds: 299));
    expect(searched, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(searched, ['socc']);
  });

  testWidgets('a cancelled search never runs', (tester) async {
    final searched = <String>[];
    final debouncer = SearchDebouncer(delay: const Duration(milliseconds: 300));
    debouncer('socc', searched.add);
    debouncer.cancel();
    await tester.pump(const Duration(seconds: 1));
    expect(searched, isEmpty);
  });
}
