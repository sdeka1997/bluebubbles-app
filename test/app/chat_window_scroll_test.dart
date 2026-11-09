// S3 chat window, scroll-path test 13 (SQLITE-PLAN-2.md section 5): what is
// on screen must not move when the window drops rows at either end or adds a
// page there. The plan's first try (one SliverAnimatedList) fails: rows
// dropped or added at the newest end move the screen by their height, since
// a reversed list measures from its newest row. This prototype is the plan's
// design: two lists either side of the CustomScrollView's center sliver.
// Rows newer than the anchor grow down from it, the anchor and older rows
// grow up, so either far end can change without moving anything between.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class _Window extends StatefulWidget {
  const _Window({required this.rows});

  final List<int> rows;

  @override
  State<_Window> createState() => _WindowState();
}

class _WindowState extends State<_Window> {
  final controller = ScrollController();
  final rowKeys = <int, GlobalKey>{};
  var newerKey = GlobalKey<SliverAnimatedListState>();
  var olderKey = GlobalKey<SliverAnimatedListState>();

  /// Rows newer than the anchor, the one next to it first (newer.last is the newest).
  List<int> newer = [];

  /// The anchor, then older rows.
  late List<int> older = [...widget.rows];

  List<int> get rows => [...newer.reversed, ...older];

  double heightOf(int row) => 40.0 + (row % 5) * 17;

  void appendOldest(List<int> rows) {
    final at = older.length;
    older.addAll(rows);
    for (var i = 0; i < rows.length; i++) {
      olderKey.currentState!.insertItem(at + i, duration: Duration.zero);
    }
  }

  void dropOldest(int count) {
    for (var i = 0; i < count; i++) {
      final row = older.removeLast();
      olderKey.currentState!.removeItem(older.length, (_, __) => SizedBox(height: heightOf(row)), duration: Duration.zero);
    }
  }

  void addNewerPage(List<int> rows) {
    // [rows] newest first; the newer list holds them nearest-the-anchor first.
    final at = newer.length;
    newer.addAll(rows.reversed);
    for (var i = 0; i < rows.length; i++) {
      newerKey.currentState!.insertItem(at + i, duration: Duration.zero);
    }
  }

  /// Drops the [count] newest rows. If that reaches the anchor, the anchor
  /// first moves to [visible], a row on screen.
  void dropNewest(int count, {required int visible}) {
    if (count >= newer.length) recentre(visible);
    for (var i = 0; i < count; i++) {
      final row = newer.removeLast();
      // Null right after recentre: the new list builds from [newer] as it is.
      newerKey.currentState?.removeItem(newer.length, (_, __) => SizedBox(height: heightOf(row)), duration: Duration.zero);
    }
  }

  /// Makes [row] (laid out) the anchor without moving the screen.
  void recentre(int row) {
    final box = rowKeys[row]!.currentContext!.findRenderObject()!;
    final reveal = RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset;
    final all = rows;
    final i = all.indexOf(row);
    final position = controller.position as ScrollPositionWithSingleContext;
    // A fling sets absolute positions each frame and would undo the
    // correction, so it pauses for this frame and restarts at its speed once
    // the new layout has set the scroll limits.
    final velocity = position.activity?.velocity ?? 0;
    position.correctBy(-reveal);
    if (velocity != 0) {
      position.goIdle();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (controller.hasClients) position.goBallistic(velocity);
      });
    }
    setState(() {
      newer = all.sublist(0, i).reversed.toList();
      older = all.sublist(i);
      newerKey = GlobalKey<SliverAnimatedListState>();
      olderKey = GlobalKey<SliverAnimatedListState>();
    });
  }

  Widget row(int row) => SizedBox(
        key: rowKeys.putIfAbsent(row, () => GlobalKey()),
        height: heightOf(row),
        child: Text('row $row'),
      );

  String shown() {
    final texts = find.byType(Text).hitTestable().evaluate().map((e) => (e.widget as Text).data).toList();
    return '${controller.offset.toStringAsFixed(1)} ${texts.isEmpty ? '-' : '${texts.first}..${texts.last}'}';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          controller: controller,
          reverse: true,
          center: olderKey,
          scrollCacheExtent: const ScrollCacheExtent.pixels(1500),
          slivers: [
            SliverAnimatedList(
              key: newerKey,
              initialItemCount: newer.length,
              itemBuilder: (context, index, animation) => row(newer[index]),
            ),
            SliverAnimatedList(
              key: olderKey,
              initialItemCount: older.length,
              itemBuilder: (context, index, animation) => row(older[index]),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  Future<_WindowState> pumpWindow(WidgetTester tester, List<int> rows) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_Window(rows: rows));
    return tester.state<_WindowState>(find.byType(_Window));
  }

  Future<void> scrollTo(WidgetTester tester, int row, {bool up = true}) async {
    await tester.dragUntilVisible(find.text('row $row'), find.byType(CustomScrollView), Offset(0, up ? 300 : -300));
    await tester.pumpAndSettle();
  }

  double top(WidgetTester tester, int row) => tester.getTopLeft(find.text('row $row')).dy;

  testWidgets('scrolling up: an older page added and the newest rows dropped leave the screen where it is',
      (tester) async {
    final state = await pumpWindow(tester, [for (var i = 1000; i > 850; i--) i]); // newest first
    await scrollTo(tester, 880);
    final before = top(tester, 880);

    state.appendOldest([for (var i = 850; i > 825; i--) i]);
    await tester.pump();
    expect(top(tester, 880), closeTo(before, 1));

    state.dropNewest(25, visible: 880);
    await tester.pump();
    expect(top(tester, 880), closeTo(before, 1));
    expect(state.rows, [for (var i = 975; i > 825; i--) i]);

    // And again, now that the anchor sits mid-window.
    await scrollTo(tester, 840);
    final before2 = top(tester, 840);
    state.appendOldest([for (var i = 825; i > 800; i--) i]);
    state.dropNewest(25, visible: 840);
    await tester.pump();
    expect(top(tester, 840), closeTo(before2, 1));
  });

  testWidgets('scrolling back down: a newer page added and the oldest rows dropped leave the screen where it is',
      (tester) async {
    final state = await pumpWindow(tester, [for (var i = 975; i > 825; i--) i]);
    await scrollTo(tester, 960);
    final before = top(tester, 960);

    state.addNewerPage([for (var i = 1000; i > 975; i--) i]);
    await tester.pump();
    expect(top(tester, 960), closeTo(before, 1));

    state.dropOldest(25);
    await tester.pump();
    expect(top(tester, 960), closeTo(before, 1));

    // The newest row is reachable and the list ends there.
    await tester.fling(find.byType(CustomScrollView), const Offset(0, -3000), 5000);
    await tester.pumpAndSettle();
    expect(find.text('row 1000'), findsOneWidget);
    expect(state.controller.offset, closeTo(state.controller.position.minScrollExtent, 1));
  });

  testWidgets('re-centring during a fling keeps the fling going from where it is', (tester) async {
    final state = await pumpWindow(tester, [for (var i = 1000; i > 850; i--) i]);
    await scrollTo(tester, 900);
    await tester.fling(find.byType(CustomScrollView), const Offset(0, 200), 800);
    await tester.pump(const Duration(milliseconds: 50));
    // Scrollables ignore pointers mid-fling, so hitTestable() finds nothing.
    final visible = state.rows.firstWhere((r) {
      final f = find.text('row $r');
      if (f.evaluate().isEmpty) return false;
      final y = tester.getTopLeft(f).dy;
      return y > 100 && y < 700;
    });
    final before = top(tester, visible);

    state.recentre(visible);
    await tester.pump();
    expect(top(tester, visible), closeTo(before, 2));
    // The restarted fling's first frame is its start, so measure the next.
    await tester.pump(const Duration(milliseconds: 16));
    final pos = tester.getTopLeft(find.text('row $visible')).dy;
    await tester.pump(const Duration(milliseconds: 16));
    // Still moving the same way at a fling's pace, not snapping by the
    // re-centring distance (which would take the row off screen).
    final moved = find.text('row $visible').evaluate().isEmpty ? null : tester.getTopLeft(find.text('row $visible')).dy - pos;
    expect(moved, isNotNull);
    expect(moved!, greaterThan(0));
    expect(moved, lessThan(200));
  });
}
