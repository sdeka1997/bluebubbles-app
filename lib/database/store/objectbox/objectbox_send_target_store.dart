import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';

/// SendTargetResolver's ObjectBox reads, moved behind MessagingStore.
mixin ObjectBoxSendTargetStore implements SendTargetStore {
  @override
  Future<SendTargetContext> sendTargetContext(Chat thread, {String? anchorGuid, int recentLimit = 50}) async {
    String? anchorChatGuid;
    if (anchorGuid != null) {
      final anchor = Database.messages.query(Message_.guid.equals(anchorGuid)).build()..limit = 1;
      anchorChatGuid = anchor.findFirst()?.appleChatGuid;
      anchor.close();
    }

    final copiesQuery = thread.threadKey == null || thread.threadKey!.isEmpty
        ? null
        : Database.chats.query(Chat_.threadKey.equals(thread.threadKey!)).build();
    final storedCopies = copiesQuery?.find() ?? const <Chat>[];
    copiesQuery?.close();
    final live = storedCopies.where((c) => c.dateDeleted == null).toList();
    final copies = live.any((c) => c.guid == thread.guid) ? live : [thread, ...live];

    final query =
        (Database.messages.query()
              ..link(Message_.chat, Chat_.id.equals(thread.id!))
              ..order(Message_.dateCreated, flags: Order.descending))
            .build()
          ..limit = recentLimit;
    final recent = query.find();
    query.close();
    return SendTargetContext(copies: copies, recent: recent, anchorChatGuid: anchorChatGuid);
  }
}
