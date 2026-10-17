import 'dart:async';
import 'dart:convert';
import 'dart:math';

const _schemaVersion = 2;

enum RecoverableDeletePhase { submitted, accepted }

enum RecoverableDeleteOutcome { deleted, definitiveFailure, pendingConfirmation }

enum RecoverableDeleteReceiptState { pending, succeeded, definitiveFailure }

class RecoverableDeleteEntry {
  const RecoverableDeleteEntry({required this.attemptId, required this.startedAt, required this.phase});
  final String attemptId;
  final DateTime startedAt;
  final RecoverableDeletePhase phase;

  @override
  bool operator ==(Object other) =>
      other is RecoverableDeleteEntry &&
      other.attemptId == attemptId &&
      other.startedAt == startedAt &&
      other.phase == phase;
  @override
  int get hashCode => Object.hash(attemptId, startedAt, phase);
}

typedef JournalRead = String? Function();
typedef JournalWrite = Future<dynamic> Function(String value);

class _DecodedJournal {
  const _DecodedJournal(this.state, {this.needsSanitizedRewrite = false});
  final Map<String, Map<String, RecoverableDeleteEntry>> state;
  final bool needsSanitizedRewrite;
}

class RecoverableDeleteRepository {
  RecoverableDeleteRepository({required this.readRaw, required this.writeRaw, this.onMalformed});

  static final Map<String, RecoverableDeleteRepository> _owners = {};

  static RecoverableDeleteRepository ownerForKey(
    String preferencesKey, {
    required JournalRead readRaw,
    required JournalWrite writeRaw,
    void Function(Object error, StackTrace trace)? onMalformed,
  }) => _owners.putIfAbsent(
    preferencesKey,
    () => RecoverableDeleteRepository(readRaw: readRaw, writeRaw: writeRaw, onMalformed: onMalformed),
  );

  static void resetOwnersForTesting() => _owners.clear();

  final JournalRead readRaw;
  final JournalWrite writeRaw;
  final void Function(Object error, StackTrace trace)? onMalformed;
  final Map<String, RecoverableDeleteCoordinator> _views = {};
  final Map<String, Future<void>> _chatTails = {};
  Map<String, Map<String, RecoverableDeleteEntry>> _canonical = {};
  Future<void> _transactionTail = Future<void>.value();
  Future<void>? _loadFuture;
  bool degraded = false;

  RecoverableDeleteCoordinator viewForServer(String serverAddress) =>
      _views.putIfAbsent(serverAddress, () => RecoverableDeleteCoordinator._(this, serverAddress));

  Future<void> ensureLoaded() => _loadFuture ??= _load();

  Future<void> _load() async {
    String? raw;
    try {
      raw = readRaw();
      final decoded = _decode(raw);
      _canonical = decoded.state;
      if (decoded.needsSanitizedRewrite) {
        try {
          final persisted = await writeRaw(_encode(_canonical));
          if (!persisted) throw StateError('recoverable-delete sanitized rewrite returned false');
        } catch (error, trace) {
          degraded = true;
          onMalformed?.call(error, trace);
        }
      }
    } catch (error, trace) {
      degraded = true;
      _canonical = {};
      onMalformed?.call(error, trace);
    }
  }

  _DecodedJournal _decode(String? raw) {
    if (raw == null) return const _DecodedJournal({});
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['schemaVersion'] != _schemaVersion || decoded['servers'] is! Map) {
      throw const FormatException('malformed recoverable-delete document');
    }
    final result = <String, Map<String, RecoverableDeleteEntry>>{};
    var needsSanitizedRewrite = false;
    for (final server in (decoded['servers'] as Map).entries) {
      if (server.key is! String || (server.key as String).isEmpty || server.value is! Map) {
        needsSanitizedRewrite = true;
        onMalformed?.call(const FormatException('malformed recoverable-delete server bucket'), StackTrace.current);
        continue;
      }
      final valid = <String, RecoverableDeleteEntry>{};
      for (final chat in (server.value as Map).entries) {
        try {
          if (chat.key is! String || (chat.key as String).isEmpty || chat.value is! Map) continue;
          final value = chat.value as Map;
          final attemptId = value['attemptId'];
          final startedAt = value['startedAt'];
          final phaseName = value['phase'];
          if (attemptId is! String || attemptId.isEmpty || startedAt is! int || startedAt < 0 || phaseName is! String) {
            needsSanitizedRewrite = true;
            onMalformed?.call(const FormatException('malformed recoverable-delete entry'), StackTrace.current);
            continue;
          }
          final phase = switch (phaseName) {
            'submitted' => RecoverableDeletePhase.submitted,
            'accepted' => RecoverableDeletePhase.accepted,
            _ => throw const FormatException('unknown phase'),
          };
          valid[chat.key as String] = RecoverableDeleteEntry(
            attemptId: attemptId,
            startedAt: DateTime.fromMillisecondsSinceEpoch(startedAt, isUtc: true),
            phase: phase,
          );
        } catch (error, trace) {
          needsSanitizedRewrite = true;
          onMalformed?.call(error, trace);
        }
      }
      if (valid.isNotEmpty) result[server.key as String] = valid;
    }
    return _DecodedJournal(result, needsSanitizedRewrite: needsSanitizedRewrite);
  }

  String _encode(Map<String, Map<String, RecoverableDeleteEntry>> state) {
    final servers = <String, dynamic>{};
    for (final server in (state.keys.toList()..sort())) {
      final bucket = state[server]!;
      if (bucket.isEmpty) continue;
      final encoded = <String, dynamic>{};
      for (final guid in (bucket.keys.toList()..sort())) {
        final entry = bucket[guid]!;
        encoded[guid] = {
          'attemptId': entry.attemptId,
          'startedAt': entry.startedAt.toUtc().millisecondsSinceEpoch,
          'phase': entry.phase.name,
        };
      }
      servers[server] = encoded;
    }
    return jsonEncode({'schemaVersion': _schemaVersion, 'servers': servers});
  }

  Map<String, Map<String, RecoverableDeleteEntry>> _clone() => {
    for (final server in _canonical.entries) server.key: Map<String, RecoverableDeleteEntry>.from(server.value),
  };

  Future<T> transaction<T>(T Function(Map<String, Map<String, RecoverableDeleteEntry>>) mutation) {
    final completer = Completer<T>();
    _transactionTail = _transactionTail.then((_) async {
      try {
        await ensureLoaded();
        if (degraded) throw StateError('recoverable-delete storage is degraded');
        final next = _clone();
        final result = mutation(next);
        final persisted = await writeRaw(_encode(next));
        if (!persisted) throw StateError('recoverable-delete persistence returned false');
        _canonical = next;
        completer.complete(result);
      } catch (error, trace) {
        completer.completeError(error, trace);
      }
    });
    return completer.future;
  }

  RecoverableDeleteEntry? entry(String server, String guid) => _canonical[server]?[guid];
  Set<String> suppressed(String server) => Set.unmodifiable(_canonical[server]?.keys ?? const <String>{});

  Future<T> withChatLock<T>(String server, String guid, Future<T> Function() action) async {
    final key = '$server\u0000$guid';
    final previous = _chatTails[key] ?? Future<void>.value();
    final done = Completer<void>();
    final queued = previous.then((_) => done.future);
    _chatTails[key] = queued;
    await previous;
    try {
      return await action();
    } finally {
      done.complete();
      if (identical(_chatTails[key], queued)) _chatTails.remove(key);
    }
  }
}

class RecoverableDeleteCoordinator {
  RecoverableDeleteCoordinator._(this.repository, this.serverAddress);
  final RecoverableDeleteRepository repository;
  final String serverAddress;

  bool isSuppressed(String guid) => repository.entry(serverAddress, guid) != null;
  bool shouldAddChat(String guid) => !isSuppressed(guid);
  List<String> visibleGuids(Iterable<String> guids) => guids.where(shouldAddChat).toList();

  Future<void> recordSubmitted(String guid, {required String attemptId, DateTime? now}) async {
    await repository.ensureLoaded();
    await repository.transaction((state) {
      (state[serverAddress] ??= {})[guid] = RecoverableDeleteEntry(
        attemptId: attemptId,
        startedAt: (now ?? DateTime.now().toUtc()).toUtc(),
        phase: RecoverableDeletePhase.submitted,
      );
    });
  }

  Future<void> _recordAccepted(String guid, String attemptId) => repository.transaction((state) {
    final current = state[serverAddress]?[guid];
    if (current == null || current.attemptId != attemptId) throw StateError('delete claim changed');
    state[serverAddress]![guid] = RecoverableDeleteEntry(
      attemptId: attemptId,
      startedAt: current.startedAt,
      phase: RecoverableDeletePhase.accepted,
    );
  });

  Future<void> _clear(String guid, String attemptId) => repository.transaction((state) {
    final current = state[serverAddress]?[guid];
    if (current?.attemptId != attemptId) return;
    state[serverAddress]!.remove(guid);
    if (state[serverAddress]!.isEmpty) state.remove(serverAddress);
  });

  Future<void> hydrate({
    required Future<RecoverableDeleteReceiptState> Function(String guid, String attemptId) status,
    required Future<void> Function(String guid) finishAccepted,
    void Function(String guid, Object error, StackTrace trace)? acceptedFailure,
  }) async {
    await repository.ensureLoaded();
    for (final guid in repository.suppressed(serverAddress).toList()) {
      try {
        await repository.withChatLock(serverAddress, guid, () async {
          var claim = repository.entry(serverAddress, guid);
          if (claim == null) return;
          if (claim.phase == RecoverableDeletePhase.submitted) {
            final receipt = await status(guid, claim.attemptId);
            if (receipt == RecoverableDeleteReceiptState.pending) return;
            if (receipt == RecoverableDeleteReceiptState.definitiveFailure) {
              await _clear(guid, claim.attemptId);
              return;
            }
            await _recordAccepted(guid, claim.attemptId);
            claim = repository.entry(serverAddress, guid);
          }
          if (claim?.phase == RecoverableDeletePhase.accepted) {
            await finishAccepted(guid);
            await _clear(guid, claim!.attemptId);
          }
        });
      } catch (error, trace) {
        acceptedFailure?.call(guid, error, trace);
      }
    }
  }

  static String _newAttemptId() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(24, (_) => random.nextInt(256))).replaceAll('=', '');
  }

  Future<RecoverableDeleteOutcome> delete(
    String guid, {
    required DateTime now,
    required Future<RecoverableDeleteReceiptState> Function(String attemptId) submit,
    required Future<RecoverableDeleteReceiptState> Function(String attemptId) status,
    required Future<void> Function() localDelete,
    required void Function(bool pending) pendingChanged,
    bool Function(Object error)? isDefinitiveFailure,
    void Function(Object error, StackTrace trace)? definitiveFailure,
    void Function(Object error, StackTrace trace)? pendingConfirmation,
  }) => repository.withChatLock(serverAddress, guid, () async {
    await repository.ensureLoaded();
    if (repository.degraded) throw StateError('recoverable-delete storage is degraded');
    if (repository.entry(serverAddress, guid) != null) {
      pendingConfirmation?.call(StateError('recoverable deletion is already pending'), StackTrace.current);
      return RecoverableDeleteOutcome.pendingConfirmation;
    }
    final attemptId = _newAttemptId();
    await recordSubmitted(guid, attemptId: attemptId, now: now);
    pendingChanged(true);
    try {
      RecoverableDeleteReceiptState receipt;
      try {
        receipt = await submit(attemptId);
      } catch (error, trace) {
        if (isDefinitiveFailure?.call(error) ?? false) {
          await _clear(guid, attemptId);
          definitiveFailure?.call(error, trace);
          return RecoverableDeleteOutcome.definitiveFailure;
        }
        try {
          receipt = await status(attemptId);
        } catch (_) {
          pendingConfirmation?.call(error, trace);
          return RecoverableDeleteOutcome.pendingConfirmation;
        }
      }
      if (receipt == RecoverableDeleteReceiptState.pending) {
        pendingConfirmation?.call(StateError('server receipt is pending'), StackTrace.current);
        return RecoverableDeleteOutcome.pendingConfirmation;
      }
      if (receipt == RecoverableDeleteReceiptState.definitiveFailure) {
        await _clear(guid, attemptId);
        definitiveFailure?.call(StateError('server reported definitive failure'), StackTrace.current);
        return RecoverableDeleteOutcome.definitiveFailure;
      }
      await _recordAccepted(guid, attemptId);
      await localDelete();
      await _clear(guid, attemptId);
      return RecoverableDeleteOutcome.deleted;
    } catch (error, trace) {
      pendingConfirmation?.call(error, trace);
      return RecoverableDeleteOutcome.pendingConfirmation;
    } finally {
      pendingChanged(false);
    }
  });

  Future<Set<String>> resolveSnapshot({
    required Map<String, int> messageCounts,
    required DateTime now,
    required bool Function(String guid) hasLocalWork,
    required Future<void> Function(String guid) softDelete,
    required Future<void> Function(String guid) deferDeletion,
    required Future<void> Function(String guid) restore,
  }) async {
    await repository.ensureLoaded();
    final protected = repository.suppressed(serverAddress);
    for (final guid in protected.toList()) {
      await repository.withChatLock(serverAddress, guid, () async {
        final claim = repository.entry(serverAddress, guid);
        if (claim == null || claim.phase == RecoverableDeletePhase.submitted) return;
        if (hasLocalWork(guid)) {
          await deferDeletion(guid);
          await restore(guid);
        } else {
          await softDelete(guid);
        }
        await _clear(guid, claim.attemptId);
      });
    }
    return protected;
  }
}
