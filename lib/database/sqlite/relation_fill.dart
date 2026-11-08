import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/attachment_repo.dart' show sqlPlaceholders;
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:collection/collection.dart';

/// Fills the relations of entities read from SQLite (S2 switch plan, commit 3):
/// everything reachable from them through `Message.chat`, `.handleRelation`,
/// `.dbAttachments`, `Attachment.message`, `Chat.dbLatestMessage`, `.handles`,
/// `Handle.contactsV2`, `ContactV2.handles` and `CustomGroup.chats` is read
/// and linked, one object per row (a chat's latest message points back at
/// that same chat). `Chat.messages` and `Chat.customGroups` are never filled:
/// callers page with MessageRepo and use CustomGroupRepo.idsForChat.
///
/// Each round reads the links of the rows not linked yet with one `IN` query
/// per kind and 500 ids, then the rows they point at; it stops when nothing
/// new turns up (a few rounds: chats, latest messages, senders, contacts).
///
/// [attachmentsOnly] is for write paths that merge into stored messages
/// (Message.merge reads `dbAttachments`) and never read the other relations.
class RelationFill {
  /// Without [latest], `Chat.dbLatestMessage` stays unfilled (the twin fold
  /// reads every chat and only needs the stored pointer id).
  RelationFill(this.db, {this.latest = true});

  final DbReader db;
  final bool latest;

  final _messages = <int, Message>{};
  final _chats = <int, Chat>{};
  final _handles = <int, Handle>{};
  final _contacts = <int, ContactV2>{};
  final _attachments = <int, Attachment>{};
  final _groups = <int, CustomGroup>{};
  final _roots = Set<Object>.identity();

  final _attachmentsOf = <int, List<int>>{};
  final _participantsOf = <int, List<int>>{};
  final _contactsOf = <int, List<int>>{};
  final _handlesOf = <int, List<int>>{};
  final _chatsOf = <int, List<int>>{};

  Future<void> messages(Iterable<Message> list) => _run(list, _messages, (m) => m.id!);
  Future<void> chats(Iterable<Chat> list) => _run(list, _chats, (c) => c.id!);
  Future<void> handles(Iterable<Handle> list) => _run(list, _handles, (h) => h.id!);
  Future<void> contacts(Iterable<ContactV2> list) => _run(list, _contacts, (c) => c.id);
  Future<void> attachments(Iterable<Attachment> list) => _run(list, _attachments, (a) => a.id!);
  Future<void> groups(Iterable<CustomGroup> list) => _run(list, _groups, (g) => g.id!);

  /// Fills only `dbAttachments` of [list] (one query on attachments_message).
  static Future<void> attachmentsOnly(DbReader db, Iterable<Message> list) async {
    final byId = {for (final m in list) m.id!: m};
    final found = <int, List<Attachment>>{};
    for (final chunk in byId.keys.toList().slices(500)) {
      for (final row in await db.select('SELECT * FROM attachments WHERE message_id IN (${sqlPlaceholders(chunk.length)})', chunk)) {
        found.putIfAbsent(row['message_id'] as int, () => []).add(attachmentFromRow(row));
      }
    }
    for (final m in byId.values) {
      m.dbAttachments.fill((found[m.id] ?? const <Attachment>[]).sortedBy<num>((a) => a.id!));
    }
  }

  Future<void> _run<T extends Object>(Iterable<T> list, Map<int, T> byId, int Function(T) id) async {
    for (final e in list) {
      _roots.add(e);
      byId.putIfAbsent(id(e), () => e);
    }
    while (await _round()) {}
    for (final e in {..._roots, ..._messages.values, ..._chats.values, ..._handles.values, ..._contacts.values,
      ..._attachments.values, ..._groups.values}) {
      _fill(e);
    }
  }

  /// Links the rows not linked yet and reads what they point at; false once nothing is left.
  Future<bool> _round() async {
    final needMessages = <int>{}, needChats = <int>{}, needHandles = <int>{};
    void need(Set<int> into, Map<int, Object> have, int id) {
      if (id != 0 && !have.containsKey(id)) into.add(id);
    }

    var linked = false;
    final messageIds = _messages.keys.where((id) => !_attachmentsOf.containsKey(id)).toList();
    if (messageIds.isNotEmpty) {
      linked = true;
      for (final id in messageIds) {
        _attachmentsOf[id] = [];
      }
      for (final row in await _in('SELECT * FROM attachments WHERE message_id IN', messageIds)) {
        final a = _attachments.putIfAbsent(row['id'] as int, () => attachmentFromRow(row));
        _attachmentsOf[row['message_id'] as int]!.add(a.id!);
      }
      for (final id in messageIds) {
        final m = _messages[id]!;
        need(needChats, _chats, m.chat.targetId);
        need(needHandles, _handles, m.handleRelation.targetId);
      }
    }
    for (final a in _attachments.values) {
      need(needMessages, _messages, a.message.targetId);
    }

    final chatIds = _chats.keys.where((id) => !_participantsOf.containsKey(id)).toList();
    if (chatIds.isNotEmpty) {
      linked = true;
      for (final id in chatIds) {
        _participantsOf[id] = [];
        if (latest) need(needMessages, _messages, _chats[id]!.dbLatestMessage.targetId);
      }
      for (final row in await _in('SELECT chat_id, handle_id FROM chat_handles WHERE chat_id IN', chatIds)) {
        _participantsOf[row['chat_id'] as int]!.add(row['handle_id'] as int);
        need(needHandles, _handles, row['handle_id'] as int);
      }
    }

    final groupIds = _groups.keys.where((id) => !_chatsOf.containsKey(id)).toList();
    if (groupIds.isNotEmpty) {
      linked = true;
      for (final id in groupIds) {
        _chatsOf[id] = [];
      }
      for (final row in await _in('SELECT group_id, chat_id FROM custom_group_chats WHERE group_id IN', groupIds)) {
        _chatsOf[row['group_id'] as int]!.add(row['chat_id'] as int);
        need(needChats, _chats, row['chat_id'] as int);
      }
    }

    final handleIds = _handles.keys.where((id) => !_contactsOf.containsKey(id)).toList();
    if (handleIds.isNotEmpty) {
      linked = true;
      for (final id in handleIds) {
        _contactsOf[id] = [];
      }
      // Contacts come with their links (by contact_handles_handle, then primary
      // key): an IN list of contact ids is planned as a scan once ANALYZE has run.
      for (final row in await _in(
          'SELECT ch.handle_id AS linked_handle_id, c.* FROM contact_handles ch JOIN contacts c ON c.id = ch.contact_id '
          'WHERE ch.handle_id IN',
          handleIds)) {
        final contact = _contacts.putIfAbsent(row['id'] as int, () => contactFromRow(row));
        _contactsOf[row['linked_handle_id'] as int]!.add(contact.id);
      }
    }

    final contactIds = _contacts.keys.where((id) => !_handlesOf.containsKey(id)).toList();
    if (contactIds.isNotEmpty) {
      linked = true;
      for (final id in contactIds) {
        _handlesOf[id] = [];
      }
      for (final row in await _in('SELECT contact_id, handle_id FROM contact_handles WHERE contact_id IN', contactIds)) {
        _handlesOf[row['contact_id'] as int]!.add(row['handle_id'] as int);
        need(needHandles, _handles, row['handle_id'] as int);
      }
    }

    await _load('messages', needMessages, _messages, messageFromRow);
    await _load('chats', needChats, _chats, chatFromRow);
    await _load('handles', needHandles, _handles, handleFromRow);
    return linked || needMessages.isNotEmpty || needChats.isNotEmpty || needHandles.isNotEmpty;
  }

  Future<List<Map<String, Object?>>> _in(String sql, List<int> ids) async => [
        for (final chunk in ids.slices(500)) ...await db.select('$sql (${sqlPlaceholders(chunk.length)})', chunk),
      ];

  Future<void> _load<T>(String table, Set<int> ids, Map<int, T> into, T Function(Map<String, Object?>) fromRow) async {
    if (ids.isEmpty) return;
    for (final row in await _in('SELECT * FROM $table WHERE id IN', ids.toList())) {
      into.putIfAbsent(row['id'] as int, () => fromRow(row));
    }
  }

  List<T> _byIds<T>(List<int>? ids, Map<int, T> from) =>
      ((ids ?? const <int>[]).toSet().toList()..sort()).map((id) => from[id]).whereType<T>().toList();

  void _fill(Object e) {
    switch (e) {
      case final Message m:
        if (!m.dbAttachments.isFilled) m.dbAttachments.fill(_byIds(_attachmentsOf[m.id], _attachments));
        if (!m.chat.isFilled) m.chat.fill(_chats[m.chat.targetId]);
        if (!m.handleRelation.isFilled) m.handleRelation.fill(_handles[m.handleRelation.targetId]);
      case final Chat c:
        if (!c.handles.isFilled) {
          c.handles.fill(_byIds(_participantsOf[c.id], _handles));
          c.participants = c.handles.toList();
        }
        if (latest && !c.dbLatestMessage.isFilled) {
          c.dbLatestMessage.fill(_messages[c.dbLatestMessage.targetId]);
          c.latestMessage = c.dbLatestMessage.target;
        }
      case final Handle h:
        if (!h.contactsV2.isFilled) h.contactsV2.fill(_byIds(_contactsOf[h.id], _contacts));
      case final ContactV2 c:
        if (!c.handles.isFilled) c.handles.fill(_byIds(_handlesOf[c.id], _handles));
      case final Attachment a:
        if (!a.message.isFilled) a.message.fill(_messages[a.message.targetId]);
      case final CustomGroup g:
        if (!g.chats.isFilled) g.chats.fill(_byIds(_chatsOf[g.id], _chats));
    }
  }
}
