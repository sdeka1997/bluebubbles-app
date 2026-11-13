import 'dart:async';

import 'package:bluebubbles/app/components/bubble_beam_loader.dart';
import 'package:flutter/material.dart';

/// BubbleBeam's opening: on the same blue Android's own launch screen shows, the glass message
/// bubble sits on the BubbleBeam gradient while bubbles rise past it, until the chats are ready.
///
/// The app builds underneath from the first frame, so this adds no loading time.
class BubbleBeamIntro extends StatefulWidget {
  const BubbleBeamIntro({super.key, required this.child, this.enabled = true, this.ready});

  /// Must match `windowSplashScreenBackground` in android/app/src/main/res/values*-v31/styles.xml.
  static const background = Color(0xFF3177F4);
  static const overlayKey = ValueKey('bubble-beam-intro');

  /// Shown at least this long so it never just flashes, and at most this long if [ready] stalls.
  static const minimum = Duration(milliseconds: 1200);
  static const maximum = Duration(seconds: 4);
  static const fade = Duration(milliseconds: 350);

  final Widget child;
  final bool enabled;

  /// Completes when the app has something to show (the chat list).
  final Future<void>? ready;

  @override
  State<BubbleBeamIntro> createState() => _BubbleBeamIntroState();
}

class _BubbleBeamIntroState extends State<BubbleBeamIntro> with TickerProviderStateMixin {
  late final AnimationController _bubbles = AnimationController(vsync: this, duration: const Duration(seconds: 3));
  late final AnimationController _fade = AnimationController(vsync: this, duration: BubbleBeamIntro.fade);
  late bool _playing = widget.enabled;
  Timer? _minimum;
  Timer? _maximum;
  bool _waitedMinimum = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    if (!_playing) return;
    _bubbles.repeat();
    _minimum = Timer(BubbleBeamIntro.minimum, () {
      _waitedMinimum = true;
      _dismissIfDone();
    });
    _maximum = Timer(BubbleBeamIntro.maximum, _dismiss);
    (widget.ready ?? Future.value()).then((_) {
      _isReady = true;
      _dismissIfDone();
    }, onError: (_) => _dismiss());
  }

  void _dismissIfDone() {
    if (_waitedMinimum && _isReady) _dismiss();
  }

  void _dismiss() {
    _minimum?.cancel();
    _maximum?.cancel();
    if (!mounted || _fade.isAnimating || _fade.isCompleted) return;
    _fade.forward().whenComplete(() {
      if (!mounted) return;
      _bubbles.stop();
      setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _minimum?.cancel();
    _maximum?.cancel();
    _bubbles.dispose();
    _fade.dispose();
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
              child: FadeTransition(
                opacity: ReverseAnimation(_fade),
                child: ColoredBox(
                  color: BubbleBeamIntro.background,
                  // Eases from Android's flat launch colour into the gradient.
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 250),
                    builder: (context, t, child) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(BubbleBeamIntro.background, const Color(0xFF5AAAFE), t)!,
                            Color.lerp(BubbleBeamIntro.background, const Color(0xFF1D4ED8), t)!,
                          ],
                        ),
                      ),
                      child: child,
                    ),
                    child: AnimatedBuilder(
                      animation: _bubbles,
                      builder: (context, child) => CustomPaint(
                        painter: RisingBubblesPainter(_bubbles.value, Colors.white),
                        child: child,
                      ),
                      child: LayoutBuilder(
                        builder: (context, box) => Center(
                          child: Image.asset("assets/icon/splash-bubble.png", width: box.maxWidth * 0.42),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
