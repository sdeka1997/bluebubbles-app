import 'package:bluebubbles/helpers/ui/reaction_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReactionTypes.checkReactionType', () {
    test('accepts standard reactions and removals', () {
      expect(ReactionTypes.checkReactionType('love'), isTrue);
      expect(ReactionTypes.checkReactionType('-question'), isTrue);
    });

    test('accepts one emoji grapheme and its removal', () {
      for (final reaction in ['😀', '-😀', '👨‍👩‍👧‍👦', '🇺🇸', '👍🏽']) {
        expect(ReactionTypes.checkReactionType(reaction), isTrue, reason: reaction);
      }
    });

    test('rejects text, blank and multiple emoji graphemes', () {
      for (final reaction in [null, '', '-', 'hello', '😀😀', 'love-letter']) {
        expect(ReactionTypes.checkReactionType(reaction), isFalse, reason: '$reaction');
      }
    });
  });

  group('ReactionTypes.pickerTypes', () {
    test('shows only standard Tapbacks before Sequoia', () {
      expect(ReactionTypes.pickerTypes(allowCustomEmoji: false), ReactionTypes.toList());
    });

    test('adds the custom emoji picker on Sequoia', () {
      expect(ReactionTypes.pickerTypes(allowCustomEmoji: true), [...ReactionTypes.toList(), '+']);
    });
  });
}
