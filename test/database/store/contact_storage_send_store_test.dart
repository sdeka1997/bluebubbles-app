import 'dart:io';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/env.dart';
import 'package:bluebubbles/models/models.dart';
import 'package:bluebubbles/services/backend/actions/storage_actions.dart';
import 'package:bluebubbles/services/backend/interfaces/contact_v2_interface.dart';
import 'package:bluebubbles/services/backend/send_target_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'store_fixture.dart';

void main() {
  setUpAll(() => isIsolateOverride = true);
  tearDownAll(() => isIsolateOverride = false);

  forEachStore((fixture) {
    group('contact links', () {
      test('sync links matching handles to the contact and an empty one-to-one chat', () async {
        final old = await fixture().handle('old@example.com');
        final email = await fixture().handle('ana@example.com');
        final phone = await fixture().handle('+155****0001');
        await fixture().contact('native-1', 'Old Name', handles: [old]);
        final chat = await fixture().chat('iMessage;-;ana@example.com');
        final incoming = ContactV2(
          nativeContactId: 'native-1',
          displayName: 'Ana New',
          addresses: const ['ana@example.com', '+155****0001'],
          firstName: 'Ana',
        )
          ..emailAddresses = const [ContactEmail(address: 'ana@example.com', label: 'work')]
          ..phoneNumbers = const [ContactPhone(number: '+1 (555) 0001', label: 'mobile')];

        final result = await fixture().store.syncContacts(
          [incoming],
          {'native-1': '/avatars/ana.jpg'},
          fetched: true,
        );

        expect(result.matchedContactCount, 1);
        expect(result.affectedHandleIds, unorderedEquals([old.id, email.id, phone.id]));
        final stored = (await fixture().store.contactById((await fixture().store.findContactId('native-1'))!))!;
        expect(stored.displayName, 'Ana New');
        expect(stored.avatarPath, '/avatars/ana.jpg');
        expect(stored.handles.map((h) => h.address), unorderedEquals(['ana@example.com', '+155****0001']));
        expect((await fixture().store.chatByGuid(chat.guid))!.handles.map((h) => h.address), ['ana@example.com']);
      });

      test('ContactV2Interface hydrates each contact linked to any requested handle once', () async {
        final ana = await fixture().handle('ana@example.com');
        final bo = await fixture().handle('+155****0001');
        await fixture().contact('ana', 'Ana', handles: [ana, bo]);
        await fixture().contact('bo', 'Bo', handles: [bo]);

        final contacts = await ContactV2Interface.getContactsForHandles(handleIds: [bo.id!, ana.id!, bo.id!]);

        expect(contacts.map((c) => c.nativeContactId), unorderedEquals(['ana', 'bo']));
        final anaContact = contacts.singleWhere((c) => c.nativeContactId == 'ana');
        expect(anaContact.handles.map((h) => h.address), unorderedEquals(['ana@example.com', '+155****0001']));
      });
    });

    group('storage filters and reset', () {
      test('analyze applies both chat and age filters before walking attachment folders', () async {
        final root = Directory.systemTemp.createTempSync('bb_storage_filter_');
        addTearDown(() => root.deleteSync(recursive: true));
        final attachments = Directory(p.join(root.path, 'attachments'))..createSync();

        final wantedChat = await fixture().chat('iMessage;-;wanted');
        final otherChat = await fixture().chat('iMessage;-;other');
        final oldWanted = await fixture().message('old-wanted', wantedChat, t0);
        final newWanted = await fixture().message(
          'new-wanted',
          wantedChat,
          DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
        );
        final oldOther = await fixture().message('old-other', otherChat, t0);
        await fixture().attachment('photo-guid', oldWanted, mimeType: 'image/jpeg');
        await fixture().attachment('video-guid', newWanted, mimeType: 'video/mp4');
        await fixture().attachment('audio-guid', oldOther, mimeType: 'audio/mpeg');

        void file(String guid, String name) {
          final dir = Directory(p.join(attachments.path, guid))..createSync();
          File(p.join(dir.path, name)).writeAsBytesSync([1, 2, 3]);
        }

        file('photo-guid', 'photo.jpg');
        file('video-guid', 'video.mp4');
        file('audio-guid', 'audio.mp3');

        final map = await StorageActions.analyze({
          'chatGuid': wantedChat.guid,
          'ageFilter': StorageAgeFilter.year1.name,
          'runId': 'filter-test',
          'attachmentsPath': attachments.path,
          'urlPreviewsPath': null,
        });
        final result = StorageAnalysisResult.fromMap(map);

        expect(result.segment(StorageSegmentType.photos)?.fileCount, 1);
        expect(result.totalFiles, 1);
        expect(result.segment(StorageSegmentType.videos), isNull);
        expect(result.segment(StorageSegmentType.audio), isNull);
      });

      test('deleting an original resets the attachment row after filesystem deletion', () async {
        final root = Directory.systemTemp.createTempSync('bb_storage_reset_');
        addTearDown(() => root.deleteSync(recursive: true));
        final attachments = Directory(p.join(root.path, 'attachments'))..createSync();
        final folder = Directory(p.join(attachments.path, 'photo-guid'))..createSync();
        File(p.join(folder.path, 'photo.jpg')).writeAsBytesSync([1, 2, 3, 4]);

        final chat = await fixture().chat('iMessage;-;wanted');
        final message = await fixture().message('m1', chat, t0);
        final attachment = (await fixture().attachment('photo-guid', message, mimeType: 'image/jpeg'))
          ..isDownloaded = true
          ..width = 100
          ..height = 80
          ..metadata = {'_orientation_processed': true, '_raw_width': 100};
        await MessagingStore.current.saveAttachment(attachment, message: message);

        final result = await StorageActions.deleteAttachments({
          'chatGuid': null,
          'ageFilter': StorageAgeFilter.all.name,
          'segments': [StorageSegmentType.photos.name],
          'attachmentsPath': attachments.path,
          'urlPreviewsPath': null,
        });

        expect(result['attachmentsReset'], 1);
        expect(folder.existsSync(), isFalse);
        final stored = (await fixture().store.attachmentById(attachment.id!))!;
        expect(stored.isDownloaded, isFalse);
        expect((stored.width, stored.height, stored.exif), (null, null, null));
        expect(stored.metadata?['_orientation_processed'], isNull);
        expect(stored.metadata?['_raw_width'], isNull);
      });
    });

    group('send target latest selection', () {
      test('resolve chooses the same-service copy with the latest activity', () async {
        final ana = await fixture().handle('ana@example.com', service: 'RCS');
        final bo = await fixture().handle('bo@example.com', service: 'RCS');
        final thread = await fixture().chat('RCS;+;old-copy', handles: [ana, bo], threadKey: 'group-thread');
        final latestCopy = await fixture().chat('RCS;+;new-copy', handles: [ana, bo], threadKey: 'group-thread');
        await fixture().message(
          'latest',
          thread,
          t0 + 1000,
          appleChatGuid: latestCopy.guid,
          service: 'RCS',
        );

        final resolved = await SendTargetResolver.resolve(thread);

        expect(resolved.guid, latestCopy.guid);
      });
    });
  });
}
