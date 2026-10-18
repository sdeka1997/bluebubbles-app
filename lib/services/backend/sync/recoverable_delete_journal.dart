import 'dart:convert';

import 'package:bluebubbles/services/backend/settings/actions/shared_preferences_database_actions.dart';
import 'package:bluebubbles/services/backend/settings/shared_preferences_service.dart';
import 'package:crypto/crypto.dart';
import 'package:synchronized/synchronized.dart';

const String recoverableDeleteAttemptIdPattern = r'^[A-Za-z0-9_-]{16,128}$';
final RegExp _attemptIdRegExp = RegExp(recoverableDeleteAttemptIdPattern);

enum RecoverableDeleteJournalPhase { submitted, accepted }

enum RecoverableDeleteJournalState { unhydrated, ready, degraded }

class RecoverableDeleteJournalEntry {
  const RecoverableDeleteJournalEntry({
    required this.serverIdentity,
    required this.chatGuid,
    required this.attemptId,
    required this.startedAt,
    required this.phase,
  });

  final String serverIdentity;
  final String chatGuid;
  final String attemptId;
  final DateTime startedAt;
  final RecoverableDeleteJournalPhase phase;

  Map<String, Object> toJson() => <String, Object>{
    // The raw server identity and GUID are required recovery data: Stage 3 must
    // select the server and call both it and the local database after restart.
    // They are values, never JSON keys or log fields.
    'serverIdentity': serverIdentity,
    'chatGuid': chatGuid,
    'attemptId': attemptId,
    'startedAt': startedAt.millisecondsSinceEpoch,
    'phase': phase.name,
  };

  RecoverableDeleteJournalEntry copyWith({RecoverableDeleteJournalPhase? phase}) => RecoverableDeleteJournalEntry(
    serverIdentity: serverIdentity,
    chatGuid: chatGuid,
    attemptId: attemptId,
    startedAt: startedAt,
    phase: phase ?? this.phase,
  );
}

abstract interface class RecoverableDeleteJournalStore {
  String? read();
  Future<void> write(String value);
}

class SharedPreferencesDeleteJournalStore implements RecoverableDeleteJournalStore {
  SharedPreferencesDeleteJournalStore(this._actions);

  final SharedPreferencesDatabaseActions _actions;

  @override
  String? read() => _actions.getRecoverableDeleteJournal();

  @override
  Future<void> write(String value) => _actions.setRecoverableDeleteJournal(value);
}

class RecoverableDeleteJournalServerView {
  RecoverableDeleteJournalServerView._(this._owner, this.serverIdentity);

  final RecoverableDeleteJournal _owner;
  final String serverIdentity;

  RecoverableDeleteJournalEntry? lookup(String chatGuid) => _owner.lookup(serverIdentity, chatGuid);
  bool isSuppressed(String chatGuid) => _owner.isSuppressed(serverIdentity, chatGuid);
  List<RecoverableDeleteJournalEntry> listUnresolved() => _owner.listUnresolved(serverIdentity: serverIdentity);
  Lock chatLock(String chatGuid) => _owner.chatLock(serverIdentity, chatGuid);
}

class RecoverableDeleteJournal {
  RecoverableDeleteJournal._(this._store);

  static RecoverableDeleteJournal? _instance;

  factory RecoverableDeleteJournal() =>
      _instance ??= RecoverableDeleteJournal._(SharedPreferencesDeleteJournalStore(PrefsSvc.database));

  factory RecoverableDeleteJournal.testing(RecoverableDeleteJournalStore store) => RecoverableDeleteJournal._(store);

  final RecoverableDeleteJournalStore _store;
  Map<String, Map<String, RecoverableDeleteJournalEntry>> _entries =
      <String, Map<String, RecoverableDeleteJournalEntry>>{};
  Map<String, dynamic> _preservedDocument = <String, dynamic>{'version': 1, 'servers': <String, dynamic>{}};
  Future<void> _mutationTail = Future<void>.value();
  Future<void>? _hydration;
  final Map<String, RecoverableDeleteJournalServerView> _serverViews = <String, RecoverableDeleteJournalServerView>{};
  final Map<String, Lock> _chatLocks = <String, Lock>{};

  RecoverableDeleteJournalState _state = RecoverableDeleteJournalState.unhydrated;
  RecoverableDeleteJournalState get state => _state;

  Future<void> hydrate() => _hydration ??= _hydrate();

  Future<void> _hydrate() async {
    final raw = _store.read();
    if (raw == null) {
      _state = RecoverableDeleteJournalState.ready;
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded['version'] != 1 || decoded['servers'] is! Map) {
        throw const FormatException('Unsupported recoverable delete journal');
      }
      final hydrated = <String, Map<String, RecoverableDeleteJournalEntry>>{};
      final quarantinedServers = <String, dynamic>{};
      for (final server in (decoded['servers'] as Map).entries) {
        if (server.key is! String) continue;
        if (server.value is! Map) {
          quarantinedServers[server.key as String] = server.value;
          continue;
        }
        final bucket = <String, RecoverableDeleteJournalEntry>{};
        final quarantinedBucket = <String, dynamic>{};
        for (final chat in (server.value as Map).entries) {
          var parsed = false;
          if (chat.key is String && chat.value is Map) {
            try {
              final value = Map<String, dynamic>.from(chat.value as Map);
              final identity = value['serverIdentity'];
              final guid = value['chatGuid'];
              final attemptId = value['attemptId'];
              final startedAt = value['startedAt'];
              final phase = value['phase'];
              if (identity is String &&
                  guid is String &&
                  attemptId is String &&
                  _attemptIdRegExp.hasMatch(attemptId) &&
                  startedAt is int &&
                  (phase == 'submitted' || phase == 'accepted') &&
                  server.key == _opaqueKey(identity) &&
                  chat.key == _opaqueKey(guid)) {
                bucket[chat.key as String] = RecoverableDeleteJournalEntry(
                  serverIdentity: identity,
                  chatGuid: guid,
                  attemptId: attemptId,
                  startedAt: DateTime.fromMillisecondsSinceEpoch(startedAt),
                  phase: phase == 'submitted'
                      ? RecoverableDeleteJournalPhase.submitted
                      : RecoverableDeleteJournalPhase.accepted,
                );
                parsed = true;
              }
            } on Object {
              // Preserve this malformed entry below without exposing it as a claim.
            }
          }
          if (!parsed && chat.key is String) {
            quarantinedBucket[chat.key as String] = chat.value;
          }
        }
        if (bucket.isNotEmpty) hydrated[server.key as String] = bucket;
        if (quarantinedBucket.isNotEmpty) {
          quarantinedServers[server.key as String] = quarantinedBucket;
        }
      }
      _preservedDocument = Map<String, dynamic>.from(decoded)..['servers'] = quarantinedServers;
      _entries = hydrated;
      _state = RecoverableDeleteJournalState.ready;
    } on Object {
      _state = RecoverableDeleteJournalState.degraded;
    }
  }

  RecoverableDeleteJournalEntry? lookup(String serverIdentity, String chatGuid) {
    _requireReady();
    return _entries[_opaqueKey(serverIdentity)]?[_opaqueKey(chatGuid)];
  }

  List<RecoverableDeleteJournalEntry> listUnresolved({String? serverIdentity}) {
    _requireReady();
    if (serverIdentity != null) {
      return List<RecoverableDeleteJournalEntry>.unmodifiable(
        _entries[_opaqueKey(serverIdentity)]?.values ?? const <RecoverableDeleteJournalEntry>[],
      );
    }
    return List<RecoverableDeleteJournalEntry>.unmodifiable(_entries.values.expand((bucket) => bucket.values));
  }

  bool isSuppressed(String serverIdentity, String chatGuid) => lookup(serverIdentity, chatGuid) != null;

  RecoverableDeleteJournalServerView forServer(String serverIdentity) => _serverViews.putIfAbsent(
    _opaqueKey(serverIdentity),
    () => RecoverableDeleteJournalServerView._(this, serverIdentity),
  );

  Lock chatLock(String serverIdentity, String chatGuid) =>
      _chatLocks.putIfAbsent('${_opaqueKey(serverIdentity)}:${_opaqueKey(chatGuid)}', Lock.new);

  Future<bool> recordAccepted(String serverIdentity, String chatGuid, String attemptId) =>
      _mutateCompareAndSet(serverIdentity, chatGuid, attemptId, (entry, bucket, chatKey) {
        bucket[chatKey] = entry.copyWith(phase: RecoverableDeleteJournalPhase.accepted);
      });

  Future<bool> clear(String serverIdentity, String chatGuid, String attemptId) =>
      _mutateCompareAndSet(serverIdentity, chatGuid, attemptId, (entry, bucket, chatKey) {
        bucket.remove(chatKey);
      });

  Future<void> recordSubmitted({
    required String serverIdentity,
    required String chatGuid,
    required String attemptId,
    required DateTime startedAt,
  }) {
    if (!_attemptIdRegExp.hasMatch(attemptId)) {
      return Future<void>.error(ArgumentError.value(attemptId, 'attemptId'));
    }
    return _mutate((next) {
      final serverKey = _opaqueKey(serverIdentity);
      final chatKey = _opaqueKey(chatGuid);
      final bucket = next.putIfAbsent(serverKey, () => <String, RecoverableDeleteJournalEntry>{});
      final current = bucket[chatKey];
      if (current != null) {
        if (current.attemptId != attemptId) {
          throw StateError('An unresolved recoverable delete claim already exists');
        }
        return false;
      }
      bucket[chatKey] = RecoverableDeleteJournalEntry(
        serverIdentity: serverIdentity,
        chatGuid: chatGuid,
        attemptId: attemptId,
        startedAt: startedAt,
        phase: RecoverableDeleteJournalPhase.submitted,
      );
      return true;
    });
  }

  Future<bool> _mutateCompareAndSet(
    String serverIdentity,
    String chatGuid,
    String attemptId,
    void Function(
      RecoverableDeleteJournalEntry entry,
      Map<String, RecoverableDeleteJournalEntry> bucket,
      String chatKey,
    )
    change,
  ) {
    _requireReady();
    final operation = _mutationTail.then((_) async {
      final next = _cloneEntries();
      final serverKey = _opaqueKey(serverIdentity);
      final chatKey = _opaqueKey(chatGuid);
      final bucket = next[serverKey];
      final current = bucket?[chatKey];
      if (current == null || current.attemptId != attemptId) return false;
      change(current, bucket!, chatKey);
      if (bucket.isEmpty) next.remove(serverKey);
      await _store.write(_encode(next));
      _entries = next;
      return true;
    });
    _mutationTail = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }

  Future<void> _mutate(bool Function(Map<String, Map<String, RecoverableDeleteJournalEntry>>) change) {
    _requireReady();
    final operation = _mutationTail.then((_) async {
      final next = _cloneEntries();
      if (!change(next)) return;
      await _store.write(_encode(next));
      _entries = next;
    });
    _mutationTail = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }

  Map<String, Map<String, RecoverableDeleteJournalEntry>> _cloneEntries() =>
      <String, Map<String, RecoverableDeleteJournalEntry>>{
        for (final server in _entries.entries)
          server.key: Map<String, RecoverableDeleteJournalEntry>.from(server.value),
      };

  String _encode(Map<String, Map<String, RecoverableDeleteJournalEntry>> entries) {
    final document = Map<String, dynamic>.from(_preservedDocument);
    final preservedServers = document['servers'];
    final servers = preservedServers is Map ? Map<String, dynamic>.from(preservedServers) : <String, dynamic>{};
    for (final server in entries.entries) {
      final preservedBucket = servers[server.key];
      if (preservedBucket != null && preservedBucket is! Map) {
        throw StateError('Canonical server key collides with quarantined evidence');
      }
      final bucket = preservedBucket == null ? <String, dynamic>{} : Map<String, dynamic>.from(preservedBucket as Map);
      for (final chat in server.value.entries) {
        if (bucket.containsKey(chat.key)) {
          throw StateError('Canonical chat key collides with quarantined evidence');
        }
        bucket[chat.key] = chat.value.toJson();
      }
      servers[server.key] = bucket;
    }
    document['version'] = 1;
    document['servers'] = servers;
    return jsonEncode(document);
  }

  void _requireReady() {
    if (state != RecoverableDeleteJournalState.ready) {
      throw StateError('Recoverable delete journal is not writable');
    }
  }
}

String _opaqueKey(String value) => sha256.convert(utf8.encode(value)).toString();
