import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/app_database.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> columnNames(AppDatabase database, String table) async {
  final rows = await database.customSelect('PRAGMA table_info($table)').get();
  return rows.map((row) => row.read<String>('name')).toList();
}

/// Writes [row] with the same upsert the copy uses and reads it back.
Future<Map<String, Object?>> roundTrip(AppDatabase database, String table, Map<String, Object?> row) async {
  await database.customStatement(upsertSql(table, row.keys.toList()), row.values.toList());
  final stored = await database
      .customSelect('SELECT * FROM $table WHERE id = ${row['id']}')
      .getSingle();
  return stored.data;
}

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase.inMemory();
    await database.customStatement("INSERT INTO chats (id, guid) VALUES (7, 'chat-7')");
    await database.customStatement("INSERT INTO handles (id, address, unique_address_and_service, service) "
        "VALUES (3, 'a', 'a/iMessage', 'iMessage')");
  });
  tearDown(() => database.close());

  test('mapper columns are exactly the table columns', () async {
    expect(messageToRow(Message(id: 1, guid: 'm', dateCreated: DateTime(2020))).keys.toSet(),
        (await columnNames(database, 'messages')).toSet());
    expect(chatToRow(Chat(id: 1, guid: 'c')).keys.toSet(), (await columnNames(database, 'chats')).toSet());
    expect(handleToRow(Handle(id: 1, address: 'a')).keys.toSet(), (await columnNames(database, 'handles')).toSet());
    expect(attachmentToRow(Attachment(id: 1)).keys.toSet(), (await columnNames(database, 'attachments')).toSet());
    expect(contactToRow(ContactV2(id: 1, displayName: 'd', nativeContactId: 'n')).keys.toSet(),
        (await columnNames(database, 'contacts')).toSet());
    expect(customGroupToRow(CustomGroup(id: 1, name: 'g')).keys.toSet(),
        (await columnNames(database, 'custom_groups')).toSet());
  });

  test('message round-trips every persisted field, sort_at is the earlier of created and delivered', () async {
    final original = Message(
      id: 11,
      originalROWID: 900,
      guid: 'msg-guid',
      handleId: 4,
      otherHandle: 5,
      text: 'hello',
      subject: 'subject',
      country: 'us',
      service: 'SMS',
      error: 22,
      errorMessage: 'boom',
      dateCreated: DateTime.fromMillisecondsSinceEpoch(1700000005000),
      dateRead: DateTime.fromMillisecondsSinceEpoch(1700000009000),
      dateDelivered: DateTime.fromMillisecondsSinceEpoch(1700000001000),
      isDelievered: true,
      isFromMe: null,
      hasDdResults: null,
      datePlayed: DateTime.fromMillisecondsSinceEpoch(1700000010000),
      hasEffectPlayed: true,
      itemType: 2,
      groupTitle: 'title',
      groupActionType: 1,
      balloonBundleId: 'balloon',
      associatedMessageGuid: 'assoc',
      associatedMessagePart: 1,
      associatedMessageType: 'love',
      expressiveSendStyleId: 'effect',
      hasAttachments: true,
      hasReactions: true,
      dateDeleted: DateTime.fromMillisecondsSinceEpoch(1700000020000),
      metadata: {'k': 'v', 'n': 1, 'nested': {'a': [1, 2]}},
      threadOriginatorGuid: 'thread',
      appleChatGuid: 'apple-chat',
      threadOriginatorPart: '0:0:1',
      attributedBody: [],
      messageSummaryInfo: [],
      payloadData: null,
      hasApplePayloadData: true,
      dateEdited: DateTime.fromMillisecondsSinceEpoch(1700000030000),
      wasDeliveredQuietly: true,
      didNotifyRecipient: true,
      isBookmarked: true,
    )..bigEmoji = null;
    original.chat.targetId = 7;
    original.handleRelation.targetId = 3;

    final row = messageToRow(original);
    expect(row['sort_at_us'], 1700000001000000);
    expect(row['is_from_me'], isNull);
    final stored = await roundTrip(database, 'messages', row);
    expect(stored, row);

    final restored = messageFromRow(stored);
    expect(messageToRow(restored), row);
    expect(restored.dateCreated, original.dateCreated);
    expect(restored.chat.targetId, 7);
    expect(restored.handleRelation.targetId, 3);
    expect(restored.metadata, original.metadata);
    expect(restored.isFromMe, isNull);
    expect(restored.bigEmoji, isNull);
  });

  test('sort_at falls back to date_created when there is no delivery date', () {
    final row = messageToRow(Message(id: 1, guid: 'g', dateCreated: DateTime.fromMillisecondsSinceEpoch(5000)));
    expect(row['sort_at_us'], 5000000);
    final later = messageToRow(Message(
        id: 2,
        guid: 'h',
        dateCreated: DateTime.fromMillisecondsSinceEpoch(5000),
        dateDelivered: DateTime.fromMillisecondsSinceEpoch(9000)));
    expect(later['sort_at_us'], 5000000);
  });

  test('chat round-trips every persisted field including its latest-message pointer', () async {
    final original = Chat(
      id: 8,
      guid: 'iMessage;+;chat8',
      chatIdentifier: 'chat8',
      serviceName: 'iMessage',
      groupId: 'gid',
      originalGroupId: 'ogid',
      legacyGroupIds: const ['l1'],
      latestGroupTitle: '',
      threadKey: 'tk',
      isArchived: null,
      isPinned: true,
      muteType: 'mute',
      muteArgs: 'args',
      hasUnreadMessage: true,
      displayName: 'name',
      isFilteredAsSpam: false,
      customAvatar: '/a',
      customBackground: '/b',
      pinnedIndex: 3,
      autoSendReadReceipts: null,
      autoSendTypingIndicators: true,
      textFieldText: 'draft',
      textFieldAttachments: const ['/x'],
      dateDeleted: DateTime.fromMillisecondsSinceEpoch(1600000000000),
      style: 43,
      lockChatName: true,
      lockChatIcon: true,
      lastReadMessageGuid: 'lr',
      customThemeLight: 'l',
      customThemeDark: 'd',
      wallpaperType: 'w',
      dynamicWallpaperId: 'dw',
      dynamicWallpaperConfig: 'cfg',
    )..dbOnlyLatestMessageDate = DateTime.fromMillisecondsSinceEpoch(1600000001000);
    original.dbLatestMessage.targetId = 99;

    final row = chatToRow(original);
    expect(row['latest_message_id'], 99);
    final stored = await roundTrip(database, 'chats', row);
    expect(stored, row);
    final restored = chatFromRow(stored);
    expect(chatToRow(restored), row);
    expect(restored.isArchived, isNull);
    expect(restored.dbLatestMessage.targetId, 99);
  });

  test('handle, attachment, contact and custom group round-trip every persisted field', () async {
    final handle = Handle(
      id: 21,
      originalROWID: 77,
      address: '+15551234567',
      formattedAddress: '(555) 123-4567',
      service: 'SMS',
      country: 'us',
      color: '#fff',
      defaultEmail: 'e@x',
      defaultPhone: '+1555',
    );
    final handleRow = handleToRow(handle);
    expect(handleRow['unique_address_and_service'], '+15551234567/SMS');
    expect(await roundTrip(database, 'handles', handleRow), handleRow);
    expect(handleToRow(handleFromRow(handleRow)), handleRow);

    final parent = messageToRow(Message(id: 31, guid: 'm31', dateCreated: DateTime(2020)));
    await database.customStatement(upsertSql('messages', parent.keys.toList()), parent.values.toList());
    final attachment = Attachment(
      id: 41,
      originalROWID: 5,
      guid: 'att',
      uti: 'public.jpeg',
      mimeType: 'image/jpeg',
      isOutgoing: null,
      transferName: 'a.jpg',
      totalBytes: 1234,
      height: 10,
      width: 20,
      webUrl: 'https://x',
      hasLivePhoto: true,
      isDownloaded: true,
      metadata: {'size': 3},
      exif: {'Make': 'Apple'},
    );
    attachment.message.targetId = 31;
    final attachmentRow = attachmentToRow(attachment);
    expect(await roundTrip(database, 'attachments', attachmentRow), attachmentRow);
    final restoredAttachment = attachmentFromRow(attachmentRow);
    expect(attachmentToRow(restoredAttachment), attachmentRow);
    expect(restoredAttachment.message.targetId, 31);
    expect(restoredAttachment.isOutgoing, isNull);

    final contact = ContactV2(
      id: 51,
      displayName: 'Jane Doe',
      nativeContactId: 'native-1',
      isNative: true,
      avatarPath: '/avatar',
      addresses: const ['+1555', 'j@x'],
      nickname: 'J',
      firstName: 'Jane',
      lastName: 'Doe',
      middleName: 'Q',
      namePrefix: 'Dr',
      nameSuffix: 'Jr',
      company: 'Co',
    )
      ..phoneNumbers = const [ContactPhone(number: '+1555', label: 'mobile')]
      ..emailAddresses = const [ContactEmail(address: 'j@x', label: 'home')];
    final contactRow = contactToRow(contact);
    expect(await roundTrip(database, 'contacts', contactRow), contactRow);
    final restoredContact = contactFromRow(contactRow);
    expect(contactToRow(restoredContact), contactRow);
    expect(restoredContact.phoneNumbers, contact.phoneNumbers);

    final group = CustomGroup(id: 61, name: 'Family', sortOrder: 2, showUnreadBadge: false);
    final groupRow = customGroupToRow(group);
    expect(await roundTrip(database, 'custom_groups', groupRow), groupRow);
    expect(customGroupToRow(customGroupFromRow(groupRow)), groupRow);
  });
}
