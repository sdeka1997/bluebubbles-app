import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/services/backend/descriptors/attachment_query_descriptor.dart';
import 'package:collection/collection.dart';

class AttachmentActions {
  static Future<int> saveAttachmentAsync(dynamic data) async {
    final attachmentData = data['attachmentData'] as Map<String, dynamic>;
    final messageData = data['messageData'] as Map<String, dynamic>?;

    return MessagingStore.current.saveAttachment(
      Attachment.fromMap(attachmentData),
      message: messageData != null ? Message.fromMap(messageData) : null,
    );
  }

  static Future<void> bulkSaveAttachmentsAsync(dynamic data) async {
    final mapData = data['mapData'] as Map<Map<String, dynamic>, List<Map<String, dynamic>>>;

    // Convert the map from serialized data back to Message/Attachment objects
    Map<Message, List<Attachment>> map = {};
    for (var entry in mapData.entries) {
      final message = Message.fromMap(entry.key);
      final attachments = entry.value.map((e) => Attachment.fromMap(e)).toList();
      map[message] = attachments;
    }

    /// convert List<List<Attachment>> into just List<Attachment> (flatten it)
    final attachments = map.values.flattened.toList();
    await MessagingStore.current.saveAttachments(attachments);
  }

  static Future<int> replaceAttachmentAsync(dynamic data) async {
    final oldGuid = data['oldGuid'] as String;
    final newAttachmentData = data['newAttachmentData'] as Map<String, dynamic>;
    return MessagingStore.current.replaceAttachment(oldGuid, Attachment.fromMap(newAttachmentData));
  }

  static Future<int?> findOneAttachmentAsync(dynamic data) async {
    final guid = data['guid'] as String;
    return MessagingStore.current.findAttachmentId(guid);
  }

  static Future<List<int>> findAttachmentsAsync(dynamic data) async {
    final queryDescriptorMap = data['queryDescriptor'] as Map<String, dynamic>?;
    return MessagingStore.current
        .findAttachmentIds(queryDescriptorMap != null ? AttachmentQueryDescriptor.fromMap(queryDescriptorMap) : null);
  }

  static Future<void> deleteAttachmentAsync(dynamic data) async {
    final guid = data['guid'] as String;
    await MessagingStore.current.deleteAttachment(guid);
  }
}
