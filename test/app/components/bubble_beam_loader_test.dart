import 'package:bluebubbles/app/components/bubble_beam_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CustomPainter painter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
          find.descendant(of: find.byType(BubbleBeamLoader), matching: find.byType(CustomPaint)))
      .map((c) => c.painter)
      .whereType<CustomPainter>()
      .single;

  testWidgets('shows the app icon over bubbles that keep moving, and stops when removed', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: BubbleBeamLoader()))));

    final provider = tester.widget<Image>(find.byType(Image)).image;
    final asset = (provider is ResizeImage ? provider.imageProvider : provider) as AssetImage;
    expect(asset.assetName, 'assets/icon/icon.png');

    final before = painter(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(painter(tester).shouldRepaint(before), isTrue);

    // Removing it must dispose the animation; an active ticker here fails the test.
    await tester.pumpWidget(const SizedBox());
    expect(find.byType(BubbleBeamLoader), findsNothing);
  });
}
