import 'package:bluebubbles/app/layouts/conversation_list/pages/search/search_query_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the preview starts at the line holding the match', () {
    final s = searchSnippet('Awesome!\n\nDo you work with Zelle or VenMo?', 'zelle')!;
    expect(s.before, 'Do you work with ');
    expect(s.match, 'Zelle');
    expect(s.after, ' or VenMo?');
  });

  test('a long line is cut to 50 characters either side of the match', () {
    final s = searchSnippet('${'a' * 80} zelle ${'b' * 80}', 'zelle')!;
    expect(s.before.length, lessThanOrEqualTo(50));
    expect(s.after.length, lessThanOrEqualTo(50));
  });

  test('no match gives no snippet', () {
    expect(searchSnippet('hello', 'zelle'), isNull);
  });
}
