// ContactRepo (contacts + contact_handles) and CustomGroupRepo (custom_groups +
// custom_group_chats): the reads ContactV2Actions / CustomGroupActions and their
// interfaces make today, and their writes, all inside Db.write.
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/contact_repo.dart';
import 'package:bluebubbles/database/sqlite/custom_group_repo.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/handle_repo.dart';
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';

import 'sqlite_seed.dart';

void main() {
  late Db db;
  late ContactRepo contacts;
  late CustomGroupRepo groups;
  late List<DbChanges> events;

  setUp(() {
    db = Db.memory();
    contacts = ContactRepo(db);
    groups = CustomGroupRepo(db);
    events = [];
    db.changes.listen(events.add);
  });
  tearDown(() => db.close());

  group('ContactRepo', () {
    Future<void> seed() => (Seed()
          ..contact(1, 'Zed')
          ..contact(2, 'Ana')
          ..handle(1, address: '+15550001', contacts: [1])
          ..handle(2, address: 'ana@x.com', contacts: [2])
          ..handle(3, address: '+15550002', contacts: [2]))
        .into(db);

    test('reads: by id(s), by native id, for handles (deduplicated), all by name, stored native ids', () async {
      await seed();
      expect((await contacts.byId(2))!.displayName, 'Ana');
      expect(await contacts.byId(9), isNull);
      expect((await contacts.byIds([1, 2, 9])).map((c) => c.id), unorderedEquals([1, 2]));
      expect((await contacts.byNativeId('native-1'))!.id, 1);
      expect(await contacts.byNativeId('nope'), isNull);
      expect((await contacts.forHandles([2, 3, 1])).map((c) => c.id), unorderedEquals([1, 2]));
      expect((await contacts.all()).map((c) => c.displayName), ['Ana', 'Zed']);
      expect(await contacts.nativeIds(), unorderedEquals(['native-1', 'native-2']));
      expect((await contacts.byId(2))!.handles.map((h) => h.id), [2, 3]);
    });

    test('byAddress matches a normalized phone or email, as ContactV2.hasMatchingAddress does', () async {
      final ana = ContactV2(displayName: 'Ana', nativeContactId: 'n-ana', addresses: ['ana@x.com', '+15550002']);
      await db.write((tx) => contacts.upsert(tx, [ana]));
      expect((await contacts.byAddress('ANA@x.com'))?.id, ana.id);
      expect((await contacts.byAddress('+1 (555) 000-2'))?.id, ana.id);
      expect(await contacts.byAddress('+15559999'), isNull);
    });

    test('upsert by native id keeps the id and every field; setHandles replaces the links', () async {
      await seed();
      final edited = ContactV2(displayName: 'Zed Z', nativeContactId: 'native-1', avatarPath: '/a.jpg', company: 'Co')
        ..phoneNumbers = [const ContactPhone(number: '+15550001', label: 'mobile')];
      final fresh = ContactV2(id: 1, displayName: 'New', nativeContactId: 'native-3');
      await db.write((tx) async {
        await contacts.upsert(tx, [edited, fresh]);
        await contacts.setHandles(tx, edited.id, [1, 3]);
      });
      expect(edited.id, 1);
      expect(fresh.id, isNot(1));
      final stored = (await contacts.byId(1))!;
      expect(stored.displayName, 'Zed Z');
      expect(stored.company, 'Co');
      expect(stored.phoneNumbers.single.label, 'mobile');
      expect(stored.handles.map((h) => h.id), [1, 3]);
      expect((await HandleRepo(db).byId(3))!.contactsV2.map((c) => c.id), unorderedEquals([1, 2]));
      expect(events.last.tables['contact_handles'], {1});
    });

    test('deleteByNativeIds removes the contacts and their links, and returns the handles they were on', () async {
      await seed();
      final affected = await db.write((tx) => contacts.deleteByNativeIds(tx, ['native-2', 'missing']));
      expect(affected, unorderedEquals([2, 3]));
      expect(await contacts.byId(2), isNull);
      expect((await HandleRepo(db).byId(3))!.contactsV2, isEmpty);
      expect((await HandleRepo(db).byId(1))!.contactsV2.single.id, 1);
    });
  });

  group('CustomGroupRepo', () {
    Future<void> seedChats() => (Seed()
          ..chat(1, guid: 'c1')
          ..chat(2, guid: 'c2')
          ..chat(3, guid: 'c3'))
        .into(db);

    test('create with chats by guid (unknown and repeated guids skipped), read back with its chats', () async {
      await seedChats();
      final id = await db.write((tx) => groups.create(tx, 'Family', ['c2', 'c1', 'c2', 'nope']));
      final group = (await groups.byId(id))!;
      expect(group.name, 'Family');
      expect(group.showUnreadBadge, isTrue);
      expect(group.chats.map((c) => c.guid), ['c1', 'c2']);
      expect(events.last.tables['custom_group_chats'], {id});
      expect(await groups.byId(99), isNull);
    });

    test('a duplicate name fails and leaves nothing behind', () async {
      await seedChats();
      await db.write((tx) => groups.create(tx, 'Work', ['c1']));
      await expectLater(db.write((tx) => groups.create(tx, 'Work', ['c2'])), throwsA(isA<SqliteException>()));
      expect(await groups.all(), hasLength(1));
    });

    test('rename, setChats, setShowUnreadBadge, reorder and delete', () async {
      await seedChats();
      final a = await db.write((tx) => groups.create(tx, 'A', ['c1']));
      final b = await db.write((tx) => groups.create(tx, 'B', ['c1', 'c2']));
      await db.write((tx) async {
        await groups.rename(tx, a, 'A2');
        await groups.setChats(tx, a, ['c3', 'c2']);
        await groups.setShowUnreadBadge(tx, b, false);
        await groups.reorder(tx, [b, a, 77]);
      });
      final all = await groups.all();
      expect(all.map((g) => g.name), ['B', 'A2'], reason: 'by sort order');
      expect(all.last.chats.map((c) => c.guid), ['c2', 'c3']);
      expect(all.first.showUnreadBadge, isFalse);
      expect((await groups.idsForChat(2)).toSet(), {a, b});

      await db.write((tx) => groups.delete(tx, b));
      expect((await groups.all()).map((g) => g.id), [a]);
      expect(await groups.idsForChat(1), isEmpty);
    });
  });
}
