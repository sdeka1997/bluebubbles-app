import 'dart:async';

import 'package:flutter/widgets.dart';

/// Waits for the old Find My card to collapse and the new one to finish
/// expanding, then positions the selected card just inside the drawer.
Future<void> ensureFindMyRowVisibleAfterExpansion(
  GlobalKey rowKey, {
  bool Function()? isCurrent,
  Duration expansionDuration = const Duration(milliseconds: 200),
  Duration scrollDuration = const Duration(milliseconds: 250),
  double topInset = 8,
}) async {
  // One frame past the animation duration guarantees both cards have reached
  // their final geometry before the target offset is measured.
  await Future<void>.delayed(expansionDuration + const Duration(milliseconds: 16));
  final frame = Completer<void>();
  WidgetsBinding.instance.addPostFrameCallback((_) => frame.complete());
  WidgetsBinding.instance.scheduleFrame();
  await frame.future;
  if (isCurrent != null && !isCurrent()) return;

  final context = rowKey.currentContext;
  if (context == null || !context.mounted) return;
  final targetBox = context.findRenderObject();
  final scrollable = Scrollable.maybeOf(context);
  if (scrollable == null) return;
  final viewportContext = scrollable.context;
  if (!viewportContext.mounted) return;
  final viewportBox = viewportContext.findRenderObject();
  if (targetBox is! RenderBox || viewportBox is! RenderBox) return;

  final targetTop = targetBox.localToGlobal(Offset.zero).dy;
  final viewportTop = viewportBox.localToGlobal(Offset.zero).dy;
  final desiredTop = viewportTop + topInset;
  final position = scrollable.position;
  final targetOffset = (position.pixels + targetTop - desiredTop).clamp(
    position.minScrollExtent,
    position.maxScrollExtent,
  );
  await position.animateTo(targetOffset, duration: scrollDuration, curve: Curves.easeOut);
}
