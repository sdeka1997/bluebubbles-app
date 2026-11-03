import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Chat.fromMap keeps the Messages group ids and newest rename', () {
    final chat = Chat.fromMap({
      'guid': 'iMessage;+;chat1',
      'groupId': 'G-NOW',
      'originalGroupId': 'G-FIRST',
      'legacyGroupIds': ['G-OLD', 'G-OLDER'],
      'latestGroupTitle': 'family',
    });

    expect(chat.originalGroupId, 'G-FIRST');
    expect(chat.legacyGroupIds, ['G-OLD', 'G-OLDER']);
    expect(chat.latestGroupTitle, 'family');
    final round = Chat.fromMap(chat.toMap());
    expect(round.originalGroupId, 'G-FIRST');
    expect(round.legacyGroupIds, ['G-OLD', 'G-OLDER']);
    expect(round.latestGroupTitle, 'family');
  });

  test('a cleared name stays empty, not unknown', () {
    expect(Chat.fromMap({'guid': 'g', 'latestGroupTitle': ''}).latestGroupTitle, '');
  });

  test('an older server leaves the new fields unknown', () {
    final chat = Chat.fromMap({'guid': 'SMS;-;+15550000001'});
    expect(chat.originalGroupId, isNull);
    expect(chat.legacyGroupIds, isNull);
    expect(chat.latestGroupTitle, isNull);
  });

  test('merging keeps known values over unknown ones', () {
    final stored = Chat(guid: 'g', originalGroupId: 'G1', legacyGroupIds: ['A'], latestGroupTitle: 'x');
    stored.merge(Chat(guid: 'g'));
    expect(stored.originalGroupId, 'G1');
    expect(stored.legacyGroupIds, ['A']);
    expect(stored.latestGroupTitle, 'x');
    stored.merge(Chat(guid: 'g', originalGroupId: 'G2', legacyGroupIds: ['B'], latestGroupTitle: ''));
    expect(stored.originalGroupId, 'G2');
    expect(stored.legacyGroupIds, ['B']);
    expect(stored.latestGroupTitle, '');
  });
}
