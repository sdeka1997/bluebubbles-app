import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/service_twin_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

Chat copy(String guid, {String? stored, String? renamed, bool locked = false}) =>
    Chat(guid: guid, displayName: stored, latestGroupTitle: renamed, lockChatName: locked);

void main() {
  test('a copy that was renamed names the thread over one that never was', () {
    final thread = copy('a', stored: '');
    expect(threadName(thread, [thread, copy('b', renamed: 'friends')]), 'friends');
  });

  test('a removed name on any copy shows the people, whatever another copy stores', () {
    final thread = copy('a', stored: 'old');
    expect(threadName(thread, [thread, copy('b', stored: 'old', renamed: '')]), '');
  });

  test('renamed copies that disagree follow the newest rename on this phone', () {
    final thread = copy('a', renamed: 'first');
    final rename = Message(guid: 'r', itemType: 2, groupTitle: 'second', dateCreated: DateTime(2026));
    expect(threadName(thread, [thread, copy('b', renamed: 'second')], newestRename: rename), 'second');
    final cleared = Message(guid: 'c', itemType: 2, dateCreated: DateTime(2026));
    expect(threadName(thread, [thread, copy('b', renamed: 'second')], newestRename: cleared), '');
  });

  test('with no renames, a stored name beats an empty one', () {
    final thread = copy('a', stored: '');
    expect(threadName(thread, [thread, copy('b', stored: 'yadi')]), 'yadi');
  });

  test('a lone chat behaves like its own current name', () {
    final chat = copy('a', stored: '.', renamed: '');
    expect(threadName(chat, [chat]), chat.currentName);
    final plain = copy('b', stored: 'family');
    expect(threadName(plain, [plain]), 'family');
  });

  test('a name set on this phone still wins', () {
    final thread = copy('a', stored: 'mine', locked: true);
    expect(threadName(thread, [thread, copy('b', renamed: 'theirs')]), 'mine');
  });
}
