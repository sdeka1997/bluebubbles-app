import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';

/// Inserts missing attachments and merges stored attachments with incoming
/// server fields taking precedence.
Future<List<Attachment>> syncAttachments(List<Attachment> attachments) {
  return MessagingStore.current.syncAttachments(attachments);
}

/// Inserts missing messages, merges stored messages, and links every result to
/// [chat].
Future<List<Message>> syncMessages(Chat chat, List<Message> messages) {
  return MessagingStore.current.syncMessages(chat, messages);
}
