import 'dart:async';
import 'dart:math' as math;

import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/ui/async_task.dart';
import 'package:bluebubbles/helpers/types/helpers/chat_metadata_helpers.dart';
import 'package:bluebubbles/helpers/types/helpers/service_twin_helpers.dart';
import 'package:bluebubbles/helpers/ui/ui_helpers.dart';
import 'package:bluebubbles/services/backend/interfaces/sync_interface.dart';
import 'package:bluebubbles/services/backend/sync/sync_retry.dart';
import 'package:bluebubbles/services/backend/sync/sync_windows.dart';
import 'package:bluebubbles/services/isolates/global_isolate.dart';
import 'package:bluebubbles/services/isolates/incremental_sync_isolate.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:bluebubbles/services/backend/sync/apple_state_catch_up.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_it/get_it.dart';

// ignore: non_constant_identifier_names
SyncService get SyncSvc => GetIt.I<SyncService>();

class SyncService {
  int numberOfMessagesPerPage = 25;
  bool skipEmptyChats = true;
  bool saveToDownloads = false;
  bool syncGroupChatIcons = false;
  int? syncTimeFilter;
  final RxBool isIncrementalSyncing = false.obs;

  /// Messages synced so far and counted at the start of a long incremental
  /// sync, for the progress bar; both 0 when no long sync is running.
  final RxInt incrementalSyncSeen = 0.obs;
  final RxInt incrementalSyncTotal = 0.obs;

  /// Whether the app left the foreground while the current sync ran.
  bool _backgroundedDuringSync = false;

  /// Tells the isolates that may be running a sync to stop after the window in
  /// hand (app backgrounded) or to carry on (app back in front). The window's
  /// checkpoint is saved, so the next sync resumes from it.
  void setSyncPaused(bool paused) {
    if (paused && isIncrementalSyncing.value) _backgroundedDuringSync = true;
    for (final isolate in <GlobalIsolate>[
      if (GetIt.I.isRegistered<GlobalIsolate>()) GetIt.I<GlobalIsolate>(),
      if (GetIt.I.isRegistered<IncrementalSyncIsolate>()) GetIt.I<IncrementalSyncIsolate>(),
    ]) {
      if (isolate.isRunning) isolate.broadcast(IsolateRequestType.setSyncPaused, paused);
    }
  }

  static const Duration _incrementalSyncCooldown = Duration(seconds: 30);
  static const int _dispatchChunkSize = 50;
  DateTime? _lastIncrementalSyncTimestamp;

  FullSyncManager? _manager;
  FullSyncManager? get fullSyncManager => _manager;

  void initFullSync() {
    _manager = FullSyncManager(
        messageCount: numberOfMessagesPerPage.toInt(),
        skipEmptyChats: skipEmptyChats,
        saveLogs: saveToDownloads,
        syncGroupChatIcons: syncGroupChatIcons,
        syncTimeFilter: syncTimeFilter);
  }

  Future<void> startFullSync() async {
    if (_manager == null) {
      initFullSync();
    }

    // Set the last sync date (for incremental, even though this isn't incremental)
    // We won't try an incremental sync until the last (full) sync date is set
    SettingsSvc.settings.lastIncrementalSync.value = DateTime.now().millisecondsSinceEpoch;
    await SettingsSvc.settings.saveOneAsync('lastIncrementalSync');
    await _manager!.start();
  }

  Future<void> _refreshServerChatMetadata() async {
    if (kIsWeb) return;
    try {
      const pageSize = 1000;
      var offset = 0;
      final remoteChats = <Map<String, dynamic>>[];
      while (true) {
        final response = await HttpSvc.chat.query(offset: offset, limit: pageSize);
        if (response.statusCode != 200) {
          throw StateError('chat metadata query returned ${response.statusCode}');
        }
        final payload = response.data as Map<String, dynamic>;
        final page = (payload['data'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        remoteChats.addAll(page);
        offset += page.length;
        final total = (payload['metadata'] as Map?)?['total'] as num?;
        if (page.isEmpty || (total != null && offset >= total.toInt()) || page.length < pageSize) break;
      }

      final localChats = Database.chats.getAll();
      late Map<String, Chat> folded;
      late List<Chat> changed;
      Database.runInTransaction(TxMode.write, () {
        changed = {
          ...updateGroupIdsFromRemote(localChats, remoteChats),
          ...updateSpamFlagsFromRemote(localChats, remoteChats),
        }.toList();
        if (changed.isNotEmpty) Database.chats.putMany(changed);
        folded = foldServiceTwins(localChats);
      });

      // Apply spam changes to the live list immediately. addChat also refuses
      // folded twins, so restored non-spam chats return without exposing twins.
      for (final chat in changed) {
        if (chat.isFilteredAsSpam == true) {
          ChatsSvc.removeChat(chat);
        } else {
          await ChatsSvc.addChat(chat, immediate: true);
        }
      }
      for (final entry in folded.entries) {
        final twin = localChats.where((chat) => chat.guid == entry.key).firstOrNull;
        if (twin != null) ChatsSvc.removeChat(twin);
        await ChatsSvc.addChat(entry.value, immediate: true);
      }
      Logger.info(
        'Refreshed metadata for ${changed.length} chats; folded ${folded.length} service twins',
        tag: 'Service Twins',
      );
    } catch (e, stack) {
      // Metadata refresh is additive. A transient failure must never block the
      // ordinary incremental message sync that follows it.
      Logger.warn('Could not refresh server chat metadata', error: e, trace: stack, tag: 'Service Twins');
    }
  }

  Future<void> startIncrementalSync({bool useGlobalIsolate = false}) async {
    if (isIncrementalSyncing.value) return;

    final now = DateTime.now();
    if (_lastIncrementalSyncTimestamp != null &&
        now.difference(_lastIncrementalSyncTimestamp!) < _incrementalSyncCooldown) {
      Logger.debug(
        'Skipping incremental sync... Last ran ${now.difference(_lastIncrementalSyncTimestamp!).inSeconds}s ago '
        '(cooldown: ${_incrementalSyncCooldown.inSeconds}s)',
        tag: 'Incremental Chat Sync',
      );
      // The cooldown protects the expensive message/contact sync, not the
      // catch-up with Apple: a read or delete event can be missed while
      // Android is backgrounded, and resume must still pick it up.
      await AppleStateCatchUp.run();
      return;
    }

    _lastIncrementalSyncTimestamp = now;
    isIncrementalSyncing.value = true;
    _backgroundedDuringSync = false;
    incrementalSyncSeen.value = 0;
    incrementalSyncTotal.value = 0;
    bool chatSyncFailed = false;

    void onProgress(dynamic data) {
      if (data is! Map) return;
      incrementalSyncSeen.value = data['seen'] as int? ?? 0;
      incrementalSyncTotal.value = data['total'] as int? ?? 0;
    }

    // Existing chats predate group-id support. Refresh only server-owned grouping
    // metadata on every real startup/resume sync, then fold any newly discovered
    // service twins. This is intentionally not a full chat resync: local names,
    // pinning, mute, archive and other app-owned settings remain untouched.
    await _refreshServerChatMetadata();

    // Per-page tracking: record message IDs and chat subtitle message IDs that were
    // already applied by per-page events so the final return can skip redundant work.
    final processedMessageIds = <int>{};
    final processedSubtitleByChat = <String, int>{}; // chatGuid → message DB ID

    // This runs on the UI thread (isolate event listeners are invoked synchronously),
    // so a page of up to `batchSize` messages must never be hydrated in one block.
    Future<void> onPageComplete(dynamic data) async {
      if (data is! Map<String, dynamic>) return;
      final messageIdsByChat =
          (data['messageIdsByChat'] as Map).map((k, v) => MapEntry(k as String, (v as List).cast<int>()));
      final latestPerChat = Map<String, int>.from(data['latestMessageIdPerChat'] as Map);

      // repositionImmediate: false so a page touching many chats rebuilds the list once.
      for (final entry in latestPerChat.entries) {
        final msg = await runAsync(() => Database.messages.get(entry.value));
        if (msg == null) continue;
        // If this chat was created for the first time during this sync,
        // ChatState doesn't exist yet — register it so updateChatLatestMessage
        // isn't a silent no-op.
        if (ChatsSvc.getChatState(entry.key) == null) {
          final chat = msg.chat.target;
          if (chat != null) await ChatsSvc.addChat(chat, immediate: true);
        }
        ChatsSvc.updateChatLatestMessage(entry.key, msg, repositionImmediate: false);
        processedSubtitleByChat[entry.key] = entry.value;
      }

      // Only an open conversation view needs the individual messages — every other
      // chat is served by the subtitle update above.
      for (final entry in messageIdsByChat.entries) {
        if (maybeFindMessagesSvc(entry.key) == null) continue;
        for (int i = 0; i < entry.value.length; i += _dispatchChunkSize) {
          // Re-resolve every chunk: the user can leave this chat between chunks
          final service = maybeFindMessagesSvc(entry.key);
          if (service == null) break;
          final chunk = entry.value.sublist(i, math.min(i + _dispatchChunkSize, entry.value.length));
          final messages = await runAsync(() => Database.messages.getMany(chunk).whereType<Message>().toList());
          for (final message in messages) {
            if (message.guid == null) continue;
            await service.addNewMessage(message);
            if (message.id != null) processedMessageIds.add(message.id!);
          }
        }
      }
    }

    // Events arrive on the instance that runs the sync, so listen there.
    final GlobalIsolate syncIsolate =
        useGlobalIsolate ? GetIt.I<GlobalIsolate>() : GetIt.I<IncrementalSyncIsolate>();
    syncIsolate.addEventListener(IsolateEvent.incrementalSyncPageComplete, onPageComplete);
    syncIsolate.addEventListener(IsolateEvent.incrementalSyncProgress, onProgress);
    // A sync started while the app is in front must not inherit a stale pause.
    syncIsolate.broadcast(IsolateRequestType.setSyncPaused, false);

    try {
      Logger.info('Starting incremental chat sync...', tag: 'Incremental Chat Sync');
      final chatStopwatch = Stopwatch()..start();
      // Retried inside this guarded call so a reconnect-triggered sync can't
      // overlap it; only a failure that outlasts the retries reaches the toast.
      final syncedMessages =
          await retryTransientSync(
        () => SyncInterface.performIncrementalSync(useGlobalIsolate: useGlobalIsolate),
        onRetry: (error, delay) => Logger.warn('Incremental sync hit a network error, retrying in ${delay.inSeconds}s',
            error: error, tag: 'Incremental Chat Sync'),
      );
      if (syncedMessages.isNotEmpty) {
        // latestMessageIdPerChat is keyed by chat GUID, so syncedMessages already contains
        // at most one message per chat. Deduplicate defensively by keeping the latest
        // message per chat GUID in case the data ever changes.
        final Map<String, Message> latestPerChat = {};
        for (final message in syncedMessages) {
          final chatGuid = message.chat.target?.guid;
          if (chatGuid == null) continue;
          final existing = latestPerChat[chatGuid];
          if (existing == null ||
              (message.dateCreated != null &&
                  (existing.dateCreated == null || message.dateCreated!.isAfter(existing.dateCreated!)))) {
            latestPerChat[chatGuid] = message;
          }
        }

        // IncrementalSyncManager.complete() already called ChatsSvc.updateChat() for every
        // synced chat. Here we only need to push the subtitle update into ChatState.
        // Skip chats where the per-page event already applied the same (or newer) message.
        for (final entry in latestPerChat.entries) {
          final message = entry.value;
          if (message.id != null && processedSubtitleByChat[entry.key] == message.id) continue;
          ChatsSvc.updateChatLatestMessage(entry.key, message, repositionImmediate: false);
        }

        // Dispatch newly synced messages to any currently active chat view.
        // Skip messages already dispatched by a per-page event.
        // MessagesService.addNewMessage() is a no-op if the message is already present,
        // so this is safe even without the skip, but avoiding the call reduces churn.
        for (final message in syncedMessages) {
          if (message.id != null && processedMessageIds.contains(message.id)) continue;
          final chatGuid = message.chat.target?.guid;
          if (chatGuid == null || message.guid == null) continue;
          if (Get.isRegistered<MessagesService>(tag: chatGuid)) {
            unawaited(Get.find<MessagesService>(tag: chatGuid).addNewMessage(message));
          }
        }
      }

      chatStopwatch.stop();
      Logger.info(
          'Incremental chat sync completed! Synced ${syncedMessages.length} messages across '
          '${syncedMessages.map((m) => m.chat.target?.guid).toSet().length} chats '
          'in ${chatStopwatch.elapsedMilliseconds}ms',
          tag: 'Incremental Chat Sync');
    } catch (e, stack) {
      Logger.error('Incremental chat sync failed!', error: e, trace: stack, tag: 'Incremental Chat Sync');
      chatSyncFailed = true;
    } finally {
      syncIsolate.removeEventListener(IsolateEvent.incrementalSyncPageComplete, onPageComplete);
      syncIsolate.removeEventListener(IsolateEvent.incrementalSyncProgress, onProgress);
    }

    // A failed chat sync must not consume the cooldown window. Otherwise a sync that
    // fails on launch (e.g. no network yet) blocks the retry triggered by the socket
    // reconnect or app resume that follows, and new messages wait out the cooldown.
    // Only the chat sync resets it: contact sync failures are usually persistent
    // (permissions, unsupported server) and shouldn't defeat the throttle.
    if (chatSyncFailed) {
      _lastIncrementalSyncTimestamp = null;
    }

    // Runs after the messages are in, so a message synced and deleted in the
    // same window still ends up hidden. Not counted toward `errors`: an older
    // server without the endpoints must not make the user think sync failed.
    await AppleStateCatchUp.run();

    final contactSyncResult = await performContactSyncToHandles();
    final contactUploadResult = await performContactSyncToServer();

    // The chat sync is the one that matters, so its failure is reported alone and wins over the rest.
    // Contact failures get their own wording: a missing contacts permission returns early without
    // throwing, so a refresh failure is a genuine local error, not something a reconnect fixes.
    if (chatSyncFailed && !shouldReportSyncFailure(backgroundedDuringSync: _backgroundedDuringSync)) {
      Logger.info('Sync stopped while the app was in the background; it resumes on return',
          tag: 'Incremental Chat Sync');
    } else if (chatSyncFailed) {
      await showToast("Sync failed. Check your connection.", isError: true);
    } else if (!contactSyncResult) {
      await showToast("Messages synced, but refreshing contacts failed. Check the logs for details.", isError: true);
    } else if (!contactUploadResult) {
      await showToast("Messages synced, but uploading contacts to the server failed.", isError: true);
    } else if (SettingsSvc.settings.showIncrementalSync.value) {
      await showToast('Incremental sync complete');
    }

    incrementalSyncSeen.value = 0;
    incrementalSyncTotal.value = 0;
    isIncrementalSyncing.value = false;
  }

  Future<bool> performContactSyncToHandles() async {
    try {
      Logger.info('Starting contact refresh', tag: 'Incremental Contact Sync');
      final contactStopwatch = Stopwatch()..start();
      final refreshedHandleIds = await ContactsSvcV2.syncContactsToHandles();
      contactStopwatch.stop();
      Logger.info(
          'Finished contact refresh, refreshed ${refreshedHandleIds.length} handles in ${contactStopwatch.elapsedMilliseconds}ms',
          tag: 'Incremental Contact Sync');

      if (refreshedHandleIds.isNotEmpty) {
        ContactsSvcV2.notifyHandlesUpdated(refreshedHandleIds);
      }

      return true;
    } catch (ex, stack) {
      Logger.error('Contacts refresh failed!', error: ex, trace: stack, tag: 'Incremental Contact Sync');
      return false;
    }
  }

  /// Contacts come from the Mac's Apple Contacts, so the phone never uploads
  /// its own; kept so callers that report sync steps still get a result.
  Future<bool> performContactSyncToServer() async => true;

}
