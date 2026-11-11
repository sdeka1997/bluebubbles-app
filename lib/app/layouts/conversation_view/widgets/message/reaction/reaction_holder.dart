import 'package:bluebubbles/app/state/message_state_scope.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/reaction/reaction.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';

/// Stateful widget that animates a reaction pop-in only once
class _ReactionAnimator extends StatefulWidget {
  const _ReactionAnimator({super.key, required this.stableKey, required this.shouldAnimate, required this.child});

  final String stableKey;
  final bool shouldAnimate;
  final Widget child;

  @override
  State<_ReactionAnimator> createState() => _ReactionAnimatorState();
}

class _ReactionAnimatorState extends State<_ReactionAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);

    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    // Animate in only if this is a new reaction
    if (widget.shouldAnimate) {
      _controller.forward();
    } else {
      // Skip animation - set to final state immediately
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}

/// One badge of the reaction stack. [offset] is its distance from the bubble's
/// tail side; only the [front] badge draws a tail.
typedef StackedReaction = ({Message reaction, double offset, bool front});

/// Lays reactions out the way iOS does: the first [ReactionHolder.maxShown] in
/// the order they were added, the oldest farthest from the tail and each newer
/// one overlapping it; any more show only as the edge of one badge behind the
/// oldest. [unique] is newest first, as [getUniqueReactionMessages] returns it.
/// Returned back to front, so later entries paint over earlier ones.
List<StackedReaction> reactionStack(List<Message> unique) {
  const step = ReactionHolder.step;
  final oldestFirst = unique.reversed.toList();
  final shown = oldestFirst.take(ReactionHolder.maxShown).toList();
  final last = shown.length - 1;
  return [
    if (oldestFirst.length > shown.length)
      (reaction: oldestFirst[shown.length], offset: last * step + ReactionHolder.hiddenEdge, front: false),
    for (var i = 0; i < shown.length; i++) (reaction: shown[i], offset: (last - i) * step, front: i == last),
  ];
}

class ReactionHolder extends StatefulWidget {
  const ReactionHolder({super.key, required this.reactions});

  final Iterable<Message> reactions;

  /// Measured from iPhone screenshots of a group chat: badges sit 70% of a
  /// badge apart (33 of 47 px) and a fourth reaction shows as a 13% edge. The
  /// filled circle of a badge here is 28 px.
  static const double step = 20;
  static const double hiddenEdge = 4;
  static const int maxShown = 3;

  @override
  State<ReactionHolder> createState() => _ReactionHolderState();
}

class _ReactionHolderState extends State<ReactionHolder> {
  Iterable<Message> get reactions => getUniqueReactionMessages(widget.reactions.toList());

  // Cache the unique reactions to prevent unnecessary rebuilds
  late List<Message> _cachedReactions;

  // Track which reaction keys have been animated
  // This prevents re-animation on rebuilds, but allows animation on first appearance
  final Set<String> _seenReactionKeys = {};

  @override
  void initState() {
    super.initState();
    _cachedReactions = reactions.toList();
  }

  @override
  void didUpdateWidget(ReactionHolder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only rebuild if reactions actually changed
    if (!_reactionsEqual(oldWidget.reactions, widget.reactions)) {
      _cachedReactions = reactions.toList();
    }
  }

  /// Check if two reaction lists are equal by comparing GUIDs
  /// This prevents unnecessary rebuilds when the same data is passed
  bool _reactionsEqual(Iterable<Message> a, Iterable<Message> b) {
    final listA = a.toList();
    final listB = b.toList();
    if (listA.length != listB.length) return false;
    for (int i = 0; i < listA.length; i++) {
      if (listA[i].guid != listB[i].guid) return false;
    }
    return true;
  }

  // Parent + reaction type + sender, so the temp -> real GUID swap doesn't re-animate.
  String _stableKey(Message e) =>
      '${e.associatedMessageGuid}-${e.associatedMessageType}-${e.isFromMe! ? 0 : e.handleId ?? 0}';

  @override
  Widget build(BuildContext context) {
    // If the reactions are empty, return nothing
    if (_cachedReactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final isFromMe = MessageStateScope.of(context).isFromMe.value;
    return SizedBox(
      height: 35,
      width: 35,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final badge in reactionStack(_cachedReactions))
            Positioned(
              key: ValueKey(_stableKey(badge.reaction)),
              top: 0,
              left: isFromMe ? badge.offset : null,
              right: isFromMe ? null : badge.offset,
              child: DeferPointer(
                child: _ReactionAnimator(
                  key: ValueKey(_stableKey(badge.reaction)),
                  stableKey: _stableKey(badge.reaction),
                  shouldAnimate: _seenReactionKeys.add(_stableKey(badge.reaction)),
                  child: ReactionWidget(reaction: badge.reaction, reactions: _cachedReactions, showTail: badge.front),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
