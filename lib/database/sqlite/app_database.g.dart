// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
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
  @override
  List<GeneratedColumn> get $columns => [id];
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
  const SqliteMessageRow({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(id: Value(id));
  }

  factory SqliteMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SqliteMessageRow(id: serializer.fromJson<int>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id)};
  }

  SqliteMessageRow copyWith({int? id}) => SqliteMessageRow(id: id ?? this.id);
  SqliteMessageRow copyWithCompanion(MessagesCompanion data) {
    return SqliteMessageRow(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('SqliteMessageRow(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SqliteMessageRow && other.id == this.id);
}

class MessagesCompanion extends UpdateCompanion<SqliteMessageRow> {
  final Value<int> id;
  const MessagesCompanion({this.id = const Value.absent()});
  MessagesCompanion.insert({this.id = const Value.absent()});
  static Insertable<SqliteMessageRow> custom({Expression<int>? id}) {
    return RawValuesInsertable({if (id != null) 'id': id});
  }

  MessagesCompanion copyWith({Value<int>? id}) {
    return MessagesCompanion(id: id ?? this.id);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }
}

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
    $customConstraints: 'REFERENCES messages(id) ON DELETE SET NULL',
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

class $LegacyHandlesTable extends LegacyHandles
    with TableInfo<$LegacyHandlesTable, LegacyHandle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LegacyHandlesTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'legacy_handles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LegacyHandle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LegacyHandle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LegacyHandle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $LegacyHandlesTable createAlias(String alias) {
    return $LegacyHandlesTable(attachedDatabase, alias);
  }
}

class LegacyHandle extends DataClass implements Insertable<LegacyHandle> {
  final int id;
  const LegacyHandle({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  LegacyHandlesCompanion toCompanion(bool nullToAbsent) {
    return LegacyHandlesCompanion(id: Value(id));
  }

  factory LegacyHandle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LegacyHandle(id: serializer.fromJson<int>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id)};
  }

  LegacyHandle copyWith({int? id}) => LegacyHandle(id: id ?? this.id);
  LegacyHandle copyWithCompanion(LegacyHandlesCompanion data) {
    return LegacyHandle(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('LegacyHandle(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LegacyHandle && other.id == this.id);
}

class LegacyHandlesCompanion extends UpdateCompanion<LegacyHandle> {
  final Value<int> id;
  const LegacyHandlesCompanion({this.id = const Value.absent()});
  LegacyHandlesCompanion.insert({this.id = const Value.absent()});
  static Insertable<LegacyHandle> custom({Expression<int>? id}) {
    return RawValuesInsertable({if (id != null) 'id': id});
  }

  LegacyHandlesCompanion copyWith({Value<int>? id}) {
    return LegacyHandlesCompanion(id: id ?? this.id);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LegacyHandlesCompanion(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }
}

class $ChatParticipantsTable extends ChatParticipants
    with TableInfo<$ChatParticipantsTable, ChatParticipant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatParticipantsTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_participants';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatParticipant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatParticipant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatParticipant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $ChatParticipantsTable createAlias(String alias) {
    return $ChatParticipantsTable(attachedDatabase, alias);
  }
}

class ChatParticipant extends DataClass implements Insertable<ChatParticipant> {
  final int id;
  const ChatParticipant({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  ChatParticipantsCompanion toCompanion(bool nullToAbsent) {
    return ChatParticipantsCompanion(id: Value(id));
  }

  factory ChatParticipant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatParticipant(id: serializer.fromJson<int>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id)};
  }

  ChatParticipant copyWith({int? id}) => ChatParticipant(id: id ?? this.id);
  ChatParticipant copyWithCompanion(ChatParticipantsCompanion data) {
    return ChatParticipant(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('ChatParticipant(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatParticipant && other.id == this.id);
}

class ChatParticipantsCompanion extends UpdateCompanion<ChatParticipant> {
  final Value<int> id;
  const ChatParticipantsCompanion({this.id = const Value.absent()});
  ChatParticipantsCompanion.insert({this.id = const Value.absent()});
  static Insertable<ChatParticipant> custom({Expression<int>? id}) {
    return RawValuesInsertable({if (id != null) 'id': id});
  }

  ChatParticipantsCompanion copyWith({Value<int>? id}) {
    return ChatParticipantsCompanion(id: id ?? this.id);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatParticipantsCompanion(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }
}

class $MessageAttachmentsTable extends MessageAttachments
    with TableInfo<$MessageAttachmentsTable, MessageAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageAttachmentsTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageAttachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageAttachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $MessageAttachmentsTable createAlias(String alias) {
    return $MessageAttachmentsTable(attachedDatabase, alias);
  }
}

class MessageAttachment extends DataClass
    implements Insertable<MessageAttachment> {
  final int id;
  const MessageAttachment({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  MessageAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return MessageAttachmentsCompanion(id: Value(id));
  }

  factory MessageAttachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageAttachment(id: serializer.fromJson<int>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id)};
  }

  MessageAttachment copyWith({int? id}) => MessageAttachment(id: id ?? this.id);
  MessageAttachment copyWithCompanion(MessageAttachmentsCompanion data) {
    return MessageAttachment(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('MessageAttachment(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageAttachment && other.id == this.id);
}

class MessageAttachmentsCompanion extends UpdateCompanion<MessageAttachment> {
  final Value<int> id;
  const MessageAttachmentsCompanion({this.id = const Value.absent()});
  MessageAttachmentsCompanion.insert({this.id = const Value.absent()});
  static Insertable<MessageAttachment> custom({Expression<int>? id}) {
    return RawValuesInsertable({if (id != null) 'id': id});
  }

  MessageAttachmentsCompanion copyWith({Value<int>? id}) {
    return MessageAttachmentsCompanion(id: id ?? this.id);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageAttachmentsCompanion(')
          ..write('id: $id')
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
  @override
  List<GeneratedColumn> get $columns => [id];
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
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StorageMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorageMetaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $StorageMetaTable createAlias(String alias) {
    return $StorageMetaTable(attachedDatabase, alias);
  }
}

class StorageMetaData extends DataClass implements Insertable<StorageMetaData> {
  final int id;
  const StorageMetaData({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  StorageMetaCompanion toCompanion(bool nullToAbsent) {
    return StorageMetaCompanion(id: Value(id));
  }

  factory StorageMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorageMetaData(id: serializer.fromJson<int>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id)};
  }

  StorageMetaData copyWith({int? id}) => StorageMetaData(id: id ?? this.id);
  StorageMetaData copyWithCompanion(StorageMetaCompanion data) {
    return StorageMetaData(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('StorageMetaData(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorageMetaData && other.id == this.id);
}

class StorageMetaCompanion extends UpdateCompanion<StorageMetaData> {
  final Value<int> id;
  const StorageMetaCompanion({this.id = const Value.absent()});
  StorageMetaCompanion.insert({this.id = const Value.absent()});
  static Insertable<StorageMetaData> custom({Expression<int>? id}) {
    return RawValuesInsertable({if (id != null) 'id': id});
  }

  StorageMetaCompanion copyWith({Value<int>? id}) {
    return StorageMetaCompanion(id: id ?? this.id);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StorageMetaCompanion(')
          ..write('id: $id')
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
  @override
  List<GeneratedColumn> get $columns => [id];
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
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CopyCheckpoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CopyCheckpoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $CopyCheckpointsTable createAlias(String alias) {
    return $CopyCheckpointsTable(attachedDatabase, alias);
  }
}

class CopyCheckpoint extends DataClass implements Insertable<CopyCheckpoint> {
  final int id;
  const CopyCheckpoint({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  CopyCheckpointsCompanion toCompanion(bool nullToAbsent) {
    return CopyCheckpointsCompanion(id: Value(id));
  }

  factory CopyCheckpoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CopyCheckpoint(id: serializer.fromJson<int>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id)};
  }

  CopyCheckpoint copyWith({int? id}) => CopyCheckpoint(id: id ?? this.id);
  CopyCheckpoint copyWithCompanion(CopyCheckpointsCompanion data) {
    return CopyCheckpoint(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('CopyCheckpoint(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CopyCheckpoint && other.id == this.id);
}

class CopyCheckpointsCompanion extends UpdateCompanion<CopyCheckpoint> {
  final Value<int> id;
  const CopyCheckpointsCompanion({this.id = const Value.absent()});
  CopyCheckpointsCompanion.insert({this.id = const Value.absent()});
  static Insertable<CopyCheckpoint> custom({Expression<int>? id}) {
    return RawValuesInsertable({if (id != null) 'id': id});
  }

  CopyCheckpointsCompanion copyWith({Value<int>? id}) {
    return CopyCheckpointsCompanion(id: id ?? this.id);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CopyCheckpointsCompanion(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $ChatsTable chats = $ChatsTable(this);
  late final $LegacyHandlesTable legacyHandles = $LegacyHandlesTable(this);
  late final $ChatParticipantsTable chatParticipants = $ChatParticipantsTable(
    this,
  );
  late final $MessageAttachmentsTable messageAttachments =
      $MessageAttachmentsTable(this);
  late final $StorageMetaTable storageMeta = $StorageMetaTable(this);
  late final $CopyCheckpointsTable copyCheckpoints = $CopyCheckpointsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    messages,
    chats,
    legacyHandles,
    chatParticipants,
    messageAttachments,
    storageMeta,
    copyCheckpoints,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'messages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chats', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({Value<int> id});
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({Value<int> id});

final class $$MessagesTableReferences
    extends BaseReferences<_$AppDatabase, $MessagesTable, SqliteMessageRow> {
  $$MessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChatsTable, List<SqliteChatRow>> _chatsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.chats,
    aliasName: $_aliasNameGenerator(db.messages.id, db.chats.latestMessageId),
  );

  $$ChatsTableProcessedTableManager get chatsRefs {
    final manager = $$ChatsTableTableManager(
      $_db,
      $_db.chats,
    ).filter((f) => f.latestMessageId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_chatsRefsTable($_db));
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

  Expression<bool> chatsRefs(
    Expression<bool> Function($$ChatsTableFilterComposer f) f,
  ) {
    final $$ChatsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chats,
      getReferencedColumn: (t) => t.latestMessageId,
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

  Expression<T> chatsRefs<T extends Object>(
    Expression<T> Function($$ChatsTableAnnotationComposer a) f,
  ) {
    final $$ChatsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chats,
      getReferencedColumn: (t) => t.latestMessageId,
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
          PrefetchHooks Function({bool chatsRefs})
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
          updateCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              MessagesCompanion(id: id),
          createCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              MessagesCompanion.insert(id: id),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({chatsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (chatsRefs) db.chats],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chatsRefs)
                    await $_getPrefetchedData<
                      SqliteMessageRow,
                      $MessagesTable,
                      SqliteChatRow
                    >(
                      currentTable: table,
                      referencedTable: $$MessagesTableReferences
                          ._chatsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MessagesTableReferences(db, table, p0).chatsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.latestMessageId == item.id,
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
      PrefetchHooks Function({bool chatsRefs})
    >;
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

  static $MessagesTable _latestMessageIdTable(_$AppDatabase db) =>
      db.messages.createAlias(
        $_aliasNameGenerator(db.chats.latestMessageId, db.messages.id),
      );

  $$MessagesTableProcessedTableManager? get latestMessageId {
    final $_column = $_itemColumn<int>('latest_message_id');
    if ($_column == null) return null;
    final manager = $$MessagesTableTableManager(
      $_db,
      $_db.messages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_latestMessageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
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

  $$MessagesTableFilterComposer get latestMessageId {
    final $$MessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.latestMessageId,
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

  $$MessagesTableOrderingComposer get latestMessageId {
    final $$MessagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.latestMessageId,
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

  $$MessagesTableAnnotationComposer get latestMessageId {
    final $$MessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.latestMessageId,
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
          PrefetchHooks Function({bool latestMessageId})
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
          prefetchHooksCallback: ({latestMessageId = false}) {
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
                    if (latestMessageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.latestMessageId,
                                referencedTable: $$ChatsTableReferences
                                    ._latestMessageIdTable(db),
                                referencedColumn: $$ChatsTableReferences
                                    ._latestMessageIdTable(db)
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
      PrefetchHooks Function({bool latestMessageId})
    >;
typedef $$LegacyHandlesTableCreateCompanionBuilder =
    LegacyHandlesCompanion Function({Value<int> id});
typedef $$LegacyHandlesTableUpdateCompanionBuilder =
    LegacyHandlesCompanion Function({Value<int> id});

class $$LegacyHandlesTableFilterComposer
    extends Composer<_$AppDatabase, $LegacyHandlesTable> {
  $$LegacyHandlesTableFilterComposer({
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
}

class $$LegacyHandlesTableOrderingComposer
    extends Composer<_$AppDatabase, $LegacyHandlesTable> {
  $$LegacyHandlesTableOrderingComposer({
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
}

class $$LegacyHandlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LegacyHandlesTable> {
  $$LegacyHandlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
}

class $$LegacyHandlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LegacyHandlesTable,
          LegacyHandle,
          $$LegacyHandlesTableFilterComposer,
          $$LegacyHandlesTableOrderingComposer,
          $$LegacyHandlesTableAnnotationComposer,
          $$LegacyHandlesTableCreateCompanionBuilder,
          $$LegacyHandlesTableUpdateCompanionBuilder,
          (
            LegacyHandle,
            BaseReferences<_$AppDatabase, $LegacyHandlesTable, LegacyHandle>,
          ),
          LegacyHandle,
          PrefetchHooks Function()
        > {
  $$LegacyHandlesTableTableManager(_$AppDatabase db, $LegacyHandlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LegacyHandlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LegacyHandlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LegacyHandlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              LegacyHandlesCompanion(id: id),
          createCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              LegacyHandlesCompanion.insert(id: id),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LegacyHandlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LegacyHandlesTable,
      LegacyHandle,
      $$LegacyHandlesTableFilterComposer,
      $$LegacyHandlesTableOrderingComposer,
      $$LegacyHandlesTableAnnotationComposer,
      $$LegacyHandlesTableCreateCompanionBuilder,
      $$LegacyHandlesTableUpdateCompanionBuilder,
      (
        LegacyHandle,
        BaseReferences<_$AppDatabase, $LegacyHandlesTable, LegacyHandle>,
      ),
      LegacyHandle,
      PrefetchHooks Function()
    >;
typedef $$ChatParticipantsTableCreateCompanionBuilder =
    ChatParticipantsCompanion Function({Value<int> id});
typedef $$ChatParticipantsTableUpdateCompanionBuilder =
    ChatParticipantsCompanion Function({Value<int> id});

class $$ChatParticipantsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatParticipantsTable> {
  $$ChatParticipantsTableFilterComposer({
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
}

class $$ChatParticipantsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatParticipantsTable> {
  $$ChatParticipantsTableOrderingComposer({
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
}

class $$ChatParticipantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatParticipantsTable> {
  $$ChatParticipantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
}

class $$ChatParticipantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatParticipantsTable,
          ChatParticipant,
          $$ChatParticipantsTableFilterComposer,
          $$ChatParticipantsTableOrderingComposer,
          $$ChatParticipantsTableAnnotationComposer,
          $$ChatParticipantsTableCreateCompanionBuilder,
          $$ChatParticipantsTableUpdateCompanionBuilder,
          (
            ChatParticipant,
            BaseReferences<
              _$AppDatabase,
              $ChatParticipantsTable,
              ChatParticipant
            >,
          ),
          ChatParticipant,
          PrefetchHooks Function()
        > {
  $$ChatParticipantsTableTableManager(
    _$AppDatabase db,
    $ChatParticipantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatParticipantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatParticipantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatParticipantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              ChatParticipantsCompanion(id: id),
          createCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              ChatParticipantsCompanion.insert(id: id),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatParticipantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatParticipantsTable,
      ChatParticipant,
      $$ChatParticipantsTableFilterComposer,
      $$ChatParticipantsTableOrderingComposer,
      $$ChatParticipantsTableAnnotationComposer,
      $$ChatParticipantsTableCreateCompanionBuilder,
      $$ChatParticipantsTableUpdateCompanionBuilder,
      (
        ChatParticipant,
        BaseReferences<_$AppDatabase, $ChatParticipantsTable, ChatParticipant>,
      ),
      ChatParticipant,
      PrefetchHooks Function()
    >;
typedef $$MessageAttachmentsTableCreateCompanionBuilder =
    MessageAttachmentsCompanion Function({Value<int> id});
typedef $$MessageAttachmentsTableUpdateCompanionBuilder =
    MessageAttachmentsCompanion Function({Value<int> id});

class $$MessageAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $MessageAttachmentsTable> {
  $$MessageAttachmentsTableFilterComposer({
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
}

class $$MessageAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $MessageAttachmentsTable> {
  $$MessageAttachmentsTableOrderingComposer({
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
}

class $$MessageAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessageAttachmentsTable> {
  $$MessageAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
}

class $$MessageAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessageAttachmentsTable,
          MessageAttachment,
          $$MessageAttachmentsTableFilterComposer,
          $$MessageAttachmentsTableOrderingComposer,
          $$MessageAttachmentsTableAnnotationComposer,
          $$MessageAttachmentsTableCreateCompanionBuilder,
          $$MessageAttachmentsTableUpdateCompanionBuilder,
          (
            MessageAttachment,
            BaseReferences<
              _$AppDatabase,
              $MessageAttachmentsTable,
              MessageAttachment
            >,
          ),
          MessageAttachment,
          PrefetchHooks Function()
        > {
  $$MessageAttachmentsTableTableManager(
    _$AppDatabase db,
    $MessageAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageAttachmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              MessageAttachmentsCompanion(id: id),
          createCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              MessageAttachmentsCompanion.insert(id: id),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessageAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessageAttachmentsTable,
      MessageAttachment,
      $$MessageAttachmentsTableFilterComposer,
      $$MessageAttachmentsTableOrderingComposer,
      $$MessageAttachmentsTableAnnotationComposer,
      $$MessageAttachmentsTableCreateCompanionBuilder,
      $$MessageAttachmentsTableUpdateCompanionBuilder,
      (
        MessageAttachment,
        BaseReferences<
          _$AppDatabase,
          $MessageAttachmentsTable,
          MessageAttachment
        >,
      ),
      MessageAttachment,
      PrefetchHooks Function()
    >;
typedef $$StorageMetaTableCreateCompanionBuilder =
    StorageMetaCompanion Function({Value<int> id});
typedef $$StorageMetaTableUpdateCompanionBuilder =
    StorageMetaCompanion Function({Value<int> id});

class $$StorageMetaTableFilterComposer
    extends Composer<_$AppDatabase, $StorageMetaTable> {
  $$StorageMetaTableFilterComposer({
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
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
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
          updateCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              StorageMetaCompanion(id: id),
          createCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              StorageMetaCompanion.insert(id: id),
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
    CopyCheckpointsCompanion Function({Value<int> id});
typedef $$CopyCheckpointsTableUpdateCompanionBuilder =
    CopyCheckpointsCompanion Function({Value<int> id});

class $$CopyCheckpointsTableFilterComposer
    extends Composer<_$AppDatabase, $CopyCheckpointsTable> {
  $$CopyCheckpointsTableFilterComposer({
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
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
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
          updateCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              CopyCheckpointsCompanion(id: id),
          createCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              CopyCheckpointsCompanion.insert(id: id),
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
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$ChatsTableTableManager get chats =>
      $$ChatsTableTableManager(_db, _db.chats);
  $$LegacyHandlesTableTableManager get legacyHandles =>
      $$LegacyHandlesTableTableManager(_db, _db.legacyHandles);
  $$ChatParticipantsTableTableManager get chatParticipants =>
      $$ChatParticipantsTableTableManager(_db, _db.chatParticipants);
  $$MessageAttachmentsTableTableManager get messageAttachments =>
      $$MessageAttachmentsTableTableManager(_db, _db.messageAttachments);
  $$StorageMetaTableTableManager get storageMeta =>
      $$StorageMetaTableTableManager(_db, _db.storageMeta);
  $$CopyCheckpointsTableTableManager get copyCheckpoints =>
      $$CopyCheckpointsTableTableManager(_db, _db.copyCheckpoints);
}
