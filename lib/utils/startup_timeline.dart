import 'package:flutter/foundation.dart';

/// Startup timeline in the system log under "BBTIME", so a release build can be
/// timed with `adb logcat` (launch, chat list, sync). Memory is read from
/// outside (`dumpsys meminfo`), not here.
class StartupTimeline {
  static final Stopwatch _clock = Stopwatch()..start();

  static bool get _enabled => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static void start() => mark('app start');

  static void mark(String step) {
    if (!_enabled) return;
    final seconds = (_clock.elapsedMilliseconds / 1000).toStringAsFixed(1);
    debugPrint('BBTIME t=${seconds}s $step');
  }
}
