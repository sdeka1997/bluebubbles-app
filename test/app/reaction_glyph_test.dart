import 'package:bluebubbles/app/layouts/conversation_view/widgets/message/reaction/reaction_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

// On device the emoji font's glyph box is larger than its font size, so an
// emoji given exactly the icon's 15 px box overflows it to the right and down.
// The test font is an exact square, so scale the text up to reproduce that.
Widget _bubble(String type, {double scale = 1}) => MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            key: const Key('bubble'),
            width: 28,
            height: 28,
            child: ReactionGlyph(type: type, color: Colors.white),
          ),
        ),
      ),
    );

void main() {
  testWidgets('a standard Tapback draws its icon', (tester) async {
    await tester.pumpWidget(_bubble('love'));
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('a custom emoji draws the emoji, not an icon file', (tester) async {
    await tester.pumpWidget(_bubble('🥪'));
    expect(find.byType(SvgPicture), findsNothing);
    expect(find.text('🥪'), findsOneWidget);
  });

  testWidgets('a custom emoji is never drawn bigger than the box it is laid out in', (tester) async {
    await tester.pumpWidget(_bubble('🥪', scale: 1.3));
    final paragraph = tester.renderObject<RenderParagraph>(find.text('🥪'));
    final needsWidth = paragraph.getMaxIntrinsicWidth(double.infinity);
    final needsHeight = paragraph.getMinIntrinsicHeight(double.infinity);
    expect(needsWidth, lessThanOrEqualTo(paragraph.size.width + 0.01),
        reason: 'emoji needs $needsWidth px wide but got ${paragraph.size.width}: it spills right');
    expect(needsHeight, lessThanOrEqualTo(paragraph.size.height + 0.01),
        reason: 'emoji needs $needsHeight px tall but got ${paragraph.size.height}: it spills down');
  });

  testWidgets('a custom emoji stays centered in the bubble', (tester) async {
    await tester.pumpWidget(_bubble('🥪', scale: 1.3));
    final bubble = tester.getRect(find.byKey(const Key('bubble')));
    final emoji = tester.getRect(find.text('🥪'));
    expect((emoji.center - bubble.center).distance, lessThan(0.5));
  });
}
