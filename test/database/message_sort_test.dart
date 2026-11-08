import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

Message _m(int? id, int createdMs, {int? deliveredMs}) => Message(
      id: id,
      guid: 'g$id-$createdMs',
      dateCreated: DateTime.fromMillisecondsSinceEpoch(createdMs),
      dateDelivered: deliveredMs == null ? null : DateTime.fromMillisecondsSinceEpoch(deliveredMs),
    );

void main() {
  test('equal times are ordered by id, the same as the SQLite paging key (sort_at_us, id)', () {
    final messages = [_m(3, 1000), _m(1, 1000), _m(2, 1000)];
    expect((messages.toList()..sort(Message.sort)).map((m) => m.id), [3, 2, 1]);
    expect((messages.toList()..sort((a, b) => Message.sort(a, b, descending: false))).map((m) => m.id), [1, 2, 3]);
  });

  test('the earlier of created and delivered decides, then id', () {
    final early = _m(10, 5000, deliveredMs: 1000); // shows at 1000
    final tie = _m(4, 1000);
    final late = _m(1, 2000);
    expect(([late, early, tie]..sort(Message.sort)).map((m) => m.id), [1, 10, 4]);
  });

  test('a message not saved yet sorts after saved ones at the same time (it gets the next id)', () {
    final unsaved = _m(null, 1000);
    final saved = _m(99, 1000);
    expect(([unsaved, saved]..sort((a, b) => Message.sort(a, b, descending: false))).last, same(unsaved));
    expect(([saved, unsaved]..sort(Message.sort)).first, same(unsaved));
    expect(Message.sort(_m(null, 1000), _m(null, 1000)), 0);
  });

  test('in-memory order equals ordering by sortAtMicros then id', () {
    final messages = [
      for (var i = 1; i <= 300; i++) _m(i, 1000 + (i * 7919) % 23 * 1000, deliveredMs: i % 5 == 0 ? 900 + (i % 3) * 1000 : null),
    ];
    final bySort = messages.toList()..sort(Message.sort);
    final byKey = messages.toList()
      ..sort((a, b) {
        final at = sortAtMicros(a.dateCreated, a.dateDelivered), bt = sortAtMicros(b.dateCreated, b.dateDelivered);
        return at != bt ? bt.compareTo(at) : b.id!.compareTo(a.id!);
      });
    expect(bySort.map((m) => m.id), byKey.map((m) => m.id));
  });
}
