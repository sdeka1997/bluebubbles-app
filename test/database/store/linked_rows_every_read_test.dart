// A reaction previews the message it reacts to, and an add/remove event names
// the person, whichever store read loaded the row: both links are relations
// the repository fills with every other relation (relation_fill.dart), not a
// second fill each read path has to remember.
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'store_fixture.dart';

const loved = 'You loved “hello there”';
const addedBob = 'You added Bob Builder to the conversation.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  storeTests((fixture) {
    late Chat chat;
    late Message target, reaction, added;

    setUp(() async {
      chat = await fixture().chat('c');
      final bob = await fixture().handle('bob@example.com', rowId: 7);
      await fixture().contact('n1', 'Bob Builder', handles: [bob]);
      target = await fixture().message('target', chat, t0, text: 'hello there');
      reaction = await fixture().message('r', chat, t0 + 1000, reactsTo: 'target', text: 'Loved “hello there”');
      added = await fixture().message('added', chat, t0 + 2000,
          itemType: 1, edit: (m) => m..groupActionType = 0..otherHandle = 7);
    });

    test('the chat list: a chat read with its latest message', () async {
      await fixture().setLatest(chat, reaction);
      expect((await fixture().store.chatById(chat.id!))!.latestMessage!.getNotificationText(), loved);
      expect((await fixture().store.chatsByIds([chat.id!])).single.latestMessage!.getNotificationText(), loved);
      await fixture().setLatest(chat, added);
      expect((await fixture().store.chatById(chat.id!))!.latestMessage!.getNotificationText(), addedBob);
    });

    test("a chat's newest message (after a delete, retry or unsend)", () async {
      expect((await fixture().store.newestMessageIn(chat.id!))!.getNotificationText(), loved);
      expect((await fixture().store.newestMessageIn(chat.id!, listing: false))!.getNotificationText(), addedBob);
    });

    test('one message by id or guid, and several by id', () async {
      expect((await fixture().store.messageById(reaction.id!))!.getNotificationText(), loved);
      expect((await fixture().store.messageByGuid('added'))!.getNotificationText(), addedBob);
      final both = await fixture().store.messagesByIds([reaction.id!, added.id!]);
      expect(both.map((m) => m.getNotificationText()), [loved, addedBob]);
    });

    test('the reactions on a message, and messages created since a time', () async {
      expect((await fixture().store.messagesAssociatedWith('target')).single.getNotificationText(), loved);
      final since = await fixture().store.messagesCreatedAfter(t0 - 1);
      expect(since.firstWhere((m) => m.guid == 'r').getNotificationText(), loved);
      expect(since.firstWhere((m) => m.guid == 'added').getNotificationText(), addedBob);
    });

    test('a page of the chat, with the reactions set on their messages', () async {
      final page = (await fixture().store.olderMessagePage(chat.id!, limit: 10)).messages;
      expect(page.firstWhere((m) => m.guid == 'added').getNotificationText(), addedBob);
      final shown = page.firstWhere((m) => m.guid == target.guid);
      expect(shown.associatedMessages.single.getNotificationText(), loved);
      expect(shown.associatedMessages.single.reactionTarget.target, same(shown), reason: 'read once, not again');
    });

    test('a reaction whose message is gone, and an event whose person is unknown, still read', () async {
      final orphan = await fixture().message('orphan', chat, t0 + 3000, reactsTo: 'gone', text: 'Loved “gone”');
      final stranger = await fixture().message('stranger', chat, t0 + 4000,
          itemType: 1, edit: (m) => m..groupActionType = 1..otherHandle = 99);
      final read = await fixture().store.messagesByIds([orphan.id!, stranger.id!]);
      expect(read.map((m) => m.getNotificationText()),
          ['You Loved “gone”', 'You removed someone from the conversation.']);
    });
  });
}
