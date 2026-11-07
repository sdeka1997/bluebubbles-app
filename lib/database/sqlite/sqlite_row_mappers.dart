import 'dart:convert';

import 'package:bluebubbles/database/models.dart';

// Rows for the SQLite tables, keyed by column name, built from and back into
// the ObjectBox entities. One function pair per entity covers every persisted
// field; the copy, its verification and the tests all go through these.

int? _us(DateTime? value) => value?.microsecondsSinceEpoch;

DateTime? _date(Object? us) => us == null ? null : DateTime.fromMicrosecondsSinceEpoch(us as int);

int? _bool(bool? value) => value == null ? null : (value ? 1 : 0);

bool? _boolOrNull(Object? value) => value == null ? null : value == 1;

bool _boolOr(Object? value, bool fallback) => value == null ? fallback : value == 1;

String? _json(Object? value) => value == null ? null : jsonEncode(value);

List<String>? _stringList(Object? json) =>
    json == null ? null : (jsonDecode(json as String) as List<dynamic>).cast<String>();

Map<String, dynamic>? _map(Object? json) => json == null ? null : jsonDecode(json as String) as Map<String, dynamic>;

int? _targetId(int id) => id == 0 ? null : id;

/// `INSERT ... ON CONFLICT(id) DO UPDATE` for [columns] of [table]. An upsert, not
/// `INSERT OR REPLACE`: a replace deletes first, which would cascade to children.
String upsertSql(String table, List<String> columns) {
  final updates = columns.where((c) => c != 'id').map((c) => '$c = excluded.$c').join(', ');
  return 'INSERT INTO $table (${columns.join(', ')}) VALUES (${List.filled(columns.length, '?').join(', ')}) '
      'ON CONFLICT(id) DO UPDATE SET $updates';
}

/// The timeline position of a message: the earlier of created and delivered, as
/// [Message.sort] orders the screen (some Macs report a late dateCreated).
int sortAtMicros(DateTime? dateCreated, DateTime? dateDelivered) {
  final created = _us(dateCreated) ?? 0;
  final delivered = _us(dateDelivered);
  return delivered != null && delivered < created ? delivered : created;
}

Map<String, Object?> messageToRow(Message m) => {
  'id': m.id,
  'original_rowid': m.originalROWID,
  'guid': m.guid,
  'handle_id': m.handleId,
  'other_handle': m.otherHandle,
  'text': m.text,
  'subject': m.subject,
  'country': m.country,
  'service': m.service,
  'date_created_us': _us(m.dateCreated),
  'sort_at_us': sortAtMicros(m.dateCreated, m.dateDelivered),
  'date_read_us': _us(m.dateRead),
  'date_delivered_us': _us(m.dateDelivered),
  'is_from_me': _bool(m.isFromMe),
  'has_dd_results': _bool(m.hasDdResults),
  'date_played_us': _us(m.datePlayed),
  'item_type': m.itemType,
  'group_title': m.groupTitle,
  'group_action_type': m.groupActionType,
  'balloon_bundle_id': m.balloonBundleId,
  'associated_message_guid': m.associatedMessageGuid,
  'associated_message_part': m.associatedMessagePart,
  'associated_message_type': m.associatedMessageType,
  'expressive_send_style_id': m.expressiveSendStyleId,
  'has_attachments': _bool(m.hasAttachments),
  'has_reactions': _bool(m.hasReactions),
  'date_deleted_us': _us(m.dateDeleted),
  'thread_originator_guid': m.threadOriginatorGuid,
  'thread_originator_part': m.threadOriginatorPart,
  'big_emoji': _bool(m.bigEmoji),
  'error': m.error,
  'chat_id': _targetId(m.chat.targetId),
  'attributed_body_json': m.dbAttributedBody,
  'message_summary_info_json': m.dbMessageSummaryInfo,
  'payload_data_json': m.dbPayloadData,
  'metadata_json': m.dbMetadata,
  'has_apple_payload_data': _bool(m.hasApplePayloadData),
  'date_edited_us': _us(m.dateEdited),
  'was_delivered_quietly': _bool(m.wasDeliveredQuietly),
  'did_notify_recipient': _bool(m.didNotifyRecipient),
  'is_bookmarked': _bool(m.isBookmarked),
  'is_delivered': _bool(m.isDelivered),
  'handle_relation_id': _targetId(m.handleRelation.targetId),
  'error_message': m.errorMessage,
  'has_effect_played': _bool(m.hasEffectPlayed),
  'apple_chat_guid': m.appleChatGuid,
};

Message messageFromRow(Map<String, Object?> r) {
  final m = Message(
    id: r['id'] as int,
    originalROWID: r['original_rowid'] as int?,
    guid: r['guid'] as String?,
    handleId: r['handle_id'] as int?,
    otherHandle: r['other_handle'] as int?,
    text: r['text'] as String?,
    subject: r['subject'] as String?,
    country: r['country'] as String?,
    service: r['service'] as String?,
    error: r['error'] as int?,
    errorMessage: r['error_message'] as String?,
    dateCreated: _date(r['date_created_us']),
    dateRead: _date(r['date_read_us']),
    dateDelivered: _date(r['date_delivered_us']),
    isDelievered: _boolOr(r['is_delivered'], false),
    isFromMe: _boolOrNull(r['is_from_me']),
    hasDdResults: _boolOrNull(r['has_dd_results']),
    datePlayed: _date(r['date_played_us']),
    hasEffectPlayed: _boolOr(r['has_effect_played'], false),
    itemType: r['item_type'] as int?,
    groupTitle: r['group_title'] as String?,
    groupActionType: r['group_action_type'] as int?,
    balloonBundleId: r['balloon_bundle_id'] as String?,
    associatedMessageGuid: r['associated_message_guid'] as String?,
    associatedMessagePart: r['associated_message_part'] as int?,
    associatedMessageType: r['associated_message_type'] as String?,
    expressiveSendStyleId: r['expressive_send_style_id'] as String?,
    hasAttachments: _boolOr(r['has_attachments'], false),
    hasReactions: _boolOr(r['has_reactions'], false),
    dateDeleted: _date(r['date_deleted_us']),
    threadOriginatorGuid: r['thread_originator_guid'] as String?,
    appleChatGuid: r['apple_chat_guid'] as String?,
    threadOriginatorPart: r['thread_originator_part'] as String?,
    hasApplePayloadData: _boolOr(r['has_apple_payload_data'], false),
    dateEdited: _date(r['date_edited_us']),
    wasDeliveredQuietly: _boolOr(r['was_delivered_quietly'], false),
    didNotifyRecipient: _boolOr(r['did_notify_recipient'], false),
    isBookmarked: _boolOr(r['is_bookmarked'], false),
  )
    ..bigEmoji = _boolOrNull(r['big_emoji'])
    ..dbAttributedBody = r['attributed_body_json'] as String?
    ..dbMessageSummaryInfo = r['message_summary_info_json'] as String?
    ..dbPayloadData = r['payload_data_json'] as String?
    ..dbMetadata = r['metadata_json'] as String?;
  m.chat.targetId = r['chat_id'] as int?;
  m.handleRelation.targetId = r['handle_relation_id'] as int?;
  return m;
}

Map<String, Object?> chatToRow(Chat c) => {
  'id': c.id,
  'guid': c.guid,
  'chat_identifier': c.chatIdentifier,
  'service_name': c.serviceName,
  'group_id': c.groupId,
  'original_group_id': c.originalGroupId,
  'legacy_group_ids_json': _json(c.legacyGroupIds),
  'latest_group_title': c.latestGroupTitle,
  'thread_key': c.threadKey,
  'is_archived': _bool(c.isArchived),
  'mute_type': c.muteType,
  'mute_args': c.muteArgs,
  'is_pinned': _bool(c.isPinned),
  'has_unread_message': _bool(c.hasUnreadMessage),
  'display_name': c.displayName,
  'is_filtered_as_spam': _bool(c.isFilteredAsSpam),
  'auto_send_read_receipts': _bool(c.autoSendReadReceipts),
  'auto_send_typing_indicators': _bool(c.autoSendTypingIndicators),
  'text_field_text': c.textFieldText,
  'text_field_attachments_json': jsonEncode(c.textFieldAttachments),
  'latest_message_id': _targetId(c.dbLatestMessage.targetId),
  'latest_message_date_us': _us(c.dbOnlyLatestMessageDate),
  'date_deleted_us': _us(c.dateDeleted),
  'style': c.style,
  'lock_chat_name': _bool(c.lockChatName),
  'lock_chat_icon': _bool(c.lockChatIcon),
  'last_read_message_guid': c.lastReadMessageGuid,
  'custom_theme_light': c.customThemeLight,
  'custom_theme_dark': c.customThemeDark,
  'wallpaper_type': c.wallpaperType,
  'dynamic_wallpaper_id': c.dynamicWallpaperId,
  'dynamic_wallpaper_config': c.dynamicWallpaperConfig,
  'custom_avatar_path': c.customAvatarPath,
  'custom_background_path': c.customBackgroundPath,
  'pin_index': c.pinIndex,
};

Chat chatFromRow(Map<String, Object?> r) {
  final c = Chat(
    id: r['id'] as int,
    guid: r['guid'] as String,
    chatIdentifier: r['chat_identifier'] as String?,
    serviceName: r['service_name'] as String?,
    groupId: r['group_id'] as String?,
    originalGroupId: r['original_group_id'] as String?,
    legacyGroupIds: _stringList(r['legacy_group_ids_json']),
    latestGroupTitle: r['latest_group_title'] as String?,
    threadKey: r['thread_key'] as String?,
    isArchived: _boolOrNull(r['is_archived']),
    muteType: r['mute_type'] as String?,
    muteArgs: r['mute_args'] as String?,
    isPinned: _boolOrNull(r['is_pinned']),
    hasUnreadMessage: _boolOrNull(r['has_unread_message']),
    displayName: r['display_name'] as String?,
    isFilteredAsSpam: _boolOrNull(r['is_filtered_as_spam']),
    autoSendReadReceipts: _boolOrNull(r['auto_send_read_receipts']),
    autoSendTypingIndicators: _boolOrNull(r['auto_send_typing_indicators']),
    textFieldText: r['text_field_text'] as String?,
    textFieldAttachments: _stringList(r['text_field_attachments_json']) ?? const [],
    dateDeleted: _date(r['date_deleted_us']),
    style: r['style'] as int?,
    lockChatName: _boolOr(r['lock_chat_name'], false),
    lockChatIcon: _boolOr(r['lock_chat_icon'], false),
    lastReadMessageGuid: r['last_read_message_guid'] as String?,
    customThemeLight: r['custom_theme_light'] as String?,
    customThemeDark: r['custom_theme_dark'] as String?,
    wallpaperType: r['wallpaper_type'] as String?,
    dynamicWallpaperId: r['dynamic_wallpaper_id'] as String?,
    dynamicWallpaperConfig: r['dynamic_wallpaper_config'] as String?,
    customAvatar: r['custom_avatar_path'] as String?,
    customBackground: r['custom_background_path'] as String?,
    pinnedIndex: r['pin_index'] as int?,
  )..dbOnlyLatestMessageDate = _date(r['latest_message_date_us']);
  c.dbLatestMessage.targetId = r['latest_message_id'] as int?;
  return c;
}

Map<String, Object?> handleToRow(Handle h) => {
  'id': h.id,
  'original_rowid': h.originalROWID,
  'address': h.address,
  'country': h.country,
  'color': h.color,
  'default_phone': h.defaultPhone,
  'default_email': h.defaultEmail,
  'formatted_address': h.formattedAddress,
  'unique_address_and_service': h.uniqueAddressAndService,
  'service': h.service,
};

Handle handleFromRow(Map<String, Object?> r) => Handle(
  id: r['id'] as int,
  originalROWID: r['original_rowid'] as int?,
  address: r['address'] as String,
  country: r['country'] as String?,
  color: r['color'] as String?,
  defaultPhone: r['default_phone'] as String?,
  defaultEmail: r['default_email'] as String?,
  formattedAddress: r['formatted_address'] as String?,
  uniqueAddressAndService: r['unique_address_and_service'] as String,
  service: r['service'] as String,
);

Map<String, Object?> attachmentToRow(Attachment a) => {
  'id': a.id,
  'original_rowid': a.originalROWID,
  'guid': a.guid,
  'uti': a.uti,
  'mime_type': a.mimeType,
  'is_outgoing': _bool(a.isOutgoing),
  'transfer_name': a.transferName,
  'total_bytes': a.totalBytes,
  'height': a.height,
  'width': a.width,
  'web_url': a.webUrl,
  'message_id': _targetId(a.message.targetId),
  'has_live_photo': _bool(a.hasLivePhoto),
  'is_downloaded': _bool(a.isDownloaded),
  'metadata_json': a.dbMetadata,
  'exif_json': _json(a.exif),
};

Attachment attachmentFromRow(Map<String, Object?> r) {
  final a = Attachment(
    id: r['id'] as int,
    originalROWID: r['original_rowid'] as int?,
    guid: r['guid'] as String?,
    uti: r['uti'] as String?,
    mimeType: r['mime_type'] as String?,
    isOutgoing: _boolOrNull(r['is_outgoing']),
    transferName: r['transfer_name'] as String?,
    totalBytes: r['total_bytes'] as int?,
    height: r['height'] as int?,
    width: r['width'] as int?,
    webUrl: r['web_url'] as String?,
    hasLivePhoto: _boolOr(r['has_live_photo'], false),
    isDownloaded: _boolOr(r['is_downloaded'], false),
    metadata: _map(r['metadata_json']),
    exif: _map(r['exif_json']),
  );
  a.message.targetId = r['message_id'] as int?;
  return a;
}

Map<String, Object?> contactToRow(ContactV2 c) => {
  'id': c.id,
  'display_name': c.displayName,
  'native_contact_id': c.nativeContactId,
  'avatar_path': c.avatarPath,
  'addresses_json': jsonEncode(c.addresses),
  'nickname': c.nickname,
  'first_name': c.firstName,
  'last_name': c.lastName,
  'middle_name': c.middleName,
  'name_prefix': c.namePrefix,
  'name_suffix': c.nameSuffix,
  'company': c.company,
  'phone_numbers_json': c.dbPhoneNumbers,
  'email_addresses_json': c.dbEmailAddresses,
  'is_native': _bool(c.isNative),
};

ContactV2 contactFromRow(Map<String, Object?> r) => ContactV2(
  id: r['id'] as int,
  displayName: r['display_name'] as String,
  nativeContactId: r['native_contact_id'] as String,
  isNative: _boolOr(r['is_native'], false),
  avatarPath: r['avatar_path'] as String?,
  addresses: _stringList(r['addresses_json']) ?? const [],
  nickname: r['nickname'] as String?,
  firstName: r['first_name'] as String?,
  lastName: r['last_name'] as String?,
  middleName: r['middle_name'] as String?,
  namePrefix: r['name_prefix'] as String?,
  nameSuffix: r['name_suffix'] as String?,
  company: r['company'] as String?,
)
  ..dbPhoneNumbers = r['phone_numbers_json'] as String?
  ..dbEmailAddresses = r['email_addresses_json'] as String?;

Map<String, Object?> customGroupToRow(CustomGroup g) => {
  'id': g.id,
  'name': g.name,
  'sort_order': g.sortOrder,
  'show_unread_badge': _bool(g.showUnreadBadge),
};

CustomGroup customGroupFromRow(Map<String, Object?> r) => CustomGroup(
  id: r['id'] as int,
  name: r['name'] as String,
  sortOrder: r['sort_order'] as int,
  showUnreadBadge: _boolOr(r['show_unread_badge'], true),
);
