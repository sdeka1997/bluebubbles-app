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

    test('shows my current custom emoji before the picker so it can be tapped to remove', () {
      expect(ReactionTypes.pickerTypes(allowCustomEmoji: true, selfReaction: '🥪'),
          [...ReactionTypes.toList(), '🥪', '+']);
    });

    test('does not repeat a standard Tapback as a custom slot', () {
      expect(ReactionTypes.pickerTypes(allowCustomEmoji: true, selfReaction: 'love'), [...ReactionTypes.toList(), '+']);
    });

    test('shows recent emoji after my custom emoji and before the picker', () {
      expect(ReactionTypes.pickerTypes(allowCustomEmoji: true, selfReaction: '🥪', recentEmojis: ['🔥', '🎉']),
          [...ReactionTypes.toList(), '🥪', '🔥', '🎉', '+']);
    });

    test('shows at most two recent emoji', () {
      expect(ReactionTypes.pickerTypes(allowCustomEmoji: true, recentEmojis: ['🔥', '🎉', '🙏']),
          [...ReactionTypes.toList(), '🔥', '🎉', '+']);
    });

    test('skips recent emoji that repeat a standard Tapback or my custom emoji', () {
      expect(ReactionTypes.pickerTypes(allowCustomEmoji: true, selfReaction: '🥪', recentEmojis: ['👍', '🥪', '❤️', '🔥', '🎉']),
          [...ReactionTypes.toList(), '🥪', '🔥', '🎉', '+']);
    });

    test('shows no recent emoji before Sequoia', () {
      expect(ReactionTypes.pickerTypes(allowCustomEmoji: false, recentEmojis: ['🔥']), ReactionTypes.toList());
    });
  });

  group('ReactionTypes.pickerWrapsToTwoRows', () {
    test('wraps a row too wide for the screen before Sequoia', () {
      expect(ReactionTypes.pickerWrapsToTwoRows(allowCustomEmoji: false, contentWidth: 400, availableWidth: 300), isTrue);
      expect(ReactionTypes.pickerWrapsToTwoRows(allowCustomEmoji: false, contentWidth: 250, availableWidth: 300), isFalse);
    });

    test('keeps one scrolling row on Sequoia however wide it is', () {
      expect(ReactionTypes.pickerWrapsToTwoRows(allowCustomEmoji: true, contentWidth: 400, availableWidth: 300), isFalse);
    });
  });
}
