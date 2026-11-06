import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/message_page.dart';
import 'package:flutter_test/flutter_test.dart';

Message m(int id, int minute, {bool deleted = false}) => Message(
      id: id,
      guid: 'g$id',
      dateCreated: DateTime(2026, 11, 6, 12).add(Duration(minutes: minute)),
      dateDeleted: deleted ? DateTime(2026, 11, 7) : null,
    );

void main() {
  final ids = [for (var i = 1; i <= 1000; i++) i];

  group('which messages to load', () {
    test('the newest-numbered ones, enough for the page plus some saved out of order', () {
      final window = newestPageWindow(ids, offset: 0, limit: 25, latestId: 1000)!;
      expect(window.length, 25 + pageSlack);
      expect(window.first, 1000);
      expect(window.last, 1000 - 25 - pageSlack + 1);
    });

    test('deeper pages load further back', () {
      final window = newestPageWindow(ids, offset: 50, limit: 25, latestId: 1000)!;
      expect(window.length, 50 + 25 + pageSlack);
    });

    test('a chat whose newest message is not among them is sorted whole instead', () {
      // Old history saved again after the newest message: it holds the highest numbers
      expect(newestPageWindow(ids, offset: 0, limit: 25, latestId: 400), isNull);
    });

    test('a chat with no stored newest message is sorted whole instead', () {
      expect(newestPageWindow(ids, offset: 0, limit: 25, latestId: null), isNull);
      expect(newestPageWindow(ids, offset: 0, limit: 25, latestId: 0), isNull);
    });

    test('a small chat loads all of it', () {
      expect(newestPageWindow([3, 1, 2], offset: 0, limit: 25, latestId: 3), [3, 2, 1]);
    });
  });

  group('the page', () {
    test('is newest first by date, even when a few were saved out of order', () {
      final window = [m(10, 10), m(9, 12), m(8, 8), m(7, 11)];
      final page = pageByDate(window, offset: 0, limit: 3, chatSize: 4)!;
      expect(page.map((e) => e.id), [9, 7, 10]);
    });

    test('a deeper page continues where the last one ended', () {
      final window = [for (var i = 1; i <= 10; i++) m(i, i)];
      expect(pageByDate(window, offset: 3, limit: 3, chatSize: 10)!.map((e) => e.id), [7, 6, 5]);
    });

    test('leaves out deleted messages unless asked for them', () {
      final window = [m(3, 3, deleted: true), m(2, 2), m(1, 1)];
      expect(pageByDate(window, offset: 0, limit: 2, chatSize: 3)!.map((e) => e.id), [2, 1]);
      expect(pageByDate(window, offset: 0, limit: 2, chatSize: 3, includeDeleted: true)!.map((e) => e.id), [3, 2]);
    });

    test('too few left to fill it while the chat has more means the chat is sorted whole', () {
      final window = [m(3, 3, deleted: true), m(2, 2, deleted: true)];
      expect(pageByDate(window, offset: 0, limit: 2, chatSize: 500), isNull);
    });

    test('the end of a chat is a short page, not a fallback', () {
      expect(pageByDate([m(2, 2), m(1, 1)], offset: 0, limit: 25, chatSize: 2)!.length, 2);
    });
  });
}
