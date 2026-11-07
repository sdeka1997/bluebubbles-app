import 'dart:async';

import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/services/isolates/global_isolate.dart';
import 'package:bluebubbles/services/isolates/isolate_event.dart';

/// The main isolate's feed of committed SQLite writes: change sets posted by
/// the other isolates as [IsolateEvent.dbChanged] ([listenTo]) and those of
/// the main isolate's own [Db] ([attachLocal]), in arrival order. Services
/// subscribe to [stream] or [on] and re-read the ids they show.
class DbChangeEvents {
  /// The app's instance on the main isolate.
  static final main = DbChangeEvents();

  final _controller = StreamController<DbChanges>.broadcast();
  final _listeners = <GlobalIsolate, void Function(dynamic)>{};

  Stream<DbChanges> get stream => _controller.stream;

  /// The changed ids of [table], for each change set that touches it.
  Stream<Set<int>> on(String table) =>
      stream.where((c) => c.tables[table]?.isNotEmpty ?? false).map((c) => c.tables[table]!);

  /// Forwards the [IsolateEvent.dbChanged] events of [isolate].
  void listenTo(GlobalIsolate isolate) {
    if (_listeners.containsKey(isolate)) return;
    void listener(dynamic data) {
      final changes = DbChanges.tryFromMap(data);
      if (changes != null) _controller.add(changes);
    }

    _listeners[isolate] = listener;
    isolate.addEventListener(IsolateEvent.dbChanged, listener);
  }

  void stopListening(GlobalIsolate isolate) {
    final listener = _listeners[isolate];
    if (listener == null) return;
    _listeners.removeWhere((key, _) => key == isolate);
    isolate.removeEventListener(IsolateEvent.dbChanged, listener);
  }

  /// Forwards the writes of the main isolate's own [db].
  StreamSubscription<DbChanges> attachLocal(Db db) => db.changes.listen(_controller.add);

  /// On a spawned isolate: posts every committed write of [db] to the main
  /// isolate as [IsolateEvent.dbChanged].
  static StreamSubscription<DbChanges> postFrom(Db db) =>
      db.changes.listen((changes) => IsolateEventEmitter.emit(IsolateEvent.dbChanged, changes.toMap()));
}
