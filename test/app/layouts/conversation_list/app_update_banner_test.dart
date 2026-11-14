import 'package:bluebubbles/app/layouts/conversation_list/widgets/header/app_update_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget banner({double? progress, bool failed = false, VoidCallback? onUpdate, VoidCallback? onDismiss}) {
    var shown = true;
    return MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => shown
              ? AppUpdateBannerView(
                  version: '2.1.2-seq.60',
                  progress: progress,
                  failed: failed,
                  onUpdate: onUpdate ?? () {},
                  onDismiss: () {
                    setState(() => shown = false);
                    onDismiss?.call();
                  },
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  testWidgets('offers the version with an Update button', (tester) async {
    var updates = 0;
    await tester.pumpWidget(banner(onUpdate: () => updates++));
    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Version 2.1.2-seq.60'), findsOneWidget);
    await tester.tap(find.text('Update'));
    expect(updates, 1);
  });

  testWidgets('shows download progress and cannot start a second download', (tester) async {
    var updates = 0;
    await tester.pumpWidget(banner(progress: 0.42, onUpdate: () => updates++));
    expect(find.text('Downloading… 42%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Update'));
    expect(updates, 0);
  });

  testWidgets('offers a retry after a failed download', (tester) async {
    await tester.pumpWidget(banner(failed: true));
    expect(find.text('Download failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('swiping it away dismisses it', (tester) async {
    var dismissed = 0;
    await tester.pumpWidget(banner(onDismiss: () => dismissed++));
    await tester.fling(find.text('Update available'), const Offset(-600, 0), 2000);
    await tester.pumpAndSettle();
    expect(dismissed, 1);
    expect(find.text('Update available'), findsNothing);
  });
}
