import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

Handle _handle(String address, int? rowId) => Handle(address: address, originalROWID: rowId);

void main() {
  group('adoptServerRowIds', () {
    test('gives a handle the ROWID the server reported for it', () {
      final tate = _handle('+15555557463', 412);

      final changed = adoptServerRowIds([(tate, 10)], const []);

      expect(tate.originalROWID, 10);
      expect(changed, [tate]);
    });

    test('clears that ROWID from another handle still holding it from the old chat.db', () {
      final tate = _handle('+15555557463', 412);
      final diya = _handle('diya@example.com', 10);

      final changed = adoptServerRowIds([(tate, 10)], [diya]);

      expect(tate.originalROWID, 10);
      expect(diya.originalROWID, isNull);
      expect(changed, unorderedEquals([tate, diya]));
    });

    test('changes nothing when the handles already match the server', () {
      final tate = _handle('+15555557463', 10);
      final other = _handle('other@example.com', 11);

      expect(adoptServerRowIds([(tate, 10)], [tate, other]), isEmpty);
      expect(other.originalROWID, 11);
    });

    test('a reported handle keeps its own new ROWID even if it held another one', () {
      final tate = _handle('+15555557463', 412);
      final diya = _handle('diya@example.com', 10);
      // A second copy of Diya, as a separate query of the holders would return.
      final diyaHolder = _handle('diya@example.com', 10);

      final changed = adoptServerRowIds([(tate, 10), (diya, 12)], [diyaHolder]);

      expect(tate.originalROWID, 10);
      expect(diya.originalROWID, 12);
      expect(changed, unorderedEquals([tate, diya]));
    });
  });

  group('serverReportedRowId', () {
    test('is the ROWID of a handle the server sent', () {
      final handle = Handle.fromMap({'originalROWID': 10, 'address': '+15555557463', 'service': 'iMessage'});

      expect(serverReportedRowId(handle), 10);
    });

    test('is null for a handle rebuilt from the local database', () {
      // Its ROWID may be left over from a previous Apple database.
      final local = Handle(id: 7, address: 'diya@example.com', originalROWID: 10);

      expect(serverReportedRowId(Handle.fromMap(local.toMap())), isNull);
    });
  });
}
