import 'package:bluebubbles/services/backend/java_dart_interop/method_channel_constants.dart';
import 'package:bluebubbles/services/backend/java_dart_interop/method_channel_handlers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for MethodChannelService without registering any of the app's
/// GetIt singletons, which is exactly the headless DartWorker's situation.
class _FakeDelegate implements MethodChannelServiceDelegate {
  _FakeDelegate({required this.headless});

  @override
  final bool headless;

  @override
  bool shouldIgnoreMessage = false;

  @override
  bool isRunning = false;

  @override
  Uint8List? previousArt;
}

void main() {
  const deleted = MethodChannelInboundMethods.messageDeleted;
  const restored = MethodChannelInboundMethods.messageRestored;

  test('while storage is not usable every push asks for a retry instead of being handled', () async {
    final handlers = MethodChannelHandlers(_FakeDelegate(headless: true));
    addTearDown(() => MethodChannelHandlers.storageUsable = MethodChannelHandlers.alwaysUsable);
    expect(await MethodChannelHandlers.storageUsable(), isTrue, reason: 'by default nothing is gated');

    var asked = 0;
    MethodChannelHandlers.storageUsable = () async {
      asked++;
      return false;
    };
    // An unknown method would otherwise report success and be dropped.
    expect(await handlers.handle(const MethodCall('not-a-method'), const {}), isFalse);
    expect(await handlers.handle(const MethodCall(MethodChannelInboundMethods.messageDeleted), const {'guid': 'g'}), isFalse);
    expect(asked, 2);
  });

  test('chat-deleted requests retry when the payload is absent', () async {
    final handlers = MethodChannelHandlers(_FakeDelegate(headless: true));

    final result = await handlers.handle(const MethodCall('chat-deleted'), null);

    expect(result, isFalse);
  });

  test('chat-read-status-changed in the headless worker does not touch the socket', () async {
    final handlers = MethodChannelHandlers(_FakeDelegate(headless: true));

    // The DartWorker never registers SocketService. A headless call must reach
    // the payload check (retry) instead of throwing on the socket lookup.
    final result = await handlers.handle(const MethodCall('chat-read-status-changed'), null);

    expect(result, isFalse);
  });

  test('both Recently Deleted events are routed to a handler', () {
    final handlers = MethodChannelHandlers(_FakeDelegate(headless: true));

    // An unrouted method silently succeeds, which would drop the event; these
    // must be claimed by a real handler instead.
    expect(handlers.hasHandlerFor(deleted), isTrue);
    expect(handlers.hasHandlerFor(restored), isTrue);
  });

  test('a headless isolate never reads LifecycleService', () {
    // LifecycleService is not registered in the headless DartWorker, so
    // reading it throws "GetIt ... not registered", the push is retried five
    // times and then dropped. headless must short-circuit the check.
    var consulted = false;
    bool isAlive() {
      consulted = true;
      throw StateError('GetIt: Object/factory with type LifecycleService is not registered');
    }

    expect(MethodChannelHandlers.shouldApplyInBackground(true, isAlive), isTrue);
    expect(consulted, isFalse);
  });

  test('a live UI leaves the event to the socket path', () {
    expect(MethodChannelHandlers.shouldApplyInBackground(false, () => true), isFalse);
  });

  test('an unloaded UI applies the change from the push', () {
    expect(MethodChannelHandlers.shouldApplyInBackground(false, () => false), isTrue);
  });

  test('the handler map routes both events to the same handler', () {
    final headless = MethodChannelHandlers(_FakeDelegate(headless: true));
    final foreground = MethodChannelHandlers(_FakeDelegate(headless: false));

    for (final handlers in [headless, foreground]) {
      expect(handlers.hasHandlerFor(deleted), isTrue);
      expect(handlers.hasHandlerFor(restored), isTrue);
    }
  });

  test('an unknown method is not claimed', () {
    final handlers = MethodChannelHandlers(_FakeDelegate(headless: true));

    expect(handlers.hasHandlerFor('message-shredded'), isFalse);
  });

  test('an unrouted method still reports success so it is not retried forever', () async {
    final handlers = MethodChannelHandlers(_FakeDelegate(headless: true));

    expect(await handlers.handle(const MethodCall('message-shredded'), null), isTrue);
  });
}
