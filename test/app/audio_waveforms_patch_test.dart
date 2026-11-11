import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// audio_waveforms 2.0.2 throws "codec is released already" when a voice
// message bubble is disposed after its waveform finished extracting
// (upstream issue #477). The app builds against a copy of 2.0.2 with the
// upstream fix (PR #515) applied until a release contains it.
void main() {
  test('audio_waveforms resolves to the patched copy', () {
    final lock = File('pubspec.lock').readAsStringSync();
    final entry = RegExp(r'\n  audio_waveforms:\n((?:    .*\n)+)').firstMatch(lock)?.group(1) ?? '';
    expect(entry, contains('path: "packages/audio_waveforms"'));
    expect(entry, contains('source: path'));
  });

  test('the waveform extractor stops its codec only once', () {
    final file = File('packages/audio_waveforms/android/src/main/kotlin/com/simform/audio_waveforms/WaveformExtractor.kt');
    expect(file.existsSync(), isTrue);
    final src = file.readAsStringSync();
    expect(src.substring(src.indexOf('fun stop()')), contains('if (!isStopped.compareAndSet(false, true)) return'));
  });
}
