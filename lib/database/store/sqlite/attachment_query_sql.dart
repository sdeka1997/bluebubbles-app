import 'package:bluebubbles/database/sqlite/attachment_repo.dart' show sqlPlaceholders;
import 'package:bluebubbles/services/backend/descriptors/attachment_query_descriptor.dart';

/// The WHERE clause and arguments of [descriptor] on the attachments table,
/// with the meaning AttachmentQueryDescriptor.buildCondition has on ObjectBox
/// (strings compared case-insensitively). Null when it has no conditions
/// (every attachment).
(String, List<Object?>)? attachmentWhere(AttachmentQueryDescriptor descriptor) {
  if (descriptor.conditions.isEmpty) return null;
  final parts = descriptor.conditions.map(_condition).toList();
  final joiner = descriptor.logic == AttachmentQueryLogic.and ? ' AND ' : ' OR ';
  return (parts.map((p) => '(${p.$1})').join(joiner), [for (final p in parts) ...p.$2]);
}

const _columns = {
  AttachmentQueryField.id: 'id',
  AttachmentQueryField.originalROWID: 'original_rowid',
  AttachmentQueryField.guid: 'guid',
  AttachmentQueryField.uti: 'uti',
  AttachmentQueryField.mimeType: 'mime_type',
  AttachmentQueryField.isOutgoing: 'is_outgoing',
  AttachmentQueryField.transferName: 'transfer_name',
  AttachmentQueryField.totalBytes: 'total_bytes',
  AttachmentQueryField.height: 'height',
  AttachmentQueryField.width: 'width',
  AttachmentQueryField.hasLivePhoto: 'has_live_photo',
};

const _strings = {
  AttachmentQueryField.guid,
  AttachmentQueryField.uti,
  AttachmentQueryField.mimeType,
  AttachmentQueryField.transferName,
};

const _bools = {AttachmentQueryField.isOutgoing, AttachmentQueryField.hasLivePhoto};

(String, List<Object?>) _condition(AttachmentQueryCondition c) {
  final column = _columns[c.field]!;
  final op = c.operator;
  final value = c.value;
  if (_bools.contains(c.field)) {
    return switch (op) {
      AttachmentQueryOperator.equals => ('$column = ?', [(value as bool) ? 1 : 0]),
      AttachmentQueryOperator.notEquals => ('$column != ?', [(value as bool) ? 1 : 0]),
      _ => throw UnsupportedError('Operator ${op.name} not supported for bool fields'),
    };
  }
  if (_strings.contains(c.field)) {
    return switch (op) {
      AttachmentQueryOperator.equals => ('$column = ? COLLATE NOCASE', [value as String]),
      AttachmentQueryOperator.notEquals => ('$column != ? COLLATE NOCASE', [value as String]),
      AttachmentQueryOperator.contains => ("$column LIKE ? ESCAPE '\\'", ['%${_escapeLike(value as String)}%']),
      AttachmentQueryOperator.startsWith => ("$column LIKE ? ESCAPE '\\'", ['${_escapeLike(value as String)}%']),
      AttachmentQueryOperator.endsWith => ("$column LIKE ? ESCAPE '\\'", ['%${_escapeLike(value as String)}']),
      AttachmentQueryOperator.oneOf => _in(column, List<String>.from(value as List), collate: true),
      _ => throw UnsupportedError('Operator ${op.name} not supported for string fields'),
    };
  }
  return switch (op) {
    AttachmentQueryOperator.equals => ('$column = ?', [value as int]),
    AttachmentQueryOperator.notEquals => ('$column != ?', [value as int]),
    AttachmentQueryOperator.greaterThan => ('$column > ?', [value as int]),
    AttachmentQueryOperator.lessThan => ('$column < ?', [value as int]),
    AttachmentQueryOperator.greaterOrEqual => ('$column >= ?', [value as int]),
    AttachmentQueryOperator.lessOrEqual => ('$column <= ?', [value as int]),
    AttachmentQueryOperator.between => ('$column BETWEEN ? AND ?', [(value as List)[0] as int, value[1] as int]),
    AttachmentQueryOperator.oneOf => _in(column, List<int>.from(value as List)),
    AttachmentQueryOperator.notOneOf => _in(column, List<int>.from(value as List), not: true),
    _ => throw UnsupportedError('Operator ${op.name} not supported for int fields'),
  };
}

(String, List<Object?>) _in(String column, List<Object> values, {bool collate = false, bool not = false}) {
  if (values.isEmpty) return (not ? '1' : '0', const []);
  return ('$column${collate ? ' COLLATE NOCASE' : ''} ${not ? 'NOT ' : ''}IN (${sqlPlaceholders(values.length)})', values);
}

/// LIKE is case-insensitive for ASCII, as ObjectBox's caseSensitive: false.
String _escapeLike(String s) => s.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
