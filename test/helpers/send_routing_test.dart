import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/classes/chat_service_type.dart';
import 'package:bluebubbles/helpers/types/helpers/send_routing.dart';
import 'package:flutter_test/flutter_test.dart';

SendCopy copy(String guid, ChatServiceType service, {int? incoming, int? active}) => SendCopy(
      guid: guid,
      service: service,
      lastIncoming: incoming == null ? null : DateTime(2026, 1, incoming),
      lastActivity: active == null ? null : DateTime(2026, 1, active),
    );

const im = ChatServiceType.iMessage, sms = ChatServiceType.sms, rcs = ChatServiceType.rcs;

void main() {
  final imA = copy('iMessage;-;+15550000001', im, incoming: 5, active: 6);
  final smsA = copy('SMS;-;+15550000001', sms, incoming: 7, active: 7);
  final rcsA = copy('RCS;-;+15550000001', rcs, incoming: 4, active: 4);
  final one = [(address: '+15550000001', iMessage: true)];
  final off = [(address: '+15550000001', iMessage: false)];
  final unknown = [(address: '+15550000001', iMessage: null)];

  test('iMessage when everyone is on iMessage, even if a text came in later', () {
    final t = pickSendTarget(copies: [imA, smsA, rcsA], isGroup: false, members: one, latestService: sms);
    expect(t.guid, imA.guid);
    expect(t.createIMessageChat, isFalse);
  });

  test('RCS when someone is off iMessage and the latest message was RCS', () {
    expect(pickSendTarget(copies: [imA, smsA, rcsA], isGroup: false, members: off, latestService: rcs).guid, rcsA.guid);
  });

  test('SMS when someone is off iMessage and the latest message was not RCS', () {
    expect(pickSendTarget(copies: [imA, smsA, rcsA], isGroup: false, members: off, latestService: sms).guid, smsA.guid);
    expect(pickSendTarget(copies: [imA, smsA, rcsA], isGroup: false, members: off, latestService: im).guid, smsA.guid);
  });

  test('RCS vs SMS follows the latest text even when an iMessage came after', () {
    expect(
        pickSendTarget(copies: [imA, smsA, rcsA], isGroup: false, members: off, latestService: im, latestTextService: rcs).guid,
        rcsA.guid);
  });

  test('an email is only reachable over iMessage', () {
    final t = pickSendTarget(
        copies: [copy('iMessage;-;a@example.com', im, active: 1)],
        isGroup: false,
        members: [(address: 'a@example.com', iMessage: null)],
        latestService: null);
    expect(t.guid, 'iMessage;-;a@example.com');
  });

  test('unknown iMessage status follows the latest message', () {
    expect(pickSendTarget(copies: [imA, smsA], isGroup: false, members: unknown, latestService: im).guid, imA.guid);
    expect(pickSendTarget(copies: [imA, smsA], isGroup: false, members: unknown, latestService: sms).guid, smsA.guid);
  });

  test('within a service, the copy that last received a message', () {
    final older = copy('iMessage;+;chat1', im, incoming: 3, active: 9);
    final newer = copy('iMessage;+;chat2', im, incoming: 8, active: 8);
    final members = [(address: '+15550000001', iMessage: true), (address: '+15550000002', iMessage: true)];
    expect(pickSendTarget(copies: [older, newer], isGroup: true, members: members, latestService: im).guid, newer.guid);
  });

  test('no incoming yet: the most recently active copy', () {
    final a = copy('iMessage;+;chat1', im, active: 3);
    final b = copy('iMessage;+;chat2', im, active: 5);
    final members = [(address: '+15550000001', iMessage: true), (address: '+15550000002', iMessage: true)];
    expect(pickSendTarget(copies: [a, b], isGroup: true, members: members, latestService: im).guid, b.guid);
  });

  test('a 1:1 on iMessage with no iMessage copy asks for one to be made', () {
    final t = pickSendTarget(copies: [smsA, rcsA], isGroup: false, members: one, latestService: sms);
    expect(t.createIMessageChat, isTrue);
    expect(t.guid, isNull);
  });

  test('a group with no iMessage copy never asks for one; it texts', () {
    final members = [(address: '+15550000001', iMessage: true), (address: '+15550000002', iMessage: true)];
    final t = pickSendTarget(copies: [copy('SMS;+;chat3', sms, active: 2)], isGroup: true, members: members, latestService: sms);
    expect(t.createIMessageChat, isFalse);
    expect(t.guid, 'SMS;+;chat3');
  });

  test('off iMessage with no SMS copy texts through the RCS copy', () {
    expect(pickSendTarget(copies: [imA, rcsA], isGroup: false, members: off, latestService: sms).guid, rcsA.guid);
  });

  test('off iMessage with only an iMessage copy still sends there; the Mac decides', () {
    expect(pickSendTarget(copies: [imA], isGroup: false, members: off, latestService: im).guid, imA.guid);
  });

  group('describeThread', () {
    Message msg(String? apple, int day, {bool fromMe = false, String? service}) =>
        Message(guid: 'm$day', appleChatGuid: apple, dateCreated: DateTime(2026, 1, day), isFromMe: fromMe, service: service);
    final thread = Chat(id: 1, guid: 'SMS;-;+15550000001');
    final imCopy = Chat(id: 2, guid: 'iMessage;-;+15550000001');

    test('times per copy; messages without an Apple chat belong to the thread chat', () {
      final d = describeThread(threadGuid: thread.guid, copies: [thread, imCopy], recent: [
        msg(null, 3),
        msg('iMessage;-;+15550000001', 5),
        msg('iMessage;-;+15550000001', 6, fromMe: true),
      ]);
      expect(d.copies[0].lastIncoming, DateTime(2026, 1, 3));
      expect(d.copies[1].lastIncoming, DateTime(2026, 1, 5));
      expect(d.copies[1].lastActivity, DateTime(2026, 1, 6));
    });

    test('latest service and latest text service', () {
      final d = describeThread(threadGuid: thread.guid, copies: [thread, imCopy], recent: [
        msg(null, 3, service: 'RCS'),
        msg(null, 4, service: 'SMS'),
        msg('iMessage;-;+15550000001', 5),
      ]);
      expect(d.latestService, ChatServiceType.iMessage);
      expect(d.latestTextService, ChatServiceType.sms);
    });

    test('a message filed under SMS but sent over RCS counts as RCS', () {
      final d = describeThread(threadGuid: thread.guid, copies: [thread], recent: [msg(null, 3, service: 'RCS')]);
      expect(d.latestTextService, ChatServiceType.rcs);
    });
  });
}
