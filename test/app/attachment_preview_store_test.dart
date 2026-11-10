// Attachment previews look attachments up through MessagingStore (switch plan
// commit 8) when the message in memory carries none: by the message, else by
// the guids its attributed body names.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../database/store/store_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  storeTests((fixture) {
    test('attachments of a message, else of the guids named', () async {
      final chat = await fixture().chat('c');
      final m = await fixture().message('m', chat, t0);
      final bare = await fixture().message('bare', chat, t0 + 1000);
      await fixture().attachment('a1', m);
      await fixture().attachment('a2', m, mimeType: 'video/mp4');
      await fixture().attachment('loose', null);
      final store = fixture().store;

      expect((await store.attachmentsOfMessage(m.id, const [])).map((a) => a.guid).toSet(), {'a1', 'a2'});
      expect((await store.attachmentsOfMessage(m.id, const ['loose'])).map((a) => a.guid).toSet(), {'a1', 'a2'});
      expect((await store.attachmentsOfMessage(bare.id, const ['loose', 'missing'])).map((a) => a.guid), ['loose']);
      expect(await store.attachmentsOfMessage(null, const []), isEmpty);
    });
  });

  test('previews read only through MessagingStore', () {
    for (final path in [
      'lib/app/components/attachment_preview.dart',
      'lib/app/layouts/conversation_list/widgets/tile/pinned_tile_text_bubble.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('Database.')), reason: path);
      expect(source, isNot(contains('Attachment_.')), reason: path);
    }
  });
}
