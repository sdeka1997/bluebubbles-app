import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/sqlite/chat_repo.dart';
import 'package:bluebubbles/database/sqlite/message_repo.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/database/store/sqlite/sqlite_messaging_store.dart';

/// SendTargetResolver reads on SQLite repositories.
mixin SqliteSendTargetStore implements SendTargetStore, SqliteStorePart {
  @override
  Future<SendTargetContext> sendTargetContext(Chat thread, {String? anchorGuid, int recentLimit = 50}) {
    return db.snapshot((reader) async {
      final anchorChatGuid = anchorGuid == null ? null : (await MessageRepo(reader).byGuid(anchorGuid))?.appleChatGuid;
      final copies = thread.threadKey?.isNotEmpty ?? false
          ? await ChatRepo(reader).threadCopies(thread.threadKey!)
          : <Chat>[];
      if (!copies.any((c) => c.guid == thread.guid)) copies.insert(0, thread);
      final recent = thread.id == null
          ? <Message>[]
          : await MessageRepo(reader).recentForChat(thread.id!, limit: recentLimit);
      return SendTargetContext(copies: copies, recent: recent, anchorChatGuid: anchorChatGuid);
    });
  }
}
