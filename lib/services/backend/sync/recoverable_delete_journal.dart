import 'dart:async';
import 'dart:convert';

/// A submitted delete is hidden for at most one conservative full-sync window.
/// The app normally receives a complete snapshot much sooner; ten minutes bounds
/// visibility loss when snapshots fail without risking an unsafe POST retry.
const recoverableDeleteSubmittedExpiry = Duration(minutes: 10);

enum RecoverableDeletePhase { submitted, accepted }

class RecoverableDeleteEntry {
  const RecoverableDeleteEntry({required this.startedAt, required this.phase});

  final DateTime startedAt;
  final RecoverableDeletePhase phase;

  @override
  bool operator ==(Object other) =>
      other is RecoverableDeleteEntry && other.startedAt == startedAt && other.phase == phase;

  @override
  int get hashCode => Object.hash(startedAt, phase);
}

class RecoverableDeleteJournalLoad {
  const RecoverableDeleteJournalLoad({
    required this.entries,
    this.expiredSubmittedGuids = const {},
    this.wasMalformed = false,
  });

  final Map<String, RecoverableDeleteEntry> entries;
  final Set<String> expiredSubmittedGuids;
  final bool wasMalformed;
}

typedef JournalRead = String? Function();
typedef JournalWrite = Future<void> Function(String value);

/// Strict, server-scoped persistence for recoverable chat deletion attempts.
/// Any malformed field invalidates the whole journal so corrupt state can never
/// hide a conversation.
class RecoverableDeleteJournal {
  RecoverableDeleteJournal({
    required this.serverAddress,
    required this.readRaw,
    required this.writeRaw,
    this.onMalformed,
  });

  final String serverAddress;
  final JournalRead readRaw;
  final JournalWrite writeRaw;
  final void Function(Object error, StackTrace trace)? onMalformed;

  static Future<void> _writeTail = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _writeTail = _writeTail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, trace) {
        completer.completeError(error, trace);
      }
    });
    return completer.future;
  }

  Map<String, Map<String, RecoverableDeleteEntry>> _decode(String? raw) {
    if (raw == null) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded.length != 2 || decoded['schemaVersion'] != 1 || decoded['servers'] is! Map) {
      throw const FormatException('malformed recoverable-delete journal');
    }
    final result = <String, Map<String, RecoverableDeleteEntry>>{};
    for (final serverItem in (decoded['servers'] as Map).entries) {
      if (serverItem.key is! String || (serverItem.key as String).isEmpty || serverItem.value is! Map) {
        throw const FormatException('malformed recoverable-delete server');
      }
      final entries = <String, RecoverableDeleteEntry>{};
      for (final chatItem in (serverItem.value as Map).entries) {
        final guid = chatItem.key;
        final value = chatItem.value;
        if (guid is! String || guid.isEmpty || value is! Map || value.length != 2) {
          throw const FormatException('malformed recoverable-delete entry');
        }
        final startedAt = value['startedAt'];
        final phaseName = value['phase'];
        if (startedAt is! int || startedAt < 0 || phaseName is! String) {
          throw const FormatException('malformed recoverable-delete fields');
        }
        final phase = switch (phaseName) {
          'submitted' => RecoverableDeletePhase.submitted,
          'accepted' => RecoverableDeletePhase.accepted,
          _ => throw const FormatException('unknown recoverable-delete phase'),
        };
        entries[guid] = RecoverableDeleteEntry(
          startedAt: DateTime.fromMillisecondsSinceEpoch(startedAt, isUtc: true),
          phase: phase,
        );
      }
      result[serverItem.key as String] = entries;
    }
    return result;
  }

  String _encode(Map<String, Map<String, RecoverableDeleteEntry>> byServer) {
    final servers = <String, dynamic>{};
    final serverNames = byServer.keys.toList()..sort();
    for (final server in serverNames) {
      final entries = byServer[server]!;
      if (entries.isEmpty) continue;
      final encodedEntries = <String, dynamic>{};
      final guids = entries.keys.toList()..sort();
      for (final guid in guids) {
        final entry = entries[guid]!;
        encodedEntries[guid] = {'startedAt': entry.startedAt.toUtc().millisecondsSinceEpoch, 'phase': entry.phase.name};
      }
      servers[server] = encodedEntries;
    }
    return jsonEncode({'schemaVersion': 1, 'servers': servers});
  }

  Future<RecoverableDeleteJournalLoad> load({DateTime? now}) => _serialized(() async {
    Map<String, Map<String, RecoverableDeleteEntry>> byServer;
    try {
      byServer = _decode(readRaw());
    } catch (error, trace) {
      onMalformed?.call(error, trace);
      await writeRaw(_encode({}));
      return const RecoverableDeleteJournalLoad(entries: {}, wasMalformed: true);
    }

    final current = Map<String, RecoverableDeleteEntry>.from(byServer[serverAddress] ?? const {});
    final expiryNow = (now ?? DateTime.now().toUtc()).toUtc();
    final expired = current.entries
        .where(
          (item) =>
              item.value.phase == RecoverableDeletePhase.submitted &&
              !item.value.startedAt.add(recoverableDeleteSubmittedExpiry).isAfter(expiryNow),
        )
        .map((item) => item.key)
        .toSet();
    if (expired.isNotEmpty) {
      current.removeWhere((guid, _) => expired.contains(guid));
      if (current.isEmpty) {
        byServer.remove(serverAddress);
      } else {
        byServer[serverAddress] = current;
      }
      await writeRaw(_encode(byServer));
    }
    return RecoverableDeleteJournalLoad(entries: Map.unmodifiable(current), expiredSubmittedGuids: expired);
  });

  Future<void> recordSubmitted(String guid, {DateTime? now}) => _mutate((entries) {
    entries[guid] = RecoverableDeleteEntry(
      startedAt: (now ?? DateTime.now().toUtc()).toUtc(),
      phase: RecoverableDeletePhase.submitted,
    );
  });

  Future<void> recordAccepted(String guid) => _mutate((entries) {
    final existing = entries[guid];
    if (existing == null) throw StateError('cannot accept a delete that was not submitted');
    entries[guid] = RecoverableDeleteEntry(startedAt: existing.startedAt, phase: RecoverableDeletePhase.accepted);
  });

  Future<void> clear(String guid) => _mutate((entries) => entries.remove(guid));

  Future<void> _mutate(void Function(Map<String, RecoverableDeleteEntry> entries) mutation) => _serialized(() async {
    final byServer = _decode(readRaw());
    final entries = Map<String, RecoverableDeleteEntry>.from(byServer[serverAddress] ?? const {});
    mutation(entries);
    if (entries.isEmpty) {
      byServer.remove(serverAddress);
    } else {
      byServer[serverAddress] = entries;
    }
    await writeRaw(_encode(byServer));
  });
}

class RecoverableDeleteCoordinator {
  RecoverableDeleteCoordinator(this.journal);

  final RecoverableDeleteJournal journal;
  final Set<String> _suppressedGuids = {};

  bool isSuppressed(String guid) => _suppressedGuids.contains(guid);
  bool shouldAddChat(String guid) => !isSuppressed(guid);
  List<String> visibleGuids(Iterable<String> guids) => guids.where(shouldAddChat).toList();

  Future<RecoverableDeleteJournalLoad> hydrate({
    DateTime? now,
    Future<void> Function(String guid)? finishAccepted,
  }) async {
    final loaded = await journal.load(now: now);
    _suppressedGuids
      ..clear()
      ..addAll(loaded.entries.keys);
    if (finishAccepted != null) {
      for (final item in loaded.entries.entries) {
        if (item.value.phase != RecoverableDeletePhase.accepted) continue;
        await finishAccepted(item.key);
        await journal.clear(item.key);
        _suppressedGuids.remove(item.key);
      }
    }
    return loaded;
  }

  Future<bool> delete(
    String guid, {
    required DateTime now,
    required Future<void> Function() submit,
    required Future<void> Function() localDelete,
    required void Function(bool pending) pendingChanged,
    bool Function(Object error)? isDefinitiveFailure,
    void Function(Object error, StackTrace trace)? definitiveFailure,
  }) async {
    if (_suppressedGuids.contains(guid)) return false;
    await journal.recordSubmitted(guid, now: now);
    _suppressedGuids.add(guid);
    pendingChanged(true);
    try {
      try {
        await submit();
      } catch (error, trace) {
        if (isDefinitiveFailure?.call(error) ?? true) {
          await journal.clear(guid);
          _suppressedGuids.remove(guid);
          definitiveFailure?.call(error, trace);
          return false;
        }
        rethrow;
      }
      await journal.recordAccepted(guid);
      await localDelete();
      await journal.clear(guid);
      _suppressedGuids.remove(guid);
      return true;
    } finally {
      pendingChanged(false);
    }
  }

  Future<Set<String>> resolveSnapshot({
    required Map<String, int> messageCounts,
    required DateTime now,
    required bool Function(String guid) hasLocalWork,
    required Future<void> Function(String guid) softDelete,
    required Future<void> Function(String guid) deferDeletion,
    required Future<void> Function(String guid) restore,
  }) async {
    final loaded = await journal.load(now: now);
    final journaledGuids = loaded.entries.keys.toSet();

    for (final guid in loaded.expiredSubmittedGuids) {
      _suppressedGuids.remove(guid);
      await restore(guid);
    }

    _suppressedGuids.addAll(loaded.entries.keys);
    for (final guid in loaded.entries.keys) {
      final count = messageCounts[guid];
      final deletionConfirmed = count == null || count == 0;
      if (deletionConfirmed) {
        if (hasLocalWork(guid)) {
          await deferDeletion(guid);
          _suppressedGuids.remove(guid);
          await restore(guid);
        } else {
          await softDelete(guid);
          _suppressedGuids.remove(guid);
        }
      } else {
        _suppressedGuids.remove(guid);
        await restore(guid);
      }
      await journal.clear(guid);
    }
    return journaledGuids;
  }
}
