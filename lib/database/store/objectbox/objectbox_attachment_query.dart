import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/descriptors/attachment_query_descriptor.dart';

/// [AttachmentQueryDescriptor] as an ObjectBox condition.
extension ObjectBoxAttachmentQuery on AttachmentQueryDescriptor {
  /// Build an ObjectBox Condition from this descriptor
  Condition<Attachment>? buildCondition() {
    if (conditions.isEmpty) return null;

    Condition<Attachment>? result = conditions.first.buildCondition();

    for (int i = 1; i < conditions.length; i++) {
      final condition = conditions[i].buildCondition();
      if (result != null) {
        result = logic == AttachmentQueryLogic.and ? result.and(condition) : result.or(condition);
      }
    }

    return result;
  }
}

extension ObjectBoxAttachmentQueryCondition on AttachmentQueryCondition {
  /// Build an ObjectBox Condition from this descriptor
  Condition<Attachment> buildCondition() {
    switch (field) {
      case AttachmentQueryField.id:
        return _buildIntCondition(Attachment_.id, value);
      case AttachmentQueryField.originalROWID:
        return _buildIntCondition(Attachment_.originalROWID, value);
      case AttachmentQueryField.guid:
        return _buildStringCondition(Attachment_.guid, value);
      case AttachmentQueryField.uti:
        return _buildStringCondition(Attachment_.uti, value);
      case AttachmentQueryField.mimeType:
        return _buildStringCondition(Attachment_.mimeType, value);
      case AttachmentQueryField.isOutgoing:
        return _buildBoolCondition(Attachment_.isOutgoing, value);
      case AttachmentQueryField.transferName:
        return _buildStringCondition(Attachment_.transferName, value);
      case AttachmentQueryField.totalBytes:
        return _buildIntCondition(Attachment_.totalBytes, value);
      case AttachmentQueryField.height:
        return _buildIntCondition(Attachment_.height, value);
      case AttachmentQueryField.width:
        return _buildIntCondition(Attachment_.width, value);
      case AttachmentQueryField.hasLivePhoto:
        return _buildBoolCondition(Attachment_.hasLivePhoto, value);
    }
  }

  Condition<Attachment> _buildIntCondition(QueryIntegerProperty<Attachment> property, dynamic value) {
    switch (operator) {
      case AttachmentQueryOperator.equals:
        return property.equals(value as int);
      case AttachmentQueryOperator.notEquals:
        return property.notEquals(value as int);
      case AttachmentQueryOperator.greaterThan:
        return property.greaterThan(value as int);
      case AttachmentQueryOperator.lessThan:
        return property.lessThan(value as int);
      case AttachmentQueryOperator.greaterOrEqual:
        return property.greaterOrEqual(value as int);
      case AttachmentQueryOperator.lessOrEqual:
        return property.lessOrEqual(value as int);
      case AttachmentQueryOperator.between:
        final values = value as List;
        return property.between(values[0] as int, values[1] as int);
      case AttachmentQueryOperator.oneOf:
        return property.oneOf(List<int>.from(value as List));
      case AttachmentQueryOperator.notOneOf:
        return property.notOneOf(List<int>.from(value as List));
      default:
        throw UnsupportedError('Operator ${operator.name} not supported for int fields');
    }
  }

  Condition<Attachment> _buildStringCondition(QueryStringProperty<Attachment> property, dynamic value) {
    switch (operator) {
      case AttachmentQueryOperator.equals:
        return property.equals(value as String, caseSensitive: false);
      case AttachmentQueryOperator.notEquals:
        return property.notEquals(value as String, caseSensitive: false);
      case AttachmentQueryOperator.contains:
        return property.contains(value as String, caseSensitive: false);
      case AttachmentQueryOperator.startsWith:
        return property.startsWith(value as String, caseSensitive: false);
      case AttachmentQueryOperator.endsWith:
        return property.endsWith(value as String, caseSensitive: false);
      case AttachmentQueryOperator.oneOf:
        return property.oneOf(List<String>.from(value as List), caseSensitive: false);
      default:
        throw UnsupportedError('Operator ${operator.name} not supported for string fields');
    }
  }

  Condition<Attachment> _buildBoolCondition(QueryBooleanProperty<Attachment> property, dynamic value) {
    switch (operator) {
      case AttachmentQueryOperator.equals:
        return property.equals(value as bool);
      case AttachmentQueryOperator.notEquals:
        return property.notEquals(value as bool);
      default:
        throw UnsupportedError('Operator ${operator.name} not supported for bool fields');
    }
  }
}
