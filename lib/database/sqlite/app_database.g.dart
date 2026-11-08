// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ChatsTable extends Chats with TableInfo<$ChatsTable, SqliteChatRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _guidMeta = const VerificationMeta('guid');
  @override
  late final GeneratedColumn<String> guid = GeneratedColumn<String>(
    'guid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _chatIdentifierMeta = const VerificationMeta(
    'chatIdentifier',
  );
  @override
  late final GeneratedColumn<String> chatIdentifier = GeneratedColumn<String>(
    'chat_identifier',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serviceNameMeta = const VerificationMeta(
    'serviceName',
  );
  @override
  late final GeneratedColumn<String> serviceName = GeneratedColumn<String>(
    'service_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalGroupIdMeta = const VerificationMeta(
    'originalGroupId',
  );
  @override
  late final GeneratedColumn<String> originalGroupId = GeneratedColumn<String>(
    'original_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _legacyGroupIdsJsonMeta =
      const VerificationMeta('legacyGroupIdsJson');
  @override
  late final GeneratedColumn<String> legacyGroupIdsJson =
      GeneratedColumn<String>(
        'legacy_group_ids_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _latestGroupTitleMeta = const VerificationMeta(
    'latestGroupTitle',
  );
  @override
  late final GeneratedColumn<String> latestGroupTitle = GeneratedColumn<String>(
    'latest_group_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _threadKeyMeta = const VerificationMeta(
    'threadKey',
  );
  @override
  late final GeneratedColumn<String> threadKey = GeneratedColumn<String>(
    'thread_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
  );
  static const VerificationMeta _muteTypeMeta = const VerificationMeta(
    'muteType',
  );
  @override
  late final GeneratedColumn<String> muteType = GeneratedColumn<String>(
    'mute_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _muteArgsMeta = const VerificationMeta(
    'muteArgs',
  );
  @override
  late final GeneratedColumn<String> muteArgs = GeneratedColumn<String>(
    'mute_args',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
  );
  static const VerificationMeta _hasUnreadMessageMeta = const VerificationMeta(
    'hasUnreadMessage',
  );
  @override
  late final GeneratedColumn<bool> hasUnreadMessage = GeneratedColumn<bool>(
    'has_unread_message',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_unread_message" IN (0, 1))',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFilteredAsSpamMeta = const VerificationMeta(
    'isFilteredAsSpam',
  );
  @override
  late final GeneratedColumn<bool> isFilteredAsSpam = GeneratedColumn<bool>(
    'is_filtered_as_spam',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_filtered_as_spam" IN (0, 1))',
    ),
  );
  static const VerificationMeta _autoSendReadReceiptsMeta =
      const VerificationMeta('autoSendReadReceipts');
  @override
  late final GeneratedColumn<bool> autoSendReadReceipts = GeneratedColumn<bool>(
    'auto_send_read_receipts',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_send_read_receipts" IN (0, 1))',
    ),
  );
  static const VerificationMeta _autoSendTypingIndicatorsMeta =
      const VerificationMeta('autoSendTypingIndicators');
  @override
  late final GeneratedColumn<bool> autoSendTypingIndicators =
      GeneratedColumn<bool>(
        'auto_send_typing_indicators',
        aliasedName,
        true,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("auto_send_typing_indicators" IN (0, 1))',
        ),
      );
  static const VerificationMeta _textFieldTextMeta = const VerificationMeta(
    'textFieldText',
  );
  @override
  late final GeneratedColumn<String> textFieldText = GeneratedColumn<String>(
    'text_field_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textFieldAttachmentsJsonMeta =
      const VerificationMeta('textFieldAttachmentsJson');
  @override
  late final GeneratedColumn<String> textFieldAttachmentsJson =
      GeneratedColumn<String>(
        'text_field_attachments_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _latestMessageIdMeta = const VerificationMeta(
    'latestMessageId',
  );
  @override
  late final GeneratedColumn<int> latestMessageId = GeneratedColumn<int>(
    'latest_message_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latestMessageDateUsMeta =
      const VerificationMeta('latestMessageDateUs');
  @override
  late final GeneratedColumn<int> latestMessageDateUs = GeneratedColumn<int>(
    'latest_message_date_us',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateDeletedUsMeta = const VerificationMeta(
    'dateDeletedUs',
  );
  @override
  late final GeneratedColumn<int> dateDeletedUs = GeneratedColumn<int>(
    'date_deleted_us',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<int> style = GeneratedColumn<int>(
    'style',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lockChatNameMeta = const VerificationMeta(
    'lockChatName',
  );
  @override
  late final GeneratedColumn<bool> lockChatName = GeneratedColumn<bool>(
    'lock_chat_name',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("lock_chat_name" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lockChatIconMeta = const VerificationMeta(
    'lockChatIcon',
  );
  @override
  late final GeneratedColumn<bool> lockChatIcon = GeneratedColumn<bool>(
    'lock_chat_icon',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("lock_chat_icon" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastReadMessageGuidMeta =
      const VerificationMeta('lastReadMessageGuid');
  @override
  late final GeneratedColumn<String> lastReadMessageGuid =
      GeneratedColumn<String>(
        'last_read_message_guid',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _customThemeLightMeta = const VerificationMeta(
    'customThemeLight',
  );
  @override
  late final GeneratedColumn<String> customThemeLight = GeneratedColumn<String>(
    'custom_theme_light',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customThemeDarkMeta = const VerificationMeta(
    'customThemeDark',
  );
  @override
  late final GeneratedColumn<String> customThemeDark = GeneratedColumn<String>(
    'custom_theme_dark',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wallpaperTypeMeta = const VerificationMeta(
    'wallpaperType',
  );
  @override
  late final GeneratedColumn<String> wallpaperType = GeneratedColumn<String>(
    'wallpaper_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dynamicWallpaperIdMeta =
      const VerificationMeta('dynamicWallpaperId');
  @override
  late final GeneratedColumn<String> dynamicWallpaperId =
      GeneratedColumn<String>(
        'dynamic_wallpaper_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _dynamicWallpaperConfigMeta =
      const VerificationMeta('dynamicWallpaperConfig');
  @override
  late final GeneratedColumn<String> dynamicWallpaperConfig =
      GeneratedColumn<String>(
        'dynamic_wallpaper_config',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _customAvatarPathMeta = const VerificationMeta(
    'customAvatarPath',
  );
  @override
  late final GeneratedColumn<String> customAvatarPath = GeneratedColumn<String>(
    'custom_avatar_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customBackgroundPathMeta =
      const VerificationMeta('customBackgroundPath');
  @override
  late final GeneratedColumn<String> customBackgroundPath =
      GeneratedColumn<String>(
        'custom_background_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _pinIndexMeta = const VerificationMeta(
    'pinIndex',
  );
  @override
  late final GeneratedColumn<int> pinIndex = GeneratedColumn<int>(
    'pin_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    guid,
    chatIdentifier,
    serviceName,
    groupId,
    originalGroupId,
    legacyGroupIdsJson,
    latestGroupTitle,
    threadKey,
    isArchived,
    muteType,
    muteArgs,
    isPinned,
    hasUnreadMessage,
    displayName,
    isFilteredAsSpam,
    autoSendReadReceipts,
    autoSendTypingIndicators,
    textFieldText,
    textFieldAttachmentsJson,
    latestMessageId,
    latestMessageDateUs,
    dateDeletedUs,
    style,
    lockChatName,
    lockChatIcon,
    lastReadMessageGuid,
    customThemeLight,
    customThemeDark,
    wallpaperType,
    dynamicWallpaperId,
    dynamicWallpaperConfig,
    customAvatarPath,
    customBackgroundPath,
    pinIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chats';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteChatRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('guid')) {
      context.handle(
        _guidMeta,
        guid.isAcceptableOrUnknown(data['guid']!, _guidMeta),
      );
    } else if (isInserting) {
      context.missing(_guidMeta);
    }
    if (data.containsKey('chat_identifier')) {
      context.handle(
        _chatIdentifierMeta,
        chatIdentifier.isAcceptableOrUnknown(
          data['chat_identifier']!,
          _chatIdentifierMeta,
        ),
      );
    }
    if (data.containsKey('service_name')) {
      context.handle(
        _serviceNameMeta,
        serviceName.isAcceptableOrUnknown(
          data['service_name']!,
          _serviceNameMeta,
        ),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('original_group_id')) {
      context.handle(
        _originalGroupIdMeta,
        originalGroupId.isAcceptableOrUnknown(
          data['original_group_id']!,
          _originalGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('legacy_group_ids_json')) {
      context.handle(
        _legacyGroupIdsJsonMeta,
        legacyGroupIdsJson.isAcceptableOrUnknown(
          data['legacy_group_ids_json']!,
          _legacyGroupIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('latest_group_title')) {
      context.handle(
        _latestGroupTitleMeta,
        latestGroupTitle.isAcceptableOrUnknown(
          data['latest_group_title']!,
          _latestGroupTitleMeta,
        ),
      );
    }
    if (data.containsKey('thread_key')) {
      context.handle(
        _threadKeyMeta,
        threadKey.isAcceptableOrUnknown(data['thread_key']!, _threadKeyMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('mute_type')) {
      context.handle(
        _muteTypeMeta,
        muteType.isAcceptableOrUnknown(data['mute_type']!, _muteTypeMeta),
      );
    }
    if (data.containsKey('mute_args')) {
      context.handle(
        _muteArgsMeta,
        muteArgs.isAcceptableOrUnknown(data['mute_args']!, _muteArgsMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('has_unread_message')) {
      context.handle(
        _hasUnreadMessageMeta,
        hasUnreadMessage.isAcceptableOrUnknown(
          data['has_unread_message']!,
          _hasUnreadMessageMeta,
        ),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('is_filtered_as_spam')) {
      context.handle(
        _isFilteredAsSpamMeta,
        isFilteredAsSpam.isAcceptableOrUnknown(
          data['is_filtered_as_spam']!,
          _isFilteredAsSpamMeta,
        ),
      );
    }
    if (data.containsKey('auto_send_read_receipts')) {
      context.handle(
        _autoSendReadReceiptsMeta,
        autoSendReadReceipts.isAcceptableOrUnknown(
          data['auto_send_read_receipts']!,
          _autoSendReadReceiptsMeta,
        ),
      );
    }
    if (data.containsKey('auto_send_typing_indicators')) {
      context.handle(
        _autoSendTypingIndicatorsMeta,
        autoSendTypingIndicators.isAcceptableOrUnknown(
          data['auto_send_typing_indicators']!,
          _autoSendTypingIndicatorsMeta,
        ),
      );
    }
    if (data.containsKey('text_field_text')) {
      context.handle(
        _textFieldTextMeta,
        textFieldText.isAcceptableOrUnknown(
          data['text_field_text']!,
          _textFieldTextMeta,
        ),
      );
    }
    if (data.containsKey('text_field_attachments_json')) {
      context.handle(
        _textFieldAttachmentsJsonMeta,
        textFieldAttachmentsJson.isAcceptableOrUnknown(
          data['text_field_attachments_json']!,
          _textFieldAttachmentsJsonMeta,
        ),
      );
    }
    if (data.containsKey('latest_message_id')) {
      context.handle(
        _latestMessageIdMeta,
        latestMessageId.isAcceptableOrUnknown(
          data['latest_message_id']!,
          _latestMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('latest_message_date_us')) {
      context.handle(
        _latestMessageDateUsMeta,
        latestMessageDateUs.isAcceptableOrUnknown(
          data['latest_message_date_us']!,
          _latestMessageDateUsMeta,
        ),
      );
    }
    if (data.containsKey('date_deleted_us')) {
      context.handle(
        _dateDeletedUsMeta,
        dateDeletedUs.isAcceptableOrUnknown(
          data['date_deleted_us']!,
          _dateDeletedUsMeta,
        ),
      );
    }
    if (data.containsKey('style')) {
      context.handle(
        _styleMeta,
        style.isAcceptableOrUnknown(data['style']!, _styleMeta),
      );
    }
    if (data.containsKey('lock_chat_name')) {
      context.handle(
        _lockChatNameMeta,
        lockChatName.isAcceptableOrUnknown(
          data['lock_chat_name']!,
          _lockChatNameMeta,
        ),
      );
    }
    if (data.containsKey('lock_chat_icon')) {
      context.handle(
        _lockChatIconMeta,
        lockChatIcon.isAcceptableOrUnknown(
          data['lock_chat_icon']!,
          _lockChatIconMeta,
        ),
      );
    }
    if (data.containsKey('last_read_message_guid')) {
      context.handle(
        _lastReadMessageGuidMeta,
        lastReadMessageGuid.isAcceptableOrUnknown(
          data['last_read_message_guid']!,
          _lastReadMessageGuidMeta,
        ),
      );
    }
    if (data.containsKey('custom_theme_light')) {
      context.handle(
        _customThemeLightMeta,
        customThemeLight.isAcceptableOrUnknown(
          data['custom_theme_light']!,
          _customThemeLightMeta,
        ),
      );
    }
    if (data.containsKey('custom_theme_dark')) {
      context.handle(
        _customThemeDarkMeta,
        customThemeDark.isAcceptableOrUnknown(
          data['custom_theme_dark']!,
          _customThemeDarkMeta,
        ),
      );
    }
    if (data.containsKey('wallpaper_type')) {
      context.handle(
        _wallpaperTypeMeta,
        wallpaperType.isAcceptableOrUnknown(
          data['wallpaper_type']!,
          _wallpaperTypeMeta,
        ),
      );
    }
    if (data.containsKey('dynamic_wallpaper_id')) {
      context.handle(
        _dynamicWallpaperIdMeta,
        dynamicWallpaperId.isAcceptableOrUnknown(
          data['dynamic_wallpaper_id']!,
          _dynamicWallpaperIdMeta,
        ),
      );
    }
    if (data.containsKey('dynamic_wallpaper_config')) {
      context.handle(
        _dynamicWallpaperConfigMeta,
        dynamicWallpaperConfig.isAcceptableOrUnknown(
          data['dynamic_wallpaper_config']!,
          _dynamicWallpaperConfigMeta,
        ),
      );
    }
    if (data.containsKey('custom_avatar_path')) {
      context.handle(
        _customAvatarPathMeta,
        customAvatarPath.isAcceptableOrUnknown(
          data['custom_avatar_path']!,
          _customAvatarPathMeta,
        ),
      );
    }
    if (data.containsKey('custom_background_path')) {
      context.handle(
        _customBackgroundPathMeta,
        customBackgroundPath.isAcceptableOrUnknown(
          data['custom_background_path']!,
          _customBackgroundPathMeta,
        ),
      );
    }
    if (data.containsKey('pin_index')) {
      context.handle(
        _pinIndexMeta,
        pinIndex.isAcceptableOrUnknown(data['pin_index']!, _pinIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SqliteChatRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteChatRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      guid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guid'],
      )!,
      chatIdentifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_identifier'],
      ),
      serviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_name'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      originalGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_group_id'],
      ),
      legacyGroupIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_group_ids_json'],
      ),
      latestGroupTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latest_group_title'],
      ),
      threadKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_key'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      ),
      muteType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mute_type'],
      ),
      muteArgs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mute_args'],
      ),
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      ),
      hasUnreadMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_unread_message'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      isFilteredAsSpam: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_filtered_as_spam'],
      ),
      autoSendReadReceipts: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_send_read_receipts'],
      ),
      autoSendTypingIndicators: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_send_typing_indicators'],
      ),
      textFieldText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_field_text'],
      ),
      textFieldAttachmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_field_attachments_json'],
      )!,
      latestMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latest_message_id'],
      ),
      latestMessageDateUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latest_message_date_us'],
      ),
      dateDeletedUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_deleted_us'],
      ),
      style: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}style'],
      ),
      lockChatName: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}lock_chat_name'],
      )!,
      lockChatIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}lock_chat_icon'],
      )!,
      lastReadMessageGuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_read_message_guid'],
      ),
      customThemeLight: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_theme_light'],
      ),
      customThemeDark: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_theme_dark'],
      ),
      wallpaperType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wallpaper_type'],
      ),
      dynamicWallpaperId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dynamic_wallpaper_id'],
      ),
      dynamicWallpaperConfig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dynamic_wallpaper_config'],
      ),
      customAvatarPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_avatar_path'],
      ),
      customBackgroundPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_background_path'],
      ),
      pinIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pin_index'],
      ),
    );
  }

  @override
  $ChatsTable createAlias(String alias) {
    return $ChatsTable(attachedDatabase, alias);
  }
}

class SqliteChatRow extends DataClass implements Insertable<SqliteChatRow> {
  final int id;
  final String guid;
  final String? chatIdentifier;
  final String? serviceName;
  final String? groupId;
  final String? originalGroupId;
  final String? legacyGroupIdsJson;
  final String? latestGroupTitle;
  final String? threadKey;
  final bool? isArchived;
  final String? muteType;
  final String? muteArgs;
  final bool? isPinned;
  final bool? hasUnreadMessage;
  final String? displayName;
  final bool? isFilteredAsSpam;
  final bool? autoSendReadReceipts;
  final bool? autoSendTypingIndicators;
  final String? textFieldText;
  final String textFieldAttachmentsJson;
  final int? latestMessageId;
  final int? latestMessageDateUs;
  final int? dateDeletedUs;
  final int? style;
  final bool lockChatName;
  final bool lockChatIcon;
  final String? lastReadMessageGuid;
  final String? customThemeLight;
  final String? customThemeDark;
  final String? wallpaperType;
  final String? dynamicWallpaperId;
  final String? dynamicWallpaperConfig;
  final String? customAvatarPath;
  final String? customBackgroundPath;
  final int? pinIndex;
  const SqliteChatRow({
    required this.id,
    required this.guid,
    this.chatIdentifier,
    this.serviceName,
    this.groupId,
    this.originalGroupId,
    this.legacyGroupIdsJson,
    this.latestGroupTitle,
    this.threadKey,
    this.isArchived,
    this.muteType,
    this.muteArgs,
    this.isPinned,
    this.hasUnreadMessage,
    this.displayName,
    this.isFilteredAsSpam,
    this.autoSendReadReceipts,
    this.autoSendTypingIndicators,
    this.textFieldText,
    required this.textFieldAttachmentsJson,
    this.latestMessageId,
    this.latestMessageDateUs,
    this.dateDeletedUs,
    this.style,
    required this.lockChatName,
    required this.lockChatIcon,
    this.lastReadMessageGuid,
    this.customThemeLight,
    this.customThemeDark,
    this.wallpaperType,
    this.dynamicWallpaperId,
    this.dynamicWallpaperConfig,
    this.customAvatarPath,
    this.customBackgroundPath,
    this.pinIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['guid'] = Variable<String>(guid);
    if (!nullToAbsent || chatIdentifier != null) {
      map['chat_identifier'] = Variable<String>(chatIdentifier);
    }
    if (!nullToAbsent || serviceName != null) {
      map['service_name'] = Variable<String>(serviceName);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || originalGroupId != null) {
      map['original_group_id'] = Variable<String>(originalGroupId);
    }
    if (!nullToAbsent || legacyGroupIdsJson != null) {
      map['legacy_group_ids_json'] = Variable<String>(legacyGroupIdsJson);
    }
    if (!nullToAbsent || latestGroupTitle != null) {
      map['latest_group_title'] = Variable<String>(latestGroupTitle);
    }
    if (!nullToAbsent || threadKey != null) {
      map['thread_key'] = Variable<String>(threadKey);
    }
    if (!nullToAbsent || isArchived != null) {
      map['is_archived'] = Variable<bool>(isArchived);
    }
    if (!nullToAbsent || muteType != null) {
      map['mute_type'] = Variable<String>(muteType);
    }
    if (!nullToAbsent || muteArgs != null) {
      map['mute_args'] = Variable<String>(muteArgs);
    }
    if (!nullToAbsent || isPinned != null) {
      map['is_pinned'] = Variable<bool>(isPinned);
    }
    if (!nullToAbsent || hasUnreadMessage != null) {
      map['has_unread_message'] = Variable<bool>(hasUnreadMessage);
    }
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || isFilteredAsSpam != null) {
      map['is_filtered_as_spam'] = Variable<bool>(isFilteredAsSpam);
    }
    if (!nullToAbsent || autoSendReadReceipts != null) {
      map['auto_send_read_receipts'] = Variable<bool>(autoSendReadReceipts);
    }
    if (!nullToAbsent || autoSendTypingIndicators != null) {
      map['auto_send_typing_indicators'] = Variable<bool>(
        autoSendTypingIndicators,
      );
    }
    if (!nullToAbsent || textFieldText != null) {
      map['text_field_text'] = Variable<String>(textFieldText);
    }
    map['text_field_attachments_json'] = Variable<String>(
      textFieldAttachmentsJson,
    );
    if (!nullToAbsent || latestMessageId != null) {
      map['latest_message_id'] = Variable<int>(latestMessageId);
    }
    if (!nullToAbsent || latestMessageDateUs != null) {
      map['latest_message_date_us'] = Variable<int>(latestMessageDateUs);
    }
    if (!nullToAbsent || dateDeletedUs != null) {
      map['date_deleted_us'] = Variable<int>(dateDeletedUs);
    }
    if (!nullToAbsent || style != null) {
      map['style'] = Variable<int>(style);
    }
    map['lock_chat_name'] = Variable<bool>(lockChatName);
    map['lock_chat_icon'] = Variable<bool>(lockChatIcon);
    if (!nullToAbsent || lastReadMessageGuid != null) {
      map['last_read_message_guid'] = Variable<String>(lastReadMessageGuid);
    }
    if (!nullToAbsent || customThemeLight != null) {
      map['custom_theme_light'] = Variable<String>(customThemeLight);
    }
    if (!nullToAbsent || customThemeDark != null) {
      map['custom_theme_dark'] = Variable<String>(customThemeDark);
    }
    if (!nullToAbsent || wallpaperType != null) {
      map['wallpaper_type'] = Variable<String>(wallpaperType);
    }
    if (!nullToAbsent || dynamicWallpaperId != null) {
      map['dynamic_wallpaper_id'] = Variable<String>(dynamicWallpaperId);
    }
    if (!nullToAbsent || dynamicWallpaperConfig != null) {
      map['dynamic_wallpaper_config'] = Variable<String>(
        dynamicWallpaperConfig,
      );
    }
    if (!nullToAbsent || customAvatarPath != null) {
      map['custom_avatar_path'] = Variable<String>(customAvatarPath);
    }
    if (!nullToAbsent || customBackgroundPath != null) {
      map['custom_background_path'] = Variable<String>(customBackgroundPath);
    }
    if (!nullToAbsent || pinIndex != null) {
      map['pin_index'] = Variable<int>(pinIndex);
    }
    return map;
  }

  ChatsCompanion toCompanion(bool nullToAbsent) {
    return ChatsCompanion(
      id: Value(id),
      guid: Value(guid),
      chatIdentifier: chatIdentifier == null && nullToAbsent
          ? const Value.absent()
          : Value(chatIdentifier),
      serviceName: serviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceName),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      originalGroupId: originalGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(originalGroupId),
      legacyGroupIdsJson: legacyGroupIdsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyGroupIdsJson),
      latestGroupTitle: latestGroupTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(latestGroupTitle),
      threadKey: threadKey == null && nullToAbsent
          ? const Value.absent()
          : Value(threadKey),
      isArchived: isArchived == null && nullToAbsent
          ? const Value.absent()
          : Value(isArchived),
      muteType: muteType == null && nullToAbsent
          ? const Value.absent()
          : Value(muteType),
      muteArgs: muteArgs == null && nullToAbsent
          ? const Value.absent()
          : Value(muteArgs),
      isPinned: isPinned == null && nullToAbsent
          ? const Value.absent()
          : Value(isPinned),
      hasUnreadMessage: hasUnreadMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(hasUnreadMessage),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      isFilteredAsSpam: isFilteredAsSpam == null && nullToAbsent
          ? const Value.absent()
          : Value(isFilteredAsSpam),
      autoSendReadReceipts: autoSendReadReceipts == null && nullToAbsent
          ? const Value.absent()
          : Value(autoSendReadReceipts),
      autoSendTypingIndicators: autoSendTypingIndicators == null && nullToAbsent
          ? const Value.absent()
          : Value(autoSendTypingIndicators),
      textFieldText: textFieldText == null && nullToAbsent
          ? const Value.absent()
          : Value(textFieldText),
      textFieldAttachmentsJson: Value(textFieldAttachmentsJson),
      latestMessageId: latestMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(latestMessageId),
      latestMessageDateUs: latestMessageDateUs == null && nullToAbsent
          ? const Value.absent()
          : Value(latestMessageDateUs),
      dateDeletedUs: dateDeletedUs == null && nullToAbsent
          ? const Value.absent()
          : Value(dateDeletedUs),
      style: style == null && nullToAbsent
          ? const Value.absent()
          : Value(style),
      lockChatName: Value(lockChatName),
      lockChatIcon: Value(lockChatIcon),
      lastReadMessageGuid: lastReadMessageGuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadMessageGuid),
      customThemeLight: customThemeLight == null && nullToAbsent
          ? const Value.absent()
          : Value(customThemeLight),
      customThemeDark: customThemeDark == null && nullToAbsent
          ? const Value.absent()
          : Value(customThemeDark),
      wallpaperType: wallpaperType == null && nullToAbsent
          ? const Value.absent()
          : Value(wallpaperType),
      dynamicWallpaperId: dynamicWallpaperId == null && nullToAbsent
          ? const Value.absent()
          : Value(dynamicWallpaperId),
      dynamicWallpaperConfig: dynamicWallpaperConfig == null && nullToAbsent
          ? const Value.absent()
          : Value(dynamicWallpaperConfig),
      customAvatarPath: customAvatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(customAvatarPath),
      customBackgroundPath: customBackgroundPath == null && nullToAbsent
          ? const Value.absent()
          : Value(customBackgroundPath),
      pinIndex: pinIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(pinIndex),
    );
  }

  factory SqliteChatRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteChatRow(
      id: serializer.fromJson<int>(json['id']),
      guid: serializer.fromJson<String>(json['guid']),
      chatIdentifier: serializer.fromJson<String?>(json['chatIdentifier']),
      serviceName: serializer.fromJson<String?>(json['serviceName']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      originalGroupId: serializer.fromJson<String?>(json['originalGroupId']),
      legacyGroupIdsJson: serializer.fromJson<String?>(
        json['legacyGroupIdsJson'],
      ),
      latestGroupTitle: serializer.fromJson<String?>(json['latestGroupTitle']),
      threadKey: serializer.fromJson<String?>(json['threadKey']),
      isArchived: serializer.fromJson<bool?>(json['isArchived']),
      muteType: serializer.fromJson<String?>(json['muteType']),
      muteArgs: serializer.fromJson<String?>(json['muteArgs']),
      isPinned: serializer.fromJson<bool?>(json['isPinned']),
      hasUnreadMessage: serializer.fromJson<bool?>(json['hasUnreadMessage']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      isFilteredAsSpam: serializer.fromJson<bool?>(json['isFilteredAsSpam']),
      autoSendReadReceipts: serializer.fromJson<bool?>(
        json['autoSendReadReceipts'],
      ),
      autoSendTypingIndicators: serializer.fromJson<bool?>(
        json['autoSendTypingIndicators'],
      ),
      textFieldText: serializer.fromJson<String?>(json['textFieldText']),
      textFieldAttachmentsJson: serializer.fromJson<String>(
        json['textFieldAttachmentsJson'],
      ),
      latestMessageId: serializer.fromJson<int?>(json['latestMessageId']),
      latestMessageDateUs: serializer.fromJson<int?>(
        json['latestMessageDateUs'],
      ),
      dateDeletedUs: serializer.fromJson<int?>(json['dateDeletedUs']),
      style: serializer.fromJson<int?>(json['style']),
      lockChatName: serializer.fromJson<bool>(json['lockChatName']),
      lockChatIcon: serializer.fromJson<bool>(json['lockChatIcon']),
      lastReadMessageGuid: serializer.fromJson<String?>(
        json['lastReadMessageGuid'],
      ),
      customThemeLight: serializer.fromJson<String?>(json['customThemeLight']),
      customThemeDark: serializer.fromJson<String?>(json['customThemeDark']),
      wallpaperType: serializer.fromJson<String?>(json['wallpaperType']),
      dynamicWallpaperId: serializer.fromJson<String?>(
        json['dynamicWallpaperId'],
      ),
      dynamicWallpaperConfig: serializer.fromJson<String?>(
        json['dynamicWallpaperConfig'],
      ),
      customAvatarPath: serializer.fromJson<String?>(json['customAvatarPath']),
      customBackgroundPath: serializer.fromJson<String?>(
        json['customBackgroundPath'],
      ),
      pinIndex: serializer.fromJson<int?>(json['pinIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'guid': serializer.toJson<String>(guid),
      'chatIdentifier': serializer.toJson<String?>(chatIdentifier),
      'serviceName': serializer.toJson<String?>(serviceName),
      'groupId': serializer.toJson<String?>(groupId),
      'originalGroupId': serializer.toJson<String?>(originalGroupId),
      'legacyGroupIdsJson': serializer.toJson<String?>(legacyGroupIdsJson),
      'latestGroupTitle': serializer.toJson<String?>(latestGroupTitle),
      'threadKey': serializer.toJson<String?>(threadKey),
      'isArchived': serializer.toJson<bool?>(isArchived),
      'muteType': serializer.toJson<String?>(muteType),
      'muteArgs': serializer.toJson<String?>(muteArgs),
      'isPinned': serializer.toJson<bool?>(isPinned),
      'hasUnreadMessage': serializer.toJson<bool?>(hasUnreadMessage),
      'displayName': serializer.toJson<String?>(displayName),
      'isFilteredAsSpam': serializer.toJson<bool?>(isFilteredAsSpam),
      'autoSendReadReceipts': serializer.toJson<bool?>(autoSendReadReceipts),
      'autoSendTypingIndicators': serializer.toJson<bool?>(
        autoSendTypingIndicators,
      ),
      'textFieldText': serializer.toJson<String?>(textFieldText),
      'textFieldAttachmentsJson': serializer.toJson<String>(
        textFieldAttachmentsJson,
      ),
      'latestMessageId': serializer.toJson<int?>(latestMessageId),
      'latestMessageDateUs': serializer.toJson<int?>(latestMessageDateUs),
      'dateDeletedUs': serializer.toJson<int?>(dateDeletedUs),
      'style': serializer.toJson<int?>(style),
      'lockChatName': serializer.toJson<bool>(lockChatName),
      'lockChatIcon': serializer.toJson<bool>(lockChatIcon),
      'lastReadMessageGuid': serializer.toJson<String?>(lastReadMessageGuid),
      'customThemeLight': serializer.toJson<String?>(customThemeLight),
      'customThemeDark': serializer.toJson<String?>(customThemeDark),
      'wallpaperType': serializer.toJson<String?>(wallpaperType),
      'dynamicWallpaperId': serializer.toJson<String?>(dynamicWallpaperId),
      'dynamicWallpaperConfig': serializer.toJson<String?>(
        dynamicWallpaperConfig,
      ),
      'customAvatarPath': serializer.toJson<String?>(customAvatarPath),
      'customBackgroundPath': serializer.toJson<String?>(customBackgroundPath),
      'pinIndex': serializer.toJson<int?>(pinIndex),
    };
  }

  SqliteChatRow copyWith({
    int? id,
    String? guid,
    Value<String?> chatIdentifier = const Value.absent(),
    Value<String?> serviceName = const Value.absent(),
    Value<String?> groupId = const Value.absent(),
    Value<String?> originalGroupId = const Value.absent(),
    Value<String?> legacyGroupIdsJson = const Value.absent(),
    Value<String?> latestGroupTitle = const Value.absent(),
    Value<String?> threadKey = const Value.absent(),
    Value<bool?> isArchived = const Value.absent(),
    Value<String?> muteType = const Value.absent(),
    Value<String?> muteArgs = const Value.absent(),
    Value<bool?> isPinned = const Value.absent(),
    Value<bool?> hasUnreadMessage = const Value.absent(),
    Value<String?> displayName = const Value.absent(),
    Value<bool?> isFilteredAsSpam = const Value.absent(),
    Value<bool?> autoSendReadReceipts = const Value.absent(),
    Value<bool?> autoSendTypingIndicators = const Value.absent(),
    Value<String?> textFieldText = const Value.absent(),
    String? textFieldAttachmentsJson,
    Value<int?> latestMessageId = const Value.absent(),
    Value<int?> latestMessageDateUs = const Value.absent(),
    Value<int?> dateDeletedUs = const Value.absent(),
    Value<int?> style = const Value.absent(),
    bool? lockChatName,
    bool? lockChatIcon,
    Value<String?> lastReadMessageGuid = const Value.absent(),
    Value<String?> customThemeLight = const Value.absent(),
    Value<String?> customThemeDark = const Value.absent(),
    Value<String?> wallpaperType = const Value.absent(),
    Value<String?> dynamicWallpaperId = const Value.absent(),
    Value<String?> dynamicWallpaperConfig = const Value.absent(),
    Value<String?> customAvatarPath = const Value.absent(),
    Value<String?> customBackgroundPath = const Value.absent(),
    Value<int?> pinIndex = const Value.absent(),
  }) => SqliteChatRow(
    id: id ?? this.id,
    guid: guid ?? this.guid,
    chatIdentifier: chatIdentifier.present
        ? chatIdentifier.value
        : this.chatIdentifier,
    serviceName: serviceName.present ? serviceName.value : this.serviceName,
    groupId: groupId.present ? groupId.value : this.groupId,
    originalGroupId: originalGroupId.present
        ? originalGroupId.value
        : this.originalGroupId,
    legacyGroupIdsJson: legacyGroupIdsJson.present
        ? legacyGroupIdsJson.value
        : this.legacyGroupIdsJson,
    latestGroupTitle: latestGroupTitle.present
        ? latestGroupTitle.value
        : this.latestGroupTitle,
    threadKey: threadKey.present ? threadKey.value : this.threadKey,
    isArchived: isArchived.present ? isArchived.value : this.isArchived,
    muteType: muteType.present ? muteType.value : this.muteType,
    muteArgs: muteArgs.present ? muteArgs.value : this.muteArgs,
    isPinned: isPinned.present ? isPinned.value : this.isPinned,
    hasUnreadMessage: hasUnreadMessage.present
        ? hasUnreadMessage.value
        : this.hasUnreadMessage,
    displayName: displayName.present ? displayName.value : this.displayName,
    isFilteredAsSpam: isFilteredAsSpam.present
        ? isFilteredAsSpam.value
        : this.isFilteredAsSpam,
    autoSendReadReceipts: autoSendReadReceipts.present
        ? autoSendReadReceipts.value
        : this.autoSendReadReceipts,
    autoSendTypingIndicators: autoSendTypingIndicators.present
        ? autoSendTypingIndicators.value
        : this.autoSendTypingIndicators,
    textFieldText: textFieldText.present
        ? textFieldText.value
        : this.textFieldText,
    textFieldAttachmentsJson:
        textFieldAttachmentsJson ?? this.textFieldAttachmentsJson,
    latestMessageId: latestMessageId.present
        ? latestMessageId.value
        : this.latestMessageId,
    latestMessageDateUs: latestMessageDateUs.present
        ? latestMessageDateUs.value
        : this.latestMessageDateUs,
    dateDeletedUs: dateDeletedUs.present
        ? dateDeletedUs.value
        : this.dateDeletedUs,
    style: style.present ? style.value : this.style,
    lockChatName: lockChatName ?? this.lockChatName,
    lockChatIcon: lockChatIcon ?? this.lockChatIcon,
    lastReadMessageGuid: lastReadMessageGuid.present
        ? lastReadMessageGuid.value
        : this.lastReadMessageGuid,
    customThemeLight: customThemeLight.present
        ? customThemeLight.value
        : this.customThemeLight,
    customThemeDark: customThemeDark.present
        ? customThemeDark.value
        : this.customThemeDark,
    wallpaperType: wallpaperType.present
        ? wallpaperType.value
        : this.wallpaperType,
    dynamicWallpaperId: dynamicWallpaperId.present
        ? dynamicWallpaperId.value
        : this.dynamicWallpaperId,
    dynamicWallpaperConfig: dynamicWallpaperConfig.present
        ? dynamicWallpaperConfig.value
        : this.dynamicWallpaperConfig,
    customAvatarPath: customAvatarPath.present
        ? customAvatarPath.value
        : this.customAvatarPath,
    customBackgroundPath: customBackgroundPath.present
        ? customBackgroundPath.value
        : this.customBackgroundPath,
    pinIndex: pinIndex.present ? pinIndex.value : this.pinIndex,
  );
  SqliteChatRow copyWithCompanion(ChatsCompanion data) {
    return SqliteChatRow(
      id: data.id.present ? data.id.value : this.id,
      guid: data.guid.present ? data.guid.value : this.guid,
      chatIdentifier: data.chatIdentifier.present
          ? data.chatIdentifier.value
          : this.chatIdentifier,
      serviceName: data.serviceName.present
          ? data.serviceName.value
          : this.serviceName,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      originalGroupId: data.originalGroupId.present
          ? data.originalGroupId.value
          : this.originalGroupId,
      legacyGroupIdsJson: data.legacyGroupIdsJson.present
          ? data.legacyGroupIdsJson.value
          : this.legacyGroupIdsJson,
      latestGroupTitle: data.latestGroupTitle.present
          ? data.latestGroupTitle.value
          : this.latestGroupTitle,
      threadKey: data.threadKey.present ? data.threadKey.value : this.threadKey,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      muteType: data.muteType.present ? data.muteType.value : this.muteType,
      muteArgs: data.muteArgs.present ? data.muteArgs.value : this.muteArgs,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      hasUnreadMessage: data.hasUnreadMessage.present
          ? data.hasUnreadMessage.value
          : this.hasUnreadMessage,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      isFilteredAsSpam: data.isFilteredAsSpam.present
          ? data.isFilteredAsSpam.value
          : this.isFilteredAsSpam,
      autoSendReadReceipts: data.autoSendReadReceipts.present
          ? data.autoSendReadReceipts.value
          : this.autoSendReadReceipts,
      autoSendTypingIndicators: data.autoSendTypingIndicators.present
          ? data.autoSendTypingIndicators.value
          : this.autoSendTypingIndicators,
      textFieldText: data.textFieldText.present
          ? data.textFieldText.value
          : this.textFieldText,
      textFieldAttachmentsJson: data.textFieldAttachmentsJson.present
          ? data.textFieldAttachmentsJson.value
          : this.textFieldAttachmentsJson,
      latestMessageId: data.latestMessageId.present
          ? data.latestMessageId.value
          : this.latestMessageId,
      latestMessageDateUs: data.latestMessageDateUs.present
          ? data.latestMessageDateUs.value
          : this.latestMessageDateUs,
      dateDeletedUs: data.dateDeletedUs.present
          ? data.dateDeletedUs.value
          : this.dateDeletedUs,
      style: data.style.present ? data.style.value : this.style,
      lockChatName: data.lockChatName.present
          ? data.lockChatName.value
          : this.lockChatName,
      lockChatIcon: data.lockChatIcon.present
          ? data.lockChatIcon.value
          : this.lockChatIcon,
      lastReadMessageGuid: data.lastReadMessageGuid.present
          ? data.lastReadMessageGuid.value
          : this.lastReadMessageGuid,
      customThemeLight: data.customThemeLight.present
          ? data.customThemeLight.value
          : this.customThemeLight,
      customThemeDark: data.customThemeDark.present
          ? data.customThemeDark.value
          : this.customThemeDark,
      wallpaperType: data.wallpaperType.present
          ? data.wallpaperType.value
          : this.wallpaperType,
      dynamicWallpaperId: data.dynamicWallpaperId.present
          ? data.dynamicWallpaperId.value
          : this.dynamicWallpaperId,
      dynamicWallpaperConfig: data.dynamicWallpaperConfig.present
          ? data.dynamicWallpaperConfig.value
          : this.dynamicWallpaperConfig,
      customAvatarPath: data.customAvatarPath.present
          ? data.customAvatarPath.value
          : this.customAvatarPath,
      customBackgroundPath: data.customBackgroundPath.present
          ? data.customBackgroundPath.value
          : this.customBackgroundPath,
      pinIndex: data.pinIndex.present ? data.pinIndex.value : this.pinIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteChatRow(')
          ..write('id: $id, ')
          ..write('guid: $guid, ')
          ..write('chatIdentifier: $chatIdentifier, ')
          ..write('serviceName: $serviceName, ')
          ..write('groupId: $groupId, ')
          ..write('originalGroupId: $originalGroupId, ')
          ..write('legacyGroupIdsJson: $legacyGroupIdsJson, ')
          ..write('latestGroupTitle: $latestGroupTitle, ')
          ..write('threadKey: $threadKey, ')
          ..write('isArchived: $isArchived, ')
          ..write('muteType: $muteType, ')
          ..write('muteArgs: $muteArgs, ')
          ..write('isPinned: $isPinned, ')
          ..write('hasUnreadMessage: $hasUnreadMessage, ')
          ..write('displayName: $displayName, ')
          ..write('isFilteredAsSpam: $isFilteredAsSpam, ')
          ..write('autoSendReadReceipts: $autoSendReadReceipts, ')
          ..write('autoSendTypingIndicators: $autoSendTypingIndicators, ')
          ..write('textFieldText: $textFieldText, ')
          ..write('textFieldAttachmentsJson: $textFieldAttachmentsJson, ')
          ..write('latestMessageId: $latestMessageId, ')
          ..write('latestMessageDateUs: $latestMessageDateUs, ')
          ..write('dateDeletedUs: $dateDeletedUs, ')
          ..write('style: $style, ')
          ..write('lockChatName: $lockChatName, ')
          ..write('lockChatIcon: $lockChatIcon, ')
          ..write('lastReadMessageGuid: $lastReadMessageGuid, ')
          ..write('customThemeLight: $customThemeLight, ')
          ..write('customThemeDark: $customThemeDark, ')
          ..write('wallpaperType: $wallpaperType, ')
          ..write('dynamicWallpaperId: $dynamicWallpaperId, ')
          ..write('dynamicWallpaperConfig: $dynamicWallpaperConfig, ')
          ..write('customAvatarPath: $customAvatarPath, ')
          ..write('customBackgroundPath: $customBackgroundPath, ')
          ..write('pinIndex: $pinIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    guid,
    chatIdentifier,
    serviceName,
    groupId,
    originalGroupId,
    legacyGroupIdsJson,
    latestGroupTitle,
    threadKey,
    isArchived,
    muteType,
    muteArgs,
    isPinned,
    hasUnreadMessage,
    displayName,
    isFilteredAsSpam,
    autoSendReadReceipts,
    autoSendTypingIndicators,
    textFieldText,
    textFieldAttachmentsJson,
    latestMessageId,
    latestMessageDateUs,
    dateDeletedUs,
    style,
    lockChatName,
    lockChatIcon,
    lastReadMessageGuid,
    customThemeLight,
    customThemeDark,
    wallpaperType,
    dynamicWallpaperId,
    dynamicWallpaperConfig,
    customAvatarPath,
    customBackgroundPath,
    pinIndex,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteChatRow &&
          other.id == this.id &&
          other.guid == this.guid &&
          other.chatIdentifier == this.chatIdentifier &&
          other.serviceName == this.serviceName &&
          other.groupId == this.groupId &&
          other.originalGroupId == this.originalGroupId &&
          other.legacyGroupIdsJson == this.legacyGroupIdsJson &&
          other.latestGroupTitle == this.latestGroupTitle &&
          other.threadKey == this.threadKey &&
          other.isArchived == this.isArchived &&
          other.muteType == this.muteType &&
          other.muteArgs == this.muteArgs &&
          other.isPinned == this.isPinned &&
          other.hasUnreadMessage == this.hasUnreadMessage &&
          other.displayName == this.displayName &&
          other.isFilteredAsSpam == this.isFilteredAsSpam &&
          other.autoSendReadReceipts == this.autoSendReadReceipts &&
          other.autoSendTypingIndicators == this.autoSendTypingIndicators &&
          other.textFieldText == this.textFieldText &&
          other.textFieldAttachmentsJson == this.textFieldAttachmentsJson &&
          other.latestMessageId == this.latestMessageId &&
          other.latestMessageDateUs == this.latestMessageDateUs &&
          other.dateDeletedUs == this.dateDeletedUs &&
          other.style == this.style &&
          other.lockChatName == this.lockChatName &&
          other.lockChatIcon == this.lockChatIcon &&
          other.lastReadMessageGuid == this.lastReadMessageGuid &&
          other.customThemeLight == this.customThemeLight &&
          other.customThemeDark == this.customThemeDark &&
          other.wallpaperType == this.wallpaperType &&
          other.dynamicWallpaperId == this.dynamicWallpaperId &&
          other.dynamicWallpaperConfig == this.dynamicWallpaperConfig &&
          other.customAvatarPath == this.customAvatarPath &&
          other.customBackgroundPath == this.customBackgroundPath &&
          other.pinIndex == this.pinIndex);
}

class ChatsCompanion extends UpdateCompanion<SqliteChatRow> {
  final Value<int> id;
  final Value<String> guid;
  final Value<String?> chatIdentifier;
  final Value<String?> serviceName;
  final Value<String?> groupId;
  final Value<String?> originalGroupId;
  final Value<String?> legacyGroupIdsJson;
  final Value<String?> latestGroupTitle;
  final Value<String?> threadKey;
  final Value<bool?> isArchived;
  final Value<String?> muteType;
  final Value<String?> muteArgs;
  final Value<bool?> isPinned;
  final Value<bool?> hasUnreadMessage;
  final Value<String?> displayName;
  final Value<bool?> isFilteredAsSpam;
  final Value<bool?> autoSendReadReceipts;
  final Value<bool?> autoSendTypingIndicators;
  final Value<String?> textFieldText;
  final Value<String> textFieldAttachmentsJson;
  final Value<int?> latestMessageId;
  final Value<int?> latestMessageDateUs;
  final Value<int?> dateDeletedUs;
  final Value<int?> style;
  final Value<bool> lockChatName;
  final Value<bool> lockChatIcon;
  final Value<String?> lastReadMessageGuid;
  final Value<String?> customThemeLight;
  final Value<String?> customThemeDark;
  final Value<String?> wallpaperType;
  final Value<String?> dynamicWallpaperId;
  final Value<String?> dynamicWallpaperConfig;
  final Value<String?> customAvatarPath;
  final Value<String?> customBackgroundPath;
  final Value<int?> pinIndex;
  const ChatsCompanion({
    this.id = const Value.absent(),
    this.guid = const Value.absent(),
    this.chatIdentifier = const Value.absent(),
    this.serviceName = const Value.absent(),
    this.groupId = const Value.absent(),
    this.originalGroupId = const Value.absent(),
    this.legacyGroupIdsJson = const Value.absent(),
    this.latestGroupTitle = const Value.absent(),
    this.threadKey = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.muteType = const Value.absent(),
    this.muteArgs = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.hasUnreadMessage = const Value.absent(),
    this.displayName = const Value.absent(),
    this.isFilteredAsSpam = const Value.absent(),
    this.autoSendReadReceipts = const Value.absent(),
    this.autoSendTypingIndicators = const Value.absent(),
    this.textFieldText = const Value.absent(),
    this.textFieldAttachmentsJson = const Value.absent(),
    this.latestMessageId = const Value.absent(),
    this.latestMessageDateUs = const Value.absent(),
    this.dateDeletedUs = const Value.absent(),
    this.style = const Value.absent(),
    this.lockChatName = const Value.absent(),
    this.lockChatIcon = const Value.absent(),
    this.lastReadMessageGuid = const Value.absent(),
    this.customThemeLight = const Value.absent(),
    this.customThemeDark = const Value.absent(),
    this.wallpaperType = const Value.absent(),
    this.dynamicWallpaperId = const Value.absent(),
    this.dynamicWallpaperConfig = const Value.absent(),
    this.customAvatarPath = const Value.absent(),
    this.customBackgroundPath = const Value.absent(),
    this.pinIndex = const Value.absent(),
  });
  ChatsCompanion.insert({
    this.id = const Value.absent(),
    required String guid,
    this.chatIdentifier = const Value.absent(),
    this.serviceName = const Value.absent(),
    this.groupId = const Value.absent(),
    this.originalGroupId = const Value.absent(),
    this.legacyGroupIdsJson = const Value.absent(),
    this.latestGroupTitle = const Value.absent(),
    this.threadKey = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.muteType = const Value.absent(),
    this.muteArgs = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.hasUnreadMessage = const Value.absent(),
    this.displayName = const Value.absent(),
    this.isFilteredAsSpam = const Value.absent(),
    this.autoSendReadReceipts = const Value.absent(),
    this.autoSendTypingIndicators = const Value.absent(),
    this.textFieldText = const Value.absent(),
    this.textFieldAttachmentsJson = const Value.absent(),
    this.latestMessageId = const Value.absent(),
    this.latestMessageDateUs = const Value.absent(),
    this.dateDeletedUs = const Value.absent(),
    this.style = const Value.absent(),
    this.lockChatName = const Value.absent(),
    this.lockChatIcon = const Value.absent(),
    this.lastReadMessageGuid = const Value.absent(),
    this.customThemeLight = const Value.absent(),
    this.customThemeDark = const Value.absent(),
    this.wallpaperType = const Value.absent(),
    this.dynamicWallpaperId = const Value.absent(),
    this.dynamicWallpaperConfig = const Value.absent(),
    this.customAvatarPath = const Value.absent(),
    this.customBackgroundPath = const Value.absent(),
    this.pinIndex = const Value.absent(),
  }) : guid = Value(guid);
  static Insertable<SqliteChatRow> custom({
    Expression<int>? id,
    Expression<String>? guid,
    Expression<String>? chatIdentifier,
    Expression<String>? serviceName,
    Expression<String>? groupId,
    Expression<String>? originalGroupId,
    Expression<String>? legacyGroupIdsJson,
    Expression<String>? latestGroupTitle,
    Expression<String>? threadKey,
    Expression<bool>? isArchived,
    Expression<String>? muteType,
    Expression<String>? muteArgs,
    Expression<bool>? isPinned,
    Expression<bool>? hasUnreadMessage,
    Expression<String>? displayName,
    Expression<bool>? isFilteredAsSpam,
    Expression<bool>? autoSendReadReceipts,
    Expression<bool>? autoSendTypingIndicators,
    Expression<String>? textFieldText,
    Expression<String>? textFieldAttachmentsJson,
    Expression<int>? latestMessageId,
    Expression<int>? latestMessageDateUs,
    Expression<int>? dateDeletedUs,
    Expression<int>? style,
    Expression<bool>? lockChatName,
    Expression<bool>? lockChatIcon,
    Expression<String>? lastReadMessageGuid,
    Expression<String>? customThemeLight,
    Expression<String>? customThemeDark,
    Expression<String>? wallpaperType,
    Expression<String>? dynamicWallpaperId,
    Expression<String>? dynamicWallpaperConfig,
    Expression<String>? customAvatarPath,
    Expression<String>? customBackgroundPath,
    Expression<int>? pinIndex,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (guid != null) 'guid': guid,
      if (chatIdentifier != null) 'chat_identifier': chatIdentifier,
      if (serviceName != null) 'service_name': serviceName,
      if (groupId != null) 'group_id': groupId,
      if (originalGroupId != null) 'original_group_id': originalGroupId,
      if (legacyGroupIdsJson != null)
        'legacy_group_ids_json': legacyGroupIdsJson,
      if (latestGroupTitle != null) 'latest_group_title': latestGroupTitle,
      if (threadKey != null) 'thread_key': threadKey,
      if (isArchived != null) 'is_archived': isArchived,
      if (muteType != null) 'mute_type': muteType,
      if (muteArgs != null) 'mute_args': muteArgs,
      if (isPinned != null) 'is_pinned': isPinned,
      if (hasUnreadMessage != null) 'has_unread_message': hasUnreadMessage,
      if (displayName != null) 'display_name': displayName,
      if (isFilteredAsSpam != null) 'is_filtered_as_spam': isFilteredAsSpam,
      if (autoSendReadReceipts != null)
        'auto_send_read_receipts': autoSendReadReceipts,
      if (autoSendTypingIndicators != null)
        'auto_send_typing_indicators': autoSendTypingIndicators,
      if (textFieldText != null) 'text_field_text': textFieldText,
      if (textFieldAttachmentsJson != null)
        'text_field_attachments_json': textFieldAttachmentsJson,
      if (latestMessageId != null) 'latest_message_id': latestMessageId,
      if (latestMessageDateUs != null)
        'latest_message_date_us': latestMessageDateUs,
      if (dateDeletedUs != null) 'date_deleted_us': dateDeletedUs,
      if (style != null) 'style': style,
      if (lockChatName != null) 'lock_chat_name': lockChatName,
      if (lockChatIcon != null) 'lock_chat_icon': lockChatIcon,
      if (lastReadMessageGuid != null)
        'last_read_message_guid': lastReadMessageGuid,
      if (customThemeLight != null) 'custom_theme_light': customThemeLight,
      if (customThemeDark != null) 'custom_theme_dark': customThemeDark,
      if (wallpaperType != null) 'wallpaper_type': wallpaperType,
      if (dynamicWallpaperId != null)
        'dynamic_wallpaper_id': dynamicWallpaperId,
      if (dynamicWallpaperConfig != null)
        'dynamic_wallpaper_config': dynamicWallpaperConfig,
      if (customAvatarPath != null) 'custom_avatar_path': customAvatarPath,
      if (customBackgroundPath != null)
        'custom_background_path': customBackgroundPath,
      if (pinIndex != null) 'pin_index': pinIndex,
    });
  }

  ChatsCompanion copyWith({
    Value<int>? id,
    Value<String>? guid,
    Value<String?>? chatIdentifier,
    Value<String?>? serviceName,
    Value<String?>? groupId,
    Value<String?>? originalGroupId,
    Value<String?>? legacyGroupIdsJson,
    Value<String?>? latestGroupTitle,
    Value<String?>? threadKey,
    Value<bool?>? isArchived,
    Value<String?>? muteType,
    Value<String?>? muteArgs,
    Value<bool?>? isPinned,
    Value<bool?>? hasUnreadMessage,
    Value<String?>? displayName,
    Value<bool?>? isFilteredAsSpam,
    Value<bool?>? autoSendReadReceipts,
    Value<bool?>? autoSendTypingIndicators,
    Value<String?>? textFieldText,
    Value<String>? textFieldAttachmentsJson,
    Value<int?>? latestMessageId,
    Value<int?>? latestMessageDateUs,
    Value<int?>? dateDeletedUs,
    Value<int?>? style,
    Value<bool>? lockChatName,
    Value<bool>? lockChatIcon,
    Value<String?>? lastReadMessageGuid,
    Value<String?>? customThemeLight,
    Value<String?>? customThemeDark,
    Value<String?>? wallpaperType,
    Value<String?>? dynamicWallpaperId,
    Value<String?>? dynamicWallpaperConfig,
    Value<String?>? customAvatarPath,
    Value<String?>? customBackgroundPath,
    Value<int?>? pinIndex,
  }) {
    return ChatsCompanion(
      id: id ?? this.id,
      guid: guid ?? this.guid,
      chatIdentifier: chatIdentifier ?? this.chatIdentifier,
      serviceName: serviceName ?? this.serviceName,
      groupId: groupId ?? this.groupId,
      originalGroupId: originalGroupId ?? this.originalGroupId,
      legacyGroupIdsJson: legacyGroupIdsJson ?? this.legacyGroupIdsJson,
      latestGroupTitle: latestGroupTitle ?? this.latestGroupTitle,
      threadKey: threadKey ?? this.threadKey,
      isArchived: isArchived ?? this.isArchived,
      muteType: muteType ?? this.muteType,
      muteArgs: muteArgs ?? this.muteArgs,
      isPinned: isPinned ?? this.isPinned,
      hasUnreadMessage: hasUnreadMessage ?? this.hasUnreadMessage,
      displayName: displayName ?? this.displayName,
      isFilteredAsSpam: isFilteredAsSpam ?? this.isFilteredAsSpam,
      autoSendReadReceipts: autoSendReadReceipts ?? this.autoSendReadReceipts,
      autoSendTypingIndicators:
          autoSendTypingIndicators ?? this.autoSendTypingIndicators,
      textFieldText: textFieldText ?? this.textFieldText,
      textFieldAttachmentsJson:
          textFieldAttachmentsJson ?? this.textFieldAttachmentsJson,
      latestMessageId: latestMessageId ?? this.latestMessageId,
      latestMessageDateUs: latestMessageDateUs ?? this.latestMessageDateUs,
      dateDeletedUs: dateDeletedUs ?? this.dateDeletedUs,
      style: style ?? this.style,
      lockChatName: lockChatName ?? this.lockChatName,
      lockChatIcon: lockChatIcon ?? this.lockChatIcon,
      lastReadMessageGuid: lastReadMessageGuid ?? this.lastReadMessageGuid,
      customThemeLight: customThemeLight ?? this.customThemeLight,
      customThemeDark: customThemeDark ?? this.customThemeDark,
      wallpaperType: wallpaperType ?? this.wallpaperType,
      dynamicWallpaperId: dynamicWallpaperId ?? this.dynamicWallpaperId,
      dynamicWallpaperConfig:
          dynamicWallpaperConfig ?? this.dynamicWallpaperConfig,
      customAvatarPath: customAvatarPath ?? this.customAvatarPath,
      customBackgroundPath: customBackgroundPath ?? this.customBackgroundPath,
      pinIndex: pinIndex ?? this.pinIndex,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (guid.present) {
      map['guid'] = Variable<String>(guid.value);
    }
    if (chatIdentifier.present) {
      map['chat_identifier'] = Variable<String>(chatIdentifier.value);
    }
    if (serviceName.present) {
      map['service_name'] = Variable<String>(serviceName.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (originalGroupId.present) {
      map['original_group_id'] = Variable<String>(originalGroupId.value);
    }
    if (legacyGroupIdsJson.present) {
      map['legacy_group_ids_json'] = Variable<String>(legacyGroupIdsJson.value);
    }
    if (latestGroupTitle.present) {
      map['latest_group_title'] = Variable<String>(latestGroupTitle.value);
    }
    if (threadKey.present) {
      map['thread_key'] = Variable<String>(threadKey.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (muteType.present) {
      map['mute_type'] = Variable<String>(muteType.value);
    }
    if (muteArgs.present) {
      map['mute_args'] = Variable<String>(muteArgs.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (hasUnreadMessage.present) {
      map['has_unread_message'] = Variable<bool>(hasUnreadMessage.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (isFilteredAsSpam.present) {
      map['is_filtered_as_spam'] = Variable<bool>(isFilteredAsSpam.value);
    }
    if (autoSendReadReceipts.present) {
      map['auto_send_read_receipts'] = Variable<bool>(
        autoSendReadReceipts.value,
      );
    }
    if (autoSendTypingIndicators.present) {
      map['auto_send_typing_indicators'] = Variable<bool>(
        autoSendTypingIndicators.value,
      );
    }
    if (textFieldText.present) {
      map['text_field_text'] = Variable<String>(textFieldText.value);
    }
    if (textFieldAttachmentsJson.present) {
      map['text_field_attachments_json'] = Variable<String>(
        textFieldAttachmentsJson.value,
      );
    }
    if (latestMessageId.present) {
      map['latest_message_id'] = Variable<int>(latestMessageId.value);
    }
    if (latestMessageDateUs.present) {
      map['latest_message_date_us'] = Variable<int>(latestMessageDateUs.value);
    }
    if (dateDeletedUs.present) {
      map['date_deleted_us'] = Variable<int>(dateDeletedUs.value);
    }
    if (style.present) {
      map['style'] = Variable<int>(style.value);
    }
    if (lockChatName.present) {
      map['lock_chat_name'] = Variable<bool>(lockChatName.value);
    }
    if (lockChatIcon.present) {
      map['lock_chat_icon'] = Variable<bool>(lockChatIcon.value);
    }
    if (lastReadMessageGuid.present) {
      map['last_read_message_guid'] = Variable<String>(
        lastReadMessageGuid.value,
      );
    }
    if (customThemeLight.present) {
      map['custom_theme_light'] = Variable<String>(customThemeLight.value);
    }
    if (customThemeDark.present) {
      map['custom_theme_dark'] = Variable<String>(customThemeDark.value);
    }
    if (wallpaperType.present) {
      map['wallpaper_type'] = Variable<String>(wallpaperType.value);
    }
    if (dynamicWallpaperId.present) {
      map['dynamic_wallpaper_id'] = Variable<String>(dynamicWallpaperId.value);
    }
    if (dynamicWallpaperConfig.present) {
      map['dynamic_wallpaper_config'] = Variable<String>(
        dynamicWallpaperConfig.value,
      );
    }
    if (customAvatarPath.present) {
      map['custom_avatar_path'] = Variable<String>(customAvatarPath.value);
    }
    if (customBackgroundPath.present) {
      map['custom_background_path'] = Variable<String>(
        customBackgroundPath.value,
      );
    }
    if (pinIndex.present) {
      map['pin_index'] = Variable<int>(pinIndex.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatsCompanion(')
          ..write('id: $id, ')
          ..write('guid: $guid, ')
          ..write('chatIdentifier: $chatIdentifier, ')
          ..write('serviceName: $serviceName, ')
          ..write('groupId: $groupId, ')
          ..write('originalGroupId: $originalGroupId, ')
          ..write('legacyGroupIdsJson: $legacyGroupIdsJson, ')
          ..write('latestGroupTitle: $latestGroupTitle, ')
          ..write('threadKey: $threadKey, ')
          ..write('isArchived: $isArchived, ')
          ..write('muteType: $muteType, ')
          ..write('muteArgs: $muteArgs, ')
          ..write('isPinned: $isPinned, ')
          ..write('hasUnreadMessage: $hasUnreadMessage, ')
          ..write('displayName: $displayName, ')
          ..write('isFilteredAsSpam: $isFilteredAsSpam, ')
          ..write('autoSendReadReceipts: $autoSendReadReceipts, ')
          ..write('autoSendTypingIndicators: $autoSendTypingIndicators, ')
          ..write('textFieldText: $textFieldText, ')
          ..write('textFieldAttachmentsJson: $textFieldAttachmentsJson, ')
          ..write('latestMessageId: $latestMessageId, ')
          ..write('latestMessageDateUs: $latestMessageDateUs, ')
          ..write('dateDeletedUs: $dateDeletedUs, ')
          ..write('style: $style, ')
          ..write('lockChatName: $lockChatName, ')
          ..write('lockChatIcon: $lockChatIcon, ')
          ..write('lastReadMessageGuid: $lastReadMessageGuid, ')
          ..write('customThemeLight: $customThemeLight, ')
          ..write('customThemeDark: $customThemeDark, ')
          ..write('wallpaperType: $wallpaperType, ')
          ..write('dynamicWallpaperId: $dynamicWallpaperId, ')
          ..write('dynamicWallpaperConfig: $dynamicWallpaperConfig, ')
          ..write('customAvatarPath: $customAvatarPath, ')
          ..write('customBackgroundPath: $customBackgroundPath, ')
          ..write('pinIndex: $pinIndex')
          ..write(')'))
        .toString();
  }
}

class $HandlesTable extends Handles
    with TableInfo<$HandlesTable, SqliteHandleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HandlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _originalRowidMeta = const VerificationMeta(
    'originalRowid',
  );
  @override
  late final GeneratedColumn<int> originalRowid = GeneratedColumn<int>(
    'original_rowid',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultPhoneMeta = const VerificationMeta(
    'defaultPhone',
  );
  @override
  late final GeneratedColumn<String> defaultPhone = GeneratedColumn<String>(
    'default_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultEmailMeta = const VerificationMeta(
    'defaultEmail',
  );
  @override
  late final GeneratedColumn<String> defaultEmail = GeneratedColumn<String>(
    'default_email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formattedAddressMeta = const VerificationMeta(
    'formattedAddress',
  );
  @override
  late final GeneratedColumn<String> formattedAddress = GeneratedColumn<String>(
    'formatted_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uniqueAddressAndServiceMeta =
      const VerificationMeta('uniqueAddressAndService');
  @override
  late final GeneratedColumn<String> uniqueAddressAndService =
      GeneratedColumn<String>(
        'unique_address_and_service',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      );
  static const VerificationMeta _serviceMeta = const VerificationMeta(
    'service',
  );
  @override
  late final GeneratedColumn<String> service = GeneratedColumn<String>(
    'service',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    originalRowid,
    address,
    country,
    color,
    defaultPhone,
    defaultEmail,
    formattedAddress,
    uniqueAddressAndService,
    service,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'handles';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteHandleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('original_rowid')) {
      context.handle(
        _originalRowidMeta,
        originalRowid.isAcceptableOrUnknown(
          data['original_rowid']!,
          _originalRowidMeta,
        ),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('default_phone')) {
      context.handle(
        _defaultPhoneMeta,
        defaultPhone.isAcceptableOrUnknown(
          data['default_phone']!,
          _defaultPhoneMeta,
        ),
      );
    }
    if (data.containsKey('default_email')) {
      context.handle(
        _defaultEmailMeta,
        defaultEmail.isAcceptableOrUnknown(
          data['default_email']!,
          _defaultEmailMeta,
        ),
      );
    }
    if (data.containsKey('formatted_address')) {
      context.handle(
        _formattedAddressMeta,
        formattedAddress.isAcceptableOrUnknown(
          data['formatted_address']!,
          _formattedAddressMeta,
        ),
      );
    }
    if (data.containsKey('unique_address_and_service')) {
      context.handle(
        _uniqueAddressAndServiceMeta,
        uniqueAddressAndService.isAcceptableOrUnknown(
          data['unique_address_and_service']!,
          _uniqueAddressAndServiceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_uniqueAddressAndServiceMeta);
    }
    if (data.containsKey('service')) {
      context.handle(
        _serviceMeta,
        service.isAcceptableOrUnknown(data['service']!, _serviceMeta),
      );
    } else if (isInserting) {
      context.missing(_serviceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SqliteHandleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteHandleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      originalRowid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_rowid'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      defaultPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_phone'],
      ),
      defaultEmail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_email'],
      ),
      formattedAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formatted_address'],
      ),
      uniqueAddressAndService: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unique_address_and_service'],
      )!,
      service: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service'],
      )!,
    );
  }

  @override
  $HandlesTable createAlias(String alias) {
    return $HandlesTable(attachedDatabase, alias);
  }
}

class SqliteHandleRow extends DataClass implements Insertable<SqliteHandleRow> {
  final int id;
  final int? originalRowid;
  final String address;
  final String? country;
  final String? color;
  final String? defaultPhone;
  final String? defaultEmail;
  final String? formattedAddress;
  final String uniqueAddressAndService;
  final String service;
  const SqliteHandleRow({
    required this.id,
    this.originalRowid,
    required this.address,
    this.country,
    this.color,
    this.defaultPhone,
    this.defaultEmail,
    this.formattedAddress,
    required this.uniqueAddressAndService,
    required this.service,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || originalRowid != null) {
      map['original_rowid'] = Variable<int>(originalRowid);
    }
    map['address'] = Variable<String>(address);
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || defaultPhone != null) {
      map['default_phone'] = Variable<String>(defaultPhone);
    }
    if (!nullToAbsent || defaultEmail != null) {
      map['default_email'] = Variable<String>(defaultEmail);
    }
    if (!nullToAbsent || formattedAddress != null) {
      map['formatted_address'] = Variable<String>(formattedAddress);
    }
    map['unique_address_and_service'] = Variable<String>(
      uniqueAddressAndService,
    );
    map['service'] = Variable<String>(service);
    return map;
  }

  HandlesCompanion toCompanion(bool nullToAbsent) {
    return HandlesCompanion(
      id: Value(id),
      originalRowid: originalRowid == null && nullToAbsent
          ? const Value.absent()
          : Value(originalRowid),
      address: Value(address),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      defaultPhone: defaultPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultPhone),
      defaultEmail: defaultEmail == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultEmail),
      formattedAddress: formattedAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(formattedAddress),
      uniqueAddressAndService: Value(uniqueAddressAndService),
      service: Value(service),
    );
  }

  factory SqliteHandleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteHandleRow(
      id: serializer.fromJson<int>(json['id']),
      originalRowid: serializer.fromJson<int?>(json['originalRowid']),
      address: serializer.fromJson<String>(json['address']),
      country: serializer.fromJson<String?>(json['country']),
      color: serializer.fromJson<String?>(json['color']),
      defaultPhone: serializer.fromJson<String?>(json['defaultPhone']),
      defaultEmail: serializer.fromJson<String?>(json['defaultEmail']),
      formattedAddress: serializer.fromJson<String?>(json['formattedAddress']),
      uniqueAddressAndService: serializer.fromJson<String>(
        json['uniqueAddressAndService'],
      ),
      service: serializer.fromJson<String>(json['service']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'originalRowid': serializer.toJson<int?>(originalRowid),
      'address': serializer.toJson<String>(address),
      'country': serializer.toJson<String?>(country),
      'color': serializer.toJson<String?>(color),
      'defaultPhone': serializer.toJson<String?>(defaultPhone),
      'defaultEmail': serializer.toJson<String?>(defaultEmail),
      'formattedAddress': serializer.toJson<String?>(formattedAddress),
      'uniqueAddressAndService': serializer.toJson<String>(
        uniqueAddressAndService,
      ),
      'service': serializer.toJson<String>(service),
    };
  }

  SqliteHandleRow copyWith({
    int? id,
    Value<int?> originalRowid = const Value.absent(),
    String? address,
    Value<String?> country = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<String?> defaultPhone = const Value.absent(),
    Value<String?> defaultEmail = const Value.absent(),
    Value<String?> formattedAddress = const Value.absent(),
    String? uniqueAddressAndService,
    String? service,
  }) => SqliteHandleRow(
    id: id ?? this.id,
    originalRowid: originalRowid.present
        ? originalRowid.value
        : this.originalRowid,
    address: address ?? this.address,
    country: country.present ? country.value : this.country,
    color: color.present ? color.value : this.color,
    defaultPhone: defaultPhone.present ? defaultPhone.value : this.defaultPhone,
    defaultEmail: defaultEmail.present ? defaultEmail.value : this.defaultEmail,
    formattedAddress: formattedAddress.present
        ? formattedAddress.value
        : this.formattedAddress,
    uniqueAddressAndService:
        uniqueAddressAndService ?? this.uniqueAddressAndService,
    service: service ?? this.service,
  );
  SqliteHandleRow copyWithCompanion(HandlesCompanion data) {
    return SqliteHandleRow(
      id: data.id.present ? data.id.value : this.id,
      originalRowid: data.originalRowid.present
          ? data.originalRowid.value
          : this.originalRowid,
      address: data.address.present ? data.address.value : this.address,
      country: data.country.present ? data.country.value : this.country,
      color: data.color.present ? data.color.value : this.color,
      defaultPhone: data.defaultPhone.present
          ? data.defaultPhone.value
          : this.defaultPhone,
      defaultEmail: data.defaultEmail.present
          ? data.defaultEmail.value
          : this.defaultEmail,
      formattedAddress: data.formattedAddress.present
          ? data.formattedAddress.value
          : this.formattedAddress,
      uniqueAddressAndService: data.uniqueAddressAndService.present
          ? data.uniqueAddressAndService.value
          : this.uniqueAddressAndService,
      service: data.service.present ? data.service.value : this.service,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteHandleRow(')
          ..write('id: $id, ')
          ..write('originalRowid: $originalRowid, ')
          ..write('address: $address, ')
          ..write('country: $country, ')
          ..write('color: $color, ')
          ..write('defaultPhone: $defaultPhone, ')
          ..write('defaultEmail: $defaultEmail, ')
          ..write('formattedAddress: $formattedAddress, ')
          ..write('uniqueAddressAndService: $uniqueAddressAndService, ')
          ..write('service: $service')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    originalRowid,
    address,
    country,
    color,
    defaultPhone,
    defaultEmail,
    formattedAddress,
    uniqueAddressAndService,
    service,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteHandleRow &&
          other.id == this.id &&
          other.originalRowid == this.originalRowid &&
          other.address == this.address &&
          other.country == this.country &&
          other.color == this.color &&
          other.defaultPhone == this.defaultPhone &&
          other.defaultEmail == this.defaultEmail &&
          other.formattedAddress == this.formattedAddress &&
          other.uniqueAddressAndService == this.uniqueAddressAndService &&
          other.service == this.service);
}

class HandlesCompanion extends UpdateCompanion<SqliteHandleRow> {
  final Value<int> id;
  final Value<int?> originalRowid;
  final Value<String> address;
  final Value<String?> country;
  final Value<String?> color;
  final Value<String?> defaultPhone;
  final Value<String?> defaultEmail;
  final Value<String?> formattedAddress;
  final Value<String> uniqueAddressAndService;
  final Value<String> service;
  const HandlesCompanion({
    this.id = const Value.absent(),
    this.originalRowid = const Value.absent(),
    this.address = const Value.absent(),
    this.country = const Value.absent(),
    this.color = const Value.absent(),
    this.defaultPhone = const Value.absent(),
    this.defaultEmail = const Value.absent(),
    this.formattedAddress = const Value.absent(),
    this.uniqueAddressAndService = const Value.absent(),
    this.service = const Value.absent(),
  });
  HandlesCompanion.insert({
    this.id = const Value.absent(),
    this.originalRowid = const Value.absent(),
    required String address,
    this.country = const Value.absent(),
    this.color = const Value.absent(),
    this.defaultPhone = const Value.absent(),
    this.defaultEmail = const Value.absent(),
    this.formattedAddress = const Value.absent(),
    required String uniqueAddressAndService,
    required String service,
  }) : address = Value(address),
       uniqueAddressAndService = Value(uniqueAddressAndService),
       service = Value(service);
  static Insertable<SqliteHandleRow> custom({
    Expression<int>? id,
    Expression<int>? originalRowid,
    Expression<String>? address,
    Expression<String>? country,
    Expression<String>? color,
    Expression<String>? defaultPhone,
    Expression<String>? defaultEmail,
    Expression<String>? formattedAddress,
    Expression<String>? uniqueAddressAndService,
    Expression<String>? service,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originalRowid != null) 'original_rowid': originalRowid,
      if (address != null) 'address': address,
      if (country != null) 'country': country,
      if (color != null) 'color': color,
      if (defaultPhone != null) 'default_phone': defaultPhone,
      if (defaultEmail != null) 'default_email': defaultEmail,
      if (formattedAddress != null) 'formatted_address': formattedAddress,
      if (uniqueAddressAndService != null)
        'unique_address_and_service': uniqueAddressAndService,
      if (service != null) 'service': service,
    });
  }

  HandlesCompanion copyWith({
    Value<int>? id,
    Value<int?>? originalRowid,
    Value<String>? address,
    Value<String?>? country,
    Value<String?>? color,
    Value<String?>? defaultPhone,
    Value<String?>? defaultEmail,
    Value<String?>? formattedAddress,
    Value<String>? uniqueAddressAndService,
    Value<String>? service,
  }) {
    return HandlesCompanion(
      id: id ?? this.id,
      originalRowid: originalRowid ?? this.originalRowid,
      address: address ?? this.address,
      country: country ?? this.country,
      color: color ?? this.color,
      defaultPhone: defaultPhone ?? this.defaultPhone,
      defaultEmail: defaultEmail ?? this.defaultEmail,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      uniqueAddressAndService:
          uniqueAddressAndService ?? this.uniqueAddressAndService,
      service: service ?? this.service,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (originalRowid.present) {
      map['original_rowid'] = Variable<int>(originalRowid.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (defaultPhone.present) {
      map['default_phone'] = Variable<String>(defaultPhone.value);
    }
    if (defaultEmail.present) {
      map['default_email'] = Variable<String>(defaultEmail.value);
    }
    if (formattedAddress.present) {
      map['formatted_address'] = Variable<String>(formattedAddress.value);
    }
    if (uniqueAddressAndService.present) {
      map['unique_address_and_service'] = Variable<String>(
        uniqueAddressAndService.value,
      );
    }
    if (service.present) {
      map['service'] = Variable<String>(service.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HandlesCompanion(')
          ..write('id: $id, ')
          ..write('originalRowid: $originalRowid, ')
          ..write('address: $address, ')
          ..write('country: $country, ')
          ..write('color: $color, ')
          ..write('defaultPhone: $defaultPhone, ')
          ..write('defaultEmail: $defaultEmail, ')
          ..write('formattedAddress: $formattedAddress, ')
          ..write('uniqueAddressAndService: $uniqueAddressAndService, ')
          ..write('service: $service')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages
    with TableInfo<$MessagesTable, SqliteMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _originalRowidMeta = const VerificationMeta(
    'originalRowid',
  );
  @override
  late final GeneratedColumn<int> originalRowid = GeneratedColumn<int>(
    'original_rowid',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _guidMeta = const VerificationMeta('guid');
  @override
  late final GeneratedColumn<String> guid = GeneratedColumn<String>(
    'guid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _handleIdMeta = const VerificationMeta(
    'handleId',
  );
  @override
  late final GeneratedColumn<int> handleId = GeneratedColumn<int>(
    'handle_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _otherHandleMeta = const VerificationMeta(
    'otherHandle',
  );
  @override
  late final GeneratedColumn<int> otherHandle = GeneratedColumn<int>(
    'other_handle',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageTextMeta = const VerificationMeta(
    'messageText',
  );
  @override
  late final GeneratedColumn<String> messageText = GeneratedColumn<String>(
    'text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serviceMeta = const VerificationMeta(
    'service',
  );
  @override
  late final GeneratedColumn<String> service = GeneratedColumn<String>(
    'service',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateCreatedUsMeta = const VerificationMeta(
    'dateCreatedUs',
  );
  @override
  late final GeneratedColumn<int> dateCreatedUs = GeneratedColumn<int>(
    'date_created_us',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortAtUsMeta = const VerificationMeta(
    'sortAtUs',
  );
  @override
  late final GeneratedColumn<int> sortAtUs = GeneratedColumn<int>(
    'sort_at_us',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateReadUsMeta = const VerificationMeta(
    'dateReadUs',
  );
  @override
  late final GeneratedColumn<int> dateReadUs = GeneratedColumn<int>(
    'date_read_us',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateDeliveredUsMeta = const VerificationMeta(
    'dateDeliveredUs',
  );
  @override
  late final GeneratedColumn<int> dateDeliveredUs = GeneratedColumn<int>(
    'date_delivered_us',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFromMeMeta = const VerificationMeta(
    'isFromMe',
  );
  @override
  late final GeneratedColumn<bool> isFromMe = GeneratedColumn<bool>(
    'is_from_me',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_from_me" IN (0, 1))',
    ),
  );
  static const VerificationMeta _hasDdResultsMeta = const VerificationMeta(
    'hasDdResults',
  );
  @override
  late final GeneratedColumn<bool> hasDdResults = GeneratedColumn<bool>(
    'has_dd_results',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_dd_results" IN (0, 1))',
    ),
  );
  static const VerificationMeta _datePlayedUsMeta = const VerificationMeta(
    'datePlayedUs',
  );
  @override
  late final GeneratedColumn<int> datePlayedUs = GeneratedColumn<int>(
    'date_played_us',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<int> itemType = GeneratedColumn<int>(
    'item_type',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupTitleMeta = const VerificationMeta(
    'groupTitle',
  );
  @override
  late final GeneratedColumn<String> groupTitle = GeneratedColumn<String>(
    'group_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupActionTypeMeta = const VerificationMeta(
    'groupActionType',
  );
  @override
  late final GeneratedColumn<int> groupActionType = GeneratedColumn<int>(
    'group_action_type',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _balloonBundleIdMeta = const VerificationMeta(
    'balloonBundleId',
  );
  @override
  late final GeneratedColumn<String> balloonBundleId = GeneratedColumn<String>(
    'balloon_bundle_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _associatedMessageGuidMeta =
      const VerificationMeta('associatedMessageGuid');
  @override
  late final GeneratedColumn<String> associatedMessageGuid =
      GeneratedColumn<String>(
        'associated_message_guid',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _associatedMessagePartMeta =
      const VerificationMeta('associatedMessagePart');
  @override
  late final GeneratedColumn<int> associatedMessagePart = GeneratedColumn<int>(
    'associated_message_part',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _associatedMessageTypeMeta =
      const VerificationMeta('associatedMessageType');
  @override
  late final GeneratedColumn<String> associatedMessageType =
      GeneratedColumn<String>(
        'associated_message_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _expressiveSendStyleIdMeta =
      const VerificationMeta('expressiveSendStyleId');
  @override
  late final GeneratedColumn<String> expressiveSendStyleId =
      GeneratedColumn<String>(
        'expressive_send_style_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _hasAttachmentsMeta = const VerificationMeta(
    'hasAttachments',
  );
  @override
  late final GeneratedColumn<bool> hasAttachments = GeneratedColumn<bool>(
    'has_attachments',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_attachments" IN (0, 1))',
    ),
  );
  static const VerificationMeta _hasReactionsMeta = const VerificationMeta(
    'hasReactions',
  );
  @override
  late final GeneratedColumn<bool> hasReactions = GeneratedColumn<bool>(
    'has_reactions',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_reactions" IN (0, 1))',
    ),
  );
  static const VerificationMeta _dateDeletedUsMeta = const VerificationMeta(
    'dateDeletedUs',
  );
  @override
  late final GeneratedColumn<int> dateDeletedUs = GeneratedColumn<int>(
    'date_deleted_us',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _threadOriginatorGuidMeta =
      const VerificationMeta('threadOriginatorGuid');
  @override
  late final GeneratedColumn<String> threadOriginatorGuid =
      GeneratedColumn<String>(
        'thread_originator_guid',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _threadOriginatorPartMeta =
      const VerificationMeta('threadOriginatorPart');
  @override
  late final GeneratedColumn<String> threadOriginatorPart =
      GeneratedColumn<String>(
        'thread_originator_part',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _bigEmojiMeta = const VerificationMeta(
    'bigEmoji',
  );
  @override
  late final GeneratedColumn<bool> bigEmoji = GeneratedColumn<bool>(
    'big_emoji',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("big_emoji" IN (0, 1))',
    ),
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<int> error = GeneratedColumn<int>(
    'error',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<int> chatId = GeneratedColumn<int>(
    'chat_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NULL REFERENCES chats (id) ON DELETE SET NULL',
  );
  static const VerificationMeta _attributedBodyJsonMeta =
      const VerificationMeta('attributedBodyJson');
  @override
  late final GeneratedColumn<String> attributedBodyJson =
      GeneratedColumn<String>(
        'attributed_body_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _messageSummaryInfoJsonMeta =
      const VerificationMeta('messageSummaryInfoJson');
  @override
  late final GeneratedColumn<String> messageSummaryInfoJson =
      GeneratedColumn<String>(
        'message_summary_info_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _payloadDataJsonMeta = const VerificationMeta(
    'payloadDataJson',
  );
  @override
  late final GeneratedColumn<String> payloadDataJson = GeneratedColumn<String>(
    'payload_data_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasApplePayloadDataMeta =
      const VerificationMeta('hasApplePayloadData');
  @override
  late final GeneratedColumn<bool> hasApplePayloadData = GeneratedColumn<bool>(
    'has_apple_payload_data',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_apple_payload_data" IN (0, 1))',
    ),
  );
  static const VerificationMeta _dateEditedUsMeta = const VerificationMeta(
    'dateEditedUs',
  );
  @override
  late final GeneratedColumn<int> dateEditedUs = GeneratedColumn<int>(
    'date_edited_us',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wasDeliveredQuietlyMeta =
      const VerificationMeta('wasDeliveredQuietly');
  @override
  late final GeneratedColumn<bool> wasDeliveredQuietly = GeneratedColumn<bool>(
    'was_delivered_quietly',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_delivered_quietly" IN (0, 1))',
    ),
  );
  static const VerificationMeta _didNotifyRecipientMeta =
      const VerificationMeta('didNotifyRecipient');
  @override
  late final GeneratedColumn<bool> didNotifyRecipient = GeneratedColumn<bool>(
    'did_notify_recipient',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("did_notify_recipient" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isBookmarkedMeta = const VerificationMeta(
    'isBookmarked',
  );
  @override
  late final GeneratedColumn<bool> isBookmarked = GeneratedColumn<bool>(
    'is_bookmarked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bookmarked" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isDeliveredMeta = const VerificationMeta(
    'isDelivered',
  );
  @override
  late final GeneratedColumn<bool> isDelivered = GeneratedColumn<bool>(
    'is_delivered',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_delivered" IN (0, 1))',
    ),
  );
  static const VerificationMeta _handleRelationIdMeta = const VerificationMeta(
    'handleRelationId',
  );
  @override
  late final GeneratedColumn<int> handleRelationId = GeneratedColumn<int>(
    'handle_relation_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NULL REFERENCES handles (id) ON DELETE SET NULL',
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasEffectPlayedMeta = const VerificationMeta(
    'hasEffectPlayed',
  );
  @override
  late final GeneratedColumn<bool> hasEffectPlayed = GeneratedColumn<bool>(
    'has_effect_played',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_effect_played" IN (0, 1))',
    ),
  );
  static const VerificationMeta _appleChatGuidMeta = const VerificationMeta(
    'appleChatGuid',
  );
  @override
  late final GeneratedColumn<String> appleChatGuid = GeneratedColumn<String>(
    'apple_chat_guid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    originalRowid,
    guid,
    handleId,
    otherHandle,
    messageText,
    subject,
    country,
    service,
    dateCreatedUs,
    sortAtUs,
    dateReadUs,
    dateDeliveredUs,
    isFromMe,
    hasDdResults,
    datePlayedUs,
    itemType,
    groupTitle,
    groupActionType,
    balloonBundleId,
    associatedMessageGuid,
    associatedMessagePart,
    associatedMessageType,
    expressiveSendStyleId,
    hasAttachments,
    hasReactions,
    dateDeletedUs,
    threadOriginatorGuid,
    threadOriginatorPart,
    bigEmoji,
    error,
    chatId,
    attributedBodyJson,
    messageSummaryInfoJson,
    payloadDataJson,
    metadataJson,
    hasApplePayloadData,
    dateEditedUs,
    wasDeliveredQuietly,
    didNotifyRecipient,
    isBookmarked,
    isDelivered,
    handleRelationId,
    errorMessage,
    hasEffectPlayed,
    appleChatGuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('original_rowid')) {
      context.handle(
        _originalRowidMeta,
        originalRowid.isAcceptableOrUnknown(
          data['original_rowid']!,
          _originalRowidMeta,
        ),
      );
    }
    if (data.containsKey('guid')) {
      context.handle(
        _guidMeta,
        guid.isAcceptableOrUnknown(data['guid']!, _guidMeta),
      );
    }
    if (data.containsKey('handle_id')) {
      context.handle(
        _handleIdMeta,
        handleId.isAcceptableOrUnknown(data['handle_id']!, _handleIdMeta),
      );
    }
    if (data.containsKey('other_handle')) {
      context.handle(
        _otherHandleMeta,
        otherHandle.isAcceptableOrUnknown(
          data['other_handle']!,
          _otherHandleMeta,
        ),
      );
    }
    if (data.containsKey('text')) {
      context.handle(
        _messageTextMeta,
        messageText.isAcceptableOrUnknown(data['text']!, _messageTextMeta),
      );
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('service')) {
      context.handle(
        _serviceMeta,
        service.isAcceptableOrUnknown(data['service']!, _serviceMeta),
      );
    }
    if (data.containsKey('date_created_us')) {
      context.handle(
        _dateCreatedUsMeta,
        dateCreatedUs.isAcceptableOrUnknown(
          data['date_created_us']!,
          _dateCreatedUsMeta,
        ),
      );
    }
    if (data.containsKey('sort_at_us')) {
      context.handle(
        _sortAtUsMeta,
        sortAtUs.isAcceptableOrUnknown(data['sort_at_us']!, _sortAtUsMeta),
      );
    } else if (isInserting) {
      context.missing(_sortAtUsMeta);
    }
    if (data.containsKey('date_read_us')) {
      context.handle(
        _dateReadUsMeta,
        dateReadUs.isAcceptableOrUnknown(
          data['date_read_us']!,
          _dateReadUsMeta,
        ),
      );
    }
    if (data.containsKey('date_delivered_us')) {
      context.handle(
        _dateDeliveredUsMeta,
        dateDeliveredUs.isAcceptableOrUnknown(
          data['date_delivered_us']!,
          _dateDeliveredUsMeta,
        ),
      );
    }
    if (data.containsKey('is_from_me')) {
      context.handle(
        _isFromMeMeta,
        isFromMe.isAcceptableOrUnknown(data['is_from_me']!, _isFromMeMeta),
      );
    }
    if (data.containsKey('has_dd_results')) {
      context.handle(
        _hasDdResultsMeta,
        hasDdResults.isAcceptableOrUnknown(
          data['has_dd_results']!,
          _hasDdResultsMeta,
        ),
      );
    }
    if (data.containsKey('date_played_us')) {
      context.handle(
        _datePlayedUsMeta,
        datePlayedUs.isAcceptableOrUnknown(
          data['date_played_us']!,
          _datePlayedUsMeta,
        ),
      );
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    }
    if (data.containsKey('group_title')) {
      context.handle(
        _groupTitleMeta,
        groupTitle.isAcceptableOrUnknown(data['group_title']!, _groupTitleMeta),
      );
    }
    if (data.containsKey('group_action_type')) {
      context.handle(
        _groupActionTypeMeta,
        groupActionType.isAcceptableOrUnknown(
          data['group_action_type']!,
          _groupActionTypeMeta,
        ),
      );
    }
    if (data.containsKey('balloon_bundle_id')) {
      context.handle(
        _balloonBundleIdMeta,
        balloonBundleId.isAcceptableOrUnknown(
          data['balloon_bundle_id']!,
          _balloonBundleIdMeta,
        ),
      );
    }
    if (data.containsKey('associated_message_guid')) {
      context.handle(
        _associatedMessageGuidMeta,
        associatedMessageGuid.isAcceptableOrUnknown(
          data['associated_message_guid']!,
          _associatedMessageGuidMeta,
        ),
      );
    }
    if (data.containsKey('associated_message_part')) {
      context.handle(
        _associatedMessagePartMeta,
        associatedMessagePart.isAcceptableOrUnknown(
          data['associated_message_part']!,
          _associatedMessagePartMeta,
        ),
      );
    }
    if (data.containsKey('associated_message_type')) {
      context.handle(
        _associatedMessageTypeMeta,
        associatedMessageType.isAcceptableOrUnknown(
          data['associated_message_type']!,
          _associatedMessageTypeMeta,
        ),
      );
    }
    if (data.containsKey('expressive_send_style_id')) {
      context.handle(
        _expressiveSendStyleIdMeta,
        expressiveSendStyleId.isAcceptableOrUnknown(
          data['expressive_send_style_id']!,
          _expressiveSendStyleIdMeta,
        ),
      );
    }
    if (data.containsKey('has_attachments')) {
      context.handle(
        _hasAttachmentsMeta,
        hasAttachments.isAcceptableOrUnknown(
          data['has_attachments']!,
          _hasAttachmentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hasAttachmentsMeta);
    }
    if (data.containsKey('has_reactions')) {
      context.handle(
        _hasReactionsMeta,
        hasReactions.isAcceptableOrUnknown(
          data['has_reactions']!,
          _hasReactionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hasReactionsMeta);
    }
    if (data.containsKey('date_deleted_us')) {
      context.handle(
        _dateDeletedUsMeta,
        dateDeletedUs.isAcceptableOrUnknown(
          data['date_deleted_us']!,
          _dateDeletedUsMeta,
        ),
      );
    }
    if (data.containsKey('thread_originator_guid')) {
      context.handle(
        _threadOriginatorGuidMeta,
        threadOriginatorGuid.isAcceptableOrUnknown(
          data['thread_originator_guid']!,
          _threadOriginatorGuidMeta,
        ),
      );
    }
    if (data.containsKey('thread_originator_part')) {
      context.handle(
        _threadOriginatorPartMeta,
        threadOriginatorPart.isAcceptableOrUnknown(
          data['thread_originator_part']!,
          _threadOriginatorPartMeta,
        ),
      );
    }
    if (data.containsKey('big_emoji')) {
      context.handle(
        _bigEmojiMeta,
        bigEmoji.isAcceptableOrUnknown(data['big_emoji']!, _bigEmojiMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    } else if (isInserting) {
      context.missing(_errorMeta);
    }
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    }
    if (data.containsKey('attributed_body_json')) {
      context.handle(
        _attributedBodyJsonMeta,
        attributedBodyJson.isAcceptableOrUnknown(
          data['attributed_body_json']!,
          _attributedBodyJsonMeta,
        ),
      );
    }
    if (data.containsKey('message_summary_info_json')) {
      context.handle(
        _messageSummaryInfoJsonMeta,
        messageSummaryInfoJson.isAcceptableOrUnknown(
          data['message_summary_info_json']!,
          _messageSummaryInfoJsonMeta,
        ),
      );
    }
    if (data.containsKey('payload_data_json')) {
      context.handle(
        _payloadDataJsonMeta,
        payloadDataJson.isAcceptableOrUnknown(
          data['payload_data_json']!,
          _payloadDataJsonMeta,
        ),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    if (data.containsKey('has_apple_payload_data')) {
      context.handle(
        _hasApplePayloadDataMeta,
        hasApplePayloadData.isAcceptableOrUnknown(
          data['has_apple_payload_data']!,
          _hasApplePayloadDataMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hasApplePayloadDataMeta);
    }
    if (data.containsKey('date_edited_us')) {
      context.handle(
        _dateEditedUsMeta,
        dateEditedUs.isAcceptableOrUnknown(
          data['date_edited_us']!,
          _dateEditedUsMeta,
        ),
      );
    }
    if (data.containsKey('was_delivered_quietly')) {
      context.handle(
        _wasDeliveredQuietlyMeta,
        wasDeliveredQuietly.isAcceptableOrUnknown(
          data['was_delivered_quietly']!,
          _wasDeliveredQuietlyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_wasDeliveredQuietlyMeta);
    }
    if (data.containsKey('did_notify_recipient')) {
      context.handle(
        _didNotifyRecipientMeta,
        didNotifyRecipient.isAcceptableOrUnknown(
          data['did_notify_recipient']!,
          _didNotifyRecipientMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_didNotifyRecipientMeta);
    }
    if (data.containsKey('is_bookmarked')) {
      context.handle(
        _isBookmarkedMeta,
        isBookmarked.isAcceptableOrUnknown(
          data['is_bookmarked']!,
          _isBookmarkedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isBookmarkedMeta);
    }
    if (data.containsKey('is_delivered')) {
      context.handle(
        _isDeliveredMeta,
        isDelivered.isAcceptableOrUnknown(
          data['is_delivered']!,
          _isDeliveredMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isDeliveredMeta);
    }
    if (data.containsKey('handle_relation_id')) {
      context.handle(
        _handleRelationIdMeta,
        handleRelationId.isAcceptableOrUnknown(
          data['handle_relation_id']!,
          _handleRelationIdMeta,
        ),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('has_effect_played')) {
      context.handle(
        _hasEffectPlayedMeta,
        hasEffectPlayed.isAcceptableOrUnknown(
          data['has_effect_played']!,
          _hasEffectPlayedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hasEffectPlayedMeta);
    }
    if (data.containsKey('apple_chat_guid')) {
      context.handle(
        _appleChatGuidMeta,
        appleChatGuid.isAcceptableOrUnknown(
          data['apple_chat_guid']!,
          _appleChatGuidMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SqliteMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteMessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      originalRowid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_rowid'],
      ),
      guid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guid'],
      ),
      handleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}handle_id'],
      ),
      otherHandle: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}other_handle'],
      ),
      messageText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      ),
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      service: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service'],
      ),
      dateCreatedUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_created_us'],
      ),
      sortAtUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_at_us'],
      )!,
      dateReadUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_read_us'],
      ),
      dateDeliveredUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_delivered_us'],
      ),
      isFromMe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_from_me'],
      ),
      hasDdResults: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_dd_results'],
      ),
      datePlayedUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_played_us'],
      ),
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_type'],
      ),
      groupTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_title'],
      ),
      groupActionType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_action_type'],
      ),
      balloonBundleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}balloon_bundle_id'],
      ),
      associatedMessageGuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}associated_message_guid'],
      ),
      associatedMessagePart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}associated_message_part'],
      ),
      associatedMessageType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}associated_message_type'],
      ),
      expressiveSendStyleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expressive_send_style_id'],
      ),
      hasAttachments: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_attachments'],
      )!,
      hasReactions: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_reactions'],
      )!,
      dateDeletedUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_deleted_us'],
      ),
      threadOriginatorGuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_originator_guid'],
      ),
      threadOriginatorPart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_originator_part'],
      ),
      bigEmoji: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}big_emoji'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}error'],
      )!,
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chat_id'],
      ),
      attributedBodyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attributed_body_json'],
      ),
      messageSummaryInfoJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_summary_info_json'],
      ),
      payloadDataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_data_json'],
      ),
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      ),
      hasApplePayloadData: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_apple_payload_data'],
      )!,
      dateEditedUs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_edited_us'],
      ),
      wasDeliveredQuietly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_delivered_quietly'],
      )!,
      didNotifyRecipient: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}did_notify_recipient'],
      )!,
      isBookmarked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bookmarked'],
      )!,
      isDelivered: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_delivered'],
      )!,
      handleRelationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}handle_relation_id'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      hasEffectPlayed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_effect_played'],
      )!,
      appleChatGuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}apple_chat_guid'],
      ),
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class SqliteMessageRow extends DataClass
    implements Insertable<SqliteMessageRow> {
  final int id;
  final int? originalRowid;
  final String? guid;
  final int? handleId;
  final int? otherHandle;
  final String? messageText;
  final String? subject;
  final String? country;
  final String? service;
  final int? dateCreatedUs;
  final int sortAtUs;
  final int? dateReadUs;
  final int? dateDeliveredUs;
  final bool? isFromMe;
  final bool? hasDdResults;
  final int? datePlayedUs;
  final int? itemType;
  final String? groupTitle;
  final int? groupActionType;
  final String? balloonBundleId;
  final String? associatedMessageGuid;
  final int? associatedMessagePart;
  final String? associatedMessageType;
  final String? expressiveSendStyleId;
  final bool hasAttachments;
  final bool hasReactions;
  final int? dateDeletedUs;
  final String? threadOriginatorGuid;
  final String? threadOriginatorPart;
  final bool? bigEmoji;
  final int error;
  final int? chatId;
  final String? attributedBodyJson;
  final String? messageSummaryInfoJson;
  final String? payloadDataJson;
  final String? metadataJson;
  final bool hasApplePayloadData;
  final int? dateEditedUs;
  final bool wasDeliveredQuietly;
  final bool didNotifyRecipient;
  final bool isBookmarked;
  final bool isDelivered;
  final int? handleRelationId;
  final String? errorMessage;
  final bool hasEffectPlayed;
  final String? appleChatGuid;
  const SqliteMessageRow({
    required this.id,
    this.originalRowid,
    this.guid,
    this.handleId,
    this.otherHandle,
    this.messageText,
    this.subject,
    this.country,
    this.service,
    this.dateCreatedUs,
    required this.sortAtUs,
    this.dateReadUs,
    this.dateDeliveredUs,
    this.isFromMe,
    this.hasDdResults,
    this.datePlayedUs,
    this.itemType,
    this.groupTitle,
    this.groupActionType,
    this.balloonBundleId,
    this.associatedMessageGuid,
    this.associatedMessagePart,
    this.associatedMessageType,
    this.expressiveSendStyleId,
    required this.hasAttachments,
    required this.hasReactions,
    this.dateDeletedUs,
    this.threadOriginatorGuid,
    this.threadOriginatorPart,
    this.bigEmoji,
    required this.error,
    this.chatId,
    this.attributedBodyJson,
    this.messageSummaryInfoJson,
    this.payloadDataJson,
    this.metadataJson,
    required this.hasApplePayloadData,
    this.dateEditedUs,
    required this.wasDeliveredQuietly,
    required this.didNotifyRecipient,
    required this.isBookmarked,
    required this.isDelivered,
    this.handleRelationId,
    this.errorMessage,
    required this.hasEffectPlayed,
    this.appleChatGuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || originalRowid != null) {
      map['original_rowid'] = Variable<int>(originalRowid);
    }
    if (!nullToAbsent || guid != null) {
      map['guid'] = Variable<String>(guid);
    }
    if (!nullToAbsent || handleId != null) {
      map['handle_id'] = Variable<int>(handleId);
    }
    if (!nullToAbsent || otherHandle != null) {
      map['other_handle'] = Variable<int>(otherHandle);
    }
    if (!nullToAbsent || messageText != null) {
      map['text'] = Variable<String>(messageText);
    }
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    if (!nullToAbsent || service != null) {
      map['service'] = Variable<String>(service);
    }
    if (!nullToAbsent || dateCreatedUs != null) {
      map['date_created_us'] = Variable<int>(dateCreatedUs);
    }
    map['sort_at_us'] = Variable<int>(sortAtUs);
    if (!nullToAbsent || dateReadUs != null) {
      map['date_read_us'] = Variable<int>(dateReadUs);
    }
    if (!nullToAbsent || dateDeliveredUs != null) {
      map['date_delivered_us'] = Variable<int>(dateDeliveredUs);
    }
    if (!nullToAbsent || isFromMe != null) {
      map['is_from_me'] = Variable<bool>(isFromMe);
    }
    if (!nullToAbsent || hasDdResults != null) {
      map['has_dd_results'] = Variable<bool>(hasDdResults);
    }
    if (!nullToAbsent || datePlayedUs != null) {
      map['date_played_us'] = Variable<int>(datePlayedUs);
    }
    if (!nullToAbsent || itemType != null) {
      map['item_type'] = Variable<int>(itemType);
    }
    if (!nullToAbsent || groupTitle != null) {
      map['group_title'] = Variable<String>(groupTitle);
    }
    if (!nullToAbsent || groupActionType != null) {
      map['group_action_type'] = Variable<int>(groupActionType);
    }
    if (!nullToAbsent || balloonBundleId != null) {
      map['balloon_bundle_id'] = Variable<String>(balloonBundleId);
    }
    if (!nullToAbsent || associatedMessageGuid != null) {
      map['associated_message_guid'] = Variable<String>(associatedMessageGuid);
    }
    if (!nullToAbsent || associatedMessagePart != null) {
      map['associated_message_part'] = Variable<int>(associatedMessagePart);
    }
    if (!nullToAbsent || associatedMessageType != null) {
      map['associated_message_type'] = Variable<String>(associatedMessageType);
    }
    if (!nullToAbsent || expressiveSendStyleId != null) {
      map['expressive_send_style_id'] = Variable<String>(expressiveSendStyleId);
    }
    map['has_attachments'] = Variable<bool>(hasAttachments);
    map['has_reactions'] = Variable<bool>(hasReactions);
    if (!nullToAbsent || dateDeletedUs != null) {
      map['date_deleted_us'] = Variable<int>(dateDeletedUs);
    }
    if (!nullToAbsent || threadOriginatorGuid != null) {
      map['thread_originator_guid'] = Variable<String>(threadOriginatorGuid);
    }
    if (!nullToAbsent || threadOriginatorPart != null) {
      map['thread_originator_part'] = Variable<String>(threadOriginatorPart);
    }
    if (!nullToAbsent || bigEmoji != null) {
      map['big_emoji'] = Variable<bool>(bigEmoji);
    }
    map['error'] = Variable<int>(error);
    if (!nullToAbsent || chatId != null) {
      map['chat_id'] = Variable<int>(chatId);
    }
    if (!nullToAbsent || attributedBodyJson != null) {
      map['attributed_body_json'] = Variable<String>(attributedBodyJson);
    }
    if (!nullToAbsent || messageSummaryInfoJson != null) {
      map['message_summary_info_json'] = Variable<String>(
        messageSummaryInfoJson,
      );
    }
    if (!nullToAbsent || payloadDataJson != null) {
      map['payload_data_json'] = Variable<String>(payloadDataJson);
    }
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    map['has_apple_payload_data'] = Variable<bool>(hasApplePayloadData);
    if (!nullToAbsent || dateEditedUs != null) {
      map['date_edited_us'] = Variable<int>(dateEditedUs);
    }
    map['was_delivered_quietly'] = Variable<bool>(wasDeliveredQuietly);
    map['did_notify_recipient'] = Variable<bool>(didNotifyRecipient);
    map['is_bookmarked'] = Variable<bool>(isBookmarked);
    map['is_delivered'] = Variable<bool>(isDelivered);
    if (!nullToAbsent || handleRelationId != null) {
      map['handle_relation_id'] = Variable<int>(handleRelationId);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['has_effect_played'] = Variable<bool>(hasEffectPlayed);
    if (!nullToAbsent || appleChatGuid != null) {
      map['apple_chat_guid'] = Variable<String>(appleChatGuid);
    }
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      originalRowid: originalRowid == null && nullToAbsent
          ? const Value.absent()
          : Value(originalRowid),
      guid: guid == null && nullToAbsent ? const Value.absent() : Value(guid),
      handleId: handleId == null && nullToAbsent
          ? const Value.absent()
          : Value(handleId),
      otherHandle: otherHandle == null && nullToAbsent
          ? const Value.absent()
          : Value(otherHandle),
      messageText: messageText == null && nullToAbsent
          ? const Value.absent()
          : Value(messageText),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      service: service == null && nullToAbsent
          ? const Value.absent()
          : Value(service),
      dateCreatedUs: dateCreatedUs == null && nullToAbsent
          ? const Value.absent()
          : Value(dateCreatedUs),
      sortAtUs: Value(sortAtUs),
      dateReadUs: dateReadUs == null && nullToAbsent
          ? const Value.absent()
          : Value(dateReadUs),
      dateDeliveredUs: dateDeliveredUs == null && nullToAbsent
          ? const Value.absent()
          : Value(dateDeliveredUs),
      isFromMe: isFromMe == null && nullToAbsent
          ? const Value.absent()
          : Value(isFromMe),
      hasDdResults: hasDdResults == null && nullToAbsent
          ? const Value.absent()
          : Value(hasDdResults),
      datePlayedUs: datePlayedUs == null && nullToAbsent
          ? const Value.absent()
          : Value(datePlayedUs),
      itemType: itemType == null && nullToAbsent
          ? const Value.absent()
          : Value(itemType),
      groupTitle: groupTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(groupTitle),
      groupActionType: groupActionType == null && nullToAbsent
          ? const Value.absent()
          : Value(groupActionType),
      balloonBundleId: balloonBundleId == null && nullToAbsent
          ? const Value.absent()
          : Value(balloonBundleId),
      associatedMessageGuid: associatedMessageGuid == null && nullToAbsent
          ? const Value.absent()
          : Value(associatedMessageGuid),
      associatedMessagePart: associatedMessagePart == null && nullToAbsent
          ? const Value.absent()
          : Value(associatedMessagePart),
      associatedMessageType: associatedMessageType == null && nullToAbsent
          ? const Value.absent()
          : Value(associatedMessageType),
      expressiveSendStyleId: expressiveSendStyleId == null && nullToAbsent
          ? const Value.absent()
          : Value(expressiveSendStyleId),
      hasAttachments: Value(hasAttachments),
      hasReactions: Value(hasReactions),
      dateDeletedUs: dateDeletedUs == null && nullToAbsent
          ? const Value.absent()
          : Value(dateDeletedUs),
      threadOriginatorGuid: threadOriginatorGuid == null && nullToAbsent
          ? const Value.absent()
          : Value(threadOriginatorGuid),
      threadOriginatorPart: threadOriginatorPart == null && nullToAbsent
          ? const Value.absent()
          : Value(threadOriginatorPart),
      bigEmoji: bigEmoji == null && nullToAbsent
          ? const Value.absent()
          : Value(bigEmoji),
      error: Value(error),
      chatId: chatId == null && nullToAbsent
          ? const Value.absent()
          : Value(chatId),
      attributedBodyJson: attributedBodyJson == null && nullToAbsent
          ? const Value.absent()
          : Value(attributedBodyJson),
      messageSummaryInfoJson: messageSummaryInfoJson == null && nullToAbsent
          ? const Value.absent()
          : Value(messageSummaryInfoJson),
      payloadDataJson: payloadDataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadDataJson),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
      hasApplePayloadData: Value(hasApplePayloadData),
      dateEditedUs: dateEditedUs == null && nullToAbsent
          ? const Value.absent()
          : Value(dateEditedUs),
      wasDeliveredQuietly: Value(wasDeliveredQuietly),
      didNotifyRecipient: Value(didNotifyRecipient),
      isBookmarked: Value(isBookmarked),
      isDelivered: Value(isDelivered),
      handleRelationId: handleRelationId == null && nullToAbsent
          ? const Value.absent()
          : Value(handleRelationId),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      hasEffectPlayed: Value(hasEffectPlayed),
      appleChatGuid: appleChatGuid == null && nullToAbsent
          ? const Value.absent()
          : Value(appleChatGuid),
    );
  }

  factory SqliteMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteMessageRow(
      id: serializer.fromJson<int>(json['id']),
      originalRowid: serializer.fromJson<int?>(json['originalRowid']),
      guid: serializer.fromJson<String?>(json['guid']),
      handleId: serializer.fromJson<int?>(json['handleId']),
      otherHandle: serializer.fromJson<int?>(json['otherHandle']),
      messageText: serializer.fromJson<String?>(json['messageText']),
      subject: serializer.fromJson<String?>(json['subject']),
      country: serializer.fromJson<String?>(json['country']),
      service: serializer.fromJson<String?>(json['service']),
      dateCreatedUs: serializer.fromJson<int?>(json['dateCreatedUs']),
      sortAtUs: serializer.fromJson<int>(json['sortAtUs']),
      dateReadUs: serializer.fromJson<int?>(json['dateReadUs']),
      dateDeliveredUs: serializer.fromJson<int?>(json['dateDeliveredUs']),
      isFromMe: serializer.fromJson<bool?>(json['isFromMe']),
      hasDdResults: serializer.fromJson<bool?>(json['hasDdResults']),
      datePlayedUs: serializer.fromJson<int?>(json['datePlayedUs']),
      itemType: serializer.fromJson<int?>(json['itemType']),
      groupTitle: serializer.fromJson<String?>(json['groupTitle']),
      groupActionType: serializer.fromJson<int?>(json['groupActionType']),
      balloonBundleId: serializer.fromJson<String?>(json['balloonBundleId']),
      associatedMessageGuid: serializer.fromJson<String?>(
        json['associatedMessageGuid'],
      ),
      associatedMessagePart: serializer.fromJson<int?>(
        json['associatedMessagePart'],
      ),
      associatedMessageType: serializer.fromJson<String?>(
        json['associatedMessageType'],
      ),
      expressiveSendStyleId: serializer.fromJson<String?>(
        json['expressiveSendStyleId'],
      ),
      hasAttachments: serializer.fromJson<bool>(json['hasAttachments']),
      hasReactions: serializer.fromJson<bool>(json['hasReactions']),
      dateDeletedUs: serializer.fromJson<int?>(json['dateDeletedUs']),
      threadOriginatorGuid: serializer.fromJson<String?>(
        json['threadOriginatorGuid'],
      ),
      threadOriginatorPart: serializer.fromJson<String?>(
        json['threadOriginatorPart'],
      ),
      bigEmoji: serializer.fromJson<bool?>(json['bigEmoji']),
      error: serializer.fromJson<int>(json['error']),
      chatId: serializer.fromJson<int?>(json['chatId']),
      attributedBodyJson: serializer.fromJson<String?>(
        json['attributedBodyJson'],
      ),
      messageSummaryInfoJson: serializer.fromJson<String?>(
        json['messageSummaryInfoJson'],
      ),
      payloadDataJson: serializer.fromJson<String?>(json['payloadDataJson']),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
      hasApplePayloadData: serializer.fromJson<bool>(
        json['hasApplePayloadData'],
      ),
      dateEditedUs: serializer.fromJson<int?>(json['dateEditedUs']),
      wasDeliveredQuietly: serializer.fromJson<bool>(
        json['wasDeliveredQuietly'],
      ),
      didNotifyRecipient: serializer.fromJson<bool>(json['didNotifyRecipient']),
      isBookmarked: serializer.fromJson<bool>(json['isBookmarked']),
      isDelivered: serializer.fromJson<bool>(json['isDelivered']),
      handleRelationId: serializer.fromJson<int?>(json['handleRelationId']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      hasEffectPlayed: serializer.fromJson<bool>(json['hasEffectPlayed']),
      appleChatGuid: serializer.fromJson<String?>(json['appleChatGuid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'originalRowid': serializer.toJson<int?>(originalRowid),
      'guid': serializer.toJson<String?>(guid),
      'handleId': serializer.toJson<int?>(handleId),
      'otherHandle': serializer.toJson<int?>(otherHandle),
      'messageText': serializer.toJson<String?>(messageText),
      'subject': serializer.toJson<String?>(subject),
      'country': serializer.toJson<String?>(country),
      'service': serializer.toJson<String?>(service),
      'dateCreatedUs': serializer.toJson<int?>(dateCreatedUs),
      'sortAtUs': serializer.toJson<int>(sortAtUs),
      'dateReadUs': serializer.toJson<int?>(dateReadUs),
      'dateDeliveredUs': serializer.toJson<int?>(dateDeliveredUs),
      'isFromMe': serializer.toJson<bool?>(isFromMe),
      'hasDdResults': serializer.toJson<bool?>(hasDdResults),
      'datePlayedUs': serializer.toJson<int?>(datePlayedUs),
      'itemType': serializer.toJson<int?>(itemType),
      'groupTitle': serializer.toJson<String?>(groupTitle),
      'groupActionType': serializer.toJson<int?>(groupActionType),
      'balloonBundleId': serializer.toJson<String?>(balloonBundleId),
      'associatedMessageGuid': serializer.toJson<String?>(
        associatedMessageGuid,
      ),
      'associatedMessagePart': serializer.toJson<int?>(associatedMessagePart),
      'associatedMessageType': serializer.toJson<String?>(
        associatedMessageType,
      ),
      'expressiveSendStyleId': serializer.toJson<String?>(
        expressiveSendStyleId,
      ),
      'hasAttachments': serializer.toJson<bool>(hasAttachments),
      'hasReactions': serializer.toJson<bool>(hasReactions),
      'dateDeletedUs': serializer.toJson<int?>(dateDeletedUs),
      'threadOriginatorGuid': serializer.toJson<String?>(threadOriginatorGuid),
      'threadOriginatorPart': serializer.toJson<String?>(threadOriginatorPart),
      'bigEmoji': serializer.toJson<bool?>(bigEmoji),
      'error': serializer.toJson<int>(error),
      'chatId': serializer.toJson<int?>(chatId),
      'attributedBodyJson': serializer.toJson<String?>(attributedBodyJson),
      'messageSummaryInfoJson': serializer.toJson<String?>(
        messageSummaryInfoJson,
      ),
      'payloadDataJson': serializer.toJson<String?>(payloadDataJson),
      'metadataJson': serializer.toJson<String?>(metadataJson),
      'hasApplePayloadData': serializer.toJson<bool>(hasApplePayloadData),
      'dateEditedUs': serializer.toJson<int?>(dateEditedUs),
      'wasDeliveredQuietly': serializer.toJson<bool>(wasDeliveredQuietly),
      'didNotifyRecipient': serializer.toJson<bool>(didNotifyRecipient),
      'isBookmarked': serializer.toJson<bool>(isBookmarked),
      'isDelivered': serializer.toJson<bool>(isDelivered),
      'handleRelationId': serializer.toJson<int?>(handleRelationId),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'hasEffectPlayed': serializer.toJson<bool>(hasEffectPlayed),
      'appleChatGuid': serializer.toJson<String?>(appleChatGuid),
    };
  }

  SqliteMessageRow copyWith({
    int? id,
    Value<int?> originalRowid = const Value.absent(),
    Value<String?> guid = const Value.absent(),
    Value<int?> handleId = const Value.absent(),
    Value<int?> otherHandle = const Value.absent(),
    Value<String?> messageText = const Value.absent(),
    Value<String?> subject = const Value.absent(),
    Value<String?> country = const Value.absent(),
    Value<String?> service = const Value.absent(),
    Value<int?> dateCreatedUs = const Value.absent(),
    int? sortAtUs,
    Value<int?> dateReadUs = const Value.absent(),
    Value<int?> dateDeliveredUs = const Value.absent(),
    Value<bool?> isFromMe = const Value.absent(),
    Value<bool?> hasDdResults = const Value.absent(),
    Value<int?> datePlayedUs = const Value.absent(),
    Value<int?> itemType = const Value.absent(),
    Value<String?> groupTitle = const Value.absent(),
    Value<int?> groupActionType = const Value.absent(),
    Value<String?> balloonBundleId = const Value.absent(),
    Value<String?> associatedMessageGuid = const Value.absent(),
    Value<int?> associatedMessagePart = const Value.absent(),
    Value<String?> associatedMessageType = const Value.absent(),
    Value<String?> expressiveSendStyleId = const Value.absent(),
    bool? hasAttachments,
    bool? hasReactions,
    Value<int?> dateDeletedUs = const Value.absent(),
    Value<String?> threadOriginatorGuid = const Value.absent(),
    Value<String?> threadOriginatorPart = const Value.absent(),
    Value<bool?> bigEmoji = const Value.absent(),
    int? error,
    Value<int?> chatId = const Value.absent(),
    Value<String?> attributedBodyJson = const Value.absent(),
    Value<String?> messageSummaryInfoJson = const Value.absent(),
    Value<String?> payloadDataJson = const Value.absent(),
    Value<String?> metadataJson = const Value.absent(),
    bool? hasApplePayloadData,
    Value<int?> dateEditedUs = const Value.absent(),
    bool? wasDeliveredQuietly,
    bool? didNotifyRecipient,
    bool? isBookmarked,
    bool? isDelivered,
    Value<int?> handleRelationId = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
    bool? hasEffectPlayed,
    Value<String?> appleChatGuid = const Value.absent(),
  }) => SqliteMessageRow(
    id: id ?? this.id,
    originalRowid: originalRowid.present
        ? originalRowid.value
        : this.originalRowid,
    guid: guid.present ? guid.value : this.guid,
    handleId: handleId.present ? handleId.value : this.handleId,
    otherHandle: otherHandle.present ? otherHandle.value : this.otherHandle,
    messageText: messageText.present ? messageText.value : this.messageText,
    subject: subject.present ? subject.value : this.subject,
    country: country.present ? country.value : this.country,
    service: service.present ? service.value : this.service,
    dateCreatedUs: dateCreatedUs.present
        ? dateCreatedUs.value
        : this.dateCreatedUs,
    sortAtUs: sortAtUs ?? this.sortAtUs,
    dateReadUs: dateReadUs.present ? dateReadUs.value : this.dateReadUs,
    dateDeliveredUs: dateDeliveredUs.present
        ? dateDeliveredUs.value
        : this.dateDeliveredUs,
    isFromMe: isFromMe.present ? isFromMe.value : this.isFromMe,
    hasDdResults: hasDdResults.present ? hasDdResults.value : this.hasDdResults,
    datePlayedUs: datePlayedUs.present ? datePlayedUs.value : this.datePlayedUs,
    itemType: itemType.present ? itemType.value : this.itemType,
    groupTitle: groupTitle.present ? groupTitle.value : this.groupTitle,
    groupActionType: groupActionType.present
        ? groupActionType.value
        : this.groupActionType,
    balloonBundleId: balloonBundleId.present
        ? balloonBundleId.value
        : this.balloonBundleId,
    associatedMessageGuid: associatedMessageGuid.present
        ? associatedMessageGuid.value
        : this.associatedMessageGuid,
    associatedMessagePart: associatedMessagePart.present
        ? associatedMessagePart.value
        : this.associatedMessagePart,
    associatedMessageType: associatedMessageType.present
        ? associatedMessageType.value
        : this.associatedMessageType,
    expressiveSendStyleId: expressiveSendStyleId.present
        ? expressiveSendStyleId.value
        : this.expressiveSendStyleId,
    hasAttachments: hasAttachments ?? this.hasAttachments,
    hasReactions: hasReactions ?? this.hasReactions,
    dateDeletedUs: dateDeletedUs.present
        ? dateDeletedUs.value
        : this.dateDeletedUs,
    threadOriginatorGuid: threadOriginatorGuid.present
        ? threadOriginatorGuid.value
        : this.threadOriginatorGuid,
    threadOriginatorPart: threadOriginatorPart.present
        ? threadOriginatorPart.value
        : this.threadOriginatorPart,
    bigEmoji: bigEmoji.present ? bigEmoji.value : this.bigEmoji,
    error: error ?? this.error,
    chatId: chatId.present ? chatId.value : this.chatId,
    attributedBodyJson: attributedBodyJson.present
        ? attributedBodyJson.value
        : this.attributedBodyJson,
    messageSummaryInfoJson: messageSummaryInfoJson.present
        ? messageSummaryInfoJson.value
        : this.messageSummaryInfoJson,
    payloadDataJson: payloadDataJson.present
        ? payloadDataJson.value
        : this.payloadDataJson,
    metadataJson: metadataJson.present ? metadataJson.value : this.metadataJson,
    hasApplePayloadData: hasApplePayloadData ?? this.hasApplePayloadData,
    dateEditedUs: dateEditedUs.present ? dateEditedUs.value : this.dateEditedUs,
    wasDeliveredQuietly: wasDeliveredQuietly ?? this.wasDeliveredQuietly,
    didNotifyRecipient: didNotifyRecipient ?? this.didNotifyRecipient,
    isBookmarked: isBookmarked ?? this.isBookmarked,
    isDelivered: isDelivered ?? this.isDelivered,
    handleRelationId: handleRelationId.present
        ? handleRelationId.value
        : this.handleRelationId,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    hasEffectPlayed: hasEffectPlayed ?? this.hasEffectPlayed,
    appleChatGuid: appleChatGuid.present
        ? appleChatGuid.value
        : this.appleChatGuid,
  );
  SqliteMessageRow copyWithCompanion(MessagesCompanion data) {
    return SqliteMessageRow(
      id: data.id.present ? data.id.value : this.id,
      originalRowid: data.originalRowid.present
          ? data.originalRowid.value
          : this.originalRowid,
      guid: data.guid.present ? data.guid.value : this.guid,
      handleId: data.handleId.present ? data.handleId.value : this.handleId,
      otherHandle: data.otherHandle.present
          ? data.otherHandle.value
          : this.otherHandle,
      messageText: data.messageText.present
          ? data.messageText.value
          : this.messageText,
      subject: data.subject.present ? data.subject.value : this.subject,
      country: data.country.present ? data.country.value : this.country,
      service: data.service.present ? data.service.value : this.service,
      dateCreatedUs: data.dateCreatedUs.present
          ? data.dateCreatedUs.value
          : this.dateCreatedUs,
      sortAtUs: data.sortAtUs.present ? data.sortAtUs.value : this.sortAtUs,
      dateReadUs: data.dateReadUs.present
          ? data.dateReadUs.value
          : this.dateReadUs,
      dateDeliveredUs: data.dateDeliveredUs.present
          ? data.dateDeliveredUs.value
          : this.dateDeliveredUs,
      isFromMe: data.isFromMe.present ? data.isFromMe.value : this.isFromMe,
      hasDdResults: data.hasDdResults.present
          ? data.hasDdResults.value
          : this.hasDdResults,
      datePlayedUs: data.datePlayedUs.present
          ? data.datePlayedUs.value
          : this.datePlayedUs,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      groupTitle: data.groupTitle.present
          ? data.groupTitle.value
          : this.groupTitle,
      groupActionType: data.groupActionType.present
          ? data.groupActionType.value
          : this.groupActionType,
      balloonBundleId: data.balloonBundleId.present
          ? data.balloonBundleId.value
          : this.balloonBundleId,
      associatedMessageGuid: data.associatedMessageGuid.present
          ? data.associatedMessageGuid.value
          : this.associatedMessageGuid,
      associatedMessagePart: data.associatedMessagePart.present
          ? data.associatedMessagePart.value
          : this.associatedMessagePart,
      associatedMessageType: data.associatedMessageType.present
          ? data.associatedMessageType.value
          : this.associatedMessageType,
      expressiveSendStyleId: data.expressiveSendStyleId.present
          ? data.expressiveSendStyleId.value
          : this.expressiveSendStyleId,
      hasAttachments: data.hasAttachments.present
          ? data.hasAttachments.value
          : this.hasAttachments,
      hasReactions: data.hasReactions.present
          ? data.hasReactions.value
          : this.hasReactions,
      dateDeletedUs: data.dateDeletedUs.present
          ? data.dateDeletedUs.value
          : this.dateDeletedUs,
      threadOriginatorGuid: data.threadOriginatorGuid.present
          ? data.threadOriginatorGuid.value
          : this.threadOriginatorGuid,
      threadOriginatorPart: data.threadOriginatorPart.present
          ? data.threadOriginatorPart.value
          : this.threadOriginatorPart,
      bigEmoji: data.bigEmoji.present ? data.bigEmoji.value : this.bigEmoji,
      error: data.error.present ? data.error.value : this.error,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      attributedBodyJson: data.attributedBodyJson.present
          ? data.attributedBodyJson.value
          : this.attributedBodyJson,
      messageSummaryInfoJson: data.messageSummaryInfoJson.present
          ? data.messageSummaryInfoJson.value
          : this.messageSummaryInfoJson,
      payloadDataJson: data.payloadDataJson.present
          ? data.payloadDataJson.value
          : this.payloadDataJson,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      hasApplePayloadData: data.hasApplePayloadData.present
          ? data.hasApplePayloadData.value
          : this.hasApplePayloadData,
      dateEditedUs: data.dateEditedUs.present
          ? data.dateEditedUs.value
          : this.dateEditedUs,
      wasDeliveredQuietly: data.wasDeliveredQuietly.present
          ? data.wasDeliveredQuietly.value
          : this.wasDeliveredQuietly,
      didNotifyRecipient: data.didNotifyRecipient.present
          ? data.didNotifyRecipient.value
          : this.didNotifyRecipient,
      isBookmarked: data.isBookmarked.present
          ? data.isBookmarked.value
          : this.isBookmarked,
      isDelivered: data.isDelivered.present
          ? data.isDelivered.value
          : this.isDelivered,
      handleRelationId: data.handleRelationId.present
          ? data.handleRelationId.value
          : this.handleRelationId,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      hasEffectPlayed: data.hasEffectPlayed.present
          ? data.hasEffectPlayed.value
          : this.hasEffectPlayed,
      appleChatGuid: data.appleChatGuid.present
          ? data.appleChatGuid.value
          : this.appleChatGuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteMessageRow(')
          ..write('id: $id, ')
          ..write('originalRowid: $originalRowid, ')
          ..write('guid: $guid, ')
          ..write('handleId: $handleId, ')
          ..write('otherHandle: $otherHandle, ')
          ..write('messageText: $messageText, ')
          ..write('subject: $subject, ')
          ..write('country: $country, ')
          ..write('service: $service, ')
          ..write('dateCreatedUs: $dateCreatedUs, ')
          ..write('sortAtUs: $sortAtUs, ')
          ..write('dateReadUs: $dateReadUs, ')
          ..write('dateDeliveredUs: $dateDeliveredUs, ')
          ..write('isFromMe: $isFromMe, ')
          ..write('hasDdResults: $hasDdResults, ')
          ..write('datePlayedUs: $datePlayedUs, ')
          ..write('itemType: $itemType, ')
          ..write('groupTitle: $groupTitle, ')
          ..write('groupActionType: $groupActionType, ')
          ..write('balloonBundleId: $balloonBundleId, ')
          ..write('associatedMessageGuid: $associatedMessageGuid, ')
          ..write('associatedMessagePart: $associatedMessagePart, ')
          ..write('associatedMessageType: $associatedMessageType, ')
          ..write('expressiveSendStyleId: $expressiveSendStyleId, ')
          ..write('hasAttachments: $hasAttachments, ')
          ..write('hasReactions: $hasReactions, ')
          ..write('dateDeletedUs: $dateDeletedUs, ')
          ..write('threadOriginatorGuid: $threadOriginatorGuid, ')
          ..write('threadOriginatorPart: $threadOriginatorPart, ')
          ..write('bigEmoji: $bigEmoji, ')
          ..write('error: $error, ')
          ..write('chatId: $chatId, ')
          ..write('attributedBodyJson: $attributedBodyJson, ')
          ..write('messageSummaryInfoJson: $messageSummaryInfoJson, ')
          ..write('payloadDataJson: $payloadDataJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('hasApplePayloadData: $hasApplePayloadData, ')
          ..write('dateEditedUs: $dateEditedUs, ')
          ..write('wasDeliveredQuietly: $wasDeliveredQuietly, ')
          ..write('didNotifyRecipient: $didNotifyRecipient, ')
          ..write('isBookmarked: $isBookmarked, ')
          ..write('isDelivered: $isDelivered, ')
          ..write('handleRelationId: $handleRelationId, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('hasEffectPlayed: $hasEffectPlayed, ')
          ..write('appleChatGuid: $appleChatGuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    originalRowid,
    guid,
    handleId,
    otherHandle,
    messageText,
    subject,
    country,
    service,
    dateCreatedUs,
    sortAtUs,
    dateReadUs,
    dateDeliveredUs,
    isFromMe,
    hasDdResults,
    datePlayedUs,
    itemType,
    groupTitle,
    groupActionType,
    balloonBundleId,
    associatedMessageGuid,
    associatedMessagePart,
    associatedMessageType,
    expressiveSendStyleId,
    hasAttachments,
    hasReactions,
    dateDeletedUs,
    threadOriginatorGuid,
    threadOriginatorPart,
    bigEmoji,
    error,
    chatId,
    attributedBodyJson,
    messageSummaryInfoJson,
    payloadDataJson,
    metadataJson,
    hasApplePayloadData,
    dateEditedUs,
    wasDeliveredQuietly,
    didNotifyRecipient,
    isBookmarked,
    isDelivered,
    handleRelationId,
    errorMessage,
    hasEffectPlayed,
    appleChatGuid,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteMessageRow &&
          other.id == this.id &&
          other.originalRowid == this.originalRowid &&
          other.guid == this.guid &&
          other.handleId == this.handleId &&
          other.otherHandle == this.otherHandle &&
          other.messageText == this.messageText &&
          other.subject == this.subject &&
          other.country == this.country &&
          other.service == this.service &&
          other.dateCreatedUs == this.dateCreatedUs &&
          other.sortAtUs == this.sortAtUs &&
          other.dateReadUs == this.dateReadUs &&
          other.dateDeliveredUs == this.dateDeliveredUs &&
          other.isFromMe == this.isFromMe &&
          other.hasDdResults == this.hasDdResults &&
          other.datePlayedUs == this.datePlayedUs &&
          other.itemType == this.itemType &&
          other.groupTitle == this.groupTitle &&
          other.groupActionType == this.groupActionType &&
          other.balloonBundleId == this.balloonBundleId &&
          other.associatedMessageGuid == this.associatedMessageGuid &&
          other.associatedMessagePart == this.associatedMessagePart &&
          other.associatedMessageType == this.associatedMessageType &&
          other.expressiveSendStyleId == this.expressiveSendStyleId &&
          other.hasAttachments == this.hasAttachments &&
          other.hasReactions == this.hasReactions &&
          other.dateDeletedUs == this.dateDeletedUs &&
          other.threadOriginatorGuid == this.threadOriginatorGuid &&
          other.threadOriginatorPart == this.threadOriginatorPart &&
          other.bigEmoji == this.bigEmoji &&
          other.error == this.error &&
          other.chatId == this.chatId &&
          other.attributedBodyJson == this.attributedBodyJson &&
          other.messageSummaryInfoJson == this.messageSummaryInfoJson &&
          other.payloadDataJson == this.payloadDataJson &&
          other.metadataJson == this.metadataJson &&
          other.hasApplePayloadData == this.hasApplePayloadData &&
          other.dateEditedUs == this.dateEditedUs &&
          other.wasDeliveredQuietly == this.wasDeliveredQuietly &&
          other.didNotifyRecipient == this.didNotifyRecipient &&
          other.isBookmarked == this.isBookmarked &&
          other.isDelivered == this.isDelivered &&
          other.handleRelationId == this.handleRelationId &&
          other.errorMessage == this.errorMessage &&
          other.hasEffectPlayed == this.hasEffectPlayed &&
          other.appleChatGuid == this.appleChatGuid);
}

class MessagesCompanion extends UpdateCompanion<SqliteMessageRow> {
  final Value<int> id;
  final Value<int?> originalRowid;
  final Value<String?> guid;
  final Value<int?> handleId;
  final Value<int?> otherHandle;
  final Value<String?> messageText;
  final Value<String?> subject;
  final Value<String?> country;
  final Value<String?> service;
  final Value<int?> dateCreatedUs;
  final Value<int> sortAtUs;
  final Value<int?> dateReadUs;
  final Value<int?> dateDeliveredUs;
  final Value<bool?> isFromMe;
  final Value<bool?> hasDdResults;
  final Value<int?> datePlayedUs;
  final Value<int?> itemType;
  final Value<String?> groupTitle;
  final Value<int?> groupActionType;
  final Value<String?> balloonBundleId;
  final Value<String?> associatedMessageGuid;
  final Value<int?> associatedMessagePart;
  final Value<String?> associatedMessageType;
  final Value<String?> expressiveSendStyleId;
  final Value<bool> hasAttachments;
  final Value<bool> hasReactions;
  final Value<int?> dateDeletedUs;
  final Value<String?> threadOriginatorGuid;
  final Value<String?> threadOriginatorPart;
  final Value<bool?> bigEmoji;
  final Value<int> error;
  final Value<int?> chatId;
  final Value<String?> attributedBodyJson;
  final Value<String?> messageSummaryInfoJson;
  final Value<String?> payloadDataJson;
  final Value<String?> metadataJson;
  final Value<bool> hasApplePayloadData;
  final Value<int?> dateEditedUs;
  final Value<bool> wasDeliveredQuietly;
  final Value<bool> didNotifyRecipient;
  final Value<bool> isBookmarked;
  final Value<bool> isDelivered;
  final Value<int?> handleRelationId;
  final Value<String?> errorMessage;
  final Value<bool> hasEffectPlayed;
  final Value<String?> appleChatGuid;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.originalRowid = const Value.absent(),
    this.guid = const Value.absent(),
    this.handleId = const Value.absent(),
    this.otherHandle = const Value.absent(),
    this.messageText = const Value.absent(),
    this.subject = const Value.absent(),
    this.country = const Value.absent(),
    this.service = const Value.absent(),
    this.dateCreatedUs = const Value.absent(),
    this.sortAtUs = const Value.absent(),
    this.dateReadUs = const Value.absent(),
    this.dateDeliveredUs = const Value.absent(),
    this.isFromMe = const Value.absent(),
    this.hasDdResults = const Value.absent(),
    this.datePlayedUs = const Value.absent(),
    this.itemType = const Value.absent(),
    this.groupTitle = const Value.absent(),
    this.groupActionType = const Value.absent(),
    this.balloonBundleId = const Value.absent(),
    this.associatedMessageGuid = const Value.absent(),
    this.associatedMessagePart = const Value.absent(),
    this.associatedMessageType = const Value.absent(),
    this.expressiveSendStyleId = const Value.absent(),
    this.hasAttachments = const Value.absent(),
    this.hasReactions = const Value.absent(),
    this.dateDeletedUs = const Value.absent(),
    this.threadOriginatorGuid = const Value.absent(),
    this.threadOriginatorPart = const Value.absent(),
    this.bigEmoji = const Value.absent(),
    this.error = const Value.absent(),
    this.chatId = const Value.absent(),
    this.attributedBodyJson = const Value.absent(),
    this.messageSummaryInfoJson = const Value.absent(),
    this.payloadDataJson = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.hasApplePayloadData = const Value.absent(),
    this.dateEditedUs = const Value.absent(),
    this.wasDeliveredQuietly = const Value.absent(),
    this.didNotifyRecipient = const Value.absent(),
    this.isBookmarked = const Value.absent(),
    this.isDelivered = const Value.absent(),
    this.handleRelationId = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.hasEffectPlayed = const Value.absent(),
    this.appleChatGuid = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    this.originalRowid = const Value.absent(),
    this.guid = const Value.absent(),
    this.handleId = const Value.absent(),
    this.otherHandle = const Value.absent(),
    this.messageText = const Value.absent(),
    this.subject = const Value.absent(),
    this.country = const Value.absent(),
    this.service = const Value.absent(),
    this.dateCreatedUs = const Value.absent(),
    required int sortAtUs,
    this.dateReadUs = const Value.absent(),
    this.dateDeliveredUs = const Value.absent(),
    this.isFromMe = const Value.absent(),
    this.hasDdResults = const Value.absent(),
    this.datePlayedUs = const Value.absent(),
    this.itemType = const Value.absent(),
    this.groupTitle = const Value.absent(),
    this.groupActionType = const Value.absent(),
    this.balloonBundleId = const Value.absent(),
    this.associatedMessageGuid = const Value.absent(),
    this.associatedMessagePart = const Value.absent(),
    this.associatedMessageType = const Value.absent(),
    this.expressiveSendStyleId = const Value.absent(),
    required bool hasAttachments,
    required bool hasReactions,
    this.dateDeletedUs = const Value.absent(),
    this.threadOriginatorGuid = const Value.absent(),
    this.threadOriginatorPart = const Value.absent(),
    this.bigEmoji = const Value.absent(),
    required int error,
    this.chatId = const Value.absent(),
    this.attributedBodyJson = const Value.absent(),
    this.messageSummaryInfoJson = const Value.absent(),
    this.payloadDataJson = const Value.absent(),
    this.metadataJson = const Value.absent(),
    required bool hasApplePayloadData,
    this.dateEditedUs = const Value.absent(),
    required bool wasDeliveredQuietly,
    required bool didNotifyRecipient,
    required bool isBookmarked,
    required bool isDelivered,
    this.handleRelationId = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required bool hasEffectPlayed,
    this.appleChatGuid = const Value.absent(),
  }) : sortAtUs = Value(sortAtUs),
       hasAttachments = Value(hasAttachments),
       hasReactions = Value(hasReactions),
       error = Value(error),
       hasApplePayloadData = Value(hasApplePayloadData),
       wasDeliveredQuietly = Value(wasDeliveredQuietly),
       didNotifyRecipient = Value(didNotifyRecipient),
       isBookmarked = Value(isBookmarked),
       isDelivered = Value(isDelivered),
       hasEffectPlayed = Value(hasEffectPlayed);
  static Insertable<SqliteMessageRow> custom({
    Expression<int>? id,
    Expression<int>? originalRowid,
    Expression<String>? guid,
    Expression<int>? handleId,
    Expression<int>? otherHandle,
    Expression<String>? messageText,
    Expression<String>? subject,
    Expression<String>? country,
    Expression<String>? service,
    Expression<int>? dateCreatedUs,
    Expression<int>? sortAtUs,
    Expression<int>? dateReadUs,
    Expression<int>? dateDeliveredUs,
    Expression<bool>? isFromMe,
    Expression<bool>? hasDdResults,
    Expression<int>? datePlayedUs,
    Expression<int>? itemType,
    Expression<String>? groupTitle,
    Expression<int>? groupActionType,
    Expression<String>? balloonBundleId,
    Expression<String>? associatedMessageGuid,
    Expression<int>? associatedMessagePart,
    Expression<String>? associatedMessageType,
    Expression<String>? expressiveSendStyleId,
    Expression<bool>? hasAttachments,
    Expression<bool>? hasReactions,
    Expression<int>? dateDeletedUs,
    Expression<String>? threadOriginatorGuid,
    Expression<String>? threadOriginatorPart,
    Expression<bool>? bigEmoji,
    Expression<int>? error,
    Expression<int>? chatId,
    Expression<String>? attributedBodyJson,
    Expression<String>? messageSummaryInfoJson,
    Expression<String>? payloadDataJson,
    Expression<String>? metadataJson,
    Expression<bool>? hasApplePayloadData,
    Expression<int>? dateEditedUs,
    Expression<bool>? wasDeliveredQuietly,
    Expression<bool>? didNotifyRecipient,
    Expression<bool>? isBookmarked,
    Expression<bool>? isDelivered,
    Expression<int>? handleRelationId,
    Expression<String>? errorMessage,
    Expression<bool>? hasEffectPlayed,
    Expression<String>? appleChatGuid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originalRowid != null) 'original_rowid': originalRowid,
      if (guid != null) 'guid': guid,
      if (handleId != null) 'handle_id': handleId,
      if (otherHandle != null) 'other_handle': otherHandle,
      if (messageText != null) 'text': messageText,
      if (subject != null) 'subject': subject,
      if (country != null) 'country': country,
      if (service != null) 'service': service,
      if (dateCreatedUs != null) 'date_created_us': dateCreatedUs,
      if (sortAtUs != null) 'sort_at_us': sortAtUs,
      if (dateReadUs != null) 'date_read_us': dateReadUs,
      if (dateDeliveredUs != null) 'date_delivered_us': dateDeliveredUs,
      if (isFromMe != null) 'is_from_me': isFromMe,
      if (hasDdResults != null) 'has_dd_results': hasDdResults,
      if (datePlayedUs != null) 'date_played_us': datePlayedUs,
      if (itemType != null) 'item_type': itemType,
      if (groupTitle != null) 'group_title': groupTitle,
      if (groupActionType != null) 'group_action_type': groupActionType,
      if (balloonBundleId != null) 'balloon_bundle_id': balloonBundleId,
      if (associatedMessageGuid != null)
        'associated_message_guid': associatedMessageGuid,
      if (associatedMessagePart != null)
        'associated_message_part': associatedMessagePart,
      if (associatedMessageType != null)
        'associated_message_type': associatedMessageType,
      if (expressiveSendStyleId != null)
        'expressive_send_style_id': expressiveSendStyleId,
      if (hasAttachments != null) 'has_attachments': hasAttachments,
      if (hasReactions != null) 'has_reactions': hasReactions,
      if (dateDeletedUs != null) 'date_deleted_us': dateDeletedUs,
      if (threadOriginatorGuid != null)
        'thread_originator_guid': threadOriginatorGuid,
      if (threadOriginatorPart != null)
        'thread_originator_part': threadOriginatorPart,
      if (bigEmoji != null) 'big_emoji': bigEmoji,
      if (error != null) 'error': error,
      if (chatId != null) 'chat_id': chatId,
      if (attributedBodyJson != null)
        'attributed_body_json': attributedBodyJson,
      if (messageSummaryInfoJson != null)
        'message_summary_info_json': messageSummaryInfoJson,
      if (payloadDataJson != null) 'payload_data_json': payloadDataJson,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (hasApplePayloadData != null)
        'has_apple_payload_data': hasApplePayloadData,
      if (dateEditedUs != null) 'date_edited_us': dateEditedUs,
      if (wasDeliveredQuietly != null)
        'was_delivered_quietly': wasDeliveredQuietly,
      if (didNotifyRecipient != null)
        'did_notify_recipient': didNotifyRecipient,
      if (isBookmarked != null) 'is_bookmarked': isBookmarked,
      if (isDelivered != null) 'is_delivered': isDelivered,
      if (handleRelationId != null) 'handle_relation_id': handleRelationId,
      if (errorMessage != null) 'error_message': errorMessage,
      if (hasEffectPlayed != null) 'has_effect_played': hasEffectPlayed,
      if (appleChatGuid != null) 'apple_chat_guid': appleChatGuid,
    });
  }

  MessagesCompanion copyWith({
    Value<int>? id,
    Value<int?>? originalRowid,
    Value<String?>? guid,
    Value<int?>? handleId,
    Value<int?>? otherHandle,
    Value<String?>? messageText,
    Value<String?>? subject,
    Value<String?>? country,
    Value<String?>? service,
    Value<int?>? dateCreatedUs,
    Value<int>? sortAtUs,
    Value<int?>? dateReadUs,
    Value<int?>? dateDeliveredUs,
    Value<bool?>? isFromMe,
    Value<bool?>? hasDdResults,
    Value<int?>? datePlayedUs,
    Value<int?>? itemType,
    Value<String?>? groupTitle,
    Value<int?>? groupActionType,
    Value<String?>? balloonBundleId,
    Value<String?>? associatedMessageGuid,
    Value<int?>? associatedMessagePart,
    Value<String?>? associatedMessageType,
    Value<String?>? expressiveSendStyleId,
    Value<bool>? hasAttachments,
    Value<bool>? hasReactions,
    Value<int?>? dateDeletedUs,
    Value<String?>? threadOriginatorGuid,
    Value<String?>? threadOriginatorPart,
    Value<bool?>? bigEmoji,
    Value<int>? error,
    Value<int?>? chatId,
    Value<String?>? attributedBodyJson,
    Value<String?>? messageSummaryInfoJson,
    Value<String?>? payloadDataJson,
    Value<String?>? metadataJson,
    Value<bool>? hasApplePayloadData,
    Value<int?>? dateEditedUs,
    Value<bool>? wasDeliveredQuietly,
    Value<bool>? didNotifyRecipient,
    Value<bool>? isBookmarked,
    Value<bool>? isDelivered,
    Value<int?>? handleRelationId,
    Value<String?>? errorMessage,
    Value<bool>? hasEffectPlayed,
    Value<String?>? appleChatGuid,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      originalRowid: originalRowid ?? this.originalRowid,
      guid: guid ?? this.guid,
      handleId: handleId ?? this.handleId,
      otherHandle: otherHandle ?? this.otherHandle,
      messageText: messageText ?? this.messageText,
      subject: subject ?? this.subject,
      country: country ?? this.country,
      service: service ?? this.service,
      dateCreatedUs: dateCreatedUs ?? this.dateCreatedUs,
      sortAtUs: sortAtUs ?? this.sortAtUs,
      dateReadUs: dateReadUs ?? this.dateReadUs,
      dateDeliveredUs: dateDeliveredUs ?? this.dateDeliveredUs,
      isFromMe: isFromMe ?? this.isFromMe,
      hasDdResults: hasDdResults ?? this.hasDdResults,
      datePlayedUs: datePlayedUs ?? this.datePlayedUs,
      itemType: itemType ?? this.itemType,
      groupTitle: groupTitle ?? this.groupTitle,
      groupActionType: groupActionType ?? this.groupActionType,
      balloonBundleId: balloonBundleId ?? this.balloonBundleId,
      associatedMessageGuid:
          associatedMessageGuid ?? this.associatedMessageGuid,
      associatedMessagePart:
          associatedMessagePart ?? this.associatedMessagePart,
      associatedMessageType:
          associatedMessageType ?? this.associatedMessageType,
      expressiveSendStyleId:
          expressiveSendStyleId ?? this.expressiveSendStyleId,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      hasReactions: hasReactions ?? this.hasReactions,
      dateDeletedUs: dateDeletedUs ?? this.dateDeletedUs,
      threadOriginatorGuid: threadOriginatorGuid ?? this.threadOriginatorGuid,
      threadOriginatorPart: threadOriginatorPart ?? this.threadOriginatorPart,
      bigEmoji: bigEmoji ?? this.bigEmoji,
      error: error ?? this.error,
      chatId: chatId ?? this.chatId,
      attributedBodyJson: attributedBodyJson ?? this.attributedBodyJson,
      messageSummaryInfoJson:
          messageSummaryInfoJson ?? this.messageSummaryInfoJson,
      payloadDataJson: payloadDataJson ?? this.payloadDataJson,
      metadataJson: metadataJson ?? this.metadataJson,
      hasApplePayloadData: hasApplePayloadData ?? this.hasApplePayloadData,
      dateEditedUs: dateEditedUs ?? this.dateEditedUs,
      wasDeliveredQuietly: wasDeliveredQuietly ?? this.wasDeliveredQuietly,
      didNotifyRecipient: didNotifyRecipient ?? this.didNotifyRecipient,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isDelivered: isDelivered ?? this.isDelivered,
      handleRelationId: handleRelationId ?? this.handleRelationId,
      errorMessage: errorMessage ?? this.errorMessage,
      hasEffectPlayed: hasEffectPlayed ?? this.hasEffectPlayed,
      appleChatGuid: appleChatGuid ?? this.appleChatGuid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (originalRowid.present) {
      map['original_rowid'] = Variable<int>(originalRowid.value);
    }
    if (guid.present) {
      map['guid'] = Variable<String>(guid.value);
    }
    if (handleId.present) {
      map['handle_id'] = Variable<int>(handleId.value);
    }
    if (otherHandle.present) {
      map['other_handle'] = Variable<int>(otherHandle.value);
    }
    if (messageText.present) {
      map['text'] = Variable<String>(messageText.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (service.present) {
      map['service'] = Variable<String>(service.value);
    }
    if (dateCreatedUs.present) {
      map['date_created_us'] = Variable<int>(dateCreatedUs.value);
    }
    if (sortAtUs.present) {
      map['sort_at_us'] = Variable<int>(sortAtUs.value);
    }
    if (dateReadUs.present) {
      map['date_read_us'] = Variable<int>(dateReadUs.value);
    }
    if (dateDeliveredUs.present) {
      map['date_delivered_us'] = Variable<int>(dateDeliveredUs.value);
    }
    if (isFromMe.present) {
      map['is_from_me'] = Variable<bool>(isFromMe.value);
    }
    if (hasDdResults.present) {
      map['has_dd_results'] = Variable<bool>(hasDdResults.value);
    }
    if (datePlayedUs.present) {
      map['date_played_us'] = Variable<int>(datePlayedUs.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<int>(itemType.value);
    }
    if (groupTitle.present) {
      map['group_title'] = Variable<String>(groupTitle.value);
    }
    if (groupActionType.present) {
      map['group_action_type'] = Variable<int>(groupActionType.value);
    }
    if (balloonBundleId.present) {
      map['balloon_bundle_id'] = Variable<String>(balloonBundleId.value);
    }
    if (associatedMessageGuid.present) {
      map['associated_message_guid'] = Variable<String>(
        associatedMessageGuid.value,
      );
    }
    if (associatedMessagePart.present) {
      map['associated_message_part'] = Variable<int>(
        associatedMessagePart.value,
      );
    }
    if (associatedMessageType.present) {
      map['associated_message_type'] = Variable<String>(
        associatedMessageType.value,
      );
    }
    if (expressiveSendStyleId.present) {
      map['expressive_send_style_id'] = Variable<String>(
        expressiveSendStyleId.value,
      );
    }
    if (hasAttachments.present) {
      map['has_attachments'] = Variable<bool>(hasAttachments.value);
    }
    if (hasReactions.present) {
      map['has_reactions'] = Variable<bool>(hasReactions.value);
    }
    if (dateDeletedUs.present) {
      map['date_deleted_us'] = Variable<int>(dateDeletedUs.value);
    }
    if (threadOriginatorGuid.present) {
      map['thread_originator_guid'] = Variable<String>(
        threadOriginatorGuid.value,
      );
    }
    if (threadOriginatorPart.present) {
      map['thread_originator_part'] = Variable<String>(
        threadOriginatorPart.value,
      );
    }
    if (bigEmoji.present) {
      map['big_emoji'] = Variable<bool>(bigEmoji.value);
    }
    if (error.present) {
      map['error'] = Variable<int>(error.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<int>(chatId.value);
    }
    if (attributedBodyJson.present) {
      map['attributed_body_json'] = Variable<String>(attributedBodyJson.value);
    }
    if (messageSummaryInfoJson.present) {
      map['message_summary_info_json'] = Variable<String>(
        messageSummaryInfoJson.value,
      );
    }
    if (payloadDataJson.present) {
      map['payload_data_json'] = Variable<String>(payloadDataJson.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (hasApplePayloadData.present) {
      map['has_apple_payload_data'] = Variable<bool>(hasApplePayloadData.value);
    }
    if (dateEditedUs.present) {
      map['date_edited_us'] = Variable<int>(dateEditedUs.value);
    }
    if (wasDeliveredQuietly.present) {
      map['was_delivered_quietly'] = Variable<bool>(wasDeliveredQuietly.value);
    }
    if (didNotifyRecipient.present) {
      map['did_notify_recipient'] = Variable<bool>(didNotifyRecipient.value);
    }
    if (isBookmarked.present) {
      map['is_bookmarked'] = Variable<bool>(isBookmarked.value);
    }
    if (isDelivered.present) {
      map['is_delivered'] = Variable<bool>(isDelivered.value);
    }
    if (handleRelationId.present) {
      map['handle_relation_id'] = Variable<int>(handleRelationId.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (hasEffectPlayed.present) {
      map['has_effect_played'] = Variable<bool>(hasEffectPlayed.value);
    }
    if (appleChatGuid.present) {
      map['apple_chat_guid'] = Variable<String>(appleChatGuid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('originalRowid: $originalRowid, ')
          ..write('guid: $guid, ')
          ..write('handleId: $handleId, ')
          ..write('otherHandle: $otherHandle, ')
          ..write('messageText: $messageText, ')
          ..write('subject: $subject, ')
          ..write('country: $country, ')
          ..write('service: $service, ')
          ..write('dateCreatedUs: $dateCreatedUs, ')
          ..write('sortAtUs: $sortAtUs, ')
          ..write('dateReadUs: $dateReadUs, ')
          ..write('dateDeliveredUs: $dateDeliveredUs, ')
          ..write('isFromMe: $isFromMe, ')
          ..write('hasDdResults: $hasDdResults, ')
          ..write('datePlayedUs: $datePlayedUs, ')
          ..write('itemType: $itemType, ')
          ..write('groupTitle: $groupTitle, ')
          ..write('groupActionType: $groupActionType, ')
          ..write('balloonBundleId: $balloonBundleId, ')
          ..write('associatedMessageGuid: $associatedMessageGuid, ')
          ..write('associatedMessagePart: $associatedMessagePart, ')
          ..write('associatedMessageType: $associatedMessageType, ')
          ..write('expressiveSendStyleId: $expressiveSendStyleId, ')
          ..write('hasAttachments: $hasAttachments, ')
          ..write('hasReactions: $hasReactions, ')
          ..write('dateDeletedUs: $dateDeletedUs, ')
          ..write('threadOriginatorGuid: $threadOriginatorGuid, ')
          ..write('threadOriginatorPart: $threadOriginatorPart, ')
          ..write('bigEmoji: $bigEmoji, ')
          ..write('error: $error, ')
          ..write('chatId: $chatId, ')
          ..write('attributedBodyJson: $attributedBodyJson, ')
          ..write('messageSummaryInfoJson: $messageSummaryInfoJson, ')
          ..write('payloadDataJson: $payloadDataJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('hasApplePayloadData: $hasApplePayloadData, ')
          ..write('dateEditedUs: $dateEditedUs, ')
          ..write('wasDeliveredQuietly: $wasDeliveredQuietly, ')
          ..write('didNotifyRecipient: $didNotifyRecipient, ')
          ..write('isBookmarked: $isBookmarked, ')
          ..write('isDelivered: $isDelivered, ')
          ..write('handleRelationId: $handleRelationId, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('hasEffectPlayed: $hasEffectPlayed, ')
          ..write('appleChatGuid: $appleChatGuid')
          ..write(')'))
        .toString();
  }
}

class $ChatHandlesTable extends ChatHandles
    with TableInfo<$ChatHandlesTable, SqliteChatHandleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatHandlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<int> chatId = GeneratedColumn<int>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES chats (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _handleIdMeta = const VerificationMeta(
    'handleId',
  );
  @override
  late final GeneratedColumn<int> handleId = GeneratedColumn<int>(
    'handle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES handles (id) ON DELETE CASCADE',
  );
  @override
  List<GeneratedColumn> get $columns => [chatId, handleId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_handles';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteChatHandleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('handle_id')) {
      context.handle(
        _handleIdMeta,
        handleId.isAcceptableOrUnknown(data['handle_id']!, _handleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_handleIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chatId, handleId};
  @override
  SqliteChatHandleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteChatHandleRow(
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chat_id'],
      )!,
      handleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}handle_id'],
      )!,
    );
  }

  @override
  $ChatHandlesTable createAlias(String alias) {
    return $ChatHandlesTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class SqliteChatHandleRow extends DataClass
    implements Insertable<SqliteChatHandleRow> {
  final int chatId;
  final int handleId;
  const SqliteChatHandleRow({required this.chatId, required this.handleId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chat_id'] = Variable<int>(chatId);
    map['handle_id'] = Variable<int>(handleId);
    return map;
  }

  ChatHandlesCompanion toCompanion(bool nullToAbsent) {
    return ChatHandlesCompanion(
      chatId: Value(chatId),
      handleId: Value(handleId),
    );
  }

  factory SqliteChatHandleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteChatHandleRow(
      chatId: serializer.fromJson<int>(json['chatId']),
      handleId: serializer.fromJson<int>(json['handleId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chatId': serializer.toJson<int>(chatId),
      'handleId': serializer.toJson<int>(handleId),
    };
  }

  SqliteChatHandleRow copyWith({int? chatId, int? handleId}) =>
      SqliteChatHandleRow(
        chatId: chatId ?? this.chatId,
        handleId: handleId ?? this.handleId,
      );
  SqliteChatHandleRow copyWithCompanion(ChatHandlesCompanion data) {
    return SqliteChatHandleRow(
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      handleId: data.handleId.present ? data.handleId.value : this.handleId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteChatHandleRow(')
          ..write('chatId: $chatId, ')
          ..write('handleId: $handleId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(chatId, handleId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteChatHandleRow &&
          other.chatId == this.chatId &&
          other.handleId == this.handleId);
}

class ChatHandlesCompanion extends UpdateCompanion<SqliteChatHandleRow> {
  final Value<int> chatId;
  final Value<int> handleId;
  const ChatHandlesCompanion({
    this.chatId = const Value.absent(),
    this.handleId = const Value.absent(),
  });
  ChatHandlesCompanion.insert({required int chatId, required int handleId})
    : chatId = Value(chatId),
      handleId = Value(handleId);
  static Insertable<SqliteChatHandleRow> custom({
    Expression<int>? chatId,
    Expression<int>? handleId,
  }) {
    return RawValuesInsertable({
      if (chatId != null) 'chat_id': chatId,
      if (handleId != null) 'handle_id': handleId,
    });
  }

  ChatHandlesCompanion copyWith({Value<int>? chatId, Value<int>? handleId}) {
    return ChatHandlesCompanion(
      chatId: chatId ?? this.chatId,
      handleId: handleId ?? this.handleId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chatId.present) {
      map['chat_id'] = Variable<int>(chatId.value);
    }
    if (handleId.present) {
      map['handle_id'] = Variable<int>(handleId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatHandlesCompanion(')
          ..write('chatId: $chatId, ')
          ..write('handleId: $handleId')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, SqliteAttachmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _originalRowidMeta = const VerificationMeta(
    'originalRowid',
  );
  @override
  late final GeneratedColumn<int> originalRowid = GeneratedColumn<int>(
    'original_rowid',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _guidMeta = const VerificationMeta('guid');
  @override
  late final GeneratedColumn<String> guid = GeneratedColumn<String>(
    'guid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _utiMeta = const VerificationMeta('uti');
  @override
  late final GeneratedColumn<String> uti = GeneratedColumn<String>(
    'uti',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isOutgoingMeta = const VerificationMeta(
    'isOutgoing',
  );
  @override
  late final GeneratedColumn<bool> isOutgoing = GeneratedColumn<bool>(
    'is_outgoing',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_outgoing" IN (0, 1))',
    ),
  );
  static const VerificationMeta _transferNameMeta = const VerificationMeta(
    'transferName',
  );
  @override
  late final GeneratedColumn<String> transferName = GeneratedColumn<String>(
    'transfer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _webUrlMeta = const VerificationMeta('webUrl');
  @override
  late final GeneratedColumn<String> webUrl = GeneratedColumn<String>(
    'web_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<int> messageId = GeneratedColumn<int>(
    'message_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NULL REFERENCES messages (id) ON DELETE SET NULL',
  );
  static const VerificationMeta _hasLivePhotoMeta = const VerificationMeta(
    'hasLivePhoto',
  );
  @override
  late final GeneratedColumn<bool> hasLivePhoto = GeneratedColumn<bool>(
    'has_live_photo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_live_photo" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isDownloadedMeta = const VerificationMeta(
    'isDownloaded',
  );
  @override
  late final GeneratedColumn<bool> isDownloaded = GeneratedColumn<bool>(
    'is_downloaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_downloaded" IN (0, 1))',
    ),
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exifJsonMeta = const VerificationMeta(
    'exifJson',
  );
  @override
  late final GeneratedColumn<String> exifJson = GeneratedColumn<String>(
    'exif_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    originalRowid,
    guid,
    uti,
    mimeType,
    isOutgoing,
    transferName,
    totalBytes,
    height,
    width,
    webUrl,
    messageId,
    hasLivePhoto,
    isDownloaded,
    metadataJson,
    exifJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteAttachmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('original_rowid')) {
      context.handle(
        _originalRowidMeta,
        originalRowid.isAcceptableOrUnknown(
          data['original_rowid']!,
          _originalRowidMeta,
        ),
      );
    }
    if (data.containsKey('guid')) {
      context.handle(
        _guidMeta,
        guid.isAcceptableOrUnknown(data['guid']!, _guidMeta),
      );
    }
    if (data.containsKey('uti')) {
      context.handle(
        _utiMeta,
        uti.isAcceptableOrUnknown(data['uti']!, _utiMeta),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('is_outgoing')) {
      context.handle(
        _isOutgoingMeta,
        isOutgoing.isAcceptableOrUnknown(data['is_outgoing']!, _isOutgoingMeta),
      );
    }
    if (data.containsKey('transfer_name')) {
      context.handle(
        _transferNameMeta,
        transferName.isAcceptableOrUnknown(
          data['transfer_name']!,
          _transferNameMeta,
        ),
      );
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('web_url')) {
      context.handle(
        _webUrlMeta,
        webUrl.isAcceptableOrUnknown(data['web_url']!, _webUrlMeta),
      );
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    }
    if (data.containsKey('has_live_photo')) {
      context.handle(
        _hasLivePhotoMeta,
        hasLivePhoto.isAcceptableOrUnknown(
          data['has_live_photo']!,
          _hasLivePhotoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hasLivePhotoMeta);
    }
    if (data.containsKey('is_downloaded')) {
      context.handle(
        _isDownloadedMeta,
        isDownloaded.isAcceptableOrUnknown(
          data['is_downloaded']!,
          _isDownloadedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isDownloadedMeta);
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    if (data.containsKey('exif_json')) {
      context.handle(
        _exifJsonMeta,
        exifJson.isAcceptableOrUnknown(data['exif_json']!, _exifJsonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SqliteAttachmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteAttachmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      originalRowid: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_rowid'],
      ),
      guid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guid'],
      ),
      uti: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uti'],
      ),
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      ),
      isOutgoing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_outgoing'],
      ),
      transferName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_name'],
      ),
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      webUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}web_url'],
      ),
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}message_id'],
      ),
      hasLivePhoto: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_live_photo'],
      )!,
      isDownloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_downloaded'],
      )!,
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      ),
      exifJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exif_json'],
      ),
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class SqliteAttachmentRow extends DataClass
    implements Insertable<SqliteAttachmentRow> {
  final int id;
  final int? originalRowid;
  final String? guid;
  final String? uti;
  final String? mimeType;
  final bool? isOutgoing;
  final String? transferName;
  final int? totalBytes;
  final int? height;
  final int? width;
  final String? webUrl;
  final int? messageId;
  final bool hasLivePhoto;
  final bool isDownloaded;
  final String? metadataJson;
  final String? exifJson;
  const SqliteAttachmentRow({
    required this.id,
    this.originalRowid,
    this.guid,
    this.uti,
    this.mimeType,
    this.isOutgoing,
    this.transferName,
    this.totalBytes,
    this.height,
    this.width,
    this.webUrl,
    this.messageId,
    required this.hasLivePhoto,
    required this.isDownloaded,
    this.metadataJson,
    this.exifJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || originalRowid != null) {
      map['original_rowid'] = Variable<int>(originalRowid);
    }
    if (!nullToAbsent || guid != null) {
      map['guid'] = Variable<String>(guid);
    }
    if (!nullToAbsent || uti != null) {
      map['uti'] = Variable<String>(uti);
    }
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || isOutgoing != null) {
      map['is_outgoing'] = Variable<bool>(isOutgoing);
    }
    if (!nullToAbsent || transferName != null) {
      map['transfer_name'] = Variable<String>(transferName);
    }
    if (!nullToAbsent || totalBytes != null) {
      map['total_bytes'] = Variable<int>(totalBytes);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || webUrl != null) {
      map['web_url'] = Variable<String>(webUrl);
    }
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<int>(messageId);
    }
    map['has_live_photo'] = Variable<bool>(hasLivePhoto);
    map['is_downloaded'] = Variable<bool>(isDownloaded);
    if (!nullToAbsent || metadataJson != null) {
      map['metadata_json'] = Variable<String>(metadataJson);
    }
    if (!nullToAbsent || exifJson != null) {
      map['exif_json'] = Variable<String>(exifJson);
    }
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      originalRowid: originalRowid == null && nullToAbsent
          ? const Value.absent()
          : Value(originalRowid),
      guid: guid == null && nullToAbsent ? const Value.absent() : Value(guid),
      uti: uti == null && nullToAbsent ? const Value.absent() : Value(uti),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      isOutgoing: isOutgoing == null && nullToAbsent
          ? const Value.absent()
          : Value(isOutgoing),
      transferName: transferName == null && nullToAbsent
          ? const Value.absent()
          : Value(transferName),
      totalBytes: totalBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalBytes),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      webUrl: webUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(webUrl),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      hasLivePhoto: Value(hasLivePhoto),
      isDownloaded: Value(isDownloaded),
      metadataJson: metadataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metadataJson),
      exifJson: exifJson == null && nullToAbsent
          ? const Value.absent()
          : Value(exifJson),
    );
  }

  factory SqliteAttachmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteAttachmentRow(
      id: serializer.fromJson<int>(json['id']),
      originalRowid: serializer.fromJson<int?>(json['originalRowid']),
      guid: serializer.fromJson<String?>(json['guid']),
      uti: serializer.fromJson<String?>(json['uti']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      isOutgoing: serializer.fromJson<bool?>(json['isOutgoing']),
      transferName: serializer.fromJson<String?>(json['transferName']),
      totalBytes: serializer.fromJson<int?>(json['totalBytes']),
      height: serializer.fromJson<int?>(json['height']),
      width: serializer.fromJson<int?>(json['width']),
      webUrl: serializer.fromJson<String?>(json['webUrl']),
      messageId: serializer.fromJson<int?>(json['messageId']),
      hasLivePhoto: serializer.fromJson<bool>(json['hasLivePhoto']),
      isDownloaded: serializer.fromJson<bool>(json['isDownloaded']),
      metadataJson: serializer.fromJson<String?>(json['metadataJson']),
      exifJson: serializer.fromJson<String?>(json['exifJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'originalRowid': serializer.toJson<int?>(originalRowid),
      'guid': serializer.toJson<String?>(guid),
      'uti': serializer.toJson<String?>(uti),
      'mimeType': serializer.toJson<String?>(mimeType),
      'isOutgoing': serializer.toJson<bool?>(isOutgoing),
      'transferName': serializer.toJson<String?>(transferName),
      'totalBytes': serializer.toJson<int?>(totalBytes),
      'height': serializer.toJson<int?>(height),
      'width': serializer.toJson<int?>(width),
      'webUrl': serializer.toJson<String?>(webUrl),
      'messageId': serializer.toJson<int?>(messageId),
      'hasLivePhoto': serializer.toJson<bool>(hasLivePhoto),
      'isDownloaded': serializer.toJson<bool>(isDownloaded),
      'metadataJson': serializer.toJson<String?>(metadataJson),
      'exifJson': serializer.toJson<String?>(exifJson),
    };
  }

  SqliteAttachmentRow copyWith({
    int? id,
    Value<int?> originalRowid = const Value.absent(),
    Value<String?> guid = const Value.absent(),
    Value<String?> uti = const Value.absent(),
    Value<String?> mimeType = const Value.absent(),
    Value<bool?> isOutgoing = const Value.absent(),
    Value<String?> transferName = const Value.absent(),
    Value<int?> totalBytes = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<int?> width = const Value.absent(),
    Value<String?> webUrl = const Value.absent(),
    Value<int?> messageId = const Value.absent(),
    bool? hasLivePhoto,
    bool? isDownloaded,
    Value<String?> metadataJson = const Value.absent(),
    Value<String?> exifJson = const Value.absent(),
  }) => SqliteAttachmentRow(
    id: id ?? this.id,
    originalRowid: originalRowid.present
        ? originalRowid.value
        : this.originalRowid,
    guid: guid.present ? guid.value : this.guid,
    uti: uti.present ? uti.value : this.uti,
    mimeType: mimeType.present ? mimeType.value : this.mimeType,
    isOutgoing: isOutgoing.present ? isOutgoing.value : this.isOutgoing,
    transferName: transferName.present ? transferName.value : this.transferName,
    totalBytes: totalBytes.present ? totalBytes.value : this.totalBytes,
    height: height.present ? height.value : this.height,
    width: width.present ? width.value : this.width,
    webUrl: webUrl.present ? webUrl.value : this.webUrl,
    messageId: messageId.present ? messageId.value : this.messageId,
    hasLivePhoto: hasLivePhoto ?? this.hasLivePhoto,
    isDownloaded: isDownloaded ?? this.isDownloaded,
    metadataJson: metadataJson.present ? metadataJson.value : this.metadataJson,
    exifJson: exifJson.present ? exifJson.value : this.exifJson,
  );
  SqliteAttachmentRow copyWithCompanion(AttachmentsCompanion data) {
    return SqliteAttachmentRow(
      id: data.id.present ? data.id.value : this.id,
      originalRowid: data.originalRowid.present
          ? data.originalRowid.value
          : this.originalRowid,
      guid: data.guid.present ? data.guid.value : this.guid,
      uti: data.uti.present ? data.uti.value : this.uti,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      isOutgoing: data.isOutgoing.present
          ? data.isOutgoing.value
          : this.isOutgoing,
      transferName: data.transferName.present
          ? data.transferName.value
          : this.transferName,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      height: data.height.present ? data.height.value : this.height,
      width: data.width.present ? data.width.value : this.width,
      webUrl: data.webUrl.present ? data.webUrl.value : this.webUrl,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      hasLivePhoto: data.hasLivePhoto.present
          ? data.hasLivePhoto.value
          : this.hasLivePhoto,
      isDownloaded: data.isDownloaded.present
          ? data.isDownloaded.value
          : this.isDownloaded,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      exifJson: data.exifJson.present ? data.exifJson.value : this.exifJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteAttachmentRow(')
          ..write('id: $id, ')
          ..write('originalRowid: $originalRowid, ')
          ..write('guid: $guid, ')
          ..write('uti: $uti, ')
          ..write('mimeType: $mimeType, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('transferName: $transferName, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('height: $height, ')
          ..write('width: $width, ')
          ..write('webUrl: $webUrl, ')
          ..write('messageId: $messageId, ')
          ..write('hasLivePhoto: $hasLivePhoto, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('exifJson: $exifJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    originalRowid,
    guid,
    uti,
    mimeType,
    isOutgoing,
    transferName,
    totalBytes,
    height,
    width,
    webUrl,
    messageId,
    hasLivePhoto,
    isDownloaded,
    metadataJson,
    exifJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteAttachmentRow &&
          other.id == this.id &&
          other.originalRowid == this.originalRowid &&
          other.guid == this.guid &&
          other.uti == this.uti &&
          other.mimeType == this.mimeType &&
          other.isOutgoing == this.isOutgoing &&
          other.transferName == this.transferName &&
          other.totalBytes == this.totalBytes &&
          other.height == this.height &&
          other.width == this.width &&
          other.webUrl == this.webUrl &&
          other.messageId == this.messageId &&
          other.hasLivePhoto == this.hasLivePhoto &&
          other.isDownloaded == this.isDownloaded &&
          other.metadataJson == this.metadataJson &&
          other.exifJson == this.exifJson);
}

class AttachmentsCompanion extends UpdateCompanion<SqliteAttachmentRow> {
  final Value<int> id;
  final Value<int?> originalRowid;
  final Value<String?> guid;
  final Value<String?> uti;
  final Value<String?> mimeType;
  final Value<bool?> isOutgoing;
  final Value<String?> transferName;
  final Value<int?> totalBytes;
  final Value<int?> height;
  final Value<int?> width;
  final Value<String?> webUrl;
  final Value<int?> messageId;
  final Value<bool> hasLivePhoto;
  final Value<bool> isDownloaded;
  final Value<String?> metadataJson;
  final Value<String?> exifJson;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.originalRowid = const Value.absent(),
    this.guid = const Value.absent(),
    this.uti = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.isOutgoing = const Value.absent(),
    this.transferName = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.height = const Value.absent(),
    this.width = const Value.absent(),
    this.webUrl = const Value.absent(),
    this.messageId = const Value.absent(),
    this.hasLivePhoto = const Value.absent(),
    this.isDownloaded = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.exifJson = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    this.id = const Value.absent(),
    this.originalRowid = const Value.absent(),
    this.guid = const Value.absent(),
    this.uti = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.isOutgoing = const Value.absent(),
    this.transferName = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.height = const Value.absent(),
    this.width = const Value.absent(),
    this.webUrl = const Value.absent(),
    this.messageId = const Value.absent(),
    required bool hasLivePhoto,
    required bool isDownloaded,
    this.metadataJson = const Value.absent(),
    this.exifJson = const Value.absent(),
  }) : hasLivePhoto = Value(hasLivePhoto),
       isDownloaded = Value(isDownloaded);
  static Insertable<SqliteAttachmentRow> custom({
    Expression<int>? id,
    Expression<int>? originalRowid,
    Expression<String>? guid,
    Expression<String>? uti,
    Expression<String>? mimeType,
    Expression<bool>? isOutgoing,
    Expression<String>? transferName,
    Expression<int>? totalBytes,
    Expression<int>? height,
    Expression<int>? width,
    Expression<String>? webUrl,
    Expression<int>? messageId,
    Expression<bool>? hasLivePhoto,
    Expression<bool>? isDownloaded,
    Expression<String>? metadataJson,
    Expression<String>? exifJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (originalRowid != null) 'original_rowid': originalRowid,
      if (guid != null) 'guid': guid,
      if (uti != null) 'uti': uti,
      if (mimeType != null) 'mime_type': mimeType,
      if (isOutgoing != null) 'is_outgoing': isOutgoing,
      if (transferName != null) 'transfer_name': transferName,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (height != null) 'height': height,
      if (width != null) 'width': width,
      if (webUrl != null) 'web_url': webUrl,
      if (messageId != null) 'message_id': messageId,
      if (hasLivePhoto != null) 'has_live_photo': hasLivePhoto,
      if (isDownloaded != null) 'is_downloaded': isDownloaded,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (exifJson != null) 'exif_json': exifJson,
    });
  }

  AttachmentsCompanion copyWith({
    Value<int>? id,
    Value<int?>? originalRowid,
    Value<String?>? guid,
    Value<String?>? uti,
    Value<String?>? mimeType,
    Value<bool?>? isOutgoing,
    Value<String?>? transferName,
    Value<int?>? totalBytes,
    Value<int?>? height,
    Value<int?>? width,
    Value<String?>? webUrl,
    Value<int?>? messageId,
    Value<bool>? hasLivePhoto,
    Value<bool>? isDownloaded,
    Value<String?>? metadataJson,
    Value<String?>? exifJson,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      originalRowid: originalRowid ?? this.originalRowid,
      guid: guid ?? this.guid,
      uti: uti ?? this.uti,
      mimeType: mimeType ?? this.mimeType,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      transferName: transferName ?? this.transferName,
      totalBytes: totalBytes ?? this.totalBytes,
      height: height ?? this.height,
      width: width ?? this.width,
      webUrl: webUrl ?? this.webUrl,
      messageId: messageId ?? this.messageId,
      hasLivePhoto: hasLivePhoto ?? this.hasLivePhoto,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      metadataJson: metadataJson ?? this.metadataJson,
      exifJson: exifJson ?? this.exifJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (originalRowid.present) {
      map['original_rowid'] = Variable<int>(originalRowid.value);
    }
    if (guid.present) {
      map['guid'] = Variable<String>(guid.value);
    }
    if (uti.present) {
      map['uti'] = Variable<String>(uti.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (isOutgoing.present) {
      map['is_outgoing'] = Variable<bool>(isOutgoing.value);
    }
    if (transferName.present) {
      map['transfer_name'] = Variable<String>(transferName.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (webUrl.present) {
      map['web_url'] = Variable<String>(webUrl.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<int>(messageId.value);
    }
    if (hasLivePhoto.present) {
      map['has_live_photo'] = Variable<bool>(hasLivePhoto.value);
    }
    if (isDownloaded.present) {
      map['is_downloaded'] = Variable<bool>(isDownloaded.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (exifJson.present) {
      map['exif_json'] = Variable<String>(exifJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('originalRowid: $originalRowid, ')
          ..write('guid: $guid, ')
          ..write('uti: $uti, ')
          ..write('mimeType: $mimeType, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('transferName: $transferName, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('height: $height, ')
          ..write('width: $width, ')
          ..write('webUrl: $webUrl, ')
          ..write('messageId: $messageId, ')
          ..write('hasLivePhoto: $hasLivePhoto, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('exifJson: $exifJson')
          ..write(')'))
        .toString();
  }
}

class $ContactsTable extends Contacts
    with TableInfo<$ContactsTable, SqliteContactRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nativeContactIdMeta = const VerificationMeta(
    'nativeContactId',
  );
  @override
  late final GeneratedColumn<String> nativeContactId = GeneratedColumn<String>(
    'native_contact_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _avatarPathMeta = const VerificationMeta(
    'avatarPath',
  );
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
    'avatar_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressesJsonMeta = const VerificationMeta(
    'addressesJson',
  );
  @override
  late final GeneratedColumn<String> addressesJson = GeneratedColumn<String>(
    'addresses_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _middleNameMeta = const VerificationMeta(
    'middleName',
  );
  @override
  late final GeneratedColumn<String> middleName = GeneratedColumn<String>(
    'middle_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _namePrefixMeta = const VerificationMeta(
    'namePrefix',
  );
  @override
  late final GeneratedColumn<String> namePrefix = GeneratedColumn<String>(
    'name_prefix',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameSuffixMeta = const VerificationMeta(
    'nameSuffix',
  );
  @override
  late final GeneratedColumn<String> nameSuffix = GeneratedColumn<String>(
    'name_suffix',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _companyMeta = const VerificationMeta(
    'company',
  );
  @override
  late final GeneratedColumn<String> company = GeneratedColumn<String>(
    'company',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneNumbersJsonMeta = const VerificationMeta(
    'phoneNumbersJson',
  );
  @override
  late final GeneratedColumn<String> phoneNumbersJson = GeneratedColumn<String>(
    'phone_numbers_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailAddressesJsonMeta =
      const VerificationMeta('emailAddressesJson');
  @override
  late final GeneratedColumn<String> emailAddressesJson =
      GeneratedColumn<String>(
        'email_addresses_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isNativeMeta = const VerificationMeta(
    'isNative',
  );
  @override
  late final GeneratedColumn<bool> isNative = GeneratedColumn<bool>(
    'is_native',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_native" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    nativeContactId,
    avatarPath,
    addressesJson,
    nickname,
    firstName,
    lastName,
    middleName,
    namePrefix,
    nameSuffix,
    company,
    phoneNumbersJson,
    emailAddressesJson,
    isNative,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contacts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteContactRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('native_contact_id')) {
      context.handle(
        _nativeContactIdMeta,
        nativeContactId.isAcceptableOrUnknown(
          data['native_contact_id']!,
          _nativeContactIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nativeContactIdMeta);
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
        _avatarPathMeta,
        avatarPath.isAcceptableOrUnknown(data['avatar_path']!, _avatarPathMeta),
      );
    }
    if (data.containsKey('addresses_json')) {
      context.handle(
        _addressesJsonMeta,
        addressesJson.isAcceptableOrUnknown(
          data['addresses_json']!,
          _addressesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_addressesJsonMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    }
    if (data.containsKey('middle_name')) {
      context.handle(
        _middleNameMeta,
        middleName.isAcceptableOrUnknown(data['middle_name']!, _middleNameMeta),
      );
    }
    if (data.containsKey('name_prefix')) {
      context.handle(
        _namePrefixMeta,
        namePrefix.isAcceptableOrUnknown(data['name_prefix']!, _namePrefixMeta),
      );
    }
    if (data.containsKey('name_suffix')) {
      context.handle(
        _nameSuffixMeta,
        nameSuffix.isAcceptableOrUnknown(data['name_suffix']!, _nameSuffixMeta),
      );
    }
    if (data.containsKey('company')) {
      context.handle(
        _companyMeta,
        company.isAcceptableOrUnknown(data['company']!, _companyMeta),
      );
    }
    if (data.containsKey('phone_numbers_json')) {
      context.handle(
        _phoneNumbersJsonMeta,
        phoneNumbersJson.isAcceptableOrUnknown(
          data['phone_numbers_json']!,
          _phoneNumbersJsonMeta,
        ),
      );
    }
    if (data.containsKey('email_addresses_json')) {
      context.handle(
        _emailAddressesJsonMeta,
        emailAddressesJson.isAcceptableOrUnknown(
          data['email_addresses_json']!,
          _emailAddressesJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_native')) {
      context.handle(
        _isNativeMeta,
        isNative.isAcceptableOrUnknown(data['is_native']!, _isNativeMeta),
      );
    } else if (isInserting) {
      context.missing(_isNativeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SqliteContactRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteContactRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      nativeContactId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}native_contact_id'],
      )!,
      avatarPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_path'],
      ),
      addressesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}addresses_json'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      ),
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      ),
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      ),
      middleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}middle_name'],
      ),
      namePrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_prefix'],
      ),
      nameSuffix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_suffix'],
      ),
      company: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company'],
      ),
      phoneNumbersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_numbers_json'],
      ),
      emailAddressesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email_addresses_json'],
      ),
      isNative: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_native'],
      )!,
    );
  }

  @override
  $ContactsTable createAlias(String alias) {
    return $ContactsTable(attachedDatabase, alias);
  }
}

class SqliteContactRow extends DataClass
    implements Insertable<SqliteContactRow> {
  final int id;
  final String displayName;
  final String nativeContactId;
  final String? avatarPath;
  final String addressesJson;
  final String? nickname;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? namePrefix;
  final String? nameSuffix;
  final String? company;
  final String? phoneNumbersJson;
  final String? emailAddressesJson;
  final bool isNative;
  const SqliteContactRow({
    required this.id,
    required this.displayName,
    required this.nativeContactId,
    this.avatarPath,
    required this.addressesJson,
    this.nickname,
    this.firstName,
    this.lastName,
    this.middleName,
    this.namePrefix,
    this.nameSuffix,
    this.company,
    this.phoneNumbersJson,
    this.emailAddressesJson,
    required this.isNative,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['display_name'] = Variable<String>(displayName);
    map['native_contact_id'] = Variable<String>(nativeContactId);
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    map['addresses_json'] = Variable<String>(addressesJson);
    if (!nullToAbsent || nickname != null) {
      map['nickname'] = Variable<String>(nickname);
    }
    if (!nullToAbsent || firstName != null) {
      map['first_name'] = Variable<String>(firstName);
    }
    if (!nullToAbsent || lastName != null) {
      map['last_name'] = Variable<String>(lastName);
    }
    if (!nullToAbsent || middleName != null) {
      map['middle_name'] = Variable<String>(middleName);
    }
    if (!nullToAbsent || namePrefix != null) {
      map['name_prefix'] = Variable<String>(namePrefix);
    }
    if (!nullToAbsent || nameSuffix != null) {
      map['name_suffix'] = Variable<String>(nameSuffix);
    }
    if (!nullToAbsent || company != null) {
      map['company'] = Variable<String>(company);
    }
    if (!nullToAbsent || phoneNumbersJson != null) {
      map['phone_numbers_json'] = Variable<String>(phoneNumbersJson);
    }
    if (!nullToAbsent || emailAddressesJson != null) {
      map['email_addresses_json'] = Variable<String>(emailAddressesJson);
    }
    map['is_native'] = Variable<bool>(isNative);
    return map;
  }

  ContactsCompanion toCompanion(bool nullToAbsent) {
    return ContactsCompanion(
      id: Value(id),
      displayName: Value(displayName),
      nativeContactId: Value(nativeContactId),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      addressesJson: Value(addressesJson),
      nickname: nickname == null && nullToAbsent
          ? const Value.absent()
          : Value(nickname),
      firstName: firstName == null && nullToAbsent
          ? const Value.absent()
          : Value(firstName),
      lastName: lastName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastName),
      middleName: middleName == null && nullToAbsent
          ? const Value.absent()
          : Value(middleName),
      namePrefix: namePrefix == null && nullToAbsent
          ? const Value.absent()
          : Value(namePrefix),
      nameSuffix: nameSuffix == null && nullToAbsent
          ? const Value.absent()
          : Value(nameSuffix),
      company: company == null && nullToAbsent
          ? const Value.absent()
          : Value(company),
      phoneNumbersJson: phoneNumbersJson == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumbersJson),
      emailAddressesJson: emailAddressesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(emailAddressesJson),
      isNative: Value(isNative),
    );
  }

  factory SqliteContactRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteContactRow(
      id: serializer.fromJson<int>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      nativeContactId: serializer.fromJson<String>(json['nativeContactId']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      addressesJson: serializer.fromJson<String>(json['addressesJson']),
      nickname: serializer.fromJson<String?>(json['nickname']),
      firstName: serializer.fromJson<String?>(json['firstName']),
      lastName: serializer.fromJson<String?>(json['lastName']),
      middleName: serializer.fromJson<String?>(json['middleName']),
      namePrefix: serializer.fromJson<String?>(json['namePrefix']),
      nameSuffix: serializer.fromJson<String?>(json['nameSuffix']),
      company: serializer.fromJson<String?>(json['company']),
      phoneNumbersJson: serializer.fromJson<String?>(json['phoneNumbersJson']),
      emailAddressesJson: serializer.fromJson<String?>(
        json['emailAddressesJson'],
      ),
      isNative: serializer.fromJson<bool>(json['isNative']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'displayName': serializer.toJson<String>(displayName),
      'nativeContactId': serializer.toJson<String>(nativeContactId),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'addressesJson': serializer.toJson<String>(addressesJson),
      'nickname': serializer.toJson<String?>(nickname),
      'firstName': serializer.toJson<String?>(firstName),
      'lastName': serializer.toJson<String?>(lastName),
      'middleName': serializer.toJson<String?>(middleName),
      'namePrefix': serializer.toJson<String?>(namePrefix),
      'nameSuffix': serializer.toJson<String?>(nameSuffix),
      'company': serializer.toJson<String?>(company),
      'phoneNumbersJson': serializer.toJson<String?>(phoneNumbersJson),
      'emailAddressesJson': serializer.toJson<String?>(emailAddressesJson),
      'isNative': serializer.toJson<bool>(isNative),
    };
  }

  SqliteContactRow copyWith({
    int? id,
    String? displayName,
    String? nativeContactId,
    Value<String?> avatarPath = const Value.absent(),
    String? addressesJson,
    Value<String?> nickname = const Value.absent(),
    Value<String?> firstName = const Value.absent(),
    Value<String?> lastName = const Value.absent(),
    Value<String?> middleName = const Value.absent(),
    Value<String?> namePrefix = const Value.absent(),
    Value<String?> nameSuffix = const Value.absent(),
    Value<String?> company = const Value.absent(),
    Value<String?> phoneNumbersJson = const Value.absent(),
    Value<String?> emailAddressesJson = const Value.absent(),
    bool? isNative,
  }) => SqliteContactRow(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    nativeContactId: nativeContactId ?? this.nativeContactId,
    avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
    addressesJson: addressesJson ?? this.addressesJson,
    nickname: nickname.present ? nickname.value : this.nickname,
    firstName: firstName.present ? firstName.value : this.firstName,
    lastName: lastName.present ? lastName.value : this.lastName,
    middleName: middleName.present ? middleName.value : this.middleName,
    namePrefix: namePrefix.present ? namePrefix.value : this.namePrefix,
    nameSuffix: nameSuffix.present ? nameSuffix.value : this.nameSuffix,
    company: company.present ? company.value : this.company,
    phoneNumbersJson: phoneNumbersJson.present
        ? phoneNumbersJson.value
        : this.phoneNumbersJson,
    emailAddressesJson: emailAddressesJson.present
        ? emailAddressesJson.value
        : this.emailAddressesJson,
    isNative: isNative ?? this.isNative,
  );
  SqliteContactRow copyWithCompanion(ContactsCompanion data) {
    return SqliteContactRow(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      nativeContactId: data.nativeContactId.present
          ? data.nativeContactId.value
          : this.nativeContactId,
      avatarPath: data.avatarPath.present
          ? data.avatarPath.value
          : this.avatarPath,
      addressesJson: data.addressesJson.present
          ? data.addressesJson.value
          : this.addressesJson,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      middleName: data.middleName.present
          ? data.middleName.value
          : this.middleName,
      namePrefix: data.namePrefix.present
          ? data.namePrefix.value
          : this.namePrefix,
      nameSuffix: data.nameSuffix.present
          ? data.nameSuffix.value
          : this.nameSuffix,
      company: data.company.present ? data.company.value : this.company,
      phoneNumbersJson: data.phoneNumbersJson.present
          ? data.phoneNumbersJson.value
          : this.phoneNumbersJson,
      emailAddressesJson: data.emailAddressesJson.present
          ? data.emailAddressesJson.value
          : this.emailAddressesJson,
      isNative: data.isNative.present ? data.isNative.value : this.isNative,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteContactRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('nativeContactId: $nativeContactId, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('addressesJson: $addressesJson, ')
          ..write('nickname: $nickname, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('middleName: $middleName, ')
          ..write('namePrefix: $namePrefix, ')
          ..write('nameSuffix: $nameSuffix, ')
          ..write('company: $company, ')
          ..write('phoneNumbersJson: $phoneNumbersJson, ')
          ..write('emailAddressesJson: $emailAddressesJson, ')
          ..write('isNative: $isNative')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    nativeContactId,
    avatarPath,
    addressesJson,
    nickname,
    firstName,
    lastName,
    middleName,
    namePrefix,
    nameSuffix,
    company,
    phoneNumbersJson,
    emailAddressesJson,
    isNative,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteContactRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.nativeContactId == this.nativeContactId &&
          other.avatarPath == this.avatarPath &&
          other.addressesJson == this.addressesJson &&
          other.nickname == this.nickname &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.middleName == this.middleName &&
          other.namePrefix == this.namePrefix &&
          other.nameSuffix == this.nameSuffix &&
          other.company == this.company &&
          other.phoneNumbersJson == this.phoneNumbersJson &&
          other.emailAddressesJson == this.emailAddressesJson &&
          other.isNative == this.isNative);
}

class ContactsCompanion extends UpdateCompanion<SqliteContactRow> {
  final Value<int> id;
  final Value<String> displayName;
  final Value<String> nativeContactId;
  final Value<String?> avatarPath;
  final Value<String> addressesJson;
  final Value<String?> nickname;
  final Value<String?> firstName;
  final Value<String?> lastName;
  final Value<String?> middleName;
  final Value<String?> namePrefix;
  final Value<String?> nameSuffix;
  final Value<String?> company;
  final Value<String?> phoneNumbersJson;
  final Value<String?> emailAddressesJson;
  final Value<bool> isNative;
  const ContactsCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.nativeContactId = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.addressesJson = const Value.absent(),
    this.nickname = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.middleName = const Value.absent(),
    this.namePrefix = const Value.absent(),
    this.nameSuffix = const Value.absent(),
    this.company = const Value.absent(),
    this.phoneNumbersJson = const Value.absent(),
    this.emailAddressesJson = const Value.absent(),
    this.isNative = const Value.absent(),
  });
  ContactsCompanion.insert({
    this.id = const Value.absent(),
    required String displayName,
    required String nativeContactId,
    this.avatarPath = const Value.absent(),
    required String addressesJson,
    this.nickname = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.middleName = const Value.absent(),
    this.namePrefix = const Value.absent(),
    this.nameSuffix = const Value.absent(),
    this.company = const Value.absent(),
    this.phoneNumbersJson = const Value.absent(),
    this.emailAddressesJson = const Value.absent(),
    required bool isNative,
  }) : displayName = Value(displayName),
       nativeContactId = Value(nativeContactId),
       addressesJson = Value(addressesJson),
       isNative = Value(isNative);
  static Insertable<SqliteContactRow> custom({
    Expression<int>? id,
    Expression<String>? displayName,
    Expression<String>? nativeContactId,
    Expression<String>? avatarPath,
    Expression<String>? addressesJson,
    Expression<String>? nickname,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? middleName,
    Expression<String>? namePrefix,
    Expression<String>? nameSuffix,
    Expression<String>? company,
    Expression<String>? phoneNumbersJson,
    Expression<String>? emailAddressesJson,
    Expression<bool>? isNative,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (nativeContactId != null) 'native_contact_id': nativeContactId,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (addressesJson != null) 'addresses_json': addressesJson,
      if (nickname != null) 'nickname': nickname,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (middleName != null) 'middle_name': middleName,
      if (namePrefix != null) 'name_prefix': namePrefix,
      if (nameSuffix != null) 'name_suffix': nameSuffix,
      if (company != null) 'company': company,
      if (phoneNumbersJson != null) 'phone_numbers_json': phoneNumbersJson,
      if (emailAddressesJson != null)
        'email_addresses_json': emailAddressesJson,
      if (isNative != null) 'is_native': isNative,
    });
  }

  ContactsCompanion copyWith({
    Value<int>? id,
    Value<String>? displayName,
    Value<String>? nativeContactId,
    Value<String?>? avatarPath,
    Value<String>? addressesJson,
    Value<String?>? nickname,
    Value<String?>? firstName,
    Value<String?>? lastName,
    Value<String?>? middleName,
    Value<String?>? namePrefix,
    Value<String?>? nameSuffix,
    Value<String?>? company,
    Value<String?>? phoneNumbersJson,
    Value<String?>? emailAddressesJson,
    Value<bool>? isNative,
  }) {
    return ContactsCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      nativeContactId: nativeContactId ?? this.nativeContactId,
      avatarPath: avatarPath ?? this.avatarPath,
      addressesJson: addressesJson ?? this.addressesJson,
      nickname: nickname ?? this.nickname,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      namePrefix: namePrefix ?? this.namePrefix,
      nameSuffix: nameSuffix ?? this.nameSuffix,
      company: company ?? this.company,
      phoneNumbersJson: phoneNumbersJson ?? this.phoneNumbersJson,
      emailAddressesJson: emailAddressesJson ?? this.emailAddressesJson,
      isNative: isNative ?? this.isNative,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (nativeContactId.present) {
      map['native_contact_id'] = Variable<String>(nativeContactId.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (addressesJson.present) {
      map['addresses_json'] = Variable<String>(addressesJson.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (middleName.present) {
      map['middle_name'] = Variable<String>(middleName.value);
    }
    if (namePrefix.present) {
      map['name_prefix'] = Variable<String>(namePrefix.value);
    }
    if (nameSuffix.present) {
      map['name_suffix'] = Variable<String>(nameSuffix.value);
    }
    if (company.present) {
      map['company'] = Variable<String>(company.value);
    }
    if (phoneNumbersJson.present) {
      map['phone_numbers_json'] = Variable<String>(phoneNumbersJson.value);
    }
    if (emailAddressesJson.present) {
      map['email_addresses_json'] = Variable<String>(emailAddressesJson.value);
    }
    if (isNative.present) {
      map['is_native'] = Variable<bool>(isNative.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactsCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('nativeContactId: $nativeContactId, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('addressesJson: $addressesJson, ')
          ..write('nickname: $nickname, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('middleName: $middleName, ')
          ..write('namePrefix: $namePrefix, ')
          ..write('nameSuffix: $nameSuffix, ')
          ..write('company: $company, ')
          ..write('phoneNumbersJson: $phoneNumbersJson, ')
          ..write('emailAddressesJson: $emailAddressesJson, ')
          ..write('isNative: $isNative')
          ..write(')'))
        .toString();
  }
}

class $ContactHandlesTable extends ContactHandles
    with TableInfo<$ContactHandlesTable, SqliteContactHandleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactHandlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contactIdMeta = const VerificationMeta(
    'contactId',
  );
  @override
  late final GeneratedColumn<int> contactId = GeneratedColumn<int>(
    'contact_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES contacts (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _handleIdMeta = const VerificationMeta(
    'handleId',
  );
  @override
  late final GeneratedColumn<int> handleId = GeneratedColumn<int>(
    'handle_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES handles (id) ON DELETE CASCADE',
  );
  @override
  List<GeneratedColumn> get $columns => [contactId, handleId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_handles';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteContactHandleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('contact_id')) {
      context.handle(
        _contactIdMeta,
        contactId.isAcceptableOrUnknown(data['contact_id']!, _contactIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contactIdMeta);
    }
    if (data.containsKey('handle_id')) {
      context.handle(
        _handleIdMeta,
        handleId.isAcceptableOrUnknown(data['handle_id']!, _handleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_handleIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contactId, handleId};
  @override
  SqliteContactHandleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteContactHandleRow(
      contactId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}contact_id'],
      )!,
      handleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}handle_id'],
      )!,
    );
  }

  @override
  $ContactHandlesTable createAlias(String alias) {
    return $ContactHandlesTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class SqliteContactHandleRow extends DataClass
    implements Insertable<SqliteContactHandleRow> {
  final int contactId;
  final int handleId;
  const SqliteContactHandleRow({
    required this.contactId,
    required this.handleId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['contact_id'] = Variable<int>(contactId);
    map['handle_id'] = Variable<int>(handleId);
    return map;
  }

  ContactHandlesCompanion toCompanion(bool nullToAbsent) {
    return ContactHandlesCompanion(
      contactId: Value(contactId),
      handleId: Value(handleId),
    );
  }

  factory SqliteContactHandleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteContactHandleRow(
      contactId: serializer.fromJson<int>(json['contactId']),
      handleId: serializer.fromJson<int>(json['handleId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contactId': serializer.toJson<int>(contactId),
      'handleId': serializer.toJson<int>(handleId),
    };
  }

  SqliteContactHandleRow copyWith({int? contactId, int? handleId}) =>
      SqliteContactHandleRow(
        contactId: contactId ?? this.contactId,
        handleId: handleId ?? this.handleId,
      );
  SqliteContactHandleRow copyWithCompanion(ContactHandlesCompanion data) {
    return SqliteContactHandleRow(
      contactId: data.contactId.present ? data.contactId.value : this.contactId,
      handleId: data.handleId.present ? data.handleId.value : this.handleId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteContactHandleRow(')
          ..write('contactId: $contactId, ')
          ..write('handleId: $handleId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(contactId, handleId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteContactHandleRow &&
          other.contactId == this.contactId &&
          other.handleId == this.handleId);
}

class ContactHandlesCompanion extends UpdateCompanion<SqliteContactHandleRow> {
  final Value<int> contactId;
  final Value<int> handleId;
  const ContactHandlesCompanion({
    this.contactId = const Value.absent(),
    this.handleId = const Value.absent(),
  });
  ContactHandlesCompanion.insert({
    required int contactId,
    required int handleId,
  }) : contactId = Value(contactId),
       handleId = Value(handleId);
  static Insertable<SqliteContactHandleRow> custom({
    Expression<int>? contactId,
    Expression<int>? handleId,
  }) {
    return RawValuesInsertable({
      if (contactId != null) 'contact_id': contactId,
      if (handleId != null) 'handle_id': handleId,
    });
  }

  ContactHandlesCompanion copyWith({
    Value<int>? contactId,
    Value<int>? handleId,
  }) {
    return ContactHandlesCompanion(
      contactId: contactId ?? this.contactId,
      handleId: handleId ?? this.handleId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contactId.present) {
      map['contact_id'] = Variable<int>(contactId.value);
    }
    if (handleId.present) {
      map['handle_id'] = Variable<int>(handleId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactHandlesCompanion(')
          ..write('contactId: $contactId, ')
          ..write('handleId: $handleId')
          ..write(')'))
        .toString();
  }
}

class $CustomGroupsTable extends CustomGroups
    with TableInfo<$CustomGroupsTable, SqliteCustomGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _showUnreadBadgeMeta = const VerificationMeta(
    'showUnreadBadge',
  );
  @override
  late final GeneratedColumn<bool> showUnreadBadge = GeneratedColumn<bool>(
    'show_unread_badge',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_unread_badge" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder, showUnreadBadge];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteCustomGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('show_unread_badge')) {
      context.handle(
        _showUnreadBadgeMeta,
        showUnreadBadge.isAcceptableOrUnknown(
          data['show_unread_badge']!,
          _showUnreadBadgeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_showUnreadBadgeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SqliteCustomGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteCustomGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      showUnreadBadge: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_unread_badge'],
      )!,
    );
  }

  @override
  $CustomGroupsTable createAlias(String alias) {
    return $CustomGroupsTable(attachedDatabase, alias);
  }
}

class SqliteCustomGroupRow extends DataClass
    implements Insertable<SqliteCustomGroupRow> {
  final int id;
  final String name;
  final int sortOrder;
  final bool showUnreadBadge;
  const SqliteCustomGroupRow({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.showUnreadBadge,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['show_unread_badge'] = Variable<bool>(showUnreadBadge);
    return map;
  }

  CustomGroupsCompanion toCompanion(bool nullToAbsent) {
    return CustomGroupsCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      showUnreadBadge: Value(showUnreadBadge),
    );
  }

  factory SqliteCustomGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteCustomGroupRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      showUnreadBadge: serializer.fromJson<bool>(json['showUnreadBadge']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'showUnreadBadge': serializer.toJson<bool>(showUnreadBadge),
    };
  }

  SqliteCustomGroupRow copyWith({
    int? id,
    String? name,
    int? sortOrder,
    bool? showUnreadBadge,
  }) => SqliteCustomGroupRow(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    showUnreadBadge: showUnreadBadge ?? this.showUnreadBadge,
  );
  SqliteCustomGroupRow copyWithCompanion(CustomGroupsCompanion data) {
    return SqliteCustomGroupRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      showUnreadBadge: data.showUnreadBadge.present
          ? data.showUnreadBadge.value
          : this.showUnreadBadge,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteCustomGroupRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('showUnreadBadge: $showUnreadBadge')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, showUnreadBadge);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteCustomGroupRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.showUnreadBadge == this.showUnreadBadge);
}

class CustomGroupsCompanion extends UpdateCompanion<SqliteCustomGroupRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<bool> showUnreadBadge;
  const CustomGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.showUnreadBadge = const Value.absent(),
  });
  CustomGroupsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int sortOrder,
    required bool showUnreadBadge,
  }) : name = Value(name),
       sortOrder = Value(sortOrder),
       showUnreadBadge = Value(showUnreadBadge);
  static Insertable<SqliteCustomGroupRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<bool>? showUnreadBadge,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (showUnreadBadge != null) 'show_unread_badge': showUnreadBadge,
    });
  }

  CustomGroupsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<bool>? showUnreadBadge,
  }) {
    return CustomGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      showUnreadBadge: showUnreadBadge ?? this.showUnreadBadge,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (showUnreadBadge.present) {
      map['show_unread_badge'] = Variable<bool>(showUnreadBadge.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('showUnreadBadge: $showUnreadBadge')
          ..write(')'))
        .toString();
  }
}

class $CustomGroupChatsTable extends CustomGroupChats
    with TableInfo<$CustomGroupChatsTable, SqliteCustomGroupChatRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomGroupChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES custom_groups (id) ON DELETE CASCADE',
  );
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<int> chatId = GeneratedColumn<int>(
    'chat_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES chats (id) ON DELETE CASCADE',
  );
  @override
  List<GeneratedColumn> get $columns => [groupId, chatId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_group_chats';
  @override
  VerificationContext validateIntegrity(
    Insertable<SqliteCustomGroupChatRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, chatId};
  @override
  SqliteCustomGroupChatRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SqliteCustomGroupChatRow(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      )!,
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chat_id'],
      )!,
    );
  }

  @override
  $CustomGroupChatsTable createAlias(String alias) {
    return $CustomGroupChatsTable(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
}

class SqliteCustomGroupChatRow extends DataClass
    implements Insertable<SqliteCustomGroupChatRow> {
  final int groupId;
  final int chatId;
  const SqliteCustomGroupChatRow({required this.groupId, required this.chatId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<int>(groupId);
    map['chat_id'] = Variable<int>(chatId);
    return map;
  }

  CustomGroupChatsCompanion toCompanion(bool nullToAbsent) {
    return CustomGroupChatsCompanion(
      groupId: Value(groupId),
      chatId: Value(chatId),
    );
  }

  factory SqliteCustomGroupChatRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteCustomGroupChatRow(
      groupId: serializer.fromJson<int>(json['groupId']),
      chatId: serializer.fromJson<int>(json['chatId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<int>(groupId),
      'chatId': serializer.toJson<int>(chatId),
    };
  }

  SqliteCustomGroupChatRow copyWith({int? groupId, int? chatId}) =>
      SqliteCustomGroupChatRow(
        groupId: groupId ?? this.groupId,
        chatId: chatId ?? this.chatId,
      );
  SqliteCustomGroupChatRow copyWithCompanion(CustomGroupChatsCompanion data) {
    return SqliteCustomGroupChatRow(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SqliteCustomGroupChatRow(')
          ..write('groupId: $groupId, ')
          ..write('chatId: $chatId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, chatId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteCustomGroupChatRow &&
          other.groupId == this.groupId &&
          other.chatId == this.chatId);
}

class CustomGroupChatsCompanion
    extends UpdateCompanion<SqliteCustomGroupChatRow> {
  final Value<int> groupId;
  final Value<int> chatId;
  const CustomGroupChatsCompanion({
    this.groupId = const Value.absent(),
    this.chatId = const Value.absent(),
  });
  CustomGroupChatsCompanion.insert({required int groupId, required int chatId})
    : groupId = Value(groupId),
      chatId = Value(chatId);
  static Insertable<SqliteCustomGroupChatRow> custom({
    Expression<int>? groupId,
    Expression<int>? chatId,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (chatId != null) 'chat_id': chatId,
    });
  }

  CustomGroupChatsCompanion copyWith({
    Value<int>? groupId,
    Value<int>? chatId,
  }) {
    return CustomGroupChatsCompanion(
      groupId: groupId ?? this.groupId,
      chatId: chatId ?? this.chatId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<int>(chatId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomGroupChatsCompanion(')
          ..write('groupId: $groupId, ')
          ..write('chatId: $chatId')
          ..write(')'))
        .toString();
  }
}

class $StorageMetaTable extends StorageMeta
    with TableInfo<$StorageMetaTable, StorageMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StorageMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'storage_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<StorageMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  StorageMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorageMetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $StorageMetaTable createAlias(String alias) {
    return $StorageMetaTable(attachedDatabase, alias);
  }
}

class StorageMetaData extends DataClass implements Insertable<StorageMetaData> {
  final String key;
  final String? value;
  const StorageMetaData({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  StorageMetaCompanion toCompanion(bool nullToAbsent) {
    return StorageMetaCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory StorageMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorageMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  StorageMetaData copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
  }) => StorageMetaData(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
  );
  StorageMetaData copyWithCompanion(StorageMetaCompanion data) {
    return StorageMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StorageMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorageMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class StorageMetaCompanion extends UpdateCompanion<StorageMetaData> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const StorageMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StorageMetaCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<StorageMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StorageMetaCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return StorageMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StorageMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CopyCheckpointsTable extends CopyCheckpoints
    with TableInfo<$CopyCheckpointsTable, CopyCheckpoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CopyCheckpointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSourceIdMeta = const VerificationMeta(
    'lastSourceId',
  );
  @override
  late final GeneratedColumn<int> lastSourceId = GeneratedColumn<int>(
    'last_source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowsCopiedMeta = const VerificationMeta(
    'rowsCopied',
  );
  @override
  late final GeneratedColumn<int> rowsCopied = GeneratedColumn<int>(
    'rows_copied',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entity, lastSourceId, rowsCopied];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'copy_checkpoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<CopyCheckpoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('last_source_id')) {
      context.handle(
        _lastSourceIdMeta,
        lastSourceId.isAcceptableOrUnknown(
          data['last_source_id']!,
          _lastSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSourceIdMeta);
    }
    if (data.containsKey('rows_copied')) {
      context.handle(
        _rowsCopiedMeta,
        rowsCopied.isAcceptableOrUnknown(data['rows_copied']!, _rowsCopiedMeta),
      );
    } else if (isInserting) {
      context.missing(_rowsCopiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity};
  @override
  CopyCheckpoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CopyCheckpoint(
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      lastSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_source_id'],
      )!,
      rowsCopied: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rows_copied'],
      )!,
    );
  }

  @override
  $CopyCheckpointsTable createAlias(String alias) {
    return $CopyCheckpointsTable(attachedDatabase, alias);
  }
}

class CopyCheckpoint extends DataClass implements Insertable<CopyCheckpoint> {
  final String entity;
  final int lastSourceId;
  final int rowsCopied;
  const CopyCheckpoint({
    required this.entity,
    required this.lastSourceId,
    required this.rowsCopied,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['last_source_id'] = Variable<int>(lastSourceId);
    map['rows_copied'] = Variable<int>(rowsCopied);
    return map;
  }

  CopyCheckpointsCompanion toCompanion(bool nullToAbsent) {
    return CopyCheckpointsCompanion(
      entity: Value(entity),
      lastSourceId: Value(lastSourceId),
      rowsCopied: Value(rowsCopied),
    );
  }

  factory CopyCheckpoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CopyCheckpoint(
      entity: serializer.fromJson<String>(json['entity']),
      lastSourceId: serializer.fromJson<int>(json['lastSourceId']),
      rowsCopied: serializer.fromJson<int>(json['rowsCopied']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'lastSourceId': serializer.toJson<int>(lastSourceId),
      'rowsCopied': serializer.toJson<int>(rowsCopied),
    };
  }

  CopyCheckpoint copyWith({
    String? entity,
    int? lastSourceId,
    int? rowsCopied,
  }) => CopyCheckpoint(
    entity: entity ?? this.entity,
    lastSourceId: lastSourceId ?? this.lastSourceId,
    rowsCopied: rowsCopied ?? this.rowsCopied,
  );
  CopyCheckpoint copyWithCompanion(CopyCheckpointsCompanion data) {
    return CopyCheckpoint(
      entity: data.entity.present ? data.entity.value : this.entity,
      lastSourceId: data.lastSourceId.present
          ? data.lastSourceId.value
          : this.lastSourceId,
      rowsCopied: data.rowsCopied.present
          ? data.rowsCopied.value
          : this.rowsCopied,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CopyCheckpoint(')
          ..write('entity: $entity, ')
          ..write('lastSourceId: $lastSourceId, ')
          ..write('rowsCopied: $rowsCopied')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entity, lastSourceId, rowsCopied);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CopyCheckpoint &&
          other.entity == this.entity &&
          other.lastSourceId == this.lastSourceId &&
          other.rowsCopied == this.rowsCopied);
}

class CopyCheckpointsCompanion extends UpdateCompanion<CopyCheckpoint> {
  final Value<String> entity;
  final Value<int> lastSourceId;
  final Value<int> rowsCopied;
  final Value<int> rowid;
  const CopyCheckpointsCompanion({
    this.entity = const Value.absent(),
    this.lastSourceId = const Value.absent(),
    this.rowsCopied = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CopyCheckpointsCompanion.insert({
    required String entity,
    required int lastSourceId,
    required int rowsCopied,
    this.rowid = const Value.absent(),
  }) : entity = Value(entity),
       lastSourceId = Value(lastSourceId),
       rowsCopied = Value(rowsCopied);
  static Insertable<CopyCheckpoint> custom({
    Expression<String>? entity,
    Expression<int>? lastSourceId,
    Expression<int>? rowsCopied,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (lastSourceId != null) 'last_source_id': lastSourceId,
      if (rowsCopied != null) 'rows_copied': rowsCopied,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CopyCheckpointsCompanion copyWith({
    Value<String>? entity,
    Value<int>? lastSourceId,
    Value<int>? rowsCopied,
    Value<int>? rowid,
  }) {
    return CopyCheckpointsCompanion(
      entity: entity ?? this.entity,
      lastSourceId: lastSourceId ?? this.lastSourceId,
      rowsCopied: rowsCopied ?? this.rowsCopied,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (lastSourceId.present) {
      map['last_source_id'] = Variable<int>(lastSourceId.value);
    }
    if (rowsCopied.present) {
      map['rows_copied'] = Variable<int>(rowsCopied.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CopyCheckpointsCompanion(')
          ..write('entity: $entity, ')
          ..write('lastSourceId: $lastSourceId, ')
          ..write('rowsCopied: $rowsCopied, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChatsTable chats = $ChatsTable(this);
  late final $HandlesTable handles = $HandlesTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $ChatHandlesTable chatHandles = $ChatHandlesTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $ContactsTable contacts = $ContactsTable(this);
  late final $ContactHandlesTable contactHandles = $ContactHandlesTable(this);
  late final $CustomGroupsTable customGroups = $CustomGroupsTable(this);
  late final $CustomGroupChatsTable customGroupChats = $CustomGroupChatsTable(
    this,
  );
  late final $StorageMetaTable storageMeta = $StorageMetaTable(this);
  late final $CopyCheckpointsTable copyCheckpoints = $CopyCheckpointsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    chats,
    handles,
    messages,
    chatHandles,
    attachments,
    contacts,
    contactHandles,
    customGroups,
    customGroupChats,
    storageMeta,
    copyCheckpoints,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chats',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('messages', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'handles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('messages', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chats',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chat_handles', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'handles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chat_handles', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'messages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('attachments', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'contacts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('contact_handles', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'handles',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('contact_handles', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'custom_groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('custom_group_chats', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chats',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('custom_group_chats', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ChatsTableCreateCompanionBuilder =
    ChatsCompanion Function({
      Value<int> id,
      required String guid,
      Value<String?> chatIdentifier,
      Value<String?> serviceName,
      Value<String?> groupId,
      Value<String?> originalGroupId,
      Value<String?> legacyGroupIdsJson,
      Value<String?> latestGroupTitle,
      Value<String?> threadKey,
      Value<bool?> isArchived,
      Value<String?> muteType,
      Value<String?> muteArgs,
      Value<bool?> isPinned,
      Value<bool?> hasUnreadMessage,
      Value<String?> displayName,
      Value<bool?> isFilteredAsSpam,
      Value<bool?> autoSendReadReceipts,
      Value<bool?> autoSendTypingIndicators,
      Value<String?> textFieldText,
      Value<String> textFieldAttachmentsJson,
      Value<int?> latestMessageId,
      Value<int?> latestMessageDateUs,
      Value<int?> dateDeletedUs,
      Value<int?> style,
      Value<bool> lockChatName,
      Value<bool> lockChatIcon,
      Value<String?> lastReadMessageGuid,
      Value<String?> customThemeLight,
      Value<String?> customThemeDark,
      Value<String?> wallpaperType,
      Value<String?> dynamicWallpaperId,
      Value<String?> dynamicWallpaperConfig,
      Value<String?> customAvatarPath,
      Value<String?> customBackgroundPath,
      Value<int?> pinIndex,
    });
typedef $$ChatsTableUpdateCompanionBuilder =
    ChatsCompanion Function({
      Value<int> id,
      Value<String> guid,
      Value<String?> chatIdentifier,
      Value<String?> serviceName,
      Value<String?> groupId,
      Value<String?> originalGroupId,
      Value<String?> legacyGroupIdsJson,
      Value<String?> latestGroupTitle,
      Value<String?> threadKey,
      Value<bool?> isArchived,
      Value<String?> muteType,
      Value<String?> muteArgs,
      Value<bool?> isPinned,
      Value<bool?> hasUnreadMessage,
      Value<String?> displayName,
      Value<bool?> isFilteredAsSpam,
      Value<bool?> autoSendReadReceipts,
      Value<bool?> autoSendTypingIndicators,
      Value<String?> textFieldText,
      Value<String> textFieldAttachmentsJson,
      Value<int?> latestMessageId,
      Value<int?> latestMessageDateUs,
      Value<int?> dateDeletedUs,
      Value<int?> style,
      Value<bool> lockChatName,
      Value<bool> lockChatIcon,
      Value<String?> lastReadMessageGuid,
      Value<String?> customThemeLight,
      Value<String?> customThemeDark,
      Value<String?> wallpaperType,
      Value<String?> dynamicWallpaperId,
      Value<String?> dynamicWallpaperConfig,
      Value<String?> customAvatarPath,
      Value<String?> customBackgroundPath,
      Value<int?> pinIndex,
    });

final class $$ChatsTableReferences
    extends BaseReferences<_$AppDatabase, $ChatsTable, SqliteChatRow> {
  $$ChatsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MessagesTable, List<SqliteMessageRow>>
  _messagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: $_aliasNameGenerator(db.chats.id, db.messages.chatId),
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.chatId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChatHandlesTable, List<SqliteChatHandleRow>>
  _chatHandlesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.chatHandles,
    aliasName: $_aliasNameGenerator(db.chats.id, db.chatHandles.chatId),
  );

  $$ChatHandlesTableProcessedTableManager get chatHandlesRefs {
    final manager = $$ChatHandlesTableTableManager(
      $_db,
      $_db.chatHandles,
    ).filter((f) => f.chatId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_chatHandlesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $CustomGroupChatsTable,
    List<SqliteCustomGroupChatRow>
  >
  _customGroupChatsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.customGroupChats,
    aliasName: $_aliasNameGenerator(db.chats.id, db.customGroupChats.chatId),
  );

  $$CustomGroupChatsTableProcessedTableManager get customGroupChatsRefs {
    final manager = $$CustomGroupChatsTableTableManager(
      $_db,
      $_db.customGroupChats,
    ).filter((f) => f.chatId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _customGroupChatsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChatsTableFilterComposer extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chatIdentifier => $composableBuilder(
    column: $table.chatIdentifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceName => $composableBuilder(
    column: $table.serviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalGroupId => $composableBuilder(
    column: $table.originalGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legacyGroupIdsJson => $composableBuilder(
    column: $table.legacyGroupIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latestGroupTitle => $composableBuilder(
    column: $table.latestGroupTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadKey => $composableBuilder(
    column: $table.threadKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get muteType => $composableBuilder(
    column: $table.muteType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get muteArgs => $composableBuilder(
    column: $table.muteArgs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasUnreadMessage => $composableBuilder(
    column: $table.hasUnreadMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFilteredAsSpam => $composableBuilder(
    column: $table.isFilteredAsSpam,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoSendReadReceipts => $composableBuilder(
    column: $table.autoSendReadReceipts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoSendTypingIndicators => $composableBuilder(
    column: $table.autoSendTypingIndicators,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textFieldText => $composableBuilder(
    column: $table.textFieldText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textFieldAttachmentsJson => $composableBuilder(
    column: $table.textFieldAttachmentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latestMessageId => $composableBuilder(
    column: $table.latestMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latestMessageDateUs => $composableBuilder(
    column: $table.latestMessageDateUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateDeletedUs => $composableBuilder(
    column: $table.dateDeletedUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lockChatName => $composableBuilder(
    column: $table.lockChatName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get lockChatIcon => $composableBuilder(
    column: $table.lockChatIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastReadMessageGuid => $composableBuilder(
    column: $table.lastReadMessageGuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customThemeLight => $composableBuilder(
    column: $table.customThemeLight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customThemeDark => $composableBuilder(
    column: $table.customThemeDark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wallpaperType => $composableBuilder(
    column: $table.wallpaperType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dynamicWallpaperId => $composableBuilder(
    column: $table.dynamicWallpaperId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dynamicWallpaperConfig => $composableBuilder(
    column: $table.dynamicWallpaperConfig,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customAvatarPath => $composableBuilder(
    column: $table.customAvatarPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customBackgroundPath => $composableBuilder(
    column: $table.customBackgroundPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pinIndex => $composableBuilder(
    column: $table.pinIndex,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.chatId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> chatHandlesRefs(
    Expression<bool> Function($$ChatHandlesTableFilterComposer f) f,
  ) {
    final $$ChatHandlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatHandles,
      getReferencedColumn: (t) => t.chatId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatHandlesTableFilterComposer(
            $db: $db,
            $table: $db.chatHandles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> customGroupChatsRefs(
    Expression<bool> Function($$CustomGroupChatsTableFilterComposer f) f,
  ) {
    final $$CustomGroupChatsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customGroupChats,
      getReferencedColumn: (t) => t.chatId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomGroupChatsTableFilterComposer(
            $db: $db,
            $table: $db.customGroupChats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChatsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chatIdentifier => $composableBuilder(
    column: $table.chatIdentifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceName => $composableBuilder(
    column: $table.serviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalGroupId => $composableBuilder(
    column: $table.originalGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legacyGroupIdsJson => $composableBuilder(
    column: $table.legacyGroupIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latestGroupTitle => $composableBuilder(
    column: $table.latestGroupTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadKey => $composableBuilder(
    column: $table.threadKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get muteType => $composableBuilder(
    column: $table.muteType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get muteArgs => $composableBuilder(
    column: $table.muteArgs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasUnreadMessage => $composableBuilder(
    column: $table.hasUnreadMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFilteredAsSpam => $composableBuilder(
    column: $table.isFilteredAsSpam,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoSendReadReceipts => $composableBuilder(
    column: $table.autoSendReadReceipts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoSendTypingIndicators => $composableBuilder(
    column: $table.autoSendTypingIndicators,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textFieldText => $composableBuilder(
    column: $table.textFieldText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textFieldAttachmentsJson => $composableBuilder(
    column: $table.textFieldAttachmentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latestMessageId => $composableBuilder(
    column: $table.latestMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latestMessageDateUs => $composableBuilder(
    column: $table.latestMessageDateUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateDeletedUs => $composableBuilder(
    column: $table.dateDeletedUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lockChatName => $composableBuilder(
    column: $table.lockChatName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get lockChatIcon => $composableBuilder(
    column: $table.lockChatIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastReadMessageGuid => $composableBuilder(
    column: $table.lastReadMessageGuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customThemeLight => $composableBuilder(
    column: $table.customThemeLight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customThemeDark => $composableBuilder(
    column: $table.customThemeDark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wallpaperType => $composableBuilder(
    column: $table.wallpaperType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dynamicWallpaperId => $composableBuilder(
    column: $table.dynamicWallpaperId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dynamicWallpaperConfig => $composableBuilder(
    column: $table.dynamicWallpaperConfig,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customAvatarPath => $composableBuilder(
    column: $table.customAvatarPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customBackgroundPath => $composableBuilder(
    column: $table.customBackgroundPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pinIndex => $composableBuilder(
    column: $table.pinIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get guid =>
      $composableBuilder(column: $table.guid, builder: (column) => column);

  GeneratedColumn<String> get chatIdentifier => $composableBuilder(
    column: $table.chatIdentifier,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serviceName => $composableBuilder(
    column: $table.serviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get originalGroupId => $composableBuilder(
    column: $table.originalGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get legacyGroupIdsJson => $composableBuilder(
    column: $table.legacyGroupIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get latestGroupTitle => $composableBuilder(
    column: $table.latestGroupTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get threadKey =>
      $composableBuilder(column: $table.threadKey, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get muteType =>
      $composableBuilder(column: $table.muteType, builder: (column) => column);

  GeneratedColumn<String> get muteArgs =>
      $composableBuilder(column: $table.muteArgs, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<bool> get hasUnreadMessage => $composableBuilder(
    column: $table.hasUnreadMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFilteredAsSpam => $composableBuilder(
    column: $table.isFilteredAsSpam,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoSendReadReceipts => $composableBuilder(
    column: $table.autoSendReadReceipts,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoSendTypingIndicators => $composableBuilder(
    column: $table.autoSendTypingIndicators,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textFieldText => $composableBuilder(
    column: $table.textFieldText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get textFieldAttachmentsJson => $composableBuilder(
    column: $table.textFieldAttachmentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get latestMessageId => $composableBuilder(
    column: $table.latestMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get latestMessageDateUs => $composableBuilder(
    column: $table.latestMessageDateUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dateDeletedUs => $composableBuilder(
    column: $table.dateDeletedUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<bool> get lockChatName => $composableBuilder(
    column: $table.lockChatName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get lockChatIcon => $composableBuilder(
    column: $table.lockChatIcon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastReadMessageGuid => $composableBuilder(
    column: $table.lastReadMessageGuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customThemeLight => $composableBuilder(
    column: $table.customThemeLight,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customThemeDark => $composableBuilder(
    column: $table.customThemeDark,
    builder: (column) => column,
  );

  GeneratedColumn<String> get wallpaperType => $composableBuilder(
    column: $table.wallpaperType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dynamicWallpaperId => $composableBuilder(
    column: $table.dynamicWallpaperId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dynamicWallpaperConfig => $composableBuilder(
    column: $table.dynamicWallpaperConfig,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customAvatarPath => $composableBuilder(
    column: $table.customAvatarPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customBackgroundPath => $composableBuilder(
    column: $table.customBackgroundPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pinIndex =>
      $composableBuilder(column: $table.pinIndex, builder: (column) => column);

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.chatId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> chatHandlesRefs<T extends Object>(
    Expression<T> Function($$ChatHandlesTableAnnotationComposer a) f,
  ) {
    final $$ChatHandlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatHandles,
      getReferencedColumn: (t) => t.chatId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatHandlesTableAnnotationComposer(
            $db: $db,
            $table: $db.chatHandles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> customGroupChatsRefs<T extends Object>(
    Expression<T> Function($$CustomGroupChatsTableAnnotationComposer a) f,
  ) {
    final $$CustomGroupChatsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customGroupChats,
      getReferencedColumn: (t) => t.chatId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomGroupChatsTableAnnotationComposer(
            $db: $db,
            $table: $db.customGroupChats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatsTable,
          SqliteChatRow,
          $$ChatsTableFilterComposer,
          $$ChatsTableOrderingComposer,
          $$ChatsTableAnnotationComposer,
          $$ChatsTableCreateCompanionBuilder,
          $$ChatsTableUpdateCompanionBuilder,
          (SqliteChatRow, $$ChatsTableReferences),
          SqliteChatRow,
          PrefetchHooks Function({
            bool messagesRefs,
            bool chatHandlesRefs,
            bool customGroupChatsRefs,
          })
        > {
  $$ChatsTableTableManager(_$AppDatabase db, $ChatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> guid = const Value.absent(),
                Value<String?> chatIdentifier = const Value.absent(),
                Value<String?> serviceName = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> originalGroupId = const Value.absent(),
                Value<String?> legacyGroupIdsJson = const Value.absent(),
                Value<String?> latestGroupTitle = const Value.absent(),
                Value<String?> threadKey = const Value.absent(),
                Value<bool?> isArchived = const Value.absent(),
                Value<String?> muteType = const Value.absent(),
                Value<String?> muteArgs = const Value.absent(),
                Value<bool?> isPinned = const Value.absent(),
                Value<bool?> hasUnreadMessage = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<bool?> isFilteredAsSpam = const Value.absent(),
                Value<bool?> autoSendReadReceipts = const Value.absent(),
                Value<bool?> autoSendTypingIndicators = const Value.absent(),
                Value<String?> textFieldText = const Value.absent(),
                Value<String> textFieldAttachmentsJson = const Value.absent(),
                Value<int?> latestMessageId = const Value.absent(),
                Value<int?> latestMessageDateUs = const Value.absent(),
                Value<int?> dateDeletedUs = const Value.absent(),
                Value<int?> style = const Value.absent(),
                Value<bool> lockChatName = const Value.absent(),
                Value<bool> lockChatIcon = const Value.absent(),
                Value<String?> lastReadMessageGuid = const Value.absent(),
                Value<String?> customThemeLight = const Value.absent(),
                Value<String?> customThemeDark = const Value.absent(),
                Value<String?> wallpaperType = const Value.absent(),
                Value<String?> dynamicWallpaperId = const Value.absent(),
                Value<String?> dynamicWallpaperConfig = const Value.absent(),
                Value<String?> customAvatarPath = const Value.absent(),
                Value<String?> customBackgroundPath = const Value.absent(),
                Value<int?> pinIndex = const Value.absent(),
              }) => ChatsCompanion(
                id: id,
                guid: guid,
                chatIdentifier: chatIdentifier,
                serviceName: serviceName,
                groupId: groupId,
                originalGroupId: originalGroupId,
                legacyGroupIdsJson: legacyGroupIdsJson,
                latestGroupTitle: latestGroupTitle,
                threadKey: threadKey,
                isArchived: isArchived,
                muteType: muteType,
                muteArgs: muteArgs,
                isPinned: isPinned,
                hasUnreadMessage: hasUnreadMessage,
                displayName: displayName,
                isFilteredAsSpam: isFilteredAsSpam,
                autoSendReadReceipts: autoSendReadReceipts,
                autoSendTypingIndicators: autoSendTypingIndicators,
                textFieldText: textFieldText,
                textFieldAttachmentsJson: textFieldAttachmentsJson,
                latestMessageId: latestMessageId,
                latestMessageDateUs: latestMessageDateUs,
                dateDeletedUs: dateDeletedUs,
                style: style,
                lockChatName: lockChatName,
                lockChatIcon: lockChatIcon,
                lastReadMessageGuid: lastReadMessageGuid,
                customThemeLight: customThemeLight,
                customThemeDark: customThemeDark,
                wallpaperType: wallpaperType,
                dynamicWallpaperId: dynamicWallpaperId,
                dynamicWallpaperConfig: dynamicWallpaperConfig,
                customAvatarPath: customAvatarPath,
                customBackgroundPath: customBackgroundPath,
                pinIndex: pinIndex,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String guid,
                Value<String?> chatIdentifier = const Value.absent(),
                Value<String?> serviceName = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> originalGroupId = const Value.absent(),
                Value<String?> legacyGroupIdsJson = const Value.absent(),
                Value<String?> latestGroupTitle = const Value.absent(),
                Value<String?> threadKey = const Value.absent(),
                Value<bool?> isArchived = const Value.absent(),
                Value<String?> muteType = const Value.absent(),
                Value<String?> muteArgs = const Value.absent(),
                Value<bool?> isPinned = const Value.absent(),
                Value<bool?> hasUnreadMessage = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<bool?> isFilteredAsSpam = const Value.absent(),
                Value<bool?> autoSendReadReceipts = const Value.absent(),
                Value<bool?> autoSendTypingIndicators = const Value.absent(),
                Value<String?> textFieldText = const Value.absent(),
                Value<String> textFieldAttachmentsJson = const Value.absent(),
                Value<int?> latestMessageId = const Value.absent(),
                Value<int?> latestMessageDateUs = const Value.absent(),
                Value<int?> dateDeletedUs = const Value.absent(),
                Value<int?> style = const Value.absent(),
                Value<bool> lockChatName = const Value.absent(),
                Value<bool> lockChatIcon = const Value.absent(),
                Value<String?> lastReadMessageGuid = const Value.absent(),
                Value<String?> customThemeLight = const Value.absent(),
                Value<String?> customThemeDark = const Value.absent(),
                Value<String?> wallpaperType = const Value.absent(),
                Value<String?> dynamicWallpaperId = const Value.absent(),
                Value<String?> dynamicWallpaperConfig = const Value.absent(),
                Value<String?> customAvatarPath = const Value.absent(),
                Value<String?> customBackgroundPath = const Value.absent(),
                Value<int?> pinIndex = const Value.absent(),
              }) => ChatsCompanion.insert(
                id: id,
                guid: guid,
                chatIdentifier: chatIdentifier,
                serviceName: serviceName,
                groupId: groupId,
                originalGroupId: originalGroupId,
                legacyGroupIdsJson: legacyGroupIdsJson,
                latestGroupTitle: latestGroupTitle,
                threadKey: threadKey,
                isArchived: isArchived,
                muteType: muteType,
                muteArgs: muteArgs,
                isPinned: isPinned,
                hasUnreadMessage: hasUnreadMessage,
                displayName: displayName,
                isFilteredAsSpam: isFilteredAsSpam,
                autoSendReadReceipts: autoSendReadReceipts,
                autoSendTypingIndicators: autoSendTypingIndicators,
                textFieldText: textFieldText,
                textFieldAttachmentsJson: textFieldAttachmentsJson,
                latestMessageId: latestMessageId,
                latestMessageDateUs: latestMessageDateUs,
                dateDeletedUs: dateDeletedUs,
                style: style,
                lockChatName: lockChatName,
                lockChatIcon: lockChatIcon,
                lastReadMessageGuid: lastReadMessageGuid,
                customThemeLight: customThemeLight,
                customThemeDark: customThemeDark,
                wallpaperType: wallpaperType,
                dynamicWallpaperId: dynamicWallpaperId,
                dynamicWallpaperConfig: dynamicWallpaperConfig,
                customAvatarPath: customAvatarPath,
                customBackgroundPath: customBackgroundPath,
                pinIndex: pinIndex,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ChatsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                messagesRefs = false,
                chatHandlesRefs = false,
                customGroupChatsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (messagesRefs) db.messages,
                    if (chatHandlesRefs) db.chatHandles,
                    if (customGroupChatsRefs) db.customGroupChats,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (messagesRefs)
                        await $_getPrefetchedData<
                          SqliteChatRow,
                          $ChatsTable,
                          SqliteMessageRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChatsTableReferences
                              ._messagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChatsTableReferences(
                                db,
                                table,
                                p0,
                              ).messagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chatId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (chatHandlesRefs)
                        await $_getPrefetchedData<
                          SqliteChatRow,
                          $ChatsTable,
                          SqliteChatHandleRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChatsTableReferences
                              ._chatHandlesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChatsTableReferences(
                                db,
                                table,
                                p0,
                              ).chatHandlesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chatId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (customGroupChatsRefs)
                        await $_getPrefetchedData<
                          SqliteChatRow,
                          $ChatsTable,
                          SqliteCustomGroupChatRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChatsTableReferences
                              ._customGroupChatsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChatsTableReferences(
                                db,
                                table,
                                p0,
                              ).customGroupChatsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chatId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatsTable,
      SqliteChatRow,
      $$ChatsTableFilterComposer,
      $$ChatsTableOrderingComposer,
      $$ChatsTableAnnotationComposer,
      $$ChatsTableCreateCompanionBuilder,
      $$ChatsTableUpdateCompanionBuilder,
      (SqliteChatRow, $$ChatsTableReferences),
      SqliteChatRow,
      PrefetchHooks Function({
        bool messagesRefs,
        bool chatHandlesRefs,
        bool customGroupChatsRefs,
      })
    >;
typedef $$HandlesTableCreateCompanionBuilder =
    HandlesCompanion Function({
      Value<int> id,
      Value<int?> originalRowid,
      required String address,
      Value<String?> country,
      Value<String?> color,
      Value<String?> defaultPhone,
      Value<String?> defaultEmail,
      Value<String?> formattedAddress,
      required String uniqueAddressAndService,
      required String service,
    });
typedef $$HandlesTableUpdateCompanionBuilder =
    HandlesCompanion Function({
      Value<int> id,
      Value<int?> originalRowid,
      Value<String> address,
      Value<String?> country,
      Value<String?> color,
      Value<String?> defaultPhone,
      Value<String?> defaultEmail,
      Value<String?> formattedAddress,
      Value<String> uniqueAddressAndService,
      Value<String> service,
    });

final class $$HandlesTableReferences
    extends BaseReferences<_$AppDatabase, $HandlesTable, SqliteHandleRow> {
  $$HandlesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MessagesTable, List<SqliteMessageRow>>
  _messagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.messages,
    aliasName: $_aliasNameGenerator(
      db.handles.id,
      db.messages.handleRelationId,
    ),
  );

  $$MessagesTableProcessedTableManager get messagesRefs {
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.handleRelationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_messagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChatHandlesTable, List<SqliteChatHandleRow>>
  _chatHandlesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.chatHandles,
    aliasName: $_aliasNameGenerator(db.handles.id, db.chatHandles.handleId),
  );

  $$ChatHandlesTableProcessedTableManager get chatHandlesRefs {
    final manager = $$ChatHandlesTableTableManager(
      $_db,
      $_db.chatHandles,
    ).filter((f) => f.handleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_chatHandlesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ContactHandlesTable, List<SqliteContactHandleRow>>
  _contactHandlesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.contactHandles,
    aliasName: $_aliasNameGenerator(db.handles.id, db.contactHandles.handleId),
  );

  $$ContactHandlesTableProcessedTableManager get contactHandlesRefs {
    final manager = $$ContactHandlesTableTableManager(
      $_db,
      $_db.contactHandles,
    ).filter((f) => f.handleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_contactHandlesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HandlesTableFilterComposer
    extends Composer<_$AppDatabase, $HandlesTable> {
  $$HandlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalRowid => $composableBuilder(
    column: $table.originalRowid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultPhone => $composableBuilder(
    column: $table.defaultPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultEmail => $composableBuilder(
    column: $table.defaultEmail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formattedAddress => $composableBuilder(
    column: $table.formattedAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uniqueAddressAndService => $composableBuilder(
    column: $table.uniqueAddressAndService,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get service => $composableBuilder(
    column: $table.service,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> messagesRefs(
    Expression<bool> Function($$MessagesTableFilterComposer f) f,
  ) {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.handleRelationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> chatHandlesRefs(
    Expression<bool> Function($$ChatHandlesTableFilterComposer f) f,
  ) {
    final $$ChatHandlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatHandles,
      getReferencedColumn: (t) => t.handleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatHandlesTableFilterComposer(
            $db: $db,
            $table: $db.chatHandles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> contactHandlesRefs(
    Expression<bool> Function($$ContactHandlesTableFilterComposer f) f,
  ) {
    final $$ContactHandlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contactHandles,
      getReferencedColumn: (t) => t.handleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactHandlesTableFilterComposer(
            $db: $db,
            $table: $db.contactHandles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HandlesTableOrderingComposer
    extends Composer<_$AppDatabase, $HandlesTable> {
  $$HandlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalRowid => $composableBuilder(
    column: $table.originalRowid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultPhone => $composableBuilder(
    column: $table.defaultPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultEmail => $composableBuilder(
    column: $table.defaultEmail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formattedAddress => $composableBuilder(
    column: $table.formattedAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uniqueAddressAndService => $composableBuilder(
    column: $table.uniqueAddressAndService,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get service => $composableBuilder(
    column: $table.service,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HandlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HandlesTable> {
  $$HandlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get originalRowid => $composableBuilder(
    column: $table.originalRowid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get defaultPhone => $composableBuilder(
    column: $table.defaultPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultEmail => $composableBuilder(
    column: $table.defaultEmail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get formattedAddress => $composableBuilder(
    column: $table.formattedAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get uniqueAddressAndService => $composableBuilder(
    column: $table.uniqueAddressAndService,
    builder: (column) => column,
  );

  GeneratedColumn<String> get service =>
      $composableBuilder(column: $table.service, builder: (column) => column);

  Expression<T> messagesRefs<T extends Object>(
    Expression<T> Function($$MessagesTableAnnotationComposer a) f,
  ) {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.handleRelationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> chatHandlesRefs<T extends Object>(
    Expression<T> Function($$ChatHandlesTableAnnotationComposer a) f,
  ) {
    final $$ChatHandlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chatHandles,
      getReferencedColumn: (t) => t.handleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatHandlesTableAnnotationComposer(
            $db: $db,
            $table: $db.chatHandles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> contactHandlesRefs<T extends Object>(
    Expression<T> Function($$ContactHandlesTableAnnotationComposer a) f,
  ) {
    final $$ContactHandlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contactHandles,
      getReferencedColumn: (t) => t.handleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactHandlesTableAnnotationComposer(
            $db: $db,
            $table: $db.contactHandles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HandlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HandlesTable,
          SqliteHandleRow,
          $$HandlesTableFilterComposer,
          $$HandlesTableOrderingComposer,
          $$HandlesTableAnnotationComposer,
          $$HandlesTableCreateCompanionBuilder,
          $$HandlesTableUpdateCompanionBuilder,
          (SqliteHandleRow, $$HandlesTableReferences),
          SqliteHandleRow,
          PrefetchHooks Function({
            bool messagesRefs,
            bool chatHandlesRefs,
            bool contactHandlesRefs,
          })
        > {
  $$HandlesTableTableManager(_$AppDatabase db, $HandlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HandlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HandlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HandlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> originalRowid = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> defaultPhone = const Value.absent(),
                Value<String?> defaultEmail = const Value.absent(),
                Value<String?> formattedAddress = const Value.absent(),
                Value<String> uniqueAddressAndService = const Value.absent(),
                Value<String> service = const Value.absent(),
              }) => HandlesCompanion(
                id: id,
                originalRowid: originalRowid,
                address: address,
                country: country,
                color: color,
                defaultPhone: defaultPhone,
                defaultEmail: defaultEmail,
                formattedAddress: formattedAddress,
                uniqueAddressAndService: uniqueAddressAndService,
                service: service,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> originalRowid = const Value.absent(),
                required String address,
                Value<String?> country = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> defaultPhone = const Value.absent(),
                Value<String?> defaultEmail = const Value.absent(),
                Value<String?> formattedAddress = const Value.absent(),
                required String uniqueAddressAndService,
                required String service,
              }) => HandlesCompanion.insert(
                id: id,
                originalRowid: originalRowid,
                address: address,
                country: country,
                color: color,
                defaultPhone: defaultPhone,
                defaultEmail: defaultEmail,
                formattedAddress: formattedAddress,
                uniqueAddressAndService: uniqueAddressAndService,
                service: service,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HandlesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                messagesRefs = false,
                chatHandlesRefs = false,
                contactHandlesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (messagesRefs) db.messages,
                    if (chatHandlesRefs) db.chatHandles,
                    if (contactHandlesRefs) db.contactHandles,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (messagesRefs)
                        await $_getPrefetchedData<
                          SqliteHandleRow,
                          $HandlesTable,
                          SqliteMessageRow
                        >(
                          currentTable: table,
                          referencedTable: $$HandlesTableReferences
                              ._messagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HandlesTableReferences(
                                db,
                                table,
                                p0,
                              ).messagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.handleRelationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (chatHandlesRefs)
                        await $_getPrefetchedData<
                          SqliteHandleRow,
                          $HandlesTable,
                          SqliteChatHandleRow
                        >(
                          currentTable: table,
                          referencedTable: $$HandlesTableReferences
                              ._chatHandlesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HandlesTableReferences(
                                db,
                                table,
                                p0,
                              ).chatHandlesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.handleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (contactHandlesRefs)
                        await $_getPrefetchedData<
                          SqliteHandleRow,
                          $HandlesTable,
                          SqliteContactHandleRow
                        >(
                          currentTable: table,
                          referencedTable: $$HandlesTableReferences
                              ._contactHandlesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HandlesTableReferences(
                                db,
                                table,
                                p0,
                              ).contactHandlesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.handleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$HandlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HandlesTable,
      SqliteHandleRow,
      $$HandlesTableFilterComposer,
      $$HandlesTableOrderingComposer,
      $$HandlesTableAnnotationComposer,
      $$HandlesTableCreateCompanionBuilder,
      $$HandlesTableUpdateCompanionBuilder,
      (SqliteHandleRow, $$HandlesTableReferences),
      SqliteHandleRow,
      PrefetchHooks Function({
        bool messagesRefs,
        bool chatHandlesRefs,
        bool contactHandlesRefs,
      })
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      Value<int?> originalRowid,
      Value<String?> guid,
      Value<int?> handleId,
      Value<int?> otherHandle,
      Value<String?> messageText,
      Value<String?> subject,
      Value<String?> country,
      Value<String?> service,
      Value<int?> dateCreatedUs,
      required int sortAtUs,
      Value<int?> dateReadUs,
      Value<int?> dateDeliveredUs,
      Value<bool?> isFromMe,
      Value<bool?> hasDdResults,
      Value<int?> datePlayedUs,
      Value<int?> itemType,
      Value<String?> groupTitle,
      Value<int?> groupActionType,
      Value<String?> balloonBundleId,
      Value<String?> associatedMessageGuid,
      Value<int?> associatedMessagePart,
      Value<String?> associatedMessageType,
      Value<String?> expressiveSendStyleId,
      required bool hasAttachments,
      required bool hasReactions,
      Value<int?> dateDeletedUs,
      Value<String?> threadOriginatorGuid,
      Value<String?> threadOriginatorPart,
      Value<bool?> bigEmoji,
      required int error,
      Value<int?> chatId,
      Value<String?> attributedBodyJson,
      Value<String?> messageSummaryInfoJson,
      Value<String?> payloadDataJson,
      Value<String?> metadataJson,
      required bool hasApplePayloadData,
      Value<int?> dateEditedUs,
      required bool wasDeliveredQuietly,
      required bool didNotifyRecipient,
      required bool isBookmarked,
      required bool isDelivered,
      Value<int?> handleRelationId,
      Value<String?> errorMessage,
      required bool hasEffectPlayed,
      Value<String?> appleChatGuid,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      Value<int?> originalRowid,
      Value<String?> guid,
      Value<int?> handleId,
      Value<int?> otherHandle,
      Value<String?> messageText,
      Value<String?> subject,
      Value<String?> country,
      Value<String?> service,
      Value<int?> dateCreatedUs,
      Value<int> sortAtUs,
      Value<int?> dateReadUs,
      Value<int?> dateDeliveredUs,
      Value<bool?> isFromMe,
      Value<bool?> hasDdResults,
      Value<int?> datePlayedUs,
      Value<int?> itemType,
      Value<String?> groupTitle,
      Value<int?> groupActionType,
      Value<String?> balloonBundleId,
      Value<String?> associatedMessageGuid,
      Value<int?> associatedMessagePart,
      Value<String?> associatedMessageType,
      Value<String?> expressiveSendStyleId,
      Value<bool> hasAttachments,
      Value<bool> hasReactions,
      Value<int?> dateDeletedUs,
      Value<String?> threadOriginatorGuid,
      Value<String?> threadOriginatorPart,
      Value<bool?> bigEmoji,
      Value<int> error,
      Value<int?> chatId,
      Value<String?> attributedBodyJson,
      Value<String?> messageSummaryInfoJson,
      Value<String?> payloadDataJson,
      Value<String?> metadataJson,
      Value<bool> hasApplePayloadData,
      Value<int?> dateEditedUs,
      Value<bool> wasDeliveredQuietly,
      Value<bool> didNotifyRecipient,
      Value<bool> isBookmarked,
      Value<bool> isDelivered,
      Value<int?> handleRelationId,
      Value<String?> errorMessage,
      Value<bool> hasEffectPlayed,
      Value<String?> appleChatGuid,
    });

final class $$MessagesTableReferences
    extends BaseReferences<_$AppDatabase, $MessagesTable, SqliteMessageRow> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChatsTable _chatIdTable(_$AppDatabase db) => db.chats.createAlias(
    $_aliasNameGenerator(db.messages.chatId, db.chats.id),
  );

  $$ChatsTableProcessedTableManager? get chatId {
    final $_column = $_itemColumn<int>('chat_id');
    if ($_column == null) return null;
    final manager = $$ChatsTableTableManager(
      $_db,
      $_db.chats,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chatIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $HandlesTable _handleRelationIdTable(_$AppDatabase db) =>
      db.handles.createAlias(
        $_aliasNameGenerator(db.messages.handleRelationId, db.handles.id),
      );

  $$HandlesTableProcessedTableManager? get handleRelationId {
    final $_column = $_itemColumn<int>('handle_relation_id');
    if ($_column == null) return null;
    final manager = $$HandlesTableTableManager(
      $_db,
      $_db.handles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_handleRelationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<SqliteAttachmentRow>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: $_aliasNameGenerator(db.messages.id, db.attachments.messageId),
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.messageId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalRowid => $composableBuilder(
    column: $table.originalRowid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get handleId => $composableBuilder(
    column: $table.handleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get otherHandle => $composableBuilder(
    column: $table.otherHandle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageText => $composableBuilder(
    column: $table.messageText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get service => $composableBuilder(
    column: $table.service,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateCreatedUs => $composableBuilder(
    column: $table.dateCreatedUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortAtUs => $composableBuilder(
    column: $table.sortAtUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateReadUs => $composableBuilder(
    column: $table.dateReadUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateDeliveredUs => $composableBuilder(
    column: $table.dateDeliveredUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFromMe => $composableBuilder(
    column: $table.isFromMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasDdResults => $composableBuilder(
    column: $table.hasDdResults,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get datePlayedUs => $composableBuilder(
    column: $table.datePlayedUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupTitle => $composableBuilder(
    column: $table.groupTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupActionType => $composableBuilder(
    column: $table.groupActionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get balloonBundleId => $composableBuilder(
    column: $table.balloonBundleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get associatedMessageGuid => $composableBuilder(
    column: $table.associatedMessageGuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get associatedMessagePart => $composableBuilder(
    column: $table.associatedMessagePart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get associatedMessageType => $composableBuilder(
    column: $table.associatedMessageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expressiveSendStyleId => $composableBuilder(
    column: $table.expressiveSendStyleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasAttachments => $composableBuilder(
    column: $table.hasAttachments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasReactions => $composableBuilder(
    column: $table.hasReactions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateDeletedUs => $composableBuilder(
    column: $table.dateDeletedUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadOriginatorGuid => $composableBuilder(
    column: $table.threadOriginatorGuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadOriginatorPart => $composableBuilder(
    column: $table.threadOriginatorPart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bigEmoji => $composableBuilder(
    column: $table.bigEmoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attributedBodyJson => $composableBuilder(
    column: $table.attributedBodyJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageSummaryInfoJson => $composableBuilder(
    column: $table.messageSummaryInfoJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadDataJson => $composableBuilder(
    column: $table.payloadDataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasApplePayloadData => $composableBuilder(
    column: $table.hasApplePayloadData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dateEditedUs => $composableBuilder(
    column: $table.dateEditedUs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasDeliveredQuietly => $composableBuilder(
    column: $table.wasDeliveredQuietly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get didNotifyRecipient => $composableBuilder(
    column: $table.didNotifyRecipient,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBookmarked => $composableBuilder(
    column: $table.isBookmarked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDelivered => $composableBuilder(
    column: $table.isDelivered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasEffectPlayed => $composableBuilder(
    column: $table.hasEffectPlayed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appleChatGuid => $composableBuilder(
    column: $table.appleChatGuid,
    builder: (column) => ColumnFilters(column),
  );

  $$ChatsTableFilterComposer get chatId {
    final $$ChatsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatId,
      referencedTable: $db.chats,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableFilterComposer(
            $db: $db,
            $table: $db.chats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HandlesTableFilterComposer get handleRelationId {
    final $$HandlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.handleRelationId,
      referencedTable: $db.handles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HandlesTableFilterComposer(
            $db: $db,
            $table: $db.handles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalRowid => $composableBuilder(
    column: $table.originalRowid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get handleId => $composableBuilder(
    column: $table.handleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get otherHandle => $composableBuilder(
    column: $table.otherHandle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageText => $composableBuilder(
    column: $table.messageText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get service => $composableBuilder(
    column: $table.service,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateCreatedUs => $composableBuilder(
    column: $table.dateCreatedUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortAtUs => $composableBuilder(
    column: $table.sortAtUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateReadUs => $composableBuilder(
    column: $table.dateReadUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateDeliveredUs => $composableBuilder(
    column: $table.dateDeliveredUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFromMe => $composableBuilder(
    column: $table.isFromMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasDdResults => $composableBuilder(
    column: $table.hasDdResults,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get datePlayedUs => $composableBuilder(
    column: $table.datePlayedUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupTitle => $composableBuilder(
    column: $table.groupTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupActionType => $composableBuilder(
    column: $table.groupActionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get balloonBundleId => $composableBuilder(
    column: $table.balloonBundleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get associatedMessageGuid => $composableBuilder(
    column: $table.associatedMessageGuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get associatedMessagePart => $composableBuilder(
    column: $table.associatedMessagePart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get associatedMessageType => $composableBuilder(
    column: $table.associatedMessageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expressiveSendStyleId => $composableBuilder(
    column: $table.expressiveSendStyleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasAttachments => $composableBuilder(
    column: $table.hasAttachments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasReactions => $composableBuilder(
    column: $table.hasReactions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateDeletedUs => $composableBuilder(
    column: $table.dateDeletedUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadOriginatorGuid => $composableBuilder(
    column: $table.threadOriginatorGuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadOriginatorPart => $composableBuilder(
    column: $table.threadOriginatorPart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bigEmoji => $composableBuilder(
    column: $table.bigEmoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attributedBodyJson => $composableBuilder(
    column: $table.attributedBodyJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageSummaryInfoJson => $composableBuilder(
    column: $table.messageSummaryInfoJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadDataJson => $composableBuilder(
    column: $table.payloadDataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasApplePayloadData => $composableBuilder(
    column: $table.hasApplePayloadData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dateEditedUs => $composableBuilder(
    column: $table.dateEditedUs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasDeliveredQuietly => $composableBuilder(
    column: $table.wasDeliveredQuietly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get didNotifyRecipient => $composableBuilder(
    column: $table.didNotifyRecipient,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBookmarked => $composableBuilder(
    column: $table.isBookmarked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDelivered => $composableBuilder(
    column: $table.isDelivered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasEffectPlayed => $composableBuilder(
    column: $table.hasEffectPlayed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appleChatGuid => $composableBuilder(
    column: $table.appleChatGuid,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChatsTableOrderingComposer get chatId {
    final $$ChatsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatId,
      referencedTable: $db.chats,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableOrderingComposer(
            $db: $db,
            $table: $db.chats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HandlesTableOrderingComposer get handleRelationId {
    final $$HandlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.handleRelationId,
      referencedTable: $db.handles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HandlesTableOrderingComposer(
            $db: $db,
            $table: $db.handles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get originalRowid => $composableBuilder(
    column: $table.originalRowid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get guid =>
      $composableBuilder(column: $table.guid, builder: (column) => column);

  GeneratedColumn<int> get handleId =>
      $composableBuilder(column: $table.handleId, builder: (column) => column);

  GeneratedColumn<int> get otherHandle => $composableBuilder(
    column: $table.otherHandle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get messageText => $composableBuilder(
    column: $table.messageText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get service =>
      $composableBuilder(column: $table.service, builder: (column) => column);

  GeneratedColumn<int> get dateCreatedUs => $composableBuilder(
    column: $table.dateCreatedUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortAtUs =>
      $composableBuilder(column: $table.sortAtUs, builder: (column) => column);

  GeneratedColumn<int> get dateReadUs => $composableBuilder(
    column: $table.dateReadUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dateDeliveredUs => $composableBuilder(
    column: $table.dateDeliveredUs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFromMe =>
      $composableBuilder(column: $table.isFromMe, builder: (column) => column);

  GeneratedColumn<bool> get hasDdResults => $composableBuilder(
    column: $table.hasDdResults,
    builder: (column) => column,
  );

  GeneratedColumn<int> get datePlayedUs => $composableBuilder(
    column: $table.datePlayedUs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get groupTitle => $composableBuilder(
    column: $table.groupTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get groupActionType => $composableBuilder(
    column: $table.groupActionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get balloonBundleId => $composableBuilder(
    column: $table.balloonBundleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get associatedMessageGuid => $composableBuilder(
    column: $table.associatedMessageGuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get associatedMessagePart => $composableBuilder(
    column: $table.associatedMessagePart,
    builder: (column) => column,
  );

  GeneratedColumn<String> get associatedMessageType => $composableBuilder(
    column: $table.associatedMessageType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expressiveSendStyleId => $composableBuilder(
    column: $table.expressiveSendStyleId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasAttachments => $composableBuilder(
    column: $table.hasAttachments,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasReactions => $composableBuilder(
    column: $table.hasReactions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dateDeletedUs => $composableBuilder(
    column: $table.dateDeletedUs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get threadOriginatorGuid => $composableBuilder(
    column: $table.threadOriginatorGuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get threadOriginatorPart => $composableBuilder(
    column: $table.threadOriginatorPart,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get bigEmoji =>
      $composableBuilder(column: $table.bigEmoji, builder: (column) => column);

  GeneratedColumn<int> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<String> get attributedBodyJson => $composableBuilder(
    column: $table.attributedBodyJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get messageSummaryInfoJson => $composableBuilder(
    column: $table.messageSummaryInfoJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadDataJson => $composableBuilder(
    column: $table.payloadDataJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasApplePayloadData => $composableBuilder(
    column: $table.hasApplePayloadData,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dateEditedUs => $composableBuilder(
    column: $table.dateEditedUs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wasDeliveredQuietly => $composableBuilder(
    column: $table.wasDeliveredQuietly,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get didNotifyRecipient => $composableBuilder(
    column: $table.didNotifyRecipient,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBookmarked => $composableBuilder(
    column: $table.isBookmarked,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDelivered => $composableBuilder(
    column: $table.isDelivered,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasEffectPlayed => $composableBuilder(
    column: $table.hasEffectPlayed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appleChatGuid => $composableBuilder(
    column: $table.appleChatGuid,
    builder: (column) => column,
  );

  $$ChatsTableAnnotationComposer get chatId {
    final $$ChatsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatId,
      referencedTable: $db.chats,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableAnnotationComposer(
            $db: $db,
            $table: $db.chats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HandlesTableAnnotationComposer get handleRelationId {
    final $$HandlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.handleRelationId,
      referencedTable: $db.handles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HandlesTableAnnotationComposer(
            $db: $db,
            $table: $db.handles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.messageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          SqliteMessageRow,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (SqliteMessageRow, $$MessagesTableReferences),
          SqliteMessageRow,
          PrefetchHooks Function({
            bool chatId,
            bool handleRelationId,
            bool attachmentsRefs,
          })
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> originalRowid = const Value.absent(),
                Value<String?> guid = const Value.absent(),
                Value<int?> handleId = const Value.absent(),
                Value<int?> otherHandle = const Value.absent(),
                Value<String?> messageText = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> service = const Value.absent(),
                Value<int?> dateCreatedUs = const Value.absent(),
                Value<int> sortAtUs = const Value.absent(),
                Value<int?> dateReadUs = const Value.absent(),
                Value<int?> dateDeliveredUs = const Value.absent(),
                Value<bool?> isFromMe = const Value.absent(),
                Value<bool?> hasDdResults = const Value.absent(),
                Value<int?> datePlayedUs = const Value.absent(),
                Value<int?> itemType = const Value.absent(),
                Value<String?> groupTitle = const Value.absent(),
                Value<int?> groupActionType = const Value.absent(),
                Value<String?> balloonBundleId = const Value.absent(),
                Value<String?> associatedMessageGuid = const Value.absent(),
                Value<int?> associatedMessagePart = const Value.absent(),
                Value<String?> associatedMessageType = const Value.absent(),
                Value<String?> expressiveSendStyleId = const Value.absent(),
                Value<bool> hasAttachments = const Value.absent(),
                Value<bool> hasReactions = const Value.absent(),
                Value<int?> dateDeletedUs = const Value.absent(),
                Value<String?> threadOriginatorGuid = const Value.absent(),
                Value<String?> threadOriginatorPart = const Value.absent(),
                Value<bool?> bigEmoji = const Value.absent(),
                Value<int> error = const Value.absent(),
                Value<int?> chatId = const Value.absent(),
                Value<String?> attributedBodyJson = const Value.absent(),
                Value<String?> messageSummaryInfoJson = const Value.absent(),
                Value<String?> payloadDataJson = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                Value<bool> hasApplePayloadData = const Value.absent(),
                Value<int?> dateEditedUs = const Value.absent(),
                Value<bool> wasDeliveredQuietly = const Value.absent(),
                Value<bool> didNotifyRecipient = const Value.absent(),
                Value<bool> isBookmarked = const Value.absent(),
                Value<bool> isDelivered = const Value.absent(),
                Value<int?> handleRelationId = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<bool> hasEffectPlayed = const Value.absent(),
                Value<String?> appleChatGuid = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                originalRowid: originalRowid,
                guid: guid,
                handleId: handleId,
                otherHandle: otherHandle,
                messageText: messageText,
                subject: subject,
                country: country,
                service: service,
                dateCreatedUs: dateCreatedUs,
                sortAtUs: sortAtUs,
                dateReadUs: dateReadUs,
                dateDeliveredUs: dateDeliveredUs,
                isFromMe: isFromMe,
                hasDdResults: hasDdResults,
                datePlayedUs: datePlayedUs,
                itemType: itemType,
                groupTitle: groupTitle,
                groupActionType: groupActionType,
                balloonBundleId: balloonBundleId,
                associatedMessageGuid: associatedMessageGuid,
                associatedMessagePart: associatedMessagePart,
                associatedMessageType: associatedMessageType,
                expressiveSendStyleId: expressiveSendStyleId,
                hasAttachments: hasAttachments,
                hasReactions: hasReactions,
                dateDeletedUs: dateDeletedUs,
                threadOriginatorGuid: threadOriginatorGuid,
                threadOriginatorPart: threadOriginatorPart,
                bigEmoji: bigEmoji,
                error: error,
                chatId: chatId,
                attributedBodyJson: attributedBodyJson,
                messageSummaryInfoJson: messageSummaryInfoJson,
                payloadDataJson: payloadDataJson,
                metadataJson: metadataJson,
                hasApplePayloadData: hasApplePayloadData,
                dateEditedUs: dateEditedUs,
                wasDeliveredQuietly: wasDeliveredQuietly,
                didNotifyRecipient: didNotifyRecipient,
                isBookmarked: isBookmarked,
                isDelivered: isDelivered,
                handleRelationId: handleRelationId,
                errorMessage: errorMessage,
                hasEffectPlayed: hasEffectPlayed,
                appleChatGuid: appleChatGuid,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> originalRowid = const Value.absent(),
                Value<String?> guid = const Value.absent(),
                Value<int?> handleId = const Value.absent(),
                Value<int?> otherHandle = const Value.absent(),
                Value<String?> messageText = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> service = const Value.absent(),
                Value<int?> dateCreatedUs = const Value.absent(),
                required int sortAtUs,
                Value<int?> dateReadUs = const Value.absent(),
                Value<int?> dateDeliveredUs = const Value.absent(),
                Value<bool?> isFromMe = const Value.absent(),
                Value<bool?> hasDdResults = const Value.absent(),
                Value<int?> datePlayedUs = const Value.absent(),
                Value<int?> itemType = const Value.absent(),
                Value<String?> groupTitle = const Value.absent(),
                Value<int?> groupActionType = const Value.absent(),
                Value<String?> balloonBundleId = const Value.absent(),
                Value<String?> associatedMessageGuid = const Value.absent(),
                Value<int?> associatedMessagePart = const Value.absent(),
                Value<String?> associatedMessageType = const Value.absent(),
                Value<String?> expressiveSendStyleId = const Value.absent(),
                required bool hasAttachments,
                required bool hasReactions,
                Value<int?> dateDeletedUs = const Value.absent(),
                Value<String?> threadOriginatorGuid = const Value.absent(),
                Value<String?> threadOriginatorPart = const Value.absent(),
                Value<bool?> bigEmoji = const Value.absent(),
                required int error,
                Value<int?> chatId = const Value.absent(),
                Value<String?> attributedBodyJson = const Value.absent(),
                Value<String?> messageSummaryInfoJson = const Value.absent(),
                Value<String?> payloadDataJson = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                required bool hasApplePayloadData,
                Value<int?> dateEditedUs = const Value.absent(),
                required bool wasDeliveredQuietly,
                required bool didNotifyRecipient,
                required bool isBookmarked,
                required bool isDelivered,
                Value<int?> handleRelationId = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                required bool hasEffectPlayed,
                Value<String?> appleChatGuid = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                originalRowid: originalRowid,
                guid: guid,
                handleId: handleId,
                otherHandle: otherHandle,
                messageText: messageText,
                subject: subject,
                country: country,
                service: service,
                dateCreatedUs: dateCreatedUs,
                sortAtUs: sortAtUs,
                dateReadUs: dateReadUs,
                dateDeliveredUs: dateDeliveredUs,
                isFromMe: isFromMe,
                hasDdResults: hasDdResults,
                datePlayedUs: datePlayedUs,
                itemType: itemType,
                groupTitle: groupTitle,
                groupActionType: groupActionType,
                balloonBundleId: balloonBundleId,
                associatedMessageGuid: associatedMessageGuid,
                associatedMessagePart: associatedMessagePart,
                associatedMessageType: associatedMessageType,
                expressiveSendStyleId: expressiveSendStyleId,
                hasAttachments: hasAttachments,
                hasReactions: hasReactions,
                dateDeletedUs: dateDeletedUs,
                threadOriginatorGuid: threadOriginatorGuid,
                threadOriginatorPart: threadOriginatorPart,
                bigEmoji: bigEmoji,
                error: error,
                chatId: chatId,
                attributedBodyJson: attributedBodyJson,
                messageSummaryInfoJson: messageSummaryInfoJson,
                payloadDataJson: payloadDataJson,
                metadataJson: metadataJson,
                hasApplePayloadData: hasApplePayloadData,
                dateEditedUs: dateEditedUs,
                wasDeliveredQuietly: wasDeliveredQuietly,
                didNotifyRecipient: didNotifyRecipient,
                isBookmarked: isBookmarked,
                isDelivered: isDelivered,
                handleRelationId: handleRelationId,
                errorMessage: errorMessage,
                hasEffectPlayed: hasEffectPlayed,
                appleChatGuid: appleChatGuid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                chatId = false,
                handleRelationId = false,
                attachmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (attachmentsRefs) db.attachments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (chatId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.chatId,
                                    referencedTable: $$MessagesTableReferences
                                        ._chatIdTable(db),
                                    referencedColumn: $$MessagesTableReferences
                                        ._chatIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (handleRelationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.handleRelationId,
                                    referencedTable: $$MessagesTableReferences
                                        ._handleRelationIdTable(db),
                                    referencedColumn: $$MessagesTableReferences
                                        ._handleRelationIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (attachmentsRefs)
                        await $_getPrefetchedData<
                          SqliteMessageRow,
                          $MessagesTable,
                          SqliteAttachmentRow
                        >(
                          currentTable: table,
                          referencedTable: $$MessagesTableReferences
                              ._attachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MessagesTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.messageId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      SqliteMessageRow,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (SqliteMessageRow, $$MessagesTableReferences),
      SqliteMessageRow,
      PrefetchHooks Function({
        bool chatId,
        bool handleRelationId,
        bool attachmentsRefs,
      })
    >;
typedef $$ChatHandlesTableCreateCompanionBuilder =
    ChatHandlesCompanion Function({required int chatId, required int handleId});
typedef $$ChatHandlesTableUpdateCompanionBuilder =
    ChatHandlesCompanion Function({Value<int> chatId, Value<int> handleId});

final class $$ChatHandlesTableReferences
    extends
        BaseReferences<_$AppDatabase, $ChatHandlesTable, SqliteChatHandleRow> {
  $$ChatHandlesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChatsTable _chatIdTable(_$AppDatabase db) => db.chats.createAlias(
    $_aliasNameGenerator(db.chatHandles.chatId, db.chats.id),
  );

  $$ChatsTableProcessedTableManager get chatId {
    final $_column = $_itemColumn<int>('chat_id')!;

    final manager = $$ChatsTableTableManager(
      $_db,
      $_db.chats,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chatIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $HandlesTable _handleIdTable(_$AppDatabase db) =>
      db.handles.createAlias(
        $_aliasNameGenerator(db.chatHandles.handleId, db.handles.id),
      );

  $$HandlesTableProcessedTableManager get handleId {
    final $_column = $_itemColumn<int>('handle_id')!;

    final manager = $$HandlesTableTableManager(
      $_db,
      $_db.handles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_handleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChatHandlesTableFilterComposer
    extends Composer<_$AppDatabase, $ChatHandlesTable> {
  $$ChatHandlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ChatsTableFilterComposer get chatId {
    final $$ChatsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatId,
      referencedTable: $db.chats,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableFilterComposer(
            $db: $db,
            $table: $db.chats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HandlesTableFilterComposer get handleId {
    final $$HandlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.handleId,
      referencedTable: $db.handles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HandlesTableFilterComposer(
            $db: $db,
            $table: $db.handles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatHandlesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatHandlesTable> {
  $$ChatHandlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ChatsTableOrderingComposer get chatId {
    final $$ChatsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatId,
      referencedTable: $db.chats,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableOrderingComposer(
            $db: $db,
            $table: $db.chats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HandlesTableOrderingComposer get handleId {
    final $$HandlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.handleId,
      referencedTable: $db.handles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HandlesTableOrderingComposer(
            $db: $db,
            $table: $db.handles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatHandlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatHandlesTable> {
  $$ChatHandlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ChatsTableAnnotationComposer get chatId {
    final $$ChatsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatId,
      referencedTable: $db.chats,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableAnnotationComposer(
            $db: $db,
            $table: $db.chats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HandlesTableAnnotationComposer get handleId {
    final $$HandlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.handleId,
      referencedTable: $db.handles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HandlesTableAnnotationComposer(
            $db: $db,
            $table: $db.handles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChatHandlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatHandlesTable,
          SqliteChatHandleRow,
          $$ChatHandlesTableFilterComposer,
          $$ChatHandlesTableOrderingComposer,
          $$ChatHandlesTableAnnotationComposer,
          $$ChatHandlesTableCreateCompanionBuilder,
          $$ChatHandlesTableUpdateCompanionBuilder,
          (SqliteChatHandleRow, $$ChatHandlesTableReferences),
          SqliteChatHandleRow,
          PrefetchHooks Function({bool chatId, bool handleId})
        > {
  $$ChatHandlesTableTableManager(_$AppDatabase db, $ChatHandlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatHandlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatHandlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatHandlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> chatId = const Value.absent(),
                Value<int> handleId = const Value.absent(),
              }) => ChatHandlesCompanion(chatId: chatId, handleId: handleId),
          createCompanionCallback:
              ({required int chatId, required int handleId}) =>
                  ChatHandlesCompanion.insert(
                    chatId: chatId,
                    handleId: handleId,
                  ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChatHandlesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({chatId = false, handleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (chatId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.chatId,
                                referencedTable: $$ChatHandlesTableReferences
                                    ._chatIdTable(db),
                                referencedColumn: $$ChatHandlesTableReferences
                                    ._chatIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (handleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.handleId,
                                referencedTable: $$ChatHandlesTableReferences
                                    ._handleIdTable(db),
                                referencedColumn: $$ChatHandlesTableReferences
                                    ._handleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChatHandlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatHandlesTable,
      SqliteChatHandleRow,
      $$ChatHandlesTableFilterComposer,
      $$ChatHandlesTableOrderingComposer,
      $$ChatHandlesTableAnnotationComposer,
      $$ChatHandlesTableCreateCompanionBuilder,
      $$ChatHandlesTableUpdateCompanionBuilder,
      (SqliteChatHandleRow, $$ChatHandlesTableReferences),
      SqliteChatHandleRow,
      PrefetchHooks Function({bool chatId, bool handleId})
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<int> id,
      Value<int?> originalRowid,
      Value<String?> guid,
      Value<String?> uti,
      Value<String?> mimeType,
      Value<bool?> isOutgoing,
      Value<String?> transferName,
      Value<int?> totalBytes,
      Value<int?> height,
      Value<int?> width,
      Value<String?> webUrl,
      Value<int?> messageId,
      required bool hasLivePhoto,
      required bool isDownloaded,
      Value<String?> metadataJson,
      Value<String?> exifJson,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<int> id,
      Value<int?> originalRowid,
      Value<String?> guid,
      Value<String?> uti,
      Value<String?> mimeType,
      Value<bool?> isOutgoing,
      Value<String?> transferName,
      Value<int?> totalBytes,
      Value<int?> height,
      Value<int?> width,
      Value<String?> webUrl,
      Value<int?> messageId,
      Value<bool> hasLivePhoto,
      Value<bool> isDownloaded,
      Value<String?> metadataJson,
      Value<String?> exifJson,
    });

final class $$AttachmentsTableReferences
    extends
        BaseReferences<_$AppDatabase, $AttachmentsTable, SqliteAttachmentRow> {
  $$AttachmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MessagesTable _messageIdTable(_$AppDatabase db) =>
      db.messages.createAlias(
        $_aliasNameGenerator(db.attachments.messageId, db.messages.id),
      );

  $$MessagesTableProcessedTableManager? get messageId {
    final $_column = $_itemColumn<int>('message_id');
    if ($_column == null) return null;
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_messageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalRowid => $composableBuilder(
    column: $table.originalRowid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uti => $composableBuilder(
    column: $table.uti,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferName => $composableBuilder(
    column: $table.transferName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get webUrl => $composableBuilder(
    column: $table.webUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasLivePhoto => $composableBuilder(
    column: $table.hasLivePhoto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exifJson => $composableBuilder(
    column: $table.exifJson,
    builder: (column) => ColumnFilters(column),
  );

  $$MessagesTableFilterComposer get messageId {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableFilterComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalRowid => $composableBuilder(
    column: $table.originalRowid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uti => $composableBuilder(
    column: $table.uti,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferName => $composableBuilder(
    column: $table.transferName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get webUrl => $composableBuilder(
    column: $table.webUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasLivePhoto => $composableBuilder(
    column: $table.hasLivePhoto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exifJson => $composableBuilder(
    column: $table.exifJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$MessagesTableOrderingComposer get messageId {
    final $$MessagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableOrderingComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get originalRowid => $composableBuilder(
    column: $table.originalRowid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get guid =>
      $composableBuilder(column: $table.guid, builder: (column) => column);

  GeneratedColumn<String> get uti =>
      $composableBuilder(column: $table.uti, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transferName => $composableBuilder(
    column: $table.transferName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<String> get webUrl =>
      $composableBuilder(column: $table.webUrl, builder: (column) => column);

  GeneratedColumn<bool> get hasLivePhoto => $composableBuilder(
    column: $table.hasLivePhoto,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exifJson =>
      $composableBuilder(column: $table.exifJson, builder: (column) => column);

  $$MessagesTableAnnotationComposer get messageId {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.messageId,
      referencedTable: $db.messages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MessagesTableAnnotationComposer(
            $db: $db,
            $table: $db.messages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          SqliteAttachmentRow,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (SqliteAttachmentRow, $$AttachmentsTableReferences),
          SqliteAttachmentRow,
          PrefetchHooks Function({bool messageId})
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> originalRowid = const Value.absent(),
                Value<String?> guid = const Value.absent(),
                Value<String?> uti = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<bool?> isOutgoing = const Value.absent(),
                Value<String?> transferName = const Value.absent(),
                Value<int?> totalBytes = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<String?> webUrl = const Value.absent(),
                Value<int?> messageId = const Value.absent(),
                Value<bool> hasLivePhoto = const Value.absent(),
                Value<bool> isDownloaded = const Value.absent(),
                Value<String?> metadataJson = const Value.absent(),
                Value<String?> exifJson = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                originalRowid: originalRowid,
                guid: guid,
                uti: uti,
                mimeType: mimeType,
                isOutgoing: isOutgoing,
                transferName: transferName,
                totalBytes: totalBytes,
                height: height,
                width: width,
                webUrl: webUrl,
                messageId: messageId,
                hasLivePhoto: hasLivePhoto,
                isDownloaded: isDownloaded,
                metadataJson: metadataJson,
                exifJson: exifJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> originalRowid = const Value.absent(),
                Value<String?> guid = const Value.absent(),
                Value<String?> uti = const Value.absent(),
                Value<String?> mimeType = const Value.absent(),
                Value<bool?> isOutgoing = const Value.absent(),
                Value<String?> transferName = const Value.absent(),
                Value<int?> totalBytes = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<String?> webUrl = const Value.absent(),
                Value<int?> messageId = const Value.absent(),
                required bool hasLivePhoto,
                required bool isDownloaded,
                Value<String?> metadataJson = const Value.absent(),
                Value<String?> exifJson = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                originalRowid: originalRowid,
                guid: guid,
                uti: uti,
                mimeType: mimeType,
                isOutgoing: isOutgoing,
                transferName: transferName,
                totalBytes: totalBytes,
                height: height,
                width: width,
                webUrl: webUrl,
                messageId: messageId,
                hasLivePhoto: hasLivePhoto,
                isDownloaded: isDownloaded,
                metadataJson: metadataJson,
                exifJson: exifJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({messageId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (messageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.messageId,
                                referencedTable: $$AttachmentsTableReferences
                                    ._messageIdTable(db),
                                referencedColumn: $$AttachmentsTableReferences
                                    ._messageIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      SqliteAttachmentRow,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (SqliteAttachmentRow, $$AttachmentsTableReferences),
      SqliteAttachmentRow,
      PrefetchHooks Function({bool messageId})
    >;
typedef $$ContactsTableCreateCompanionBuilder =
    ContactsCompanion Function({
      Value<int> id,
      required String displayName,
      required String nativeContactId,
      Value<String?> avatarPath,
      required String addressesJson,
      Value<String?> nickname,
      Value<String?> firstName,
      Value<String?> lastName,
      Value<String?> middleName,
      Value<String?> namePrefix,
      Value<String?> nameSuffix,
      Value<String?> company,
      Value<String?> phoneNumbersJson,
      Value<String?> emailAddressesJson,
      required bool isNative,
    });
typedef $$ContactsTableUpdateCompanionBuilder =
    ContactsCompanion Function({
      Value<int> id,
      Value<String> displayName,
      Value<String> nativeContactId,
      Value<String?> avatarPath,
      Value<String> addressesJson,
      Value<String?> nickname,
      Value<String?> firstName,
      Value<String?> lastName,
      Value<String?> middleName,
      Value<String?> namePrefix,
      Value<String?> nameSuffix,
      Value<String?> company,
      Value<String?> phoneNumbersJson,
      Value<String?> emailAddressesJson,
      Value<bool> isNative,
    });

final class $$ContactsTableReferences
    extends BaseReferences<_$AppDatabase, $ContactsTable, SqliteContactRow> {
  $$ContactsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ContactHandlesTable, List<SqliteContactHandleRow>>
  _contactHandlesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.contactHandles,
    aliasName: $_aliasNameGenerator(
      db.contacts.id,
      db.contactHandles.contactId,
    ),
  );

  $$ContactHandlesTableProcessedTableManager get contactHandlesRefs {
    final manager = $$ContactHandlesTableTableManager(
      $_db,
      $_db.contactHandles,
    ).filter((f) => f.contactId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_contactHandlesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContactsTableFilterComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nativeContactId => $composableBuilder(
    column: $table.nativeContactId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addressesJson => $composableBuilder(
    column: $table.addressesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get middleName => $composableBuilder(
    column: $table.middleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namePrefix => $composableBuilder(
    column: $table.namePrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameSuffix => $composableBuilder(
    column: $table.nameSuffix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumbersJson => $composableBuilder(
    column: $table.phoneNumbersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emailAddressesJson => $composableBuilder(
    column: $table.emailAddressesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isNative => $composableBuilder(
    column: $table.isNative,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> contactHandlesRefs(
    Expression<bool> Function($$ContactHandlesTableFilterComposer f) f,
  ) {
    final $$ContactHandlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contactHandles,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactHandlesTableFilterComposer(
            $db: $db,
            $table: $db.contactHandles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContactsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nativeContactId => $composableBuilder(
    column: $table.nativeContactId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addressesJson => $composableBuilder(
    column: $table.addressesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get middleName => $composableBuilder(
    column: $table.middleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namePrefix => $composableBuilder(
    column: $table.namePrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameSuffix => $composableBuilder(
    column: $table.nameSuffix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get company => $composableBuilder(
    column: $table.company,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumbersJson => $composableBuilder(
    column: $table.phoneNumbersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emailAddressesJson => $composableBuilder(
    column: $table.emailAddressesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isNative => $composableBuilder(
    column: $table.isNative,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContactsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactsTable> {
  $$ContactsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nativeContactId => $composableBuilder(
    column: $table.nativeContactId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get addressesJson => $composableBuilder(
    column: $table.addressesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get middleName => $composableBuilder(
    column: $table.middleName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get namePrefix => $composableBuilder(
    column: $table.namePrefix,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nameSuffix => $composableBuilder(
    column: $table.nameSuffix,
    builder: (column) => column,
  );

  GeneratedColumn<String> get company =>
      $composableBuilder(column: $table.company, builder: (column) => column);

  GeneratedColumn<String> get phoneNumbersJson => $composableBuilder(
    column: $table.phoneNumbersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emailAddressesJson => $composableBuilder(
    column: $table.emailAddressesJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isNative =>
      $composableBuilder(column: $table.isNative, builder: (column) => column);

  Expression<T> contactHandlesRefs<T extends Object>(
    Expression<T> Function($$ContactHandlesTableAnnotationComposer a) f,
  ) {
    final $$ContactHandlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contactHandles,
      getReferencedColumn: (t) => t.contactId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactHandlesTableAnnotationComposer(
            $db: $db,
            $table: $db.contactHandles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContactsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactsTable,
          SqliteContactRow,
          $$ContactsTableFilterComposer,
          $$ContactsTableOrderingComposer,
          $$ContactsTableAnnotationComposer,
          $$ContactsTableCreateCompanionBuilder,
          $$ContactsTableUpdateCompanionBuilder,
          (SqliteContactRow, $$ContactsTableReferences),
          SqliteContactRow,
          PrefetchHooks Function({bool contactHandlesRefs})
        > {
  $$ContactsTableTableManager(_$AppDatabase db, $ContactsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> nativeContactId = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                Value<String> addressesJson = const Value.absent(),
                Value<String?> nickname = const Value.absent(),
                Value<String?> firstName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                Value<String?> middleName = const Value.absent(),
                Value<String?> namePrefix = const Value.absent(),
                Value<String?> nameSuffix = const Value.absent(),
                Value<String?> company = const Value.absent(),
                Value<String?> phoneNumbersJson = const Value.absent(),
                Value<String?> emailAddressesJson = const Value.absent(),
                Value<bool> isNative = const Value.absent(),
              }) => ContactsCompanion(
                id: id,
                displayName: displayName,
                nativeContactId: nativeContactId,
                avatarPath: avatarPath,
                addressesJson: addressesJson,
                nickname: nickname,
                firstName: firstName,
                lastName: lastName,
                middleName: middleName,
                namePrefix: namePrefix,
                nameSuffix: nameSuffix,
                company: company,
                phoneNumbersJson: phoneNumbersJson,
                emailAddressesJson: emailAddressesJson,
                isNative: isNative,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String displayName,
                required String nativeContactId,
                Value<String?> avatarPath = const Value.absent(),
                required String addressesJson,
                Value<String?> nickname = const Value.absent(),
                Value<String?> firstName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                Value<String?> middleName = const Value.absent(),
                Value<String?> namePrefix = const Value.absent(),
                Value<String?> nameSuffix = const Value.absent(),
                Value<String?> company = const Value.absent(),
                Value<String?> phoneNumbersJson = const Value.absent(),
                Value<String?> emailAddressesJson = const Value.absent(),
                required bool isNative,
              }) => ContactsCompanion.insert(
                id: id,
                displayName: displayName,
                nativeContactId: nativeContactId,
                avatarPath: avatarPath,
                addressesJson: addressesJson,
                nickname: nickname,
                firstName: firstName,
                lastName: lastName,
                middleName: middleName,
                namePrefix: namePrefix,
                nameSuffix: nameSuffix,
                company: company,
                phoneNumbersJson: phoneNumbersJson,
                emailAddressesJson: emailAddressesJson,
                isNative: isNative,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ContactsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({contactHandlesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (contactHandlesRefs) db.contactHandles,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (contactHandlesRefs)
                    await $_getPrefetchedData<
                      SqliteContactRow,
                      $ContactsTable,
                      SqliteContactHandleRow
                    >(
                      currentTable: table,
                      referencedTable: $$ContactsTableReferences
                          ._contactHandlesRefsTable(db),
                      managerFromTypedResult: (p0) => $$ContactsTableReferences(
                        db,
                        table,
                        p0,
                      ).contactHandlesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.contactId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ContactsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactsTable,
      SqliteContactRow,
      $$ContactsTableFilterComposer,
      $$ContactsTableOrderingComposer,
      $$ContactsTableAnnotationComposer,
      $$ContactsTableCreateCompanionBuilder,
      $$ContactsTableUpdateCompanionBuilder,
      (SqliteContactRow, $$ContactsTableReferences),
      SqliteContactRow,
      PrefetchHooks Function({bool contactHandlesRefs})
    >;
typedef $$ContactHandlesTableCreateCompanionBuilder =
    ContactHandlesCompanion Function({
      required int contactId,
      required int handleId,
    });
typedef $$ContactHandlesTableUpdateCompanionBuilder =
    ContactHandlesCompanion Function({
      Value<int> contactId,
      Value<int> handleId,
    });

final class $$ContactHandlesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ContactHandlesTable,
          SqliteContactHandleRow
        > {
  $$ContactHandlesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ContactsTable _contactIdTable(_$AppDatabase db) =>
      db.contacts.createAlias(
        $_aliasNameGenerator(db.contactHandles.contactId, db.contacts.id),
      );

  $$ContactsTableProcessedTableManager get contactId {
    final $_column = $_itemColumn<int>('contact_id')!;

    final manager = $$ContactsTableTableManager(
      $_db,
      $_db.contacts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contactIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $HandlesTable _handleIdTable(_$AppDatabase db) =>
      db.handles.createAlias(
        $_aliasNameGenerator(db.contactHandles.handleId, db.handles.id),
      );

  $$HandlesTableProcessedTableManager get handleId {
    final $_column = $_itemColumn<int>('handle_id')!;

    final manager = $$HandlesTableTableManager(
      $_db,
      $_db.handles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_handleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ContactHandlesTableFilterComposer
    extends Composer<_$AppDatabase, $ContactHandlesTable> {
  $$ContactHandlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ContactsTableFilterComposer get contactId {
    final $$ContactsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableFilterComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HandlesTableFilterComposer get handleId {
    final $$HandlesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.handleId,
      referencedTable: $db.handles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HandlesTableFilterComposer(
            $db: $db,
            $table: $db.handles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactHandlesTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactHandlesTable> {
  $$ContactHandlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ContactsTableOrderingComposer get contactId {
    final $$ContactsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableOrderingComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HandlesTableOrderingComposer get handleId {
    final $$HandlesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.handleId,
      referencedTable: $db.handles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HandlesTableOrderingComposer(
            $db: $db,
            $table: $db.handles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactHandlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactHandlesTable> {
  $$ContactHandlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ContactsTableAnnotationComposer get contactId {
    final $$ContactsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contactId,
      referencedTable: $db.contacts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactsTableAnnotationComposer(
            $db: $db,
            $table: $db.contacts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HandlesTableAnnotationComposer get handleId {
    final $$HandlesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.handleId,
      referencedTable: $db.handles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HandlesTableAnnotationComposer(
            $db: $db,
            $table: $db.handles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactHandlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactHandlesTable,
          SqliteContactHandleRow,
          $$ContactHandlesTableFilterComposer,
          $$ContactHandlesTableOrderingComposer,
          $$ContactHandlesTableAnnotationComposer,
          $$ContactHandlesTableCreateCompanionBuilder,
          $$ContactHandlesTableUpdateCompanionBuilder,
          (SqliteContactHandleRow, $$ContactHandlesTableReferences),
          SqliteContactHandleRow,
          PrefetchHooks Function({bool contactId, bool handleId})
        > {
  $$ContactHandlesTableTableManager(
    _$AppDatabase db,
    $ContactHandlesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactHandlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactHandlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactHandlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> contactId = const Value.absent(),
                Value<int> handleId = const Value.absent(),
              }) => ContactHandlesCompanion(
                contactId: contactId,
                handleId: handleId,
              ),
          createCompanionCallback:
              ({required int contactId, required int handleId}) =>
                  ContactHandlesCompanion.insert(
                    contactId: contactId,
                    handleId: handleId,
                  ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ContactHandlesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({contactId = false, handleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (contactId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.contactId,
                                referencedTable: $$ContactHandlesTableReferences
                                    ._contactIdTable(db),
                                referencedColumn:
                                    $$ContactHandlesTableReferences
                                        ._contactIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (handleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.handleId,
                                referencedTable: $$ContactHandlesTableReferences
                                    ._handleIdTable(db),
                                referencedColumn:
                                    $$ContactHandlesTableReferences
                                        ._handleIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ContactHandlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactHandlesTable,
      SqliteContactHandleRow,
      $$ContactHandlesTableFilterComposer,
      $$ContactHandlesTableOrderingComposer,
      $$ContactHandlesTableAnnotationComposer,
      $$ContactHandlesTableCreateCompanionBuilder,
      $$ContactHandlesTableUpdateCompanionBuilder,
      (SqliteContactHandleRow, $$ContactHandlesTableReferences),
      SqliteContactHandleRow,
      PrefetchHooks Function({bool contactId, bool handleId})
    >;
typedef $$CustomGroupsTableCreateCompanionBuilder =
    CustomGroupsCompanion Function({
      Value<int> id,
      required String name,
      required int sortOrder,
      required bool showUnreadBadge,
    });
typedef $$CustomGroupsTableUpdateCompanionBuilder =
    CustomGroupsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> sortOrder,
      Value<bool> showUnreadBadge,
    });

final class $$CustomGroupsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CustomGroupsTable,
          SqliteCustomGroupRow
        > {
  $$CustomGroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $CustomGroupChatsTable,
    List<SqliteCustomGroupChatRow>
  >
  _customGroupChatsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.customGroupChats,
    aliasName: $_aliasNameGenerator(
      db.customGroups.id,
      db.customGroupChats.groupId,
    ),
  );

  $$CustomGroupChatsTableProcessedTableManager get customGroupChatsRefs {
    final manager = $$CustomGroupChatsTableTableManager(
      $_db,
      $_db.customGroupChats,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _customGroupChatsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CustomGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomGroupsTable> {
  $$CustomGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showUnreadBadge => $composableBuilder(
    column: $table.showUnreadBadge,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> customGroupChatsRefs(
    Expression<bool> Function($$CustomGroupChatsTableFilterComposer f) f,
  ) {
    final $$CustomGroupChatsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customGroupChats,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomGroupChatsTableFilterComposer(
            $db: $db,
            $table: $db.customGroupChats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomGroupsTable> {
  $$CustomGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showUnreadBadge => $composableBuilder(
    column: $table.showUnreadBadge,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomGroupsTable> {
  $$CustomGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get showUnreadBadge => $composableBuilder(
    column: $table.showUnreadBadge,
    builder: (column) => column,
  );

  Expression<T> customGroupChatsRefs<T extends Object>(
    Expression<T> Function($$CustomGroupChatsTableAnnotationComposer a) f,
  ) {
    final $$CustomGroupChatsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customGroupChats,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomGroupChatsTableAnnotationComposer(
            $db: $db,
            $table: $db.customGroupChats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CustomGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomGroupsTable,
          SqliteCustomGroupRow,
          $$CustomGroupsTableFilterComposer,
          $$CustomGroupsTableOrderingComposer,
          $$CustomGroupsTableAnnotationComposer,
          $$CustomGroupsTableCreateCompanionBuilder,
          $$CustomGroupsTableUpdateCompanionBuilder,
          (SqliteCustomGroupRow, $$CustomGroupsTableReferences),
          SqliteCustomGroupRow,
          PrefetchHooks Function({bool customGroupChatsRefs})
        > {
  $$CustomGroupsTableTableManager(_$AppDatabase db, $CustomGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> showUnreadBadge = const Value.absent(),
              }) => CustomGroupsCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                showUnreadBadge: showUnreadBadge,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int sortOrder,
                required bool showUnreadBadge,
              }) => CustomGroupsCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                showUnreadBadge: showUnreadBadge,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({customGroupChatsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (customGroupChatsRefs) db.customGroupChats,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (customGroupChatsRefs)
                    await $_getPrefetchedData<
                      SqliteCustomGroupRow,
                      $CustomGroupsTable,
                      SqliteCustomGroupChatRow
                    >(
                      currentTable: table,
                      referencedTable: $$CustomGroupsTableReferences
                          ._customGroupChatsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CustomGroupsTableReferences(
                            db,
                            table,
                            p0,
                          ).customGroupChatsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.groupId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CustomGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomGroupsTable,
      SqliteCustomGroupRow,
      $$CustomGroupsTableFilterComposer,
      $$CustomGroupsTableOrderingComposer,
      $$CustomGroupsTableAnnotationComposer,
      $$CustomGroupsTableCreateCompanionBuilder,
      $$CustomGroupsTableUpdateCompanionBuilder,
      (SqliteCustomGroupRow, $$CustomGroupsTableReferences),
      SqliteCustomGroupRow,
      PrefetchHooks Function({bool customGroupChatsRefs})
    >;
typedef $$CustomGroupChatsTableCreateCompanionBuilder =
    CustomGroupChatsCompanion Function({
      required int groupId,
      required int chatId,
    });
typedef $$CustomGroupChatsTableUpdateCompanionBuilder =
    CustomGroupChatsCompanion Function({Value<int> groupId, Value<int> chatId});

final class $$CustomGroupChatsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CustomGroupChatsTable,
          SqliteCustomGroupChatRow
        > {
  $$CustomGroupChatsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CustomGroupsTable _groupIdTable(_$AppDatabase db) =>
      db.customGroups.createAlias(
        $_aliasNameGenerator(db.customGroupChats.groupId, db.customGroups.id),
      );

  $$CustomGroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<int>('group_id')!;

    final manager = $$CustomGroupsTableTableManager(
      $_db,
      $_db.customGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChatsTable _chatIdTable(_$AppDatabase db) => db.chats.createAlias(
    $_aliasNameGenerator(db.customGroupChats.chatId, db.chats.id),
  );

  $$ChatsTableProcessedTableManager get chatId {
    final $_column = $_itemColumn<int>('chat_id')!;

    final manager = $$ChatsTableTableManager(
      $_db,
      $_db.chats,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chatIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CustomGroupChatsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomGroupChatsTable> {
  $$CustomGroupChatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CustomGroupsTableFilterComposer get groupId {
    final $$CustomGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.customGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomGroupsTableFilterComposer(
            $db: $db,
            $table: $db.customGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChatsTableFilterComposer get chatId {
    final $$ChatsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatId,
      referencedTable: $db.chats,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableFilterComposer(
            $db: $db,
            $table: $db.chats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomGroupChatsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomGroupChatsTable> {
  $$CustomGroupChatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CustomGroupsTableOrderingComposer get groupId {
    final $$CustomGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.customGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.customGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChatsTableOrderingComposer get chatId {
    final $$ChatsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatId,
      referencedTable: $db.chats,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableOrderingComposer(
            $db: $db,
            $table: $db.chats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomGroupChatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomGroupChatsTable> {
  $$CustomGroupChatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CustomGroupsTableAnnotationComposer get groupId {
    final $$CustomGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.customGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CustomGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.customGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChatsTableAnnotationComposer get chatId {
    final $$ChatsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chatId,
      referencedTable: $db.chats,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChatsTableAnnotationComposer(
            $db: $db,
            $table: $db.chats,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CustomGroupChatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomGroupChatsTable,
          SqliteCustomGroupChatRow,
          $$CustomGroupChatsTableFilterComposer,
          $$CustomGroupChatsTableOrderingComposer,
          $$CustomGroupChatsTableAnnotationComposer,
          $$CustomGroupChatsTableCreateCompanionBuilder,
          $$CustomGroupChatsTableUpdateCompanionBuilder,
          (SqliteCustomGroupChatRow, $$CustomGroupChatsTableReferences),
          SqliteCustomGroupChatRow,
          PrefetchHooks Function({bool groupId, bool chatId})
        > {
  $$CustomGroupChatsTableTableManager(
    _$AppDatabase db,
    $CustomGroupChatsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomGroupChatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomGroupChatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomGroupChatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> groupId = const Value.absent(),
                Value<int> chatId = const Value.absent(),
              }) => CustomGroupChatsCompanion(groupId: groupId, chatId: chatId),
          createCompanionCallback:
              ({required int groupId, required int chatId}) =>
                  CustomGroupChatsCompanion.insert(
                    groupId: groupId,
                    chatId: chatId,
                  ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CustomGroupChatsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false, chatId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupId,
                                referencedTable:
                                    $$CustomGroupChatsTableReferences
                                        ._groupIdTable(db),
                                referencedColumn:
                                    $$CustomGroupChatsTableReferences
                                        ._groupIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (chatId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.chatId,
                                referencedTable:
                                    $$CustomGroupChatsTableReferences
                                        ._chatIdTable(db),
                                referencedColumn:
                                    $$CustomGroupChatsTableReferences
                                        ._chatIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CustomGroupChatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomGroupChatsTable,
      SqliteCustomGroupChatRow,
      $$CustomGroupChatsTableFilterComposer,
      $$CustomGroupChatsTableOrderingComposer,
      $$CustomGroupChatsTableAnnotationComposer,
      $$CustomGroupChatsTableCreateCompanionBuilder,
      $$CustomGroupChatsTableUpdateCompanionBuilder,
      (SqliteCustomGroupChatRow, $$CustomGroupChatsTableReferences),
      SqliteCustomGroupChatRow,
      PrefetchHooks Function({bool groupId, bool chatId})
    >;
typedef $$StorageMetaTableCreateCompanionBuilder =
    StorageMetaCompanion Function({
      required String key,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$StorageMetaTableUpdateCompanionBuilder =
    StorageMetaCompanion Function({
      Value<String> key,
      Value<String?> value,
      Value<int> rowid,
    });

class $$StorageMetaTableFilterComposer
    extends Composer<_$AppDatabase, $StorageMetaTable> {
  $$StorageMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StorageMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $StorageMetaTable> {
  $$StorageMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StorageMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $StorageMetaTable> {
  $$StorageMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$StorageMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StorageMetaTable,
          StorageMetaData,
          $$StorageMetaTableFilterComposer,
          $$StorageMetaTableOrderingComposer,
          $$StorageMetaTableAnnotationComposer,
          $$StorageMetaTableCreateCompanionBuilder,
          $$StorageMetaTableUpdateCompanionBuilder,
          (
            StorageMetaData,
            BaseReferences<_$AppDatabase, $StorageMetaTable, StorageMetaData>,
          ),
          StorageMetaData,
          PrefetchHooks Function()
        > {
  $$StorageMetaTableTableManager(_$AppDatabase db, $StorageMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StorageMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StorageMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StorageMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StorageMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StorageMetaCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StorageMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StorageMetaTable,
      StorageMetaData,
      $$StorageMetaTableFilterComposer,
      $$StorageMetaTableOrderingComposer,
      $$StorageMetaTableAnnotationComposer,
      $$StorageMetaTableCreateCompanionBuilder,
      $$StorageMetaTableUpdateCompanionBuilder,
      (
        StorageMetaData,
        BaseReferences<_$AppDatabase, $StorageMetaTable, StorageMetaData>,
      ),
      StorageMetaData,
      PrefetchHooks Function()
    >;
typedef $$CopyCheckpointsTableCreateCompanionBuilder =
    CopyCheckpointsCompanion Function({
      required String entity,
      required int lastSourceId,
      required int rowsCopied,
      Value<int> rowid,
    });
typedef $$CopyCheckpointsTableUpdateCompanionBuilder =
    CopyCheckpointsCompanion Function({
      Value<String> entity,
      Value<int> lastSourceId,
      Value<int> rowsCopied,
      Value<int> rowid,
    });

class $$CopyCheckpointsTableFilterComposer
    extends Composer<_$AppDatabase, $CopyCheckpointsTable> {
  $$CopyCheckpointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSourceId => $composableBuilder(
    column: $table.lastSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowsCopied => $composableBuilder(
    column: $table.rowsCopied,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CopyCheckpointsTableOrderingComposer
    extends Composer<_$AppDatabase, $CopyCheckpointsTable> {
  $$CopyCheckpointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSourceId => $composableBuilder(
    column: $table.lastSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowsCopied => $composableBuilder(
    column: $table.rowsCopied,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CopyCheckpointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CopyCheckpointsTable> {
  $$CopyCheckpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<int> get lastSourceId => $composableBuilder(
    column: $table.lastSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rowsCopied => $composableBuilder(
    column: $table.rowsCopied,
    builder: (column) => column,
  );
}

class $$CopyCheckpointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CopyCheckpointsTable,
          CopyCheckpoint,
          $$CopyCheckpointsTableFilterComposer,
          $$CopyCheckpointsTableOrderingComposer,
          $$CopyCheckpointsTableAnnotationComposer,
          $$CopyCheckpointsTableCreateCompanionBuilder,
          $$CopyCheckpointsTableUpdateCompanionBuilder,
          (
            CopyCheckpoint,
            BaseReferences<
              _$AppDatabase,
              $CopyCheckpointsTable,
              CopyCheckpoint
            >,
          ),
          CopyCheckpoint,
          PrefetchHooks Function()
        > {
  $$CopyCheckpointsTableTableManager(
    _$AppDatabase db,
    $CopyCheckpointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CopyCheckpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CopyCheckpointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CopyCheckpointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entity = const Value.absent(),
                Value<int> lastSourceId = const Value.absent(),
                Value<int> rowsCopied = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CopyCheckpointsCompanion(
                entity: entity,
                lastSourceId: lastSourceId,
                rowsCopied: rowsCopied,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entity,
                required int lastSourceId,
                required int rowsCopied,
                Value<int> rowid = const Value.absent(),
              }) => CopyCheckpointsCompanion.insert(
                entity: entity,
                lastSourceId: lastSourceId,
                rowsCopied: rowsCopied,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CopyCheckpointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CopyCheckpointsTable,
      CopyCheckpoint,
      $$CopyCheckpointsTableFilterComposer,
      $$CopyCheckpointsTableOrderingComposer,
      $$CopyCheckpointsTableAnnotationComposer,
      $$CopyCheckpointsTableCreateCompanionBuilder,
      $$CopyCheckpointsTableUpdateCompanionBuilder,
      (
        CopyCheckpoint,
        BaseReferences<_$AppDatabase, $CopyCheckpointsTable, CopyCheckpoint>,
      ),
      CopyCheckpoint,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChatsTableTableManager get chats =>
      $$ChatsTableTableManager(_db, _db.chats);
  $$HandlesTableTableManager get handles =>
      $$HandlesTableTableManager(_db, _db.handles);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$ChatHandlesTableTableManager get chatHandles =>
      $$ChatHandlesTableTableManager(_db, _db.chatHandles);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$ContactsTableTableManager get contacts =>
      $$ContactsTableTableManager(_db, _db.contacts);
  $$ContactHandlesTableTableManager get contactHandles =>
      $$ContactHandlesTableTableManager(_db, _db.contactHandles);
  $$CustomGroupsTableTableManager get customGroups =>
      $$CustomGroupsTableTableManager(_db, _db.customGroups);
  $$CustomGroupChatsTableTableManager get customGroupChats =>
      $$CustomGroupChatsTableTableManager(_db, _db.customGroupChats);
  $$StorageMetaTableTableManager get storageMeta =>
      $$StorageMetaTableTableManager(_db, _db.storageMeta);
  $$CopyCheckpointsTableTableManager get copyCheckpoints =>
      $$CopyCheckpointsTableTableManager(_db, _db.copyCheckpoints);
}
