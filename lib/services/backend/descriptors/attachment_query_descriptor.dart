/// Serializable query descriptor for Attachment queries that can cross isolate boundaries.
/// Each store turns it into its own query: ObjectBox conditions
/// (objectbox_attachment_query.dart), SQL (attachment_query_sql.dart).
class AttachmentQueryDescriptor {
  final List<AttachmentQueryCondition> conditions;
  final AttachmentQueryLogic logic;

  AttachmentQueryDescriptor({
    required this.conditions,
    this.logic = AttachmentQueryLogic.and,
  });

  /// Convert to a serializable map
  Map<String, dynamic> toMap() {
    return {
      'conditions': conditions.map((c) => c.toMap()).toList(),
      'logic': logic.name,
    };
  }

  /// Create from a serialized map
  factory AttachmentQueryDescriptor.fromMap(Map<String, dynamic> map) {
    return AttachmentQueryDescriptor(
      conditions: (map['conditions'] as List).map((c) => AttachmentQueryCondition.fromMap(c)).toList(),
      logic: AttachmentQueryLogic.values.firstWhere(
        (e) => e.name == map['logic'],
        orElse: () => AttachmentQueryLogic.and,
      ),
    );
  }
}

enum AttachmentQueryLogic {
  and,
  or,
}

/// Individual query condition for attachment fields
class AttachmentQueryCondition {
  final AttachmentQueryField field;
  final AttachmentQueryOperator operator;
  final dynamic value;

  AttachmentQueryCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'field': field.name,
      'operator': operator.name,
      'value': value,
    };
  }

  factory AttachmentQueryCondition.fromMap(Map<String, dynamic> map) {
    return AttachmentQueryCondition(
      field: AttachmentQueryField.values.firstWhere((e) => e.name == map['field']),
      operator: AttachmentQueryOperator.values.firstWhere((e) => e.name == map['operator']),
      value: map['value'],
    );
  }
}

enum AttachmentQueryField {
  id,
  originalROWID,
  guid,
  uti,
  mimeType,
  isOutgoing,
  transferName,
  totalBytes,
  height,
  width,
  hasLivePhoto,
}

enum AttachmentQueryOperator {
  equals,
  notEquals,
  greaterThan,
  lessThan,
  greaterOrEqual,
  lessOrEqual,
  between,
  contains,
  startsWith,
  endsWith,
  oneOf,
  notOneOf,
}
