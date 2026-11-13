// BubbleBeam's opening is drawn by Android on its own thread, not by the app's Flutter UI. The app's
// Dart code runs on Android's main thread, so an opening drawn by Flutter stalled whenever startup work
// did: on the phone it dropped to 10-15 frames a second and froze for 0.45 s while duplicate
// conversations merged. Opening.kt draws into its own surface from its own thread instead, so it keeps
// moving however busy startup is. That it stays smooth is checked by screen recording on the phone;
// these tests keep it the same animation as the app's and keep the hand-offs seamless.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bluebubbles/app/components/rising_bubbles.dart';
import 'package:flutter_test/flutter_test.dart';

final _res = Directory('android/app/src/main/res');
const _kotlin = 'android/app/src/main/kotlin/com/bluebubbles/messaging';
String _read(String path) => File(path).readAsStringSync();

/// The colour named [name] in res/values/colors.xml.
String? _colour(String name) => RegExp('<color name="$name">([^<]+)</color>')
    .firstMatch(_read('${_res.path}/values/colors.xml'))
    ?.group(1)
    ?.toUpperCase();

void main() {
  test('Android draws the same bubbles as the app\'s loading animation', () {
    final opening = File('$_kotlin/Opening.kt');
    expect(opening.existsSync(), isTrue);
    final rows = RegExp(r'floatArrayOf\(([^)]*)\)')
        .allMatches(opening.readAsStringSync())
        .map((m) => m.group(1)!.split(',').map((v) => double.parse(v.trim().replaceAll('f', ''))).toList())
        .toList();
    expect(rows, [
      for (final (x, phase, r, sway) in risingBubbles) [x, phase, r, sway]
    ]);
  });

  test('the opening is drawn off the main thread, into its own surface', () {
    final opening = _read('$_kotlin/Opening.kt');
    expect(opening, contains('HandlerThread('));
    expect(opening, contains('lockHardwareCanvas()'));
    expect(opening, contains('setZOrderOnTop(true)'));
    // The bubbles loop at the speed of the app's loading animation.
    expect(RegExp(r'loopMs = (\d+)L').firstMatch(opening)?.group(1), '3000');
    expect(_read('lib/app/components/bubble_beam_loader.dart'), contains('duration: const Duration(seconds: 3)'));
  });

  test('it starts on the launch screen colour and eases into the gradient', () {
    final launch = _colour('opening_launch');
    expect(launch, isNotNull);
    final styles = _res
        .listSync()
        .whereType<Directory>()
        .where((d) => d.path.endsWith('-v31'))
        .map((d) => File('${d.path}/styles.xml'))
        .where((f) => f.existsSync())
        .toList();
    expect(styles, isNotEmpty);
    for (final f in styles) {
      expect(RegExp(r'windowSplashScreenBackground">([^<]+)<').firstMatch(f.readAsStringSync())?.group(1)?.toUpperCase(),
          launch,
          reason: f.path);
    }
    // Before Android 12 the launch screen is a plain colour too.
    final launchBackgrounds =
        _res.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('launch_background.xml'));
    expect(launchBackgrounds, isNotEmpty);
    for (final f in launchBackgrounds) {
      expect(f.readAsStringSync(), contains('android:color="$launch"'), reason: f.path);
    }
    expect(_colour('opening_top'), '#5AAAFE');
    expect(_colour('opening_bottom'), '#1D4ED8');
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

  test('the glass bubble is an Android resource, and Flutter no longer draws an opening', () {
    expect(File('${_res.path}/drawable-nodpi/opening_bubble.png').existsSync(), isTrue);
    expect(File('assets/icon/splash-bubble.png').existsSync(), isFalse);
    expect(_read('pubspec.yaml'), isNot(contains('splash-bubble')));
    expect(File('lib/app/components/bubble_beam_intro.dart').existsSync(), isFalse);
    expect(_read('lib/main.dart'), isNot(contains('BubbleBeamIntro')));
  });

  test('the app ends the opening once the chat list has loaded, and the activity listens for it', () {
    final chats = _read('lib/services/ui/chat/chats_service.dart');
    final loaded = chats.indexOf('loadedAllChats.complete();');
    expect(loaded, isNot(-1));
    expect(chats.indexOf('MethodChannelSvc.actions.endOpening()', loaded), isNot(-1));
    expect(_read('lib/services/network/method_channel_actions.dart'), contains("invokeMethod('opening-done')"));
    expect(_read('$_kotlin/services/backend_ui_interop/MethodCallHandler.kt'),
        contains('"opening-done" -> {'));
    final activity = _read('$_kotlin/MainActivity.kt');
    expect(activity, contains('Opening('));
    // Only on a cold open after setup, as before: not while setting up, nor when Android recreates the screen.
    expect(activity, contains('getBoolean("finishedSetup", false)'));
    expect(activity, contains('savedInstanceState == null'));
  });
}
