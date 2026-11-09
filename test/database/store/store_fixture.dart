// Runs a test body against both MessagingStore implementations (S2 switch
// plan, commits 4-6): ObjectBox on a real store in a temp directory (the
// Actions' own code reads `Database.*`, so the boxes are set once per test
// file), SQLite on a fresh in-memory Db per test. Not a test file itself.
import 'dart:io';

import 'package:bluebubbles/database/database.dart';
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
  ActiveStore get kind;
  MessagingStore get store;

  /// The SQLite file of the SQLite fixture (null on ObjectBox).
  Db? get db => null;

  Future<Handle> handle(String address, {String service = 'iMessage', int? rowId, String? color});

  Future<Chat> chat(
    String guid, {
    List<Handle> handles = const [],
    String? threadKey,
    DateTime? deleted,
    bool unread = false,
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
  });

  Future<Attachment> attachment(String guid, Message? message, {String? mimeType});

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

class ObjectBoxFixture extends StoreFixture {
  ObjectBoxFixture(this.obx);

  final Store obx;

  @override
  ActiveStore get kind => ActiveStore.objectBox;

  @override
  final MessagingStore store = MessagingStore.forStore(ActiveStore.objectBox);

  @override
  Future<Handle> handle(String address, {String service = 'iMessage', int? rowId, String? color}) async {
    final h = Handle(address: address, service: service, originalROWID: rowId, color: color);
    obx.box<Handle>().put(h);
    return h;
  }

  @override
  Future<Chat> chat(
    String guid, {
    List<Handle> handles = const [],
    String? threadKey,
    DateTime? deleted,
    bool unread = false,
  }) async {
    final c = Chat(guid: guid, threadKey: threadKey, dateDeleted: deleted, hasUnreadMessage: unread)
      ..handles.addAll(handles);
    obx.box<Chat>().put(c);
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
      int? deliveredMs}) async {
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
    if (chat != null) m.chat.target = chat;
    if (from != null) m.handleRelation.target = from;
    obx.box<Message>().put(m);
    return m;
  }

  @override
  Future<Attachment> attachment(String guid, Message? message, {String? mimeType}) async {
    final a = Attachment(guid: guid, mimeType: mimeType ?? 'image/jpeg', transferName: '$guid.jpg', isOutgoing: false);
    if (message != null) a.message.target = message;
    obx.box<Attachment>().put(a);
    return a;
  }

  @override
  Future<ContactV2> contact(String nativeId, String name, {List<Handle> handles = const []}) async {
    final c = ContactV2(nativeContactId: nativeId, displayName: name)..handles.addAll(handles);
    obx.box<ContactV2>().put(c);
    return c;
  }

  @override
  Future<void> setLatest(Chat chat, Message? message) async {
    chat.dbLatestMessage.target = message;
    chat.dbOnlyLatestMessageDate = message?.dateCreated;
    obx.box<Chat>().put(chat);
  }

  @override
  Future<void> reset() async => _emptyObjectBox(obx);
}

class SqliteFixture extends StoreFixture {
  @override
  Db db = Db.memory();

  @override
  ActiveStore get kind => ActiveStore.sqlite;

  @override
  late MessagingStore store = MessagingStore.forStore(ActiveStore.sqlite, db: db);

  @override
  Future<void> reset() async {
    await db.close();
    db = Db.memory();
    store = MessagingStore.forStore(ActiveStore.sqlite, db: db);
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
  }) async {
    final c = Chat(guid: guid, threadKey: threadKey, dateDeleted: deleted, hasUnreadMessage: unread);
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
      int? deliveredMs}) async {
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
    m.id = await _insert('messages', messageToRow(m));
    return m;
  }

  @override
  Future<Attachment> attachment(String guid, Message? message, {String? mimeType}) async {
    final a = Attachment(guid: guid, mimeType: mimeType ?? 'image/jpeg', transferName: '$guid.jpg', isOutgoing: false);
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

Directory? _obxDir;
Store? _obx;

/// Opens this test file's ObjectBox store once and points `Database.*` at it.
Store _openObjectBox() {
  if (_obx != null) return _obx!;
  _obxDir = Directory.systemTemp.createTempSync('bb_store_');
  final store = _obx = Store(getObjectBoxModel(), directory: _obxDir!.path);
  Database.store = store;
  Database.attachments = store.box<Attachment>();
  Database.chats = store.box<Chat>();
  Database.contactsV2 = store.box<ContactV2>();
  Database.customGroups = store.box<CustomGroup>();
  Database.handles = store.box<Handle>();
  Database.messages = store.box<Message>();
  return store;
}

void _emptyObjectBox(Store store) {
  store.runInTransaction(TxMode.write, () {
    store.box<Attachment>().removeAll();
    store.box<Message>().removeAll();
    store.box<CustomGroup>().removeAll();
    store.box<Chat>().removeAll();
    store.box<ContactV2>().removeAll();
    store.box<Handle>().removeAll();
  });
}

/// An empty ObjectBox store for a test that needs both stores at once (the
/// rollback drill); `Database.*` points at it.
ObjectBoxFixture objectBoxFixture() => ObjectBoxFixture(_openObjectBox()..let(_emptyObjectBox));

/// Closes what [objectBoxFixture] opened; for tearDownAll.
void closeObjectBox() {
  _obx?.close();
  _obx = null;
  _obxDir?.deleteSync(recursive: true);
  _obxDir = null;
}

/// Defines [body]'s tests twice, in a group per store; each test gets an empty
/// store in `fixture()`, which is also `MessagingStore.current` while it runs.
void forEachStore(void Function(StoreFixture Function() fixture) body, {Set<ActiveStore> only = const {}}) {
  setUpAll(() {
    if (!GetIt.I.isRegistered<BaseLogger>()) GetIt.I.registerSingleton<BaseLogger>(BaseLogger());
  });
  tearDownAll(closeObjectBox);

  for (final kind in ActiveStore.values) {
    if (only.isNotEmpty && !only.contains(kind)) continue;
    group(kind == ActiveStore.objectBox ? 'ObjectBox' : 'SQLite', () {
      late StoreFixture fixture;
      setUp(() {
        fixture = switch (kind) {
          ActiveStore.objectBox => ObjectBoxFixture(_openObjectBox()..let(_emptyObjectBox)),
          ActiveStore.sqlite => SqliteFixture(),
        };
        MessagingStore.use(fixture.store);
      });
      tearDown(() async {
        MessagingStore.use(null);
        await fixture.db?.close();
      });
      body(() => fixture);
    });
  }
}

extension _Let<T> on T {
  void let(void Function(T) f) => f(this);
}
