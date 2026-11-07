import 'package:bluebubbles/database/io/chat.dart';
import 'package:bluebubbles/database/sqlite/app_database.dart';
import 'package:bluebubbles/database/sqlite/sqlite_chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chat round-trips every persisted scalar through SQLite', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final repository = SqliteChatRepository(database);
    final original = Chat(
      id: 42,
      guid: 'iMessage;-;chat-guid',
      chatIdentifier: 'chat-identifier',
      serviceName: 'iMessage',
      groupId: 'group-id',
      originalGroupId: 'original-group-id',
      legacyGroupIds: const ['legacy-1', 'legacy-2'],
      latestGroupTitle: '',
      threadKey: 'thread-key',
      isArchived: true,
      muteType: 'until',
      muteArgs: '{"until":123}',
      isPinned: false,
      hasUnreadMessage: true,
      displayName: 'Display name',
      isFilteredAsSpam: null,
      autoSendReadReceipts: true,
      autoSendTypingIndicators: false,
      textFieldText: 'draft',
      textFieldAttachments: const ['/tmp/a', '/tmp/b'],
      dateDeleted: DateTime.utc(2026, 11, 7, 1, 2, 3, 4, 5),
      style: 43,
      lockChatName: true,
      lockChatIcon: false,
      lastReadMessageGuid: 'last-read-guid',
      customThemeLight: '{"theme":"light"}',
      customThemeDark: '{"theme":"dark"}',
      wallpaperType: 'dynamic',
      dynamicWallpaperId: 'wallpaper-id',
      dynamicWallpaperConfig: '{"speed":2}',
      customAvatar: '/private/avatar',
      customBackground: '/private/background',
      pinnedIndex: 7,
    )..dbOnlyLatestMessageDate = DateTime.utc(2026, 11, 7, 2, 3, 4, 5, 6);

    await repository.save(original);
    final restored = await repository.byGuid(original.guid);

    expect(restored, isNotNull);
    expect(restored!.id, original.id);
    expect(restored.guid, original.guid);
    expect(restored.chatIdentifier, original.chatIdentifier);
    expect(restored.serviceName, original.serviceName);
    expect(restored.groupId, original.groupId);
    expect(restored.originalGroupId, original.originalGroupId);
    expect(restored.legacyGroupIds, original.legacyGroupIds);
    expect(restored.latestGroupTitle, original.latestGroupTitle);
    expect(restored.threadKey, original.threadKey);
    expect(restored.isArchived, original.isArchived);
    expect(restored.muteType, original.muteType);
    expect(restored.muteArgs, original.muteArgs);
    expect(restored.isPinned, original.isPinned);
    expect(restored.hasUnreadMessage, original.hasUnreadMessage);
    expect(restored.displayName, original.displayName);
    expect(restored.isFilteredAsSpam, isNull);
    expect(restored.autoSendReadReceipts, original.autoSendReadReceipts);
    expect(restored.autoSendTypingIndicators, original.autoSendTypingIndicators);
    expect(restored.textFieldText, original.textFieldText);
    expect(restored.textFieldAttachments, original.textFieldAttachments);
    expect(restored.dbOnlyLatestMessageDate, original.dbOnlyLatestMessageDate);
    expect(restored.dateDeleted, original.dateDeleted);
    expect(restored.style, original.style);
    expect(restored.lockChatName, original.lockChatName);
    expect(restored.lockChatIcon, original.lockChatIcon);
    expect(restored.lastReadMessageGuid, original.lastReadMessageGuid);
    expect(restored.customThemeLight, original.customThemeLight);
    expect(restored.customThemeDark, original.customThemeDark);
    expect(restored.wallpaperType, original.wallpaperType);
    expect(restored.dynamicWallpaperId, original.dynamicWallpaperId);
    expect(restored.dynamicWallpaperConfig, original.dynamicWallpaperConfig);
    expect(restored.customAvatarPath, original.customAvatarPath);
    expect(restored.customBackgroundPath, original.customBackgroundPath);
    expect(restored.pinIndex, original.pinIndex);
  });
}
