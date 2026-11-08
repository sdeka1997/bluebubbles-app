import 'package:flutter/material.dart';

/// How far a live pin's pulse grows, as a multiple of the pin.
const double findMyLivePulseScale = 2.2;

/// The ring that keeps growing out of a pin and fading while that person's
/// location is live, as Find My shows a live location.
class FindMyLivePulse extends StatefulWidget {
  final double size;
  final Color color;

  const FindMyLivePulse({super.key, required this.size, required this.color});

  @override
  State<FindMyLivePulse> createState() => _FindMyLivePulseState();
}

class _FindMyLivePulseState extends State<FindMyLivePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeOut.transform(_controller.value);
        final diameter = widget.size * (1 + (findMyLivePulseScale - 1) * t);
        return IgnorePointer(
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.35 * (1 - t)),
            ),
          ),
        );
      },
    );
  }
}
