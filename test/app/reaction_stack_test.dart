import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/reaction/reaction_clipper.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/reaction/reaction_holder.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

// Rules read off iPhone screenshots of a group chat and matched to the server's
// reaction order: up to three badges in the order the reactions were added,
// the newest in front at the tail; more than three show as one edge behind.
Message _r(String guid) => Message(guid: guid, associatedMessageType: 'love', dateCreated: DateTime(2026));

// getUniqueReactionMessages hands the holder the newest first.
List<String> _backToFront(List<StackedReaction> s) => [for (final b in s) b.reaction.guid!];

void main() {
  test('one reaction sits at the tail and draws it', () {
    final s = reactionStack([_r('a')]);
    expect(_backToFront(s), ['a']);
    expect(s.single.offset, 0);
    expect(s.single.front, isTrue);
  });

  test('two reactions: the newer one is in front at the tail, the older one clear of it', () {
    final s = reactionStack([_r('new'), _r('old')]);
    expect(_backToFront(s), ['old', 'new']);
    expect([for (final b in s) b.offset], [ReactionHolder.step, 0]);
    expect([for (final b in s) b.front], [false, true]);
  });

  test('each badge shows most of itself, as on iOS', () {
    expect(ReactionHolder.step / 28, closeTo(0.70, 0.03));
  });

  test('three reactions spread out in the order they were added', () {
    final s = reactionStack([_r('c'), _r('b'), _r('a')]);
    expect(_backToFront(s), ['a', 'b', 'c']);
    expect([for (final b in s) b.offset], [2 * ReactionHolder.step, ReactionHolder.step, 0]);
  });

  test('more than three: the first three show, the rest are one edge behind the oldest', () {
    final s = reactionStack([_r('e'), _r('d'), _r('c'), _r('b'), _r('a')]);
    expect(_backToFront(s), ['d', 'a', 'b', 'c']);
    expect(s.first.offset, 2 * ReactionHolder.step + ReactionHolder.hiddenEdge);
    expect(s.where((b) => b.front).length, 1);
  });

  test('a badge stacked behind another draws no tail', () {
    const size = Size(35, 35);
    for (final dir in ReactionTailDirection.values) {
      final withTail = ReactionClipper(tailDirection: dir).getClip(size).getBounds();
      final without = ReactionClipper(tailDirection: dir, tail: false).getClip(size).getBounds();
      expect(withTail.height, closeTo(35, 0.01));
      expect(without.height, closeTo(28, 0.01));
    }
  });
}
