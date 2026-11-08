import 'dart:convert';

import 'package:bluebubbles/database/io/chat.dart' as domain;
import 'package:bluebubbles/database/sqlite/app_database.dart';
import 'package:drift/drift.dart';

class SqliteChatRepository {
  SqliteChatRepository(this.database);

  final AppDatabase database;

  Future<domain.Chat?> byGuid(String guid) async {
    final row = await (database.select(database.chats)..where((chat) => chat.guid.equals(guid))).getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<void> save(domain.Chat chat) async {
    final companion = ChatsCompanion.insert(
      id: chat.id == null ? const Value.absent() : Value(chat.id!),
      guid: chat.guid,
      chatIdentifier: Value(chat.chatIdentifier),
      serviceName: Value(chat.serviceName),
      groupId: Value(chat.groupId),
      originalGroupId: Value(chat.originalGroupId),
      legacyGroupIdsJson: Value(chat.legacyGroupIds == null ? null : jsonEncode(chat.legacyGroupIds)),
      latestGroupTitle: Value(chat.latestGroupTitle),
      threadKey: Value(chat.threadKey),
      isArchived: Value(chat.isArchived),
      muteType: Value(chat.muteType),
      muteArgs: Value(chat.muteArgs),
      isPinned: Value(chat.isPinned),
      hasUnreadMessage: Value(chat.hasUnreadMessage),
      displayName: Value(chat.displayName),
      isFilteredAsSpam: Value(chat.isFilteredAsSpam),
      autoSendReadReceipts: Value(chat.autoSendReadReceipts),
      autoSendTypingIndicators: Value(chat.autoSendTypingIndicators),
      textFieldText: Value(chat.textFieldText),
      textFieldAttachmentsJson: Value(jsonEncode(chat.textFieldAttachments)),
      latestMessageDateUs: Value(_toMicros(chat.dbOnlyLatestMessageDate)),
      dateDeletedUs: Value(_toMicros(chat.dateDeleted)),
      style: Value(chat.style),
      lockChatName: Value(chat.lockChatName),
      lockChatIcon: Value(chat.lockChatIcon),
      lastReadMessageGuid: Value(chat.lastReadMessageGuid),
      customThemeLight: Value(chat.customThemeLight),
      customThemeDark: Value(chat.customThemeDark),
      wallpaperType: Value(chat.wallpaperType),
      dynamicWallpaperId: Value(chat.dynamicWallpaperId),
      dynamicWallpaperConfig: Value(chat.dynamicWallpaperConfig),
      customAvatarPath: Value(chat.customAvatarPath),
      customBackgroundPath: Value(chat.customBackgroundPath),
      pinIndex: Value(chat.pinIndex),
    );
    await database.into(database.chats).insertOnConflictUpdate(companion);
  }

  domain.Chat _fromRow(SqliteChatRow row) {
    return domain.Chat(
      id: row.id,
      guid: row.guid,
      chatIdentifier: row.chatIdentifier,
      serviceName: row.serviceName,
      groupId: row.groupId,
      originalGroupId: row.originalGroupId,
      legacyGroupIds: _decodeStringList(row.legacyGroupIdsJson),
      latestGroupTitle: row.latestGroupTitle,
      threadKey: row.threadKey,
      isArchived: row.isArchived,
      muteType: row.muteType,
      muteArgs: row.muteArgs,
      isPinned: row.isPinned,
      hasUnreadMessage: row.hasUnreadMessage,
      displayName: row.displayName,
      isFilteredAsSpam: row.isFilteredAsSpam,
      autoSendReadReceipts: row.autoSendReadReceipts,
      autoSendTypingIndicators: row.autoSendTypingIndicators,
      textFieldText: row.textFieldText,
      textFieldAttachments: _decodeStringList(row.textFieldAttachmentsJson) ?? const [],
      dateDeleted: _fromMicros(row.dateDeletedUs),
      style: row.style,
      lockChatName: row.lockChatName,
      lockChatIcon: row.lockChatIcon,
      lastReadMessageGuid: row.lastReadMessageGuid,
      customThemeLight: row.customThemeLight,
      customThemeDark: row.customThemeDark,
      wallpaperType: row.wallpaperType,
      dynamicWallpaperId: row.dynamicWallpaperId,
      dynamicWallpaperConfig: row.dynamicWallpaperConfig,
      customAvatar: row.customAvatarPath,
      customBackground: row.customBackgroundPath,
      pinnedIndex: row.pinIndex,
    )..dbOnlyLatestMessageDate = _fromMicros(row.latestMessageDateUs);
  }
}

int? _toMicros(DateTime? value) => value?.toUtc().microsecondsSinceEpoch;

DateTime? _fromMicros(int? value) => value == null ? null : DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true);

List<String>? _decodeStringList(String? value) {
  if (value == null) return null;
  return (jsonDecode(value) as List<dynamic>).cast<String>();
}
