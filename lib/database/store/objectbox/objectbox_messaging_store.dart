import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/objectbox/objectbox_attachment_store.dart';
import 'package:bluebubbles/database/store/objectbox/objectbox_custom_group_store.dart';
import 'package:bluebubbles/database/store/objectbox/objectbox_handle_store.dart';
import 'package:bluebubbles/database/store/objectbox/objectbox_message_store.dart';
import 'package:bluebubbles/database/store/objectbox/objectbox_sync_helper_store.dart';
import 'package:bluebubbles/database/store/objectbox/objectbox_sync_store.dart';

/// [MessagingStore] on ObjectBox: the Actions' own code, moved here unchanged
/// (it reads and writes `Database.*` as it did inside the Actions).
class ObjectBoxMessagingStore extends MessagingStore
    with
        ObjectBoxHandleStore,
        ObjectBoxCustomGroupStore,
        ObjectBoxMessageStore,
        ObjectBoxAttachmentStore,
        ObjectBoxSyncHelperStore,
        ObjectBoxSyncStore {
  @override
  ActiveStore get kind => ActiveStore.objectBox;
}
