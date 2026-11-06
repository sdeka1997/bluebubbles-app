import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:get_it/get_it.dart';

/// Starts Find My on the Mac when the app connects in the foreground, so the
/// map, if it opens soon after, finds it already running instead of waiting
/// for it to launch. The server keeps it a minute, following nobody, and quits
/// it if no map opens. Servers without this event ignore it.
class FindMyWarmup {
  FindMyWarmup({required bool Function() foreground, required Future<void> Function() send})
      : _foreground = foreground,
        _send = send;

  final bool Function() _foreground;
  final Future<void> Function() _send;

  static final FindMyWarmup instance = FindMyWarmup(
    foreground: () => GetIt.I.isRegistered<LifecycleService>() && LifecycleSvc.isForeground,
    send: () => SocketSvc.sendMessage('findmy-warm', {}),
  );

  /// The socket connected; reconnecting after time in the background counts too.
  void onConnected() {
    if (!_foreground()) return;
    _send().then(
      (_) {},
      onError: (Object e) => Logger.info("Find My warm-up not delivered: $e"),
    );
  }
}
