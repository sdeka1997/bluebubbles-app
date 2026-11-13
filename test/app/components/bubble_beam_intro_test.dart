// BubbleBeam opens on plain BubbleBeam blue (Android's own launch screen, no icon), then the app
// plays its loading animation on that blue (the glass message bubble with bubbles rising) until
// the chat list is ready, and fades into it.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bluebubbles/app/components/bubble_beam_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Probe extends StatefulWidget {
  const _Probe();

  static int created = 0;
  static int taps = 0;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    _Probe.created++;
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: TextButton(onPressed: () => _Probe.taps++, child: const Text('chats'))));
}

Widget _app({bool enabled = true, Future<void>? ready}) => MaterialApp(
      builder: (context, child) => BubbleBeamIntro(enabled: enabled, ready: ready, child: child!),
      home: const _Probe(),
    );

final _overlay = find.byKey(BubbleBeamIntro.overlayKey);

/// Steps time forward a frame at a time, as the phone would, so the fade can run.
Future<void> _run(WidgetTester tester, Duration d) async {
  for (var t = Duration.zero; t < d; t += const Duration(milliseconds: 50)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

final _res = Directory('android/app/src/main/res');

void main() {
  setUp(() {
    _Probe.created = 0;
    _Probe.taps = 0;
  });

  testWidgets('plays over the app until the chats are ready, then fades away without rebuilding it', (tester) async {
    final ready = Completer<void>();
    await tester.pumpWidget(_app(ready: ready.future));
    expect(_overlay, findsOneWidget);
    expect(_Probe.created, 1, reason: 'the app builds underneath from the first frame');

    final bubble = tester.widget<Image>(find.descendant(of: _overlay, matching: find.byType(Image)));
    expect((bubble.image as AssetImage).assetName, 'assets/icon/splash-bubble.png');

    await tester.tap(find.text('chats'), warnIfMissed: false);
    expect(_Probe.taps, 0, reason: 'the animation covers the app while it plays');

    CustomPainter painter() =>
        tester.widget<CustomPaint>(find.descendant(of: _overlay, matching: find.byType(CustomPaint)).first).painter!;
    final before = painter();
    await tester.pump(const Duration(milliseconds: 300));
    expect(painter().shouldRepaint(before), isTrue, reason: 'the bubbles keep rising');

    await tester.pump(BubbleBeamIntro.minimum * 2);
    expect(_overlay, findsOneWidget, reason: 'still waiting for the chats');

    ready.complete();
    await _run(tester, BubbleBeamIntro.fade * 2);
    expect(_overlay, findsNothing);
    expect(_Probe.created, 1, reason: 'removing the animation must not rebuild the app');
    await tester.tap(find.text('chats'));
    expect(_Probe.taps, 1);
  });

  testWidgets('stays at least the minimum even when the chats are already there', (tester) async {
    await tester.pumpWidget(_app(ready: Future.value()));
    await tester.pump(BubbleBeamIntro.minimum - const Duration(milliseconds: 100));
    expect(_overlay, findsOneWidget);
    await _run(tester, const Duration(milliseconds: 200) + BubbleBeamIntro.fade * 2);
    expect(_overlay, findsNothing);
  });

  testWidgets('stops waiting after the maximum', (tester) async {
    await tester.pumpWidget(_app(ready: Completer<void>().future));
    await _run(tester, BubbleBeamIntro.maximum + BubbleBeamIntro.fade * 2);
    expect(_overlay, findsNothing);
  });

  testWidgets('is skipped where it is disabled', (tester) async {
    await tester.pumpWidget(_app(enabled: false));
    expect(_overlay, findsNothing);
    await tester.tap(find.text('chats'));
    expect(_Probe.taps, 1);
  });

  test("Android's launch screen is the animation's blue, so the hand-off is seamless", () {
    final styles = _res
        .listSync()
        .whereType<Directory>()
        .where((d) => d.path.endsWith('-v31'))
        .map((d) => File('${d.path}/styles.xml'))
        .where((f) => f.existsSync())
        .toList();
    expect(styles, isNotEmpty);
    for (final f in styles) {
      final colour = RegExp(r'windowSplashScreenBackground">([^<]+)<').firstMatch(f.readAsStringSync())?.group(1);
      expect(colour?.toUpperCase(), _hex(BubbleBeamIntro.background), reason: f.path);
    }
    // Before Android 12 the launch screen is a plain colour too.
    final launch = _res.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('launch_background.xml'));
    expect(launch, isNotEmpty);
    for (final f in launch) {
      expect(f.readAsStringSync(), contains('android:color="${_hex(BubbleBeamIntro.background)}"'), reason: f.path);
    }
  });

  testWidgets("Android's launch screen shows no icon", (tester) async {
    final icons = _res.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('/android12splash.png')).toList();
    expect(icons, isNotEmpty);
    await tester.runAsync(() async {
      for (final f in icons) {
        final image = (await (await ui.instantiateImageCodec(f.readAsBytesSync())).getNextFrame()).image;
        final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
        expect([for (var i = 3; i < rgba.length; i += 4) rgba[i]].every((a) => a == 0), isTrue, reason: f.path);
      }
    });
  });
}
