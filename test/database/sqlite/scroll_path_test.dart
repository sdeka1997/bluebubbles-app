// Scroll-path tests of SQLITE-PLAN-2 section 5 (1-8, 11, 12), against an
// in-memory SQLite database through MessageRepo, no widgets. 5, 9, 10 and 13
// need the chat window and widgets of stage S3.
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/db.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:bluebubbles/database/sqlite/sqlite_row_mappers.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sqlite_seed.dart';

const _pageSize = 25;

/// Scrolls up from the newest page to the oldest, the way the chat screen
/// will: each request is "older than the oldest row shown". Checks every page
/// on the way: newest first inside, strictly older than everything shown
/// before, never a repeated guid, and never the same key twice in a row (the
/// seq.39 loop: the same page requested 126 times). [between] runs after each
/// page, before the next request (arrivals, deletes, folds mid-scroll).
Future<List<Message>> scrollToOldest(MessageRepo repo, List<int> chatIds,
    {int limit = _pageSize, Future<void> Function(int page, List<Message> shown)? between}) async {
  final shown = <Message>[];
  final seen = <String>{};
  MessageKey? lastRequested;
  var page = await repo.newest(chatIds, limit: limit);
  for (var n = 0; page.isNotEmpty; n++) {
    final keys = page.map(MessageKey.of).toList();
    for (var i = 1; i < keys.length; i++) {
      expect(keys[i].compareTo(keys[i - 1]), lessThan(0), reason: 'page $n is not newest first');
    }
    if (shown.isNotEmpty) {
      expect(keys.first.compareTo(MessageKey.of(shown.last)), lessThan(0), reason: 'page $n is not older than page ${n - 1}');
    }
    for (final m in page) {
      expect(seen.add(m.guid!), isTrue, reason: '${m.guid} shown twice (page $n)');
    }
    shown.addAll(page);
    await between?.call(n, shown);
    final next = MessageKey.of(shown.last);
    expect(next, isNot(lastRequested), reason: 'olderThan($next) requested twice in a row');
    lastRequested = next;
    page = await repo.olderThan(chatIds, next, limit: limit);
    expect(n, lessThan(100000), reason: 'runaway scroll');
  }
  return shown;
}

/// The timeline rows of [chatIds] in screen order, read straight from the table.
Future<List<String>> expectedTimeline(Db db, List<int> chatIds) async {
  final rows = await db.select(
      'SELECT * FROM messages WHERE chat_id IN (${chatIds.join(',')}) '
      'AND associated_message_guid IS NULL AND date_deleted_us IS NULL');
  final messages = rows.map((r) => Message(
        id: r['id'] as int,
        guid: r['guid'] as String,
        dateCreated: DateTime.fromMicrosecondsSinceEpoch(r['date_created_us'] as int),
        dateDelivered: r['date_delivered_us'] == null ? null : DateTime.fromMicrosecondsSinceEpoch(r['date_delivered_us'] as int),
      ));
  return (messages.toList()..sort(Message.sort)).map((m) => m.guid!).toList();
}

List<String> guidsOf(Iterable<Message> messages) => messages.map((m) => m.guid!).toList();

void main() {
  late Db db;
  late MessageRepo repo;

  setUp(() {
    db = Db.memory();
    repo = MessageRepo(db);
  });
  tearDown(() => db.close());

  test('1. successive pages through a 60k-message chat: all new, strictly older, union = every timeline row', () async {
    final seed = Seed()
      ..chat(1)
      ..chat(2);
    var id = 0;
    for (var i = 0; i < 60000; i++) {
      final ms = baseMs + i * 60000;
      seed.message(++id, 1, ms);
      final target = id;
      if (i % 7 == 0) seed.message(++id, 1, ms + 1, reactionTo: 'm$target'); // reactions don't take page slots
      if (i % 101 == 0) seed.message(++id, 1, ms + 2, deleted: true);
      if (i % 3 == 0) seed.message(++id, 2, ms + 3); // another chat, same dates
      if (i % 40 == 0) seed.attachment(id, id);
    }
    await seed.into(db);

    final clock = Stopwatch()..start();
    final shown = await scrollToOldest(repo, [1]);
    // ignore: avoid_print
    print('scroll 1: ${shown.length} rows in ${(shown.length / _pageSize).ceil()} pages, ${clock.elapsedMilliseconds} ms');
    expect(shown, hasLength(60000));
    expect(guidsOf(shown), await expectedTimeline(db, [1]));
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('2. 200 messages sharing one time page correctly across page edges', () async {
    final seed = Seed()..chat(1);
    for (var i = 1; i <= 30; i++) {
      seed.message(i, 1, baseMs + i * 1000);
    }
    // Ids are not in time order relative to the neighbours, as when history arrives late.
    for (var i = 0; i < 200; i++) {
      seed.message(1000 + (i * 37) % 200, 1, baseMs + 15500);
    }
    await seed.into(db);

    final shown = await scrollToOldest(repo, [1], limit: 25);
    expect(shown, hasLength(230));
    expect(guidsOf(shown), await expectedTimeline(db, [1]));
    final tied = shown.where((m) => m.dateCreated == at(baseMs + 15500)).map((m) => m.id!).toList();
    expect(tied, List.generate(200, (i) => 1199 - i));
  });

  test('3. delivered-before-created rows sit in Message.sort order, no skip or repeat at page edges', () async {
    final seed = Seed()..chat(1);
    for (var i = 1; i <= 500; i++) {
      final ms = baseMs + i * 1000;
      // Every 3rd sent message reports delivery before its creation, some by minutes.
      seed.message(i, 1, ms, deliveredMs: i % 3 == 0 ? ms - (i % 9 == 0 ? 180000 : 1500) : null);
    }
    await seed.into(db);

    final shown = await scrollToOldest(repo, [1], limit: 7);
    final inMemory = shown.toList()..sort(Message.sort);
    expect(shown, hasLength(500));
    expect(guidsOf(shown), guidsOf(inMemory));
    expect(guidsOf(shown), await expectedTimeline(db, [1]));
  });

  test('4. arrivals mid-scroll do not change the next older page', () async {
    final seed = Seed()..chat(1);
    for (var i = 1; i <= 200; i++) {
      seed.message(i, 1, baseMs + i * 1000);
    }
    await seed.into(db);

    var nextId = 10000;
    final before = <int, List<String>>{};
    final shown = await scrollToOldest(repo, [1], between: (page, shown) async {
      before[page] = guidsOf(await repo.olderThan([1], MessageKey.of(shown.last)));
      // New messages arrive (socket/FCM) and a reaction to a row on screen.
      await db.write((tx) async {
        for (var k = 0; k < 3; k++) {
          final m = Message(id: ++nextId, guid: 'new$nextId', dateCreated: at(baseMs + 500000 + nextId))..chat.targetId = 1;
          await _insert(tx, m);
        }
        final r = Message(id: ++nextId, guid: 'r$nextId', dateCreated: at(baseMs + 500000 + nextId), associatedMessageGuid: shown.last.guid)
          ..chat.targetId = 1;
        await _insert(tx, r);
      });
      expect(guidsOf(await repo.olderThan([1], MessageKey.of(shown.last))), before[page], reason: 'page ${page + 1} moved');
    });
    // The walk saw the original 200 plus only the arrivals that were already there at open.
    expect(guidsOf(shown).where((g) => g.startsWith('m')), List.generate(200, (i) => 'm${200 - i}'));
    expect(guidsOf(shown).where((g) => !g.startsWith('m')), isEmpty);
    // And the newest page now shows the arrivals.
    expect(guidsOf(await repo.newest([1], limit: 3)).every((g) => g.startsWith('new')), isTrue);
  });

  test('6. deleting a row on screen and one just older than the oldest row shown: no skip, no repeat', () async {
    final seed = Seed()..chat(1);
    for (var i = 1; i <= 120; i++) {
      seed.message(i, 1, baseMs + i * 1000);
    }
    await seed.into(db);

    final deleted = <String>{};
    final shown = await scrollToOldest(repo, [1], limit: 10, between: (page, shown) async {
      if (page % 2 != 0) return;
      final onScreen = shown[shown.length - 3];
      final nextOlder = (await repo.olderThan([1], MessageKey.of(shown.last), limit: 1)).firstOrNull;
      await db.write((tx) async {
        for (final m in [onScreen, ?nextOlder]) {
          await tx.execute('UPDATE messages SET date_deleted_us = ? WHERE id = ?', [baseMs * 1000, m.id]);
          deleted.add(m.guid!);
        }
      });
    });
    final remaining = List.generate(120, (i) => 'm${120 - i}');
    final notShown = deleted.where((g) => !guidsOf(shown).contains(g)).toSet();
    // Rows deleted before the walk reached them are skipped; every other row shows once, in order.
    expect(guidsOf(shown), remaining.where((g) => !notShown.contains(g)).toList());
    expect(notShown, isNotEmpty);
  });

  test('7. 8,000 rows from 2017 saved after newer ones are reached in date order; late rows inside the shown range stay out', () async {
    final seed = Seed()..chat(1);
    for (var i = 1; i <= 2000; i++) {
      seed.message(i, 1, baseMs + i * 60000); // 2017-07 onwards
    }
    await seed.into(db);
    // Late history: higher ids, older dates (the seq.39 trap: newest id != newest date).
    final late = Seed();
    for (var i = 0; i < 8000; i++) {
      late.message(5000 + i, 1, baseMs - (8000 - i) * 60000, guid: 'old${5000 + i}');
    }
    await late.into(db);

    var insertedInRange = false;
    final shown = await scrollToOldest(repo, [1], between: (page, shown) async {
      if (page != 10) return;
      // A message dated inside what is already shown, saved now: paging older never returns it.
      await db.write((tx) => _insert(
          tx, Message(id: 99999, guid: 'inrange', dateCreated: shown[shown.length - 100].dateCreated!.add(const Duration(seconds: 1)))
            ..chat.targetId = 1));
      insertedInRange = true;
    });
    expect(insertedInRange, isTrue);
    expect(shown, hasLength(10000));
    expect(guidsOf(shown).take(2000), List.generate(2000, (i) => 'm${2000 - i}'));
    expect(guidsOf(shown).skip(2000), List.generate(8000, (i) => 'old${12999 - i}'));
    // Reloading that range (scroll back down) shows it in place.
    final anchor = shown[shown.length - 9900];
    final around = await repo.around([1], MessageKey.of(anchor), before: 150, after: 150);
    expect(guidsOf(around), contains('inrange'));
    final sorted = around.toList()..sort(Message.sort);
    expect(guidsOf(around), guidsOf(sorted));
  });

  test('8. two merged chat ids: interleaved, then folded mid-scroll; no duplicates, strictly older, complete', () async {
    final seed = Seed()
      ..chat(1)
      ..chat(2);
    for (var i = 1; i <= 400; i++) {
      // Interleaved, with cross-chat ties every 10th.
      seed.message(i, i.isEven ? 1 : 2, baseMs + (i % 10 == 0 ? i - 1 : i) * 1000);
    }
    await seed.into(db);
    final expected = await expectedTimeline(db, [1, 2]);

    final shown = await scrollToOldest(repo, [1, 2], limit: 25, between: (page, _) async {
      if (page != 5) return;
      // Folding moves the twin's messages into the canonical chat (service twins).
      await db.write((tx) => tx.execute('UPDATE messages SET chat_id = 1 WHERE chat_id = 2'));
    });
    expect(guidsOf(shown), expected);
    expect(guidsOf(shown).toSet(), hasLength(400));
    // After the fold a single chat id gives the same timeline, and a chat id
    // passed twice (canonical listed again as a twin) adds nothing.
    expect(guidsOf(await scrollToOldest(repo, [1])), expected);
    expect(guidsOf(await scrollToOldest(repo, [1, 1, 2])), expected);
  });

  test('11. around(): the target once, N on each side, also inside a run of equal times', () async {
    final seed = Seed()..chat(1);
    for (var i = 1; i <= 100; i++) {
      seed.message(i, 1, baseMs + i * 1000);
    }
    for (var i = 0; i < 80; i++) {
      seed.message(200 + i, 1, baseMs + 50500); // 80-way tie in the middle
    }
    await seed.into(db);
    final timeline = await expectedTimeline(db, [1]);

    for (final target in ['m50', 'm240', 'm200', 'm279', 'm1', 'm100']) {
      final m = (await repo.byGuid(target))!;
      final page = await repo.around([1], MessageKey.of(m), before: 25, after: 25);
      final at = timeline.indexOf(target);
      expect(guidsOf(page).where((g) => g == target), hasLength(1), reason: target);
      expect(guidsOf(page), timeline.sublist(max(0, at - 25), min(timeline.length, at + 26)), reason: target);
    }
  });

  test('12. regression guard (seq.39): the walk fails if olderThan returns a page it already returned', () async {
    final seed = Seed()..chat(1);
    for (var i = 1; i <= 60; i++) {
      seed.message(i, 1, baseMs + i * 1000);
    }
    await seed.into(db);

    // A repository that answers "older than X" with the same window every time
    // (as seq.39's offset counting did) is caught on the second request.
    final stuck = _StuckRepo(db);
    await expectLater(scrollToOldest(stuck, [1]), throwsA(isA<TestFailure>()));
    expect(stuck.olderCalls, 2);
    // The real repository walks to the end with one request per page.
    final counting = _CountingRepo(db);
    final shown = await scrollToOldest(counting, [1]);
    expect(shown, hasLength(60));
    expect(counting.requested, hasLength(3));
    expect(counting.requested.toSet(), hasLength(3));
  });
}

int max(int a, int b) => a > b ? a : b;
int min(int a, int b) => a < b ? a : b;

Future<void> _insert(WriteTx tx, Message m) {
  final row = messageToRow(m);
  return tx.execute(upsertSql('messages', row.keys.toList()), row.values.toList());
}

class _StuckRepo extends MessageRepo {
  _StuckRepo(super.db);

  int olderCalls = 0;
  List<Message>? _first;

  @override
  Future<List<Message>> olderThan(List<int> chatIds, MessageKey key, {int limit = 25, bool includeDeleted = false}) async {
    olderCalls++;
    return _first ??= await super.olderThan(chatIds, key, limit: limit);
  }
}

class _CountingRepo extends MessageRepo {
  _CountingRepo(super.db);

  final requested = <MessageKey>[];

  @override
  Future<List<Message>> olderThan(List<int> chatIds, MessageKey key, {int limit = 25, bool includeDeleted = false}) {
    requested.add(key);
    return super.olderThan(chatIds, key, limit: limit);
  }
}
