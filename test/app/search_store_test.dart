// Message search reads through MessagingStore (switch plan commit 8): results
// each with its chat, and the search screen no longer queries ObjectBox.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../database/store/store_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  storeTests((fixture) {
    test('text matches newest first, with their chats, and each filter', () async {
      final bob = await fixture().handle('bob@x.com', rowId: 7);
      final chat = await fixture().chat('c', handles: [bob]);
      final other = await fixture().chat('other');
      await fixture().message('mine', chat, t0, text: 'Hello there');
      await fixture().message('bobs', chat, t0 + 1000, from: bob, handleId: 7, text: 'well HELLO');
      await fixture().message('elsewhere', other, t0 + 2000, text: 'hello again');
      await fixture().message('gone', chat, t0 + 3000, text: 'hello', deleted: true);
      await fixture().message('love', chat, t0 + 4000, text: 'hello', reactsTo: 'mine');
      await fixture().message('nope', chat, t0 + 5000, text: 'goodbye');
      final store = fixture().store;

      final all = await store.searchMessages('hello');
      expect(all.map((m) => m.guid), ['elsewhere', 'bobs', 'mine']);
      expect(all.map((m) => m.chat.target?.guid), ['other', 'c', 'c']);
      expect((await store.searchMessages('hello', chatId: chat.id)).map((m) => m.guid), ['bobs', 'mine']);
      expect((await store.searchMessages('hello', isFromMe: false)).map((m) => m.guid), ['bobs']);
      expect((await store.searchMessages('hello', senderRowId: 7)).map((m) => m.guid), ['bobs']);
      expect((await store.searchMessages('hello', since: ms(t0 + 500))).map((m) => m.guid), ['elsewhere', 'bobs']);
      expect((await store.searchMessages('hello', limit: 1)).map((m) => m.guid), ['elsewhere']);
    });

    test('chats by guid, in the order asked, missing ones skipped', () async {
      await fixture().chat('a');
      await fixture().chat('b');

      expect((await fixture().store.chatsByGuids(['b', 'missing', 'a'])).map((c) => c.guid), ['b', 'a']);
    });
  });

  test('the search screen reads only through MessagingStore', () {
    final source = File('lib/app/layouts/conversation_list/pages/search/search_query_helper.dart').readAsStringSync();
    expect(source, isNot(contains('Database.')));
    expect(source, isNot(contains('package:objectbox')));
  });
}
