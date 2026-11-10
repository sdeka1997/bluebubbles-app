// The chat-stats screen reads through MessagingStore.chatStats (S2 switch plan,
// commit 7) from ChatStatsRepo, and the screen itself no longer queries
// ObjectBox.
import 'dart:io';

import 'package:bluebubbles/services/ui/chat/chat_stats/chat_stats_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../database/store/store_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  storeTests((fixture) {
    test('counts, timestamps, texts and reactions of one chat', () async {
      final bob = await fixture().handle('bob@x.com', rowId: 7);
      final chat = await fixture().chat('c', handles: [bob]);
      final other = await fixture().chat('other');
      await fixture().message('mine1', chat, t0, text: 'hello there');
      await fixture().message('mine2', chat, t0 + 2000, text: 'hi');
      await fixture().message('theirs', chat, t0 + 1000, from: bob, text: 'yo');
      await fixture().message('love', chat, t0 + 3000, from: bob, reactsTo: 'mine1');
      await fixture().message('gone', chat, t0 + 4000, deleted: true);
      await fixture().message('rename', chat, t0 + 5000, itemType: 2);
      await fixture().message('elsewhere', other, t0 + 6000);

      final stats = fixture().store.chatStats(chat);

      expect(await stats.messageCountForTier(), 3);
      expect(await stats.sentCount(), 2);
      expect(await stats.receivedCount(), 1);
      expect(await stats.receivedCount(participantId: bob.id), 1);
      expect(await stats.cacheKey(), (count: 3, latestMillis: t0 + 2000));
      expect(await stats.firstMessageMillis(), t0);
      expect(await stats.timestampsByParticipant(), {
        kMeParticipantId: [t0, t0 + 2000],
        bob.id!: [t0 + 1000],
      });
      expect(await stats.timestampsByParticipant(sinceMillis: t0 + 1500), {
        kMeParticipantId: [t0 + 2000],
      });
      expect(await stats.participantHandleIds(), [bob.id]);
      expect((await stats.recentTexts(fromMe: true)).toSet(), {'hello there', 'hi'});
      expect(await stats.reactions(), [(type: 'love', participantId: bob.id!)]);
      expect(await stats.textCoverage(), 1.0);
      expect((await stats.groupEvents()).map((e) => e.dateMillis), [t0 + 5000]);
    });
  });

  test('the stats controller reads only through MessagingStore', () {
    final source =
        File('lib/app/layouts/conversation_details/pages/chat_stats/chat_stats_controller.dart').readAsStringSync();
    expect(source, isNot(contains('ChatStatsQueries.')));
    expect(source, isNot(contains('Database.')));
  });
}
