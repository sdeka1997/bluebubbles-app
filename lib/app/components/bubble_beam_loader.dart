import 'dart:math' as math;

import 'package:flutter/material.dart';

/// BubbleBeam's loading animation: the app icon gently breathing while bubbles rise and fade around it.
class BubbleBeamLoader extends StatefulWidget {
  const BubbleBeamLoader({super.key, this.size = 160});

  final double size;

  @override
  State<BubbleBeamLoader> createState() => _BubbleBeamLoaderState();
}

class _BubbleBeamLoaderState extends State<BubbleBeamLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.size * 0.55;
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final breath = 1 + 0.04 * math.sin(_controller.value * 2 * math.pi);
          return CustomPaint(
            painter: RisingBubblesPainter(_controller.value, color),
            child: Center(child: Transform.scale(scale: breath, child: child)),
          );
        },
        // Decode at display size; the asset itself is 1024 px.
        child: Image.asset("assets/icon/icon.png",
            width: iconSize,
            height: iconSize,
            cacheWidth: (iconSize * MediaQuery.devicePixelRatioOf(context)).round()),
      ),
    );
  }
}

class RisingBubblesPainter extends CustomPainter {
  RisingBubblesPainter(this.progress, this.color);

  final double progress;
  final Color color;

  // (x across the box, phase offset, radius as a fraction of the box, sideways sway)
  static const _bubbles = [
    (0.10, 0.00, 0.050, 0.04),
    (0.30, 0.55, 0.035, 0.03),
    (0.84, 0.20, 0.060, 0.05),
    (0.68, 0.75, 0.030, 0.03),
    (0.93, 0.45, 0.025, 0.02),
    (0.05, 0.35, 0.028, 0.02),
    (0.50, 0.90, 0.022, 0.02),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (x, phase, r, sway) in _bubbles) {
      final p = (progress + phase) % 1.0;
      final fade = p < 0.15 ? p / 0.15 : (p > 0.85 ? (1 - p) / 0.15 : 1.0);
      final radius = r * size.width * (0.7 + 0.3 * p);
      final center = Offset(
        (x + sway * math.sin((p * 2 + phase) * 2 * math.pi)) * size.width,
        size.height * (1.05 - 1.1 * p),
      );
      canvas.drawCircle(center, radius, Paint()..color = color.withAlpha((30 * fade).round()));
      canvas.drawCircle(
          center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.0, radius * 0.14)
            ..color = color.withAlpha((140 * fade).round()));
      canvas.drawCircle(center + Offset(-radius * 0.35, -radius * 0.35), radius * 0.2,
          Paint()..color = Colors.white.withAlpha((200 * fade).round()));
    }
  }

  @override
  bool shouldRepaint(RisingBubblesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
