import 'package:bluebubbles/database/models.dart';

// Messages lists a thread by its newest ordinary item (item type 0): a
// message, attachment or reaction. Every other item type -- people added or
// removed, a rename or removed name, someone leaving, a group photo, location
// sharing and other status lines -- shows inside the thread but never becomes
// its preview or moves it in the list. Messages counts unread the same way.

/// Whether [message] can be its thread's preview and set its place in the list.
bool listsThread(Message message) => message.isTranscriptVisible && (message.itemType ?? 0) == 0;
