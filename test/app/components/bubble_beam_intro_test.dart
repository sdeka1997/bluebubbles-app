// BubbleBeam opens the way Sleeper does: Android's own splash is plain BubbleBeam blue with no icon,
// then the app plays its intro on that same blue and fades into the chat list.
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
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(onPressed: () => _Probe.taps++, child: const Text('chats')),
    ),
  );
}

Widget _app({bool enabled = true}) => MaterialApp(
  builder: (context, child) => BubbleBeamIntro(enabled: enabled, child: child!),
  home: const _Probe(),
);

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

final _res = Directory('android/app/src/main/res');

void main() {
  setUp(() {
    _Probe.created = 0;
    _Probe.taps = 0;
  });

  testWidgets('plays over the app while it loads, then gets out of the way without rebuilding it', (tester) async {
    await tester.pumpWidget(_app());
    expect(find.byKey(BubbleBeamIntro.overlayKey), findsOneWidget);
    expect(_Probe.created, 1, reason: 'the app builds underneath from the first frame');

    await tester.tap(find.text('chats'), warnIfMissed: false);
    expect(_Probe.taps, 0, reason: 'the intro covers the app while it plays');

    final painter = tester.widget<CustomPaint>(
      find.descendant(of: find.byKey(BubbleBeamIntro.overlayKey), matching: find.byType(CustomPaint)).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    final later = tester.widget<CustomPaint>(
      find.descendant(of: find.byKey(BubbleBeamIntro.overlayKey), matching: find.byType(CustomPaint)).first,
    );
    expect(later.painter!.shouldRepaint(painter.painter!), isTrue, reason: 'it animates');

    await tester.pump(BubbleBeamIntro.duration);
    await tester.pump();
    expect(find.byKey(BubbleBeamIntro.overlayKey), findsNothing);
    expect(_Probe.created, 1, reason: 'removing the intro must not rebuild the app');
    await tester.tap(find.text('chats'));
    expect(_Probe.taps, 1);
  });

  testWidgets('is skipped where it is disabled', (tester) async {
    await tester.pumpWidget(_app(enabled: false));
    expect(find.byKey(BubbleBeamIntro.overlayKey), findsNothing);
    await tester.tap(find.text('chats'));
    expect(_Probe.taps, 1);
  });

  test("Android's splash is the intro's blue, so the hand-off is seamless", () {
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
    final launch = _res
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('launch_background.xml'));
    expect(launch, isNotEmpty);
    for (final f in launch) {
      expect(f.readAsStringSync(), isNot(contains('@drawable/splash')), reason: f.path);
    }
  });

  testWidgets("Android's splash shows no icon", (tester) async {
    final icons = _res
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('/android12splash.png'))
        .toList();
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
