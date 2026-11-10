// Runs a test body against the MessagingStore on a fresh in-memory SQLite Db
// per test, with seeding helpers. Not a test file itself.
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

/// One store under test, with store-neutral seeding. Seeded entities come back
/// with their local ids set.
abstract class StoreFixture {
  MessagingStore get store;
  Db get db;

  Future<Handle> handle(String address, {String service = 'iMessage', int? rowId, String? color});

  Future<Chat> chat(
    String guid, {
    List<Handle> handles = const [],
    String? threadKey,
    DateTime? deleted,
    bool unread = false,
    String? groupTitle,
    String? identifier,
  });

  Future<Message> message(
    String guid,
    Chat? chat,
    int ms, {
    Handle? from,
    int? handleId,
    String? reactsTo,
    String? threadOriginator,
    String? appleChatGuid,
    String? service,
    bool deleted = false,
    int? itemType,
    String? text,
    int? rowId,
    int? deliveredMs,
    void Function(Message m)? edit,
  });

  Future<Attachment> attachment(String guid, Message? message, {String? mimeType, void Function(Attachment)? edit});

  Future<ContactV2> contact(String nativeId, String name, {List<Handle> handles = const []});

  Future<void> setLatest(Chat chat, Message? message);

  /// Empties the store (it stays `MessagingStore.current`).
  Future<void> reset();
}

DateTime ms(int value) => DateTime.fromMillisecondsSinceEpoch(value);

const t0 = 1600000000000;

Message _message(
  String guid,
  int msValue,
  Handle? from,
  int? handleId,
  String? reactsTo,
  String? threadOriginator,
  String? appleChatGuid,
  String? service,
  bool deleted,
  int? itemType,
  String? text,
  int? rowId, [
  int? deliveredMs,
]) =>
    Message(
      guid: guid,
      text: text ?? 'text of $guid',
      dateCreated: ms(msValue),
      dateDelivered: deliveredMs == null ? null : ms(deliveredMs),
      isFromMe: from == null && handleId == null,
      handleId: handleId ?? from?.originalROWID ?? 0,
      associatedMessageGuid: reactsTo,
      associatedMessageType: reactsTo == null ? null : 'love',
      threadOriginatorGuid: threadOriginator,
      appleChatGuid: appleChatGuid,
      service: service,
      dateDeleted: deleted ? ms(msValue + 1) : null,
      itemType: itemType ?? 0,
      originalROWID: rowId,
    );

class SqliteFixture extends StoreFixture {
  @override
  Db db = Db.memory();

  @override
  late MessagingStore store = MessagingStore(db);

  @override
  Future<void> reset() async {
    await db.close();
    db = Db.memory();
    store = MessagingStore(db);
    MessagingStore.use(store);
  }

  Future<int> _insert(String table, Map<String, Object?> row) => db.write((tx) => tx.insert(table, row..['id'] = null));

  @override
  Future<Handle> handle(String address, {String service = 'iMessage', int? rowId, String? color}) async {
    final h = Handle(address: address, service: service, originalROWID: rowId, color: color);
    h.id = await _insert('handles', handleToRow(h));
    return h;
  }

  @override
  Future<Chat> chat(
    String guid, {
    List<Handle> handles = const [],
    String? threadKey,
    DateTime? deleted,
    bool unread = false,
    String? groupTitle,
    String? identifier,
  }) async {
    final c = Chat(guid: guid, threadKey: threadKey, dateDeleted: deleted, hasUnreadMessage: unread)
      ..latestGroupTitle = groupTitle
      ..chatIdentifier = identifier;
    c.id = await _insert('chats', chatToRow(c));
    await db.write((tx) async {
      for (final h in handles) {
        await tx.execute('INSERT INTO chat_handles (chat_id, handle_id) VALUES (?, ?)', [c.id, h.id]);
      }
    });
    c.handles.addAll(handles);
    return c;
  }

  @override
  Future<Message> message(String guid, Chat? chat, int ms,
      {Handle? from,
      int? handleId,
      String? reactsTo,
      String? threadOriginator,
      String? appleChatGuid,
      String? service,
      bool deleted = false,
      int? itemType,
      String? text,
      int? rowId,
      int? deliveredMs,
      void Function(Message m)? edit}) async {
    final m = _message(
      guid,
      ms,
      from,
      handleId,
      reactsTo,
      threadOriginator,
      appleChatGuid,
      service,
      deleted,
      itemType,
      text,
      rowId,
      deliveredMs,
    );
    m.chat.targetId = chat?.id;
    m.handleRelation.targetId = from?.id;
    edit?.call(m);
    m.id = await _insert('messages', messageToRow(m));
    return m;
  }

  @override
  Future<Attachment> attachment(String guid, Message? message, {String? mimeType, void Function(Attachment)? edit}) async {
    final a = Attachment(guid: guid, mimeType: mimeType ?? 'image/jpeg', transferName: '$guid.jpg', isOutgoing: false);
    edit?.call(a);
    a.message.targetId = message?.id;
    a.id = await _insert('attachments', attachmentToRow(a));
    return a;
  }

  @override
  Future<ContactV2> contact(String nativeId, String name, {List<Handle> handles = const []}) async {
    final c = ContactV2(nativeContactId: nativeId, displayName: name);
    c.id = await _insert('contacts', contactToRow(c));
    await db.write((tx) async {
      for (final h in handles) {
        await tx.execute('INSERT INTO contact_handles (contact_id, handle_id) VALUES (?, ?)', [c.id, h.id]);
      }
    });
    return c;
  }

  @override
  Future<void> setLatest(Chat chat, Message? message) => db.write((tx) => tx.execute(
      'UPDATE chats SET latest_message_id = ?, latest_message_date_us = ? WHERE id = ?',
      [message?.id, message?.dateCreated?.microsecondsSinceEpoch, chat.id]));
}

/// Defines [body]'s tests over a fresh in-memory SQLite store per test, in
/// `fixture()`, which is also `MessagingStore.current` while it runs. Each call
/// is its own group, so a file may call it more than once.
void storeTests(void Function(SqliteFixture Function() fixture) body) {
  group('', () {
    setUpAll(() {
      if (!GetIt.I.isRegistered<BaseLogger>()) GetIt.I.registerSingleton<BaseLogger>(BaseLogger());
    });

    late SqliteFixture fixture;
    setUp(() {
      fixture = SqliteFixture();
      MessagingStore.use(fixture.store);
    });
    tearDown(() async {
      MessagingStore.use(null);
      await fixture.db.close();
    });
    body(() => fixture);
  });
}
