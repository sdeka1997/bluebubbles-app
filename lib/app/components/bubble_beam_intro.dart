import 'dart:math' as math;

import 'package:flutter/material.dart';

/// BubbleBeam's opening: on the same blue Android's own launch screen shows, the bubble beam
/// streams in from the bottom-left, the message bubble pops in over it, then it all fades into the app.
///
/// The app builds underneath from the first frame, so this adds no loading time.
class BubbleBeamIntro extends StatefulWidget {
  const BubbleBeamIntro({super.key, required this.child, this.enabled = true});

  /// Must match `windowSplashScreenBackground` in android/app/src/main/res/values*-v31/styles.xml.
  static const background = Color(0xFF3177F4);
  static const duration = Duration(milliseconds: 1600);
  static const overlayKey = ValueKey('bubble-beam-intro');

  final Widget child;
  final bool enabled;

  @override
  State<BubbleBeamIntro> createState() => _BubbleBeamIntroState();
}

class _BubbleBeamIntroState extends State<BubbleBeamIntro> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: BubbleBeamIntro.duration);
  late bool _playing = widget.enabled;

  @override
  void initState() {
    super.initState();
    if (_playing) {
      _controller.forward().whenComplete(() {
        if (mounted) setState(() => _playing = false);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (_playing)
          Positioned.fill(
            child: AbsorbPointer(
              key: BubbleBeamIntro.overlayKey,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Opacity(
                  opacity: 1 - Curves.easeIn.transform(_interval(_controller.value, 0.72, 1)),
                  child: ColoredBox(
                    color: BubbleBeamIntro.background,
                    child: CustomPaint(painter: _IntroPainter(_controller.value), size: Size.infinite),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

double _interval(double t, double begin, double end) => ((t - begin) / (end - begin)).clamp(0.0, 1.0);

/// Draws the app icon's artwork (laid out on a 1024 square) at [progress] through the intro.
class _IntroPainter extends CustomPainter {
  _IntroPainter(this.progress);

  final double progress;

  // The icon's bubble beam: (x, y, radius, how far along the beam from the bottom-left).
  static const _beam = [
    (139.5, 719.9, 10.1, 0.04),
    (163.8, 745.8, 11.0, 0.05),
    (189.4, 714.7, 11.2, 0.09),
    (218.5, 748.1, 11.3, 0.09),
    (144.5, 774.5, 11.3, 0.01),
    (232.2, 700.3, 13.6, 0.13),
    (261.0, 632.6, 14.0, 0.20),
    (190.4, 765.5, 14.1, 0.06),
    (260.8, 723.8, 15.9, 0.14),
    (312.9, 631.6, 16.2, 0.25),
    (335.3, 519.5, 18.6, 0.34),
    (315.6, 564.5, 18.9, 0.29),
    (290.7, 686.5, 19.9, 0.19),
    (444.7, 615.1, 22.0, 0.37),
    (512.6, 485.2, 22.8, 0.51),
    (363.5, 625.3, 23.3, 0.29),
    (505.1, 586.3, 23.8, 0.44),
    (372.1, 569.8, 26.4, 0.34),
    (429.5, 532.3, 27.6, 0.41),
    (559.8, 532.4, 29.1, 0.52),
    (612.0, 331.6, 30.8, 0.69),
    (696.7, 464.1, 31.3, 0.68),
    (529.3, 422.8, 31.9, 0.56),
    (900.2, 328.2, 33.0, 0.94),
    (619.0, 424.9, 37.1, 0.64),
    (735.1, 386.5, 37.1, 0.76),
    (712.3, 206.0, 43.1, 0.86),
    (691.1, 304.2, 46.0, 0.78),
    (815.5, 264.4, 50.9, 0.91),
  ];

  // The message bubble, as drawn in the icon before it is scaled into place.
  static final _message = Path()
    ..moveTo(512, 170)
    ..cubicTo(312, 170, 150, 304, 150, 470)
    ..cubicTo(150, 578, 219, 673, 322, 726)
    ..cubicTo(311, 770, 265, 812, 265, 812)
    ..cubicTo(265, 812, 335, 807, 408, 758)
    ..cubicTo(441, 766, 475, 770, 512, 770)
    ..cubicTo(712, 770, 874, 636, 874, 470)
    ..cubicTo(874, 304, 712, 170, 512, 170)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height) * 0.62;
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    canvas.scale(side / 1024);

    for (final (x, y, r, along) in _beam) {
      // Each bubble floats in along the beam, the bottom-left ones first.
      final start = along * 0.35;
      final p = Curves.easeOutCubic.transform(_interval(progress, start, start + 0.3));
      if (p == 0) continue;
      final drift = (1 - p) * 140;
      final c = Offset(x - drift * 0.8090, y - drift * -0.5878);
      final radius = r * (0.4 + 0.6 * p);
      canvas.drawCircle(c, radius, Paint()..color = Colors.white.withValues(alpha: 0.16 * p));
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(3, radius * 0.10)
          ..color = Colors.white.withValues(alpha: 0.92 * p),
      );
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: radius * 0.62),
        200 * math.pi / 180,
        50 * math.pi / 180,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(2.5, radius * 0.15)
          ..color = Colors.white.withValues(alpha: 0.85 * p),
      );
    }

    // The message bubble pops in over the beam with a little overshoot.
    final pop = _interval(progress, 0.22, 0.58);
    if (pop == 0) return;
    final fade = math.min(1.0, pop * 2);
    canvas.translate(512, 502);
    canvas.scale(0.78 * Curves.easeOutBack.transform(pop));
    canvas.translate(-512, -512);
    canvas.drawPath(_message, Paint()..color = const Color(0xFFF4F8FF).withValues(alpha: fade));
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(512, 470), width: 362 * 0.74 * 2, height: 300 * 0.70 * 2),
      198 * math.pi / 180,
      54 * math.pi / 180,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 30
        ..color = const Color(0xFF9CC3FF).withValues(alpha: fade),
    );
  }

  @override
  bool shouldRepaint(_IntroPainter oldDelegate) => oldDelegate.progress != progress;
}
