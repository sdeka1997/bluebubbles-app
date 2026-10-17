import 'package:bluebubbles/services/backend/settings/shared_preferences_service.dart';

typedef PreferenceStringWriter = Future<bool> Function(String key, String value);

class SharedPreferencesDatabaseActions {
  static const String _finishedSetupKey = 'finishedSetup';
  static const String _dbVersionKey = 'dbVersion';
  static const String _themesVersionKey = 'themesVersion';
  static const String _useCustomPathKey = 'use-custom-path';
  static const String _customPathKey = 'custom-path';
  static const String _chatStateBaselineKey = 'chat-state-replication-baseline-v2';
  static const String _deferredChatDeletionsKey = 'deferred-chat-deletions-v2';
  static const String _recoverableDeleteJournalKey = 'recoverable-chat-delete-journal-v1';

  final SharedPreferencesService service;
  final PreferenceStringWriter _writeString;

  SharedPreferencesDatabaseActions(this.service, {PreferenceStringWriter? writeString})
      : _writeString = writeString ??
            ((key, value) async {
              // SharedPreferencesWithCache reports platform failures by
              // throwing rather than returning the legacy bool result.
              await service.i.setString(key, value);
              return true;
            });

  bool getFinishedSetup() => service.i.getBool(_finishedSetupKey) ?? false;

  int? getDbVersion() => service.i.getInt(_dbVersionKey);

  Future<void> setDbVersion(int version) => service.i.setInt(_dbVersionKey, version);

  int getThemesVersion() => service.i.getInt(_themesVersionKey) ?? 0;

  Future<void> setThemesVersion(int version) => service.i.setInt(_themesVersionKey, version);

  bool shouldUseCustomPath() => service.i.getBool(_useCustomPathKey) == true;

  String? getCustomPath() => service.i.getString(_customPathKey);

  String? getChatStateBaseline() => service.i.getString(_chatStateBaselineKey);

  Future<void> setChatStateBaseline(String value) => service.i.setString(_chatStateBaselineKey, value);

  String? getDeferredChatDeletions() => service.i.getString(_deferredChatDeletionsKey);

  Future<void> setDeferredChatDeletions(String value) => service.i.setString(_deferredChatDeletionsKey, value);

  String? getRecoverableDeleteJournal() => service.i.getString(_recoverableDeleteJournalKey);

  Future<void> setRecoverableDeleteJournal(String value) async {
    final written = await _writeString(_recoverableDeleteJournalKey, value);
    if (!written) throw StateError('failed to persist recoverable-delete journal');
  }

  Future<void> clearCustomPathConfig() async {
    await service.i.remove(_useCustomPathKey);
    await service.i.remove(_customPathKey);
  }
}
