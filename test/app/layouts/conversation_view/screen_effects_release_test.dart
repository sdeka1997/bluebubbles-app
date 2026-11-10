// The full-screen effects layer (fireworks, balloons, ...) of a chat screen:
// leaving the chat must release it. It listens to the app-wide event stream,
// and a subscription left open keeps its State, and through its context the
// whole chat screen it sat in, alive after the chat is closed.
import 'dart:developer' show reachabilityBarrier;

import 'package:bluebubbles/app/layouts/conversation_view/widgets/effects/screen_effects_widget.dart';
import 'package:bluebubbles/services/backend_ui_interop/event_dispatcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide EventDispatcher;
import 'package:get_it/get_it.dart';

Future<void> _fullGc() async {
  final start = reachabilityBarrier;
  final junk = <List<int>>[];
  while (reachabilityBarrier < start + 2) {
    junk.add(List<int>.filled(200000, 0));
    if (junk.length > 40) junk.removeAt(0);
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  setUp(() => GetIt.I.registerSingleton<EventDispatcher>(EventDispatcher()));
  tearDown(() => GetIt.I.unregister<EventDispatcher>());

  testWidgets('a closed chat screen\'s effects layer is released', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Stack(children: [Positioned.fill(child: ScreenEffectsWidget())])));
    await tester.pump(); // the controllers are made after the first frame
    final state = WeakReference<State>(tester.state(find.byType(ScreenEffectsWidget)));

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();
    await tester.runAsync(_fullGc);

    expect(state.target, isNull, reason: 'something still holds the effects layer after the chat closed');
  });

  testWidgets('an effect sent after the chat closed does nothing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Stack(children: [Positioned.fill(child: ScreenEffectsWidget())])));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump();

    EventDispatcherSvc.emit('play-effect', {'type': 'confetti', 'size': null});
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
