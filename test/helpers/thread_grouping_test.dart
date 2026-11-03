import 'package:bluebubbles/helpers/types/helpers/thread_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

ChatKeys group(String guid,
        {String? groupId,
        String? originalGroupId,
        List<String> legacy = const [],
        required Set<String> people,
        String? name,
        String? identifier}) =>
    ChatKeys(
      guid: guid,
      chatIdentifier: identifier ?? guid.split(';').last,
      isGroup: true,
      groupIds: {if (groupId != null) groupId, if (originalGroupId != null) originalGroupId, ...legacy},
      people: people,
      name: name ?? '',
    );

ChatKeys oneToOne(String guid, String person) => ChatKeys(
      guid: guid,
      chatIdentifier: guid.split(';').last,
      isGroup: false,
      groupIds: const {},
      people: {person},
      name: '',
    );

/// The threads [chats] fall into, each as a set of guids.
Set<Set<String>> threads(List<ChatKeys> chats) {
  final keys = threadKeys(chats);
  final byKey = <String, Set<String>>{};
  keys.forEach((guid, key) => byKey.putIfAbsent(key, () => {}).add(guid));
  return byKey.values.toSet();
}

void main() {
  const a = 'card:A', b = 'card:B', c = 'card:C', d = 'card:D';

  test('copies of one chat on iMessage, SMS and RCS are one thread', () {
    expect(
        threads([
          group('iMessage;+;chat1', people: {a, b}, name: 'x', identifier: 'chat1'),
          group('SMS;+;chat1', people: {a, b}, name: 'other', identifier: 'chat1'),
        ]),
        {
          {'iMessage;+;chat1', 'SMS;+;chat1'}
        });
  });

  test('a member added under a new group id stays in the thread through the old id (Ming)', () {
    expect(
        threads([
          group('iMessage;+;old', groupId: 'G-OLD', people: {a, b}, name: 'Ming Dynasty'),
          group('iMessage;+;new', groupId: 'G-NEW', legacy: ['G-OLD'], people: {a, b, c}, name: 'Ming Dynasty'),
        ]),
        {
          {'iMessage;+;old', 'iMessage;+;new'}
        });
  });

  test('an old unnamed copy joins a renamed thread through its old group id (Family)', () {
    expect(
        threads([
          group('iMessage;+;fam', groupId: 'G1', legacy: ['G-2440'], people: {a, b}, name: 'family'),
          group('iMessage;+;2440', groupId: 'G-2440', people: {a, b}, name: ''),
        ]),
        {
          {'iMessage;+;fam', 'iMessage;+;2440'}
        });
  });

  test('an original group id links copies too', () {
    expect(
        threads([
          group('iMessage;+;x', groupId: 'G-NOW', originalGroupId: 'G-FIRST', people: {a, b}),
          group('SMS;+;y', groupId: 'G-FIRST', people: {a, c}),
        ]),
        {
          {'iMessage;+;x', 'SMS;+;y'}
        });
  });

  test('groups with the same people and the same name are one thread', () {
    expect(
        threads([
          group('iMessage;+;1', groupId: 'G1', people: {a, b}, name: 'apes'),
          group('iMessage;+;2', groupId: 'G2', people: {b, a}, name: 'apes'),
        ]),
        {
          {'iMessage;+;1', 'iMessage;+;2'}
        });
  });

  test('no name counts as a name: two unnamed groups with the same people are one thread', () {
    expect(
        threads([
          group('iMessage;+;1', groupId: 'G1', people: {a, b}),
          group('SMS;+;2', groupId: 'G2', people: {a, b}),
        ]),
        {
          {'iMessage;+;1', 'SMS;+;2'}
        });
  });

  test('same people with different names stay separate (apes vs mb setl)', () {
    expect(
        threads([
          group('iMessage;+;1', groupId: 'G1', people: {a, b}, name: 'apes'),
          group('iMessage;+;2', groupId: 'G2', people: {a, b}, name: 'mb setl'),
        ]),
        {
          {'iMessage;+;1'},
          {'iMessage;+;2'}
        });
  });

  test('a named and an unnamed group with the same people stay separate', () {
    expect(
        threads([
          group('iMessage;+;1', groupId: 'G1', people: {a, b}, name: 'Roomies'),
          group('iMessage;+;2', groupId: 'G2', people: {a, b}),
        ]),
        hasLength(2));
  });

  test('the same name with different people stays separate', () {
    expect(
        threads([
          group('iMessage;+;1', groupId: 'G1', people: {a, b}, name: 'Hoops'),
          group('iMessage;+;2', groupId: 'G2', people: {a, c}, name: 'Hoops'),
        ]),
        hasLength(2));
  });

  test('names compare after trimming surrounding spaces', () {
    expect(
        threads([
          group('iMessage;+;1', groupId: 'G1', people: {a, b}, name: 'apes '),
          group('iMessage;+;2', groupId: 'G2', people: {a, b}, name: 'apes'),
        ]),
        hasLength(1));
  });

  test('links chain: A to B by group id, B to C by people and name', () {
    expect(
        threads([
          group('iMessage;+;A', groupId: 'G-A', people: {a, b, c}, name: 'n'),
          group('iMessage;+;B', groupId: 'G-B', legacy: ['G-A'], people: {a, b}, name: 'm'),
          group('SMS;+;C', groupId: 'G-C', people: {a, b}, name: 'm'),
        ]),
        {
          {'iMessage;+;A', 'iMessage;+;B', 'SMS;+;C'}
        });
  });

  test('one-to-one chats with the same person are one thread (email and phone on one card)', () {
    expect(
        threads([
          oneToOne('iMessage;-;jiahui@example.com', a),
          oneToOne('iMessage;-;+15550000001', a),
          oneToOne('SMS;-;+15550000001', a),
          oneToOne('iMessage;-;+15550000002', b),
        ]),
        {
          {'iMessage;-;jiahui@example.com', 'iMessage;-;+15550000001', 'SMS;-;+15550000001'},
          {'iMessage;-;+15550000002'}
        });
  });

  test('a one-to-one chat never joins a group with the same person', () {
    expect(
        threads([
          oneToOne('iMessage;-;+15550000001', a),
          group('iMessage;+;g', groupId: 'G', people: {a}),
        ]),
        hasLength(2));
  });

  test('a group with no participants only joins by chat identifier or group id', () {
    expect(
        threads([
          group('iMessage;+;1', groupId: 'G1', people: {}),
          group('iMessage;+;2', groupId: 'G2', people: {}),
        ]),
        hasLength(2));
  });

  test('empty group ids link nothing', () {
    expect(
        threads([
          group('iMessage;+;1', groupId: '', people: {a, b}, name: 'p'),
          group('iMessage;+;2', groupId: '', people: {c, d}, name: 'q'),
        ]),
        hasLength(2));
  });

  test('the thread key does not depend on input order', () {
    final chats = [
      group('iMessage;+;old', groupId: 'G-OLD', people: {a, b}, name: 'M'),
      group('iMessage;+;new', groupId: 'G-NEW', legacy: ['G-OLD'], people: {a, b, c}, name: 'M'),
      group('SMS;+;sms', groupId: 'G-S', people: {a, b, c}, name: 'M'),
    ];
    expect(threadKeys(chats), threadKeys(chats.reversed.toList()));
  });
}
