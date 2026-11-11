# audio_waveforms 2.0.2, patched

A copy of [audio_waveforms](https://pub.dev/packages/audio_waveforms) 2.0.2
(`lib/`, `android/`, `ios/`, `pubspec.yaml`, `LICENSE`, unchanged) with one
upstream fix applied: [PR #515](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/pull/515),
which makes `WaveformExtractor.stop()` run once. Without it, disposing a
voice-message player after its waveform finished extracting throws
`IllegalStateException: codec is released already`
([issue #477](https://github.com/SimformSolutionsPvtLtd/audio_waveforms/issues/477)).

Wired in through `dependency_overrides` in the app's `pubspec.yaml`. Delete
this folder and the override once a released version contains PR #515.
