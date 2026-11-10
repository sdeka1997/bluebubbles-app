import 'dart:async';
import 'dart:io';

import 'package:bluebubbles/env.dart';
import 'package:bluebubbles/database/sqlite/storage.dart';
import 'package:bluebubbles/database/store/sqlite/theme_store.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

class Database {
  /// Bump this whenever preset theme definitions change (colors, font sizes,
  /// etc.) to force existing installs to re-seed preset themes on next launch.
  static int themesVersion = 6;

  static String get appDocPath => FilesystemSvc.appDocDir.path;

  static final Completer<void> initComplete = Completer();

  static Future<void> init() async {
    // Web doesn't use a database currently, so do not do anything
    if (kIsWeb) return;

    // Wait for SettingsService to be fully initialized before accessing settings.
    // This _shouldn't_ be needed, but we're going to do it just in case...
    bool setupFinished = false;
    if (GetIt.I.isRegistered<SettingsService>()) {
      await SettingsSvc.initCompleted.future;
      setupFinished = SettingsSvc.settings.finishedSetup.value;
    }

    bool setupFinished2 = PrefsSvc.database.getFinishedSetup();
    Logger.info("Database init: SettingsSvc.finishedSetup = $setupFinished, PrefsSvc.finishedSetup = $setupFinished2");

    // Setup only ever runs on main, so only main may act on an unfinished one.
    final directory = Directory(appDocPath);
    if (!setupFinished && !isIsolate) {
      Logger.warn("Clearing database because setup is not finished...");
      deleteStorageFiles(directory);
    }

    final store = await openStorage(directory, onMain: !isIsolate);
    MessagingStore.select(store);
    ThemeStore.current = await ThemeStore.open(store.db);

    await seedThemes();

    initComplete.complete();
  }

  static Future<void> waitForInit() async {
    await initComplete.future;
  }

  static Future<void> seedThemes() async {
    try {
      final isFirstRun = ThemeStore.current!.isEmpty;
      final storedThemesVersion = PrefsSvc.database.getThemesVersion();
      final needsReseed = isFirstRun || storedThemesVersion < Database.themesVersion;
      if (isFirstRun) {
        await PrefsSvc.theme.setSelectedThemes(
          darkTheme: "OLED Dark",
          lightTheme: "Bright White",
        );
      }
      if (needsReseed) {
        for (final preset in ThemesService.defaultThemes) {
          preset.save();
        }
        await PrefsSvc.database.setThemesVersion(Database.themesVersion);
      }
    } catch (e, s) {
      Logger.error("Failed to seed themes!", error: e, trace: s);
    }
  }

  /// Wipes the messaging data and the themes, for a full app reset. For a
  /// messaging-only wipe that keeps themes, use [resetMessagingData].
  ///
  /// Note: scheduled messages are not stored locally — they live server-side and
  /// are fetched via the API (see `ScheduledMessagesMixin`), so there's nothing to
  /// clear here for them.
  static Future<void> reset() async {
    await resetMessagingData();
    ThemeStore.current?.clear();
    await ThemeStore.current?.flush();
  }

  /// Wipes messaging-scoped data: attachments, chats, contacts, handles, messages, and custom groups.
  /// Leaves settings, themes and scheduled messages untouched.
  static Future<void> resetMessagingData() => MessagingStore.current.clearMessagingData();
}
