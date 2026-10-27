import 'package:bluebubbles/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// What sits inside an iOS-skin Tapback bubble: the standard Tapback icon, or
/// a custom emoji scaled to fit and centered in the same space.
class ReactionGlyph extends StatelessWidget {
  const ReactionGlyph({super.key, required this.type, required this.color});

  /// Reaction type, e.g. "love" or a custom emoji such as "🥪".
  final String type;

  /// Icon color for standard Tapbacks; emoji keep their own colors.
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (ReactionTypes.toList().contains(type.replaceAll("-", ""))) {
      return Padding(
        padding: const EdgeInsets.all(6.5).add(EdgeInsets.only(right: type == "emphasize" ? 1 : 0)),
        child: SvgPicture.asset(
          'assets/reactions/$type-black.svg',
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      );
    }
    // An emoji drawn at the icon's 15 px overflows the 15 px icon box (its line
    // box is taller and wider than its size), pushing it right and down.
    return Padding(
      padding: const EdgeInsets.all(5),
      child: FittedBox(
        child: Text(
          ReactionTypes.emojiForReaction(type),
          style: const TextStyle(fontSize: 15, height: 1, fontFamily: 'Apple Color Emoji'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
