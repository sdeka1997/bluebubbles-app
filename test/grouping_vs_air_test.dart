// Checks the app grouping code against a Mac's data; skipped unless GROUPING_FIXTURE is set.
// Run with GROUPING_FIXTURE=/path/to/fixture.json.
import 'dart:convert';
import 'dart:io';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/chat_keys.dart';
import 'package:bluebubbles/helpers/types/helpers/thread_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final path = Platform.environment['GROUPING_FIXTURE'];
  test('grouping matches the Air', () {
    final data = jsonDecode(File(path!).readAsStringSync()) as Map<String, dynamic>;
    final byAddress = <String, ContactV2>{};
    for (final c in (data['cards'] as List).cast<Map<String, dynamic>>()) {
      final card = ContactV2(nativeContactId: c['id'], displayName: c['id']);
      for (final p in (c['phones'] as List).cast<String>()) {
        for (final v in _variants(p)) {
          byAddress[v] = card;
        }
      }
      for (final e in (c['emails'] as List).cast<String>()) {
        byAddress[ContactV2.normalizeEmail(e)] = card;
      }
    }
    final chats = <Chat>[];
    final rowOf = <String, int>{};
    for (final r in (data['chats'] as List).cast<Map<String, dynamic>>()) {
      final chat = Chat(
        guid: r['guid'],
        chatIdentifier: r['ident'],
        style: r['style'],
        groupId: (r['gid'] as String?)?.isEmpty ?? true ? null : r['gid'],
        originalGroupId: (r['ogid'] as String?)?.isEmpty ?? true ? null : r['ogid'],
        legacyGroupIds: (r['legacy'] as List).cast<String>(),
        displayName: r['name'],
        latestGroupTitle: r['latest'],
      );
      for (final a in (r['people'] as List).cast<String>()) {
        final h = Handle(address: a);
        final card = a.contains('@')
            ? byAddress[ContactV2.normalizeEmail(a)]
            : _variants(a).map((v) => byAddress[v]).nonNulls.firstOrNull;
        if (card != null) h.contactsV2.add(card);
        chat.handles.add(h);
      }
      chats.add(chat);
      rowOf[chat.guid] = r['id'];
    }
    final keys = threadKeys([for (final c in chats) chatKeysFor(c)]);
    final ours = {for (final e in keys.entries) rowOf[e.key]!: e.value};
    final truth = {for (final e in (data['truth'] as Map).entries) int.parse(e.key): e.value as int};

    var missed = 0, wrong = 0, pairsTruth = 0;
    final rows = truth.keys.toList()..sort();
    final missedPairs = <String>[], wrongPairs = <String>[];
    for (var i = 0; i < rows.length; i++) {
      for (var j = i + 1; j < rows.length; j++) {
        final a = rows[i], b = rows[j];
        final sameTruth = truth[a] == truth[b];
        final sameOurs = ours[a] == ours[b];
        if (sameTruth) pairsTruth++;
        if (sameTruth && !sameOurs) {
          missed++;
          if (missedPairs.length < 20) missedPairs.add('$a-$b');
        }
        if (!sameTruth && sameOurs) {
          wrong++;
          if (wrongPairs.length < 40) wrongPairs.add('$a-$b');
        }
      }
    }
    final threads = ours.values.toSet().length;
    final spans = <String, Set<int>>{};
    for (final r in rows) {
      spans.putIfAbsent(ours[r]!, () => {}).add(truth[r]!);
    }
    final out = StringBuffer();
    for (final e in spans.entries.where((e) => e.value.length > 1)) {
      final members = rows.where((r) => ours[r] == e.key).toList();
      out.writeln('SPAN ${members.join(',')}');
    }
    File('/tmp/grouping-spans.txt').writeAsStringSync(out.toString());
    File('/tmp/grouping-ours.json').writeAsStringSync(jsonEncode({for (final e in ours.entries) '${e.key}': e.value}));
    // ignore: avoid_print
    print('RESULT chats=${chats.length} compared=${rows.length} threads=$threads '
        'airPairs=$pairsTruth missed=$missed joinedBeyondAir=$wrong');
    // ignore: avoid_print
    print('MISSED ${missedPairs.join(' ')}');
    // ignore: avoid_print
    print('JOINED ${wrongPairs.join(' ')}');
  }, skip: path == null);
}

/// The forms the app matches a number on: as written, and with the + and a
/// 1-3 digit country code dropped (as ContactV2Actions does).
Set<String> _variants(String phone) {
  final n = ContactV2.normalizePhoneNumber(phone);
  if (n.isEmpty) return {};
  if (!n.startsWith('+')) return {n};
  return {n, n.substring(1), for (var i = 1; i <= 3 && i + 1 < n.length; i++) n.substring(i + 1)};
}
