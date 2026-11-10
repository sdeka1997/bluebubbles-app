import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Diagnostic for the memory investigation: how much of the message database this process
/// holds in memory, written to the system log under "BBMEM" so a release build can be read
/// with `adb logcat`. Marks the named steps, plus every 5 s for the first two minutes so
/// anything unnamed shows up in the timeline too.
class MemTrace {
  static final Stopwatch _clock = Stopwatch()..start();
  static final RegExp _mapping = RegExp(r'^[0-9a-f]+-[0-9a-f]+ ');
  static Timer? _ticker;

  static bool get _enabled => !kIsWeb && Platform.isAndroid;

  static void start() {
    if (!_enabled || _ticker != null) return;
    mark('app start');
    _ticker = Timer.periodic(const Duration(seconds: 5), (timer) {
      mark('tick');
      if (_clock.elapsed > const Duration(minutes: 2)) timer.cancel();
    });
  }

  /// A timeline line without the memory reading: cheap enough for every page of a chat.
  static void note(String step) {
    if (!_enabled) return;
    final seconds = (_clock.elapsedMilliseconds / 1000).toStringAsFixed(1);
    debugPrint('BBMEM t=${seconds}s $step');
  }

  static void mark(String step) {
    if (!_enabled) return;
    try {
      var dbKb = 0;
      var totalKb = 0;
      var inDb = false;
      for (final line in File('/proc/self/smaps').readAsLinesSync()) {
        if (_mapping.hasMatch(line)) {
          inDb = line.endsWith('data.mdb');
        } else if (line.startsWith('Rss:')) {
          final kb = int.tryParse(line.substring(4).trim().split(' ').first) ?? 0;
          totalKb += kb;
          if (inDb) dbKb += kb;
        }
      }
      final seconds = (_clock.elapsedMilliseconds / 1000).toStringAsFixed(1);
      debugPrint('BBMEM t=${seconds}s db=${dbKb ~/ 1024}MB rss=${totalKb ~/ 1024}MB $step');
    } catch (e) {
      debugPrint('BBMEM unavailable: $e');
    }
  }
}
