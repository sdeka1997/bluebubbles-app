import 'dart:async';
import 'dart:developer' show reachabilityBarrier;
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

/// Diagnostic for the chat-screen leak: how many objects of each kind are still
/// alive, written under "BBLIVE". A Finalizer counts each tracked object when
/// the VM collects it, so "alive" is made minus collected. [log] first makes
/// the VM run full collections (it allocates short-lived garbage until two have
/// run), so anything still alive afterwards is held by something.
class LiveCount {
  static final Map<String, int> _made = {};
  static final Map<String, int> _freed = {};
  static final Finalizer<String> _finalizer = Finalizer((kind) => _freed[kind] = (_freed[kind] ?? 0) + 1);

  static bool get _enabled => !kIsWeb && Platform.isAndroid;

  static void track(Object object, String kind) {
    if (!_enabled) return;
    _made[kind] = (_made[kind] ?? 0) + 1;
    _finalizer.attach(object, kind);
  }

  static Future<void> log(String step) async {
    if (!_enabled) return;
    final start = reachabilityBarrier;
    final junk = <List<int>>[];
    var rounds = 0;
    while (reachabilityBarrier < start + 2 && rounds < 400) {
      junk.add(List<int>.filled(200000, 0));
      if (junk.length > 40) junk.removeAt(0);
      rounds++;
      await Future<void>.delayed(Duration.zero);
    }
    junk.clear();
    // Finalizers run as their own events after a collection.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final kinds = _made.keys.toList()..sort();
    final counts = kinds.map((k) => '$k=${_made[k]! - (_freed[k] ?? 0)}/${_made[k]}').join(' ');
    debugPrint('BBLIVE $step gcs=${reachabilityBarrier - start} rss=${ProcessInfo.currentRss ~/ (1024 * 1024)}MB $counts');
  }
}
