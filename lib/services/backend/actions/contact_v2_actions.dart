import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/helpers/types/helpers/server_contacts.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// ContactV2Actions - Isolate-side logic for the new contact service
/// All operations here run in the GlobalIsolate to prevent UI jank
/// This follows the architecture outlined in FR-1.md
class ContactV2Actions {
  /// Completer to ensure syncContactsToHandles only runs once at a time
  static Completer<_ContactSyncStats>? _syncCompleter;

  /// Fetch all contacts from device and match them to existing handles
  /// This is the main operation described in Section II.A of FR-1.md
  ///
  /// Returns only the affected handle IDs — the shape every existing caller
  /// depends on. Use [syncContactsToHandlesWithStats] for the fetch/match
  /// counts as well (e.g. for diagnostic display).
  static Future<List<int>> syncContactsToHandles(dynamic data) async {
    final stats = await _syncContactsToHandlesInternal(data);
    return stats.affectedHandleIds;
  }

  /// Same operation as [syncContactsToHandles], but also returns the device
  /// contact count and matched-contact count — used by the Contacts
  /// Management page's manual refresh to show live diagnostic feedback.
  static Future<Map<String, dynamic>> syncContactsToHandlesWithStats(dynamic data) async {
    final stats = await _syncContactsToHandlesInternal(data);
    return stats.toMap();
  }

  static Future<_ContactSyncStats> _syncContactsToHandlesInternal(dynamic data) async {
    // If already processing, wait for the existing operation to complete
    if (_syncCompleter != null && !_syncCompleter!.isCompleted) {
      Logger.info('[ContactV2] Sync already in progress, waiting for completion...');
      return await _syncCompleter!.future;
    }

    // Create a new completer for this sync operation
    _syncCompleter = Completer<_ContactSyncStats>();

    final startTime = DateTime.now().millisecondsSinceEpoch;
    final affectedHandleIds = <int>[];
    int matchedContactCount = 0;

    try {
      List<ContactV2> networkContacts = [];
      final avatarPaths = <String, String?>{};

      // Every platform reads the Mac's Apple Contacts through the server: the
      // app mirrors the iPhone, so names, photos and who-is-who come from the
      // same iCloud cards the iPhone uses, never from the phone's own contacts.
      Logger.info('[ContactV2] Starting contact fetch from server...');
      final response = await HttpSvc.contact.fetchAll(withAvatars: true);
      final fetched = response.statusCode == 200 && response.data['data'] is List;
      if (fetched) {
        for (final card in contactsFromServer(response.data['data'] as List)) {
          final contactId = card.contact.nativeContactId;
          if (card.avatar != null) {
            try {
              final savedPath = await _saveContactAvatar(contactId, base64Decode(card.avatar!));
              // A null path means the disk write failed — leave the key unset so
              // the existing avatarPath is preserved instead of being wiped.
              if (savedPath != null) avatarPaths[contactId] = savedPath;
            } catch (_) {}
          } else {
            // Server reports no avatar for this contact — record the removal explicitly.
            avatarPaths[contactId] = null;
          }
          networkContacts.add(card.contact);
        }
        Logger.info('[ContactV2] Fetched ${networkContacts.length} contacts from server');
      } else {
        // Keep what's stored rather than wiping every name on a failed fetch.
        Logger.warn('[ContactV2] Server contacts unavailable (status ${response.statusCode})');
      }

      final storeResult = await MessagingStore.current.syncContacts(
        networkContacts,
        avatarPaths,
        fetched: fetched,
      );
      affectedHandleIds.addAll(storeResult.affectedHandleIds);
      matchedContactCount = storeResult.matchedContactCount;

      final endTime = DateTime.now().millisecondsSinceEpoch;
      // De-duplicate — a handle can be marked affected by both a name/avatar
      // change and a handle-link change within the same sync.
      final uniqueAffected = affectedHandleIds.toSet().toList();
      Logger.info('[ContactV2] Contact fetch and match completed in ${endTime - startTime}ms');
      Logger.info('[ContactV2] Affected ${uniqueAffected.length} handles');

      final stats = _ContactSyncStats(
        affectedHandleIds: uniqueAffected,
        deviceContactCount: networkContacts.length,
        matchedContactCount: matchedContactCount,
      );

      // Complete the completer with the result
      _syncCompleter?.complete(stats);
      return stats;
    } catch (e, stack) {
      // Logged with the exception's runtimeType called out explicitly so this is
      // distinguishable in exported logs from the "0 contacts, no exception" case
      // logged above — both currently end in an empty sync result, but only one
      // of them is an actual failure.
      Logger.error('[ContactV2] Error fetching and matching contacts (${e.runtimeType}): $e',
          error: e, trace: stack);

      // Complete the completer with an empty result on error
      const stats = _ContactSyncStats(affectedHandleIds: [], deviceContactCount: 0, matchedContactCount: 0);
      _syncCompleter?.complete(stats);
      return stats;
    }
  }

  /// Check for contact database changes by comparing native contact IDs
  /// This is used by the periodic background task (Section II.B of FR-1.md)
  static Future<bool> checkContactChanges(dynamic data) async {
    try {
      // Contacts come from the server, which has no change feed: resync and
      // report whether any handle changed.
      final stats = await _syncContactsToHandlesInternal(data);
      return stats.affectedHandleIds.isNotEmpty;
    } catch (e, stack) {
      Logger.error('[ContactV2] Error checking contact changes', error: e, trace: stack);
      return false;
    }
  }

  /// Get all stored ContactV2 IDs for comparison
  static Future<List<String>> getStoredContactIds(dynamic data) async {
    return MessagingStore.current.contactNativeIds();
  }

  /// Find a single ContactV2 by native contact ID
  /// Returns the ObjectBox ID of the matching contact, or null if not found.
  static Future<int?> findOneContact(dynamic data) async {
    final dataMap = data as Map<dynamic, dynamic>;
    final nativeContactId = dataMap['nativeContactId'] as String;

    return MessagingStore.current.findContactId(nativeContactId);
  }

  /// Get ContactV2 IDs for a list of Handle IDs.
  /// Returns de-duplicated ObjectBox IDs so the interface can hydrate full objects.
  static Future<List<int>> getContactsForHandles(dynamic data) async {
    final dataMap = data as Map<dynamic, dynamic>;
    final handleIds = (dataMap['handleIds'] as List).cast<int>();

    return MessagingStore.current.contactIdsForHandles(handleIds);
  }

  /// Manually trigger a contact refresh
  static Future<List<int>> refreshContacts(dynamic data) async {
    return await syncContactsToHandles(data);
  }

  /// Save a contact avatar to disk and return the file path
  ///
  /// Optimizations:
  /// - Only writes if avatar doesn't exist or has changed
  /// - Uses file size comparison first (fast)
  /// - Falls back to hash comparison if sizes match
  static Future<String?> _saveContactAvatar(String contactId, Uint8List avatarData) async {
    try {
      final avatarsDir = Directory(FilesystemSvc.contactAvatarsPath);

      // Create the directory if it doesn't exist
      if (!await avatarsDir.exists()) {
        await avatarsDir.create(recursive: true);
      }

      // Save the avatar with the contact ID as filename. The ID is sanitized because
      // it isn't ours: macOS record IDs look like `<uuid>:ABPerson`, and the fallback
      // when the server sends no ID is the display name. A reserved character there
      // yields a path that later breaks anything parsing it as a URI (Windows toasts).
      final avatarFile = File(p.join(avatarsDir.path, '${sanitizeFileName(contactId)}.jpg'));

      // Check if avatar already exists and compare it to avoid unnecessary writes
      if (await avatarFile.exists()) {
        final existingData = await avatarFile.readAsBytes();

        // Quick size check first
        if (existingData.length == avatarData.length) {
          // If sizes match, do a hash comparison to be sure
          final existingHash = sha256.convert(existingData);
          final newHash = sha256.convert(avatarData);

          if (existingHash == newHash) {
            // Avatar hasn't changed, return existing path without writing
            return avatarFile.path;
          }
        }
      }

      // Avatar is new or has changed, write it to disk
      await avatarFile.writeAsBytes(avatarData);

      return avatarFile.path;
    } catch (e, stack) {
      Logger.error('[ContactV2] Error saving avatar for contact $contactId', error: e, trace: stack);
      return null;
    }
  }

  /// Get a contact by address (email or phone number).
  /// Returns the ObjectBox ID of the matching contact, or null if not found.
  static Future<int?> getContactByAddress(dynamic data) async {
    final dataMap = data as Map<dynamic, dynamic>;
    final address = dataMap['address'] as String;

    return MessagingStore.current.contactIdByAddress(address);
  }

  /// Get all contacts from the database.
  /// Returns a list of ObjectBox IDs so the interface can hydrate full objects.
  static Future<List<int>> getAllContacts(dynamic data) async {
    return MessagingStore.current.allContactIds();
  }

  /// Get avatar data for a contact by native contact ID
  static Future<Uint8List?> getContactAvatar(dynamic data) async {
    final dataMap = data as Map<dynamic, dynamic>;
    final nativeContactId = dataMap['nativeContactId'] as String;

    try {
      // First try to get from disk (if we've already saved it)
      final avatarsDir = Directory(FilesystemSvc.contactAvatarsPath);
      final avatarFile = File(p.join(avatarsDir.path, '$nativeContactId.jpg'));

      if (await avatarFile.exists()) {
        return await avatarFile.readAsBytes();
      }

      // Photos come with the server's contacts and are saved during sync.
      return null;
    } catch (e, stack) {
      Logger.error('[ContactV2] Error getting contact avatar for $nativeContactId', error: e, trace: stack);
      return null;
    }
  }

  /// Uploads contacts to the server
  static Future<void> uploadContacts(dynamic data) async {
    final contacts = data['contacts'] as List<Map<String, dynamic>>;

    try {
      await HttpSvc.contact.create(contacts);
      Logger.info('[ContactV2] Successfully uploaded ${contacts.length} contacts to server');
    } catch (err, stack) {
      if (err is Response) {
        Logger.error(err.data["error"]["message"].toString(), error: err, trace: stack, tag: 'ContactV2Actions');
      } else {
        Logger.error('Failed to upload contacts!', error: err, trace: stack, tag: 'ContactV2Actions');
      }
    }
  }

  /// Returns each on-device account with contacts, plus a live contact count
  /// per account. Used by the Contacts Management page's account selector.
  /// Mobile only — desktop has no device accounts.
  static Future<List<Map<String, dynamic>>> getAccountContactCounts(dynamic data) async {
    // Contacts come from the Mac's Apple Contacts, not the phone's accounts.
    return [];
  }
}

/// Result of a device/network contact fetch-and-match pass. Kept isolate-internal
/// (not returned directly across the isolate boundary — see
/// [ContactV2Actions.syncContactsToHandles] vs
/// [ContactV2Actions.syncContactsToHandlesWithStats]).
class _ContactSyncStats {
  final List<int> affectedHandleIds;
  final int deviceContactCount;
  final int matchedContactCount;

  const _ContactSyncStats({
    required this.affectedHandleIds,
    required this.deviceContactCount,
    required this.matchedContactCount,
  });

  Map<String, dynamic> toMap() => {
        'affectedHandleIds': affectedHandleIds,
        'deviceContactCount': deviceContactCount,
        'matchedContactCount': matchedContactCount,
      };
}
