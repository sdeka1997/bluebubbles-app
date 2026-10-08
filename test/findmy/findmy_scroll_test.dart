import 'dart:async';

import 'package:bluebubbles/app/layouts/findmy/findmy_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('second selected row is visible after first card collapses', (tester) async {
    final keys = List.generate(8, (_) => GlobalKey());
    int selected = -1;
    late StateSetter setState;

    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
        key: const Key('viewport'),
        height: 420,
        child: StatefulBuilder(builder: (context, update) {
          setState = update;
          return ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) => AnimatedSize(
              key: keys[index],
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: SizedBox(height: selected == index ? 220 : 72, child: Text('row $index')),
            ),
          );
        }),
      )),
    ));

    setState(() => selected = 3);
    unawaited(ensureFindMyRowVisibleAfterExpansion(keys[3]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 217));
    await tester.pumpAndSettle();

    setState(() => selected = 4);
    unawaited(ensureFindMyRowVisibleAfterExpansion(keys[4]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 217));
    await tester.pumpAndSettle();

    final viewportTop = tester.getTopLeft(find.byKey(const Key('viewport'))).dy;
    final selectedTop = tester.getTopLeft(find.byKey(keys[4])).dy;
    expect(selectedTop, greaterThanOrEqualTo(viewportTop));
    expect(selectedTop, lessThan(viewportTop + 16));
  });
}
