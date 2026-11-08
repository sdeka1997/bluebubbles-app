import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/services/backend/descriptors/attachment_query_descriptor.dart';
import 'package:collection/collection.dart';

/// AttachmentActions' ObjectBox code.
mixin ObjectBoxAttachmentStore implements AttachmentStore {
  static Attachment? _findOne(String guid) {
    final queryBuilder = Database.attachments.query(Attachment_.guid.equals(guid));
    queryBuilder.link(Attachment_.message);
    final query = queryBuilder.build();
    query.limit = 1;
    final result = query.findFirst();
    query.close();
    return result;
  }

  @override
  Future<int> saveAttachment(Attachment attachment, {Message? message}) async {
    return Database.runInTransaction(TxMode.write, () {
      /// Find an existing attachment with message relationship loaded
      Attachment? existing = _findOne(attachment.guid!);
      if (existing != null) {
        attachment.id = existing.id;

        // Always preserve the existing message relationship unless explicitly overridden
        if (existing.message.hasValue) {
          attachment.message.target = existing.message.target;
        }
      }

      try {
        /// Override with new message link if provided
        if (message != null) {
          if (message.id != null) {
            attachment.message.target = message;
          }
        }

        attachment.id = Database.attachments.put(attachment);
      } on UniqueViolationException catch (_) {}

      // Return just the ID for efficient transfer across isolates
      return attachment.id!;
    });
  }

  @override
  Future<void> saveAttachments(List<Attachment> attachments) async {
    /// find existing attachments using query descriptor
    final guids = attachments.map((e) => e.guid!).toList();
    final queryDescriptor = AttachmentQueryDescriptor(
      conditions: [
        AttachmentQueryCondition(
          field: AttachmentQueryField.guid,
          operator: AttachmentQueryOperator.oneOf,
          value: guids,
        ),
      ],
    );

    List<Attachment> existingAttachments = await Attachment.findAsync(
      queryDescriptor: queryDescriptor,
    );

    return Database.runInTransaction(TxMode.write, () {
      /// map existing attachment IDs and preserve message relationships
      for (Attachment a in attachments) {
        final existing = existingAttachments.firstWhereOrNull((e) => e.guid == a.guid);
        if (existing != null) {
          a.id = existing.id;

          // Preserve the existing message relationship to prevent it from being cleared by put
          if (existing.message.hasValue && !a.message.hasValue) {
            a.message.target = existing.message.target;
          }
        }
      }

      try {
        /// store the attachments and update their ids
        final ids = Database.attachments.putMany(attachments);
        for (int i = 0; i < attachments.length; i++) {
          attachments[i].id = ids[i];
        }
      } on UniqueViolationException catch (_) {}
    });
  }

  @override
  Future<int> replaceAttachment(String oldGuid, Attachment newAttachment) async {
    return Database.runInTransaction(TxMode.write, () {
      Attachment? existing = _findOne(oldGuid);
      if (existing == null) {
        throw Exception("Old GUID ($oldGuid) does not exist!");
      }

      // Note: cm and cvc services are NOT called here since they're only available on UI thread
      // This should be handled by the caller on the main thread before/after calling this

      // Guard against a race: another async path may have already inserted newAttachment.guid
      // between the caller's findOneAsync check and this transaction. If so, merge the new
      // fields into the conflicting record (preserving its ID so existing UI references stay
      // valid), then remove the stale temp-guid record.
      final conflicting = _findOne(newAttachment.guid!);
      if (conflicting != null && conflicting.id != existing.id) {
        conflicting.originalROWID = newAttachment.originalROWID;
        conflicting.uti = newAttachment.uti;
        conflicting.mimeType = newAttachment.mimeType ?? conflicting.mimeType;
        conflicting.isOutgoing = newAttachment.isOutgoing;
        conflicting.transferName = newAttachment.transferName;
        conflicting.totalBytes = newAttachment.totalBytes;
        conflicting.bytes = newAttachment.bytes;
        conflicting.webUrl = newAttachment.webUrl;
        conflicting.hasLivePhoto = newAttachment.hasLivePhoto;
        Database.attachments.put(conflicting);
        Database.attachments.remove(existing.id!);

        newAttachment.id = conflicting.id;
        newAttachment.width = conflicting.width;
        newAttachment.height = conflicting.height;
        newAttachment.metadata = conflicting.metadata;
        return newAttachment.id!;
      }

      // update values and save
      existing.guid = newAttachment.guid;
      existing.originalROWID = newAttachment.originalROWID;
      existing.uti = newAttachment.uti;
      existing.mimeType = newAttachment.mimeType ?? existing.mimeType;
      existing.isOutgoing = newAttachment.isOutgoing;
      existing.transferName = newAttachment.transferName;
      existing.totalBytes = newAttachment.totalBytes;
      existing.bytes = newAttachment.bytes;
      existing.webUrl = newAttachment.webUrl;
      existing.hasLivePhoto = newAttachment.hasLivePhoto;
      // Use synchronous put within the transaction to preserve the message relationship.
      // saveAsync(null) would run outside this transaction and would fail to find the
      // attachment by the new guid (since DB still has the old guid), stripping the
      // message.targetId link and causing the conversation tile subtitle to show blank.
      Database.attachments.put(existing);

      // grab values from existing
      newAttachment.id = existing.id;
      newAttachment.width = existing.width;
      newAttachment.height = existing.height;
      newAttachment.metadata = existing.metadata;

      // Return just the ID for efficient transfer across isolates
      return newAttachment.id!;
    });
  }

  @override
  Future<int?> findAttachmentId(String guid) async {
    return Database.runInTransaction(TxMode.read, () {
      // Return just the ID for efficient transfer across isolates
      return _findOne(guid)?.id;
    });
  }

  @override
  Future<List<int>> findAttachmentIds(AttachmentQueryDescriptor? queryDescriptor) async {
    return Database.runInTransaction(TxMode.read, () {
      final attachmentBox = Database.attachments;

      // Build condition from descriptor if provided
      final Condition<Attachment>? condition = queryDescriptor?.buildCondition();

      final queryBuilder = condition != null ? attachmentBox.query(condition) : attachmentBox.query();
      queryBuilder.link(Attachment_.message);
      final query = queryBuilder.build();
      final results = query.find();
      query.close();

      // Return just the IDs for efficient transfer across isolates
      return results.map((e) => e.id!).toList();
    });
  }

  @override
  Future<void> deleteAttachment(String guid) async {
    return Database.runInTransaction(TxMode.write, () {
      final query = Database.attachments.query(Attachment_.guid.equals(guid)).build();
      final result = query.findFirst();
      query.close();

      if (result?.id != null) {
        Database.attachments.remove(result!.id!);
      }
    });
  }

  @override
  Future<Attachment?> attachmentById(int id) async => Database.attachments.get(id);

  @override
  Future<List<Attachment>> attachmentsByIds(List<int> ids) async =>
      Database.attachments.getMany(ids).whereType<Attachment>().toList();
}
