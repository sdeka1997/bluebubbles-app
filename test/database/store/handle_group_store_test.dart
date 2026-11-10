// HandleActions/HandleInterface and CustomGroupActions/CustomGroupInterface
// through MessagingStore (S2 switch plan, commits 4-5), on the SQLite
// repositories.
import 'package:bluebubbles/env.dart';
import 'package:bluebubbles/services/backend/actions/custom_group_actions.dart';
import 'package:bluebubbles/services/backend/actions/handle_actions.dart';
import 'package:bluebubbles/services/backend/interfaces/custom_group_interface.dart';
import 'package:bluebubbles/services/backend/interfaces/handle_interface.dart';
import 'package:bluebubbles/services/backend_ui_interop/event_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart' hide EventDispatcher;
import 'package:get_it/get_it.dart';

import 'store_fixture.dart';

void main() {
  setUpAll(() {
    isIsolateOverride = true;
    if (!GetIt.I.isRegistered<EventDispatcher>()) GetIt.I.registerSingleton<EventDispatcher>(EventDispatcher());
  });
  tearDownAll(() => isIsolateOverride = false);

  storeTests((fixture) {
    group('HandleActions', () {
      test('saveHandleAsync inserts, then matches by address and keeps id, ROWID and color', () async {
        final id = await HandleActions.saveHandleAsync({
          'handleData': {'address': 'ana@x.com', 'service': 'iMessage', 'color': 'red', 'originalROWID': 7},
          'updateColor': false,
          'matchOnOriginalROWID': false,
        });
        final again = await HandleActions.saveHandleAsync({
          'handleData': {'address': 'ana@x.com', 'service': 'iMessage', 'color': 'blue'},
          'updateColor': false,
          'matchOnOriginalROWID': false,
        });
        expect(again, id);
        final stored = (await fixture().store.handleById(id))!;
        expect((stored.originalROWID, stored.color, stored.formattedAddress), (7, 'red', 'ana@x.com'));

        await HandleActions.saveHandleAsync({
          'handleData': {'address': 'ana@x.com', 'service': 'iMessage', 'color': 'blue'},
          'updateColor': true,
          'matchOnOriginalROWID': false,
        });
        expect((await fixture().store.handleById(id))!.color, 'blue');
      });

      test('saveHandleAsync can match on the server ROWID', () async {
        final h = await fixture().handle('+15550001', rowId: 42);
        final id = await HandleActions.saveHandleAsync({
          'handleData': {'address': '+15550001', 'service': 'iMessage', 'originalROWID': 42, 'country': 'US'},
          'updateColor': false,
          'matchOnOriginalROWID': true,
        });
        expect(id, h.id);
        expect((await fixture().store.handleById(id))!.country, 'US');
      });

      test('bulkSaveHandlesAsync saves new and existing handles in order', () async {
        final bo = await fixture().handle('bo@x.com', rowId: 2);
        final ids = await HandleActions.bulkSaveHandlesAsync({
          'handlesData': [
            {'address': 'ana@x.com', 'service': 'iMessage'},
            {'address': 'bo@x.com', 'service': 'iMessage', 'country': 'CA'},
          ],
          'matchOnOriginalROWID': false,
        });
        expect(ids, hasLength(2));
        expect(ids[1], bo.id);
        final stored = await fixture().store.handlesByIds(ids);
        expect(stored.map((h) => (h.address, h.originalROWID, h.country)), [('ana@x.com', null, null), ('bo@x.com', 2, 'CA')]);
      });

      test('findOneHandleAsync: by id, falling back to ROWID; by ROWID; by address and service', () async {
        final ana = await fixture().handle('ana@x.com', rowId: 900);
        final bo = await fixture().handle('bo@x.com', service: 'SMS', rowId: 901);
        expect(await HandleActions.findOneHandleAsync({'id': ana.id}), ana.id);
        expect(await HandleActions.findOneHandleAsync({'id': 901}), bo.id, reason: 'no local id 901: ROWID');
        expect(await HandleActions.findOneHandleAsync({'originalROWID': 900}), ana.id);
        expect(await HandleActions.findOneHandleAsync({'address': 'bo@x.com', 'service': 'SMS'}), bo.id);
        expect(await HandleActions.findOneHandleAsync({'address': 'bo@x.com', 'service': 'iMessage'}), isNull);
        expect(await HandleActions.findOneHandleAsync({'id': 0}), isNull);
        expect(await HandleActions.findHandlesAsync({}), unorderedEquals([ana.id, bo.id]));
      });

      test('HandleInterface returns the stored handles', () async {
        final saved = await HandleInterface.saveHandleAsync(
            handleData: {'address': 'ana@x.com', 'service': 'iMessage'}, updateColor: false, matchOnOriginalROWID: false);
        expect(saved.address, 'ana@x.com');
        final bulk = await HandleInterface.bulkSaveHandlesAsync(
            handlesData: [{'address': 'bo@x.com', 'service': 'iMessage'}], matchOnOriginalROWID: false);
        expect(bulk.single.address, 'bo@x.com');
        expect((await HandleInterface.findOneHandleAsync(address: 'bo@x.com', service: 'iMessage'))!.id, bulk.single.id);
        expect((await HandleInterface.findHandlesAsync()).map((h) => h.address), unorderedEquals(['ana@x.com', 'bo@x.com']));
      });
    });

    group('CustomGroupActions', () {
      test('create with the stored chats among the guids, deduplicated; a taken name throws', () async {
        await fixture().chat('c1');
        await fixture().chat('c2');
        final id = await CustomGroupActions.create({'name': 'Work', 'chatGuids': ['c1', 'c2', 'c1', 'nope']});
        final group = (await fixture().store.customGroupById(id))!;
        expect(group.name, 'Work');
        expect(group.chats.map((c) => c.guid), unorderedEquals(['c1', 'c2']));
        await expectLater(CustomGroupActions.create({'name': 'Work', 'chatGuids': <String>[]}), throwsA(anything));
        expect(await CustomGroupActions.getAllIds({}), [id]);
      });

      test('rename, set chats, unread badge; renaming onto a taken name throws', () async {
        await fixture().chat('c1');
        await fixture().chat('c2');
        final work = await CustomGroupActions.create({'name': 'Work', 'chatGuids': ['c1']});
        await CustomGroupActions.create({'name': 'Home', 'chatGuids': <String>[]});
        expect(await CustomGroupActions.rename({'id': work, 'name': 'Office'}), work);
        await expectLater(CustomGroupActions.rename({'id': work, 'name': 'Home'}), throwsA(anything));
        expect(await CustomGroupActions.updateChats({'id': work, 'chatGuids': ['c2', 'c2']}), work);
        expect(await CustomGroupActions.setShowUnreadBadge({'id': work, 'value': false}), work);
        final group = (await fixture().store.customGroupById(work))!;
        expect((group.name, group.showUnreadBadge), ('Office', false));
        expect(group.chats.map((c) => c.guid), ['c2']);
      });

      test('reorder (unknown ids skipped), getAllIds in that order, delete', () async {
        final a = await CustomGroupActions.create({'name': 'A', 'chatGuids': <String>[]});
        final b = await CustomGroupActions.create({'name': 'B', 'chatGuids': <String>[]});
        final c = await CustomGroupActions.create({'name': 'C', 'chatGuids': <String>[]});
        await CustomGroupActions.reorder({'ids': [c, 9999, a, b]});
        expect(await CustomGroupActions.getAllIds({}), [c, a, b]);
        await CustomGroupActions.delete({'id': a});
        expect(await CustomGroupActions.getAllIds({}), [c, b]);
      });

      test('CustomGroupInterface returns the stored groups', () async {
        await fixture().chat('c1');
        final created = await CustomGroupInterface.create(name: 'Work', chatGuids: ['c1']);
        expect(created.chats.single.guid, 'c1');
        expect((await CustomGroupInterface.rename(id: created.id!, name: 'Office')).name, 'Office');
        expect((await CustomGroupInterface.updateChats(id: created.id!, chatGuids: [])).chats, isEmpty);
        expect((await CustomGroupInterface.setShowUnreadBadge(id: created.id!, value: false)).showUnreadBadge, isFalse);
        final other = await CustomGroupInterface.create(name: 'Home', chatGuids: []);
        await CustomGroupInterface.reorder(ids: [other.id!, created.id!]);
        expect((await CustomGroupInterface.getAll()).map((g) => g.name), ['Home', 'Office']);
        await CustomGroupInterface.delete(id: other.id!);
        expect((await CustomGroupInterface.getAll()).map((g) => g.name), ['Office']);
      });
    });
  });
}
