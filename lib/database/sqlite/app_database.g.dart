// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ChatsTable extends Chats with TableInfo<$ChatsTable, Chat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chats';
  @override
  VerificationContext validateIntegrity(
    Insertable<Chat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Chat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Chat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $ChatsTable createAlias(String alias) {
    return $ChatsTable(attachedDatabase, alias);
  }
}

class Chat extends DataClass implements Insertable<Chat> {
  final int id;
  const Chat({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  ChatsCompanion toCompanion(bool nullToAbsent) {
    return ChatsCompanion(id: Value(id));
  }

  factory Chat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Chat(id: serializer.fromJson<int>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id)};
  }

  Chat copyWith({int? id}) => Chat(id: id ?? this.id);
  Chat copyWithCompanion(ChatsCompanion data) {
    return Chat(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('Chat(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Chat && other.id == this.id);
}

class ChatsCompanion extends UpdateCompanion<Chat> {
  final Value<int> id;
  const ChatsCompanion({this.id = const Value.absent()});
  ChatsCompanion.insert({this.id = const Value.absent()});
  static Insertable<Chat> custom({Expression<int>? id}) {
    return RawValuesInsertable({if (id != null) 'id': id});
  }

  ChatsCompanion copyWith({Value<int>? id}) {
    return ChatsCompanion(id: id ?? this.id);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatsCompanion(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }
}

class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final int id;
  const Message({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(id: Value(id));
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(id: serializer.fromJson<int>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id)};
  }

  Message copyWith({int? id}) => Message(id: id ?? this.id);
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Message && other.id == this.id);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> id;
  const MessagesCompanion({this.id = const Value.absent()});
  MessagesCompanion.insert({this.id = const Value.absent()});
  static Insertable<Message> custom({Expression<int>? id}) {
    return RawValuesInsertable({if (id != null) 'id': id});
  }

  MessagesCompanion copyWith({Value<int>? id}) {
    return MessagesCompanion(id: id ?? this.id);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }
}

class $LegacyHandlesTable extends LegacyHandles
    with TableInfo<$LegacyHandlesTable, LegacyHandle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LegacyHandlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'legacy_handles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LegacyHandle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LegacyHandle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LegacyHandle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $LegacyHandlesTable createAlias(String alias) {
    return $LegacyHandlesTable(attachedDatabase, alias);
  }
}

class LegacyHandle extends DataClass implements Insertable<LegacyHandle> {
  final int id;
  const LegacyHandle({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  LegacyHandlesCompanion toCompanion(bool nullToAbsent) {
    return LegacyHandlesCompanion(id: Value(id));
  }

  factory LegacyHandle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LegacyHandle(id: serializer.fromJson<int>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id)};
  }

  LegacyHandle copyWith({int? id}) => LegacyHandle(id: id ?? this.id);
  LegacyHandle copyWithCompanion(LegacyHandlesCompanion data) {
    return LegacyHandle(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('LegacyHandle(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LegacyHandle && other.id == this.id);
}

class LegacyHandlesCompanion extends UpdateCompanion<LegacyHandle> {
  final Value<int> id;
  const LegacyHandlesCompanion({this.id = const Value.absent()});
  LegacyHandlesCompanion.insert({this.id = const Value.absent()});
  static Insertable<LegacyHandle> custom({Expression<int>? id}) {
    return RawValuesInsertable({if (id != null) 'id': id});
  }

  LegacyHandlesCompanion copyWith({Value<int>? id}) {
    return LegacyHandlesCompanion(id: id ?? this.id);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LegacyHandlesCompanion(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }
}

class $ChatParticipantsTable extends ChatParticipants
    with TableInfo<$ChatParticipantsTable, ChatParticipant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatParticipantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_participants';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChatParticipant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChatParticipant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatParticipant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $ChatParticipantsTable createAlias(String alias) {
    return $ChatParticipantsTable(attachedDatabase, alias);
  }
}

class ChatParticipant extends DataClass implements Insertable<ChatParticipant> {
  final int id;
  const ChatParticipant({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  ChatParticipantsCompanion toCompanion(bool nullToAbsent) {
    return ChatParticipantsCompanion(id: Value(id));
  }

  factory ChatParticipant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatParticipant(id: serializer.fromJson<int>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id)};
  }

  ChatParticipant copyWith({int? id}) => ChatParticipant(id: id ?? this.id);
  ChatParticipant copyWithCompanion(ChatParticipantsCompanion data) {
    return ChatParticipant(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('ChatParticipant(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatParticipant && other.id == this.id);
}

class ChatParticipantsCompanion extends UpdateCompanion<ChatParticipant> {
  final Value<int> id;
  const ChatParticipantsCompanion({this.id = const Value.absent()});
  ChatParticipantsCompanion.insert({this.id = const Value.absent()});
  static Insertable<ChatParticipant> custom({Expression<int>? id}) {
    return RawValuesInsertable({if (id != null) 'id': id});
  }

  ChatParticipantsCompanion copyWith({Value<int>? id}) {
    return ChatParticipantsCompanion(id: id ?? this.id);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatParticipantsCompanion(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }
}

class $MessageAttachmentsTable extends MessageAttachments
    with TableInfo<$MessageAttachmentsTable, MessageAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessageAttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'message_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessageAttachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessageAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessageAttachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $MessageAttachmentsTable createAlias(String alias) {
    return $MessageAttachmentsTable(attachedDatabase, alias);
  }
}

class MessageAttachment extends DataClass
    implements Insertable<MessageAttachment> {
  final int id;
  const MessageAttachment({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  MessageAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return MessageAttachmentsCompanion(id: Value(id));
  }

  factory MessageAttachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessageAttachment(id: serializer.fromJson<int>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id)};
  }

  MessageAttachment copyWith({int? id}) => MessageAttachment(id: id ?? this.id);
  MessageAttachment copyWithCompanion(MessageAttachmentsCompanion data) {
    return MessageAttachment(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('MessageAttachment(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessageAttachment && other.id == this.id);
}

class MessageAttachmentsCompanion extends UpdateCompanion<MessageAttachment> {
  final Value<int> id;
  const MessageAttachmentsCompanion({this.id = const Value.absent()});
  MessageAttachmentsCompanion.insert({this.id = const Value.absent()});
  static Insertable<MessageAttachment> custom({Expression<int>? id}) {
    return RawValuesInsertable({if (id != null) 'id': id});
  }

  MessageAttachmentsCompanion copyWith({Value<int>? id}) {
    return MessageAttachmentsCompanion(id: id ?? this.id);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessageAttachmentsCompanion(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }
}

class $StorageMetaTable extends StorageMeta
    with TableInfo<$StorageMetaTable, StorageMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StorageMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'storage_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<StorageMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StorageMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorageMetaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $StorageMetaTable createAlias(String alias) {
    return $StorageMetaTable(attachedDatabase, alias);
  }
}

class StorageMetaData extends DataClass implements Insertable<StorageMetaData> {
  final int id;
  const StorageMetaData({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  StorageMetaCompanion toCompanion(bool nullToAbsent) {
    return StorageMetaCompanion(id: Value(id));
  }

  factory StorageMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorageMetaData(id: serializer.fromJson<int>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id)};
  }

  StorageMetaData copyWith({int? id}) => StorageMetaData(id: id ?? this.id);
  StorageMetaData copyWithCompanion(StorageMetaCompanion data) {
    return StorageMetaData(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('StorageMetaData(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorageMetaData && other.id == this.id);
}

class StorageMetaCompanion extends UpdateCompanion<StorageMetaData> {
  final Value<int> id;
  const StorageMetaCompanion({this.id = const Value.absent()});
  StorageMetaCompanion.insert({this.id = const Value.absent()});
  static Insertable<StorageMetaData> custom({Expression<int>? id}) {
    return RawValuesInsertable({if (id != null) 'id': id});
  }

  StorageMetaCompanion copyWith({Value<int>? id}) {
    return StorageMetaCompanion(id: id ?? this.id);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StorageMetaCompanion(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }
}

class $CopyCheckpointsTable extends CopyCheckpoints
    with TableInfo<$CopyCheckpointsTable, CopyCheckpoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CopyCheckpointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'copy_checkpoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<CopyCheckpoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CopyCheckpoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CopyCheckpoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $CopyCheckpointsTable createAlias(String alias) {
    return $CopyCheckpointsTable(attachedDatabase, alias);
  }
}

class CopyCheckpoint extends DataClass implements Insertable<CopyCheckpoint> {
  final int id;
  const CopyCheckpoint({required this.id});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    return map;
  }

  CopyCheckpointsCompanion toCompanion(bool nullToAbsent) {
    return CopyCheckpointsCompanion(id: Value(id));
  }

  factory CopyCheckpoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CopyCheckpoint(id: serializer.fromJson<int>(json['id']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'id': serializer.toJson<int>(id)};
  }

  CopyCheckpoint copyWith({int? id}) => CopyCheckpoint(id: id ?? this.id);
  CopyCheckpoint copyWithCompanion(CopyCheckpointsCompanion data) {
    return CopyCheckpoint(id: data.id.present ? data.id.value : this.id);
  }

  @override
  String toString() {
    return (StringBuffer('CopyCheckpoint(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => id.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CopyCheckpoint && other.id == this.id);
}

class CopyCheckpointsCompanion extends UpdateCompanion<CopyCheckpoint> {
  final Value<int> id;
  const CopyCheckpointsCompanion({this.id = const Value.absent()});
  CopyCheckpointsCompanion.insert({this.id = const Value.absent()});
  static Insertable<CopyCheckpoint> custom({Expression<int>? id}) {
    return RawValuesInsertable({if (id != null) 'id': id});
  }

  CopyCheckpointsCompanion copyWith({Value<int>? id}) {
    return CopyCheckpointsCompanion(id: id ?? this.id);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CopyCheckpointsCompanion(')
          ..write('id: $id')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ChatsTable chats = $ChatsTable(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $LegacyHandlesTable legacyHandles = $LegacyHandlesTable(this);
  late final $ChatParticipantsTable chatParticipants = $ChatParticipantsTable(
    this,
  );
  late final $MessageAttachmentsTable messageAttachments =
      $MessageAttachmentsTable(this);
  late final $StorageMetaTable storageMeta = $StorageMetaTable(this);
  late final $CopyCheckpointsTable copyCheckpoints = $CopyCheckpointsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    chats,
    messages,
    legacyHandles,
    chatParticipants,
    messageAttachments,
    storageMeta,
    copyCheckpoints,
  ];
}

typedef $$ChatsTableCreateCompanionBuilder =
    ChatsCompanion Function({Value<int> id});
typedef $$ChatsTableUpdateCompanionBuilder =
    ChatsCompanion Function({Value<int> id});

class $$ChatsTableFilterComposer extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatsTable> {
  $$ChatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
}

class $$ChatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatsTable,
          Chat,
          $$ChatsTableFilterComposer,
          $$ChatsTableOrderingComposer,
          $$ChatsTableAnnotationComposer,
          $$ChatsTableCreateCompanionBuilder,
          $$ChatsTableUpdateCompanionBuilder,
          (Chat, BaseReferences<_$AppDatabase, $ChatsTable, Chat>),
          Chat,
          PrefetchHooks Function()
        > {
  $$ChatsTableTableManager(_$AppDatabase db, $ChatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              ChatsCompanion(id: id),
          createCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              ChatsCompanion.insert(id: id),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatsTable,
      Chat,
      $$ChatsTableFilterComposer,
      $$ChatsTableOrderingComposer,
      $$ChatsTableAnnotationComposer,
      $$ChatsTableCreateCompanionBuilder,
      $$ChatsTableUpdateCompanionBuilder,
      (Chat, BaseReferences<_$AppDatabase, $ChatsTable, Chat>),
      Chat,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({Value<int> id});
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({Value<int> id});

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              MessagesCompanion(id: id),
          createCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              MessagesCompanion.insert(id: id),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;
typedef $$LegacyHandlesTableCreateCompanionBuilder =
    LegacyHandlesCompanion Function({Value<int> id});
typedef $$LegacyHandlesTableUpdateCompanionBuilder =
    LegacyHandlesCompanion Function({Value<int> id});

class $$LegacyHandlesTableFilterComposer
    extends Composer<_$AppDatabase, $LegacyHandlesTable> {
  $$LegacyHandlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LegacyHandlesTableOrderingComposer
    extends Composer<_$AppDatabase, $LegacyHandlesTable> {
  $$LegacyHandlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LegacyHandlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LegacyHandlesTable> {
  $$LegacyHandlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
}

class $$LegacyHandlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LegacyHandlesTable,
          LegacyHandle,
          $$LegacyHandlesTableFilterComposer,
          $$LegacyHandlesTableOrderingComposer,
          $$LegacyHandlesTableAnnotationComposer,
          $$LegacyHandlesTableCreateCompanionBuilder,
          $$LegacyHandlesTableUpdateCompanionBuilder,
          (
            LegacyHandle,
            BaseReferences<_$AppDatabase, $LegacyHandlesTable, LegacyHandle>,
          ),
          LegacyHandle,
          PrefetchHooks Function()
        > {
  $$LegacyHandlesTableTableManager(_$AppDatabase db, $LegacyHandlesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LegacyHandlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LegacyHandlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LegacyHandlesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              LegacyHandlesCompanion(id: id),
          createCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              LegacyHandlesCompanion.insert(id: id),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LegacyHandlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LegacyHandlesTable,
      LegacyHandle,
      $$LegacyHandlesTableFilterComposer,
      $$LegacyHandlesTableOrderingComposer,
      $$LegacyHandlesTableAnnotationComposer,
      $$LegacyHandlesTableCreateCompanionBuilder,
      $$LegacyHandlesTableUpdateCompanionBuilder,
      (
        LegacyHandle,
        BaseReferences<_$AppDatabase, $LegacyHandlesTable, LegacyHandle>,
      ),
      LegacyHandle,
      PrefetchHooks Function()
    >;
typedef $$ChatParticipantsTableCreateCompanionBuilder =
    ChatParticipantsCompanion Function({Value<int> id});
typedef $$ChatParticipantsTableUpdateCompanionBuilder =
    ChatParticipantsCompanion Function({Value<int> id});

class $$ChatParticipantsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatParticipantsTable> {
  $$ChatParticipantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChatParticipantsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatParticipantsTable> {
  $$ChatParticipantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChatParticipantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatParticipantsTable> {
  $$ChatParticipantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
}

class $$ChatParticipantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChatParticipantsTable,
          ChatParticipant,
          $$ChatParticipantsTableFilterComposer,
          $$ChatParticipantsTableOrderingComposer,
          $$ChatParticipantsTableAnnotationComposer,
          $$ChatParticipantsTableCreateCompanionBuilder,
          $$ChatParticipantsTableUpdateCompanionBuilder,
          (
            ChatParticipant,
            BaseReferences<
              _$AppDatabase,
              $ChatParticipantsTable,
              ChatParticipant
            >,
          ),
          ChatParticipant,
          PrefetchHooks Function()
        > {
  $$ChatParticipantsTableTableManager(
    _$AppDatabase db,
    $ChatParticipantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatParticipantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatParticipantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatParticipantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              ChatParticipantsCompanion(id: id),
          createCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              ChatParticipantsCompanion.insert(id: id),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChatParticipantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChatParticipantsTable,
      ChatParticipant,
      $$ChatParticipantsTableFilterComposer,
      $$ChatParticipantsTableOrderingComposer,
      $$ChatParticipantsTableAnnotationComposer,
      $$ChatParticipantsTableCreateCompanionBuilder,
      $$ChatParticipantsTableUpdateCompanionBuilder,
      (
        ChatParticipant,
        BaseReferences<_$AppDatabase, $ChatParticipantsTable, ChatParticipant>,
      ),
      ChatParticipant,
      PrefetchHooks Function()
    >;
typedef $$MessageAttachmentsTableCreateCompanionBuilder =
    MessageAttachmentsCompanion Function({Value<int> id});
typedef $$MessageAttachmentsTableUpdateCompanionBuilder =
    MessageAttachmentsCompanion Function({Value<int> id});

class $$MessageAttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $MessageAttachmentsTable> {
  $$MessageAttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessageAttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $MessageAttachmentsTable> {
  $$MessageAttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessageAttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessageAttachmentsTable> {
  $$MessageAttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
}

class $$MessageAttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessageAttachmentsTable,
          MessageAttachment,
          $$MessageAttachmentsTableFilterComposer,
          $$MessageAttachmentsTableOrderingComposer,
          $$MessageAttachmentsTableAnnotationComposer,
          $$MessageAttachmentsTableCreateCompanionBuilder,
          $$MessageAttachmentsTableUpdateCompanionBuilder,
          (
            MessageAttachment,
            BaseReferences<
              _$AppDatabase,
              $MessageAttachmentsTable,
              MessageAttachment
            >,
          ),
          MessageAttachment,
          PrefetchHooks Function()
        > {
  $$MessageAttachmentsTableTableManager(
    _$AppDatabase db,
    $MessageAttachmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessageAttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessageAttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessageAttachmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              MessageAttachmentsCompanion(id: id),
          createCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              MessageAttachmentsCompanion.insert(id: id),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessageAttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessageAttachmentsTable,
      MessageAttachment,
      $$MessageAttachmentsTableFilterComposer,
      $$MessageAttachmentsTableOrderingComposer,
      $$MessageAttachmentsTableAnnotationComposer,
      $$MessageAttachmentsTableCreateCompanionBuilder,
      $$MessageAttachmentsTableUpdateCompanionBuilder,
      (
        MessageAttachment,
        BaseReferences<
          _$AppDatabase,
          $MessageAttachmentsTable,
          MessageAttachment
        >,
      ),
      MessageAttachment,
      PrefetchHooks Function()
    >;
typedef $$StorageMetaTableCreateCompanionBuilder =
    StorageMetaCompanion Function({Value<int> id});
typedef $$StorageMetaTableUpdateCompanionBuilder =
    StorageMetaCompanion Function({Value<int> id});

class $$StorageMetaTableFilterComposer
    extends Composer<_$AppDatabase, $StorageMetaTable> {
  $$StorageMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StorageMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $StorageMetaTable> {
  $$StorageMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StorageMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $StorageMetaTable> {
  $$StorageMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
}

class $$StorageMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StorageMetaTable,
          StorageMetaData,
          $$StorageMetaTableFilterComposer,
          $$StorageMetaTableOrderingComposer,
          $$StorageMetaTableAnnotationComposer,
          $$StorageMetaTableCreateCompanionBuilder,
          $$StorageMetaTableUpdateCompanionBuilder,
          (
            StorageMetaData,
            BaseReferences<_$AppDatabase, $StorageMetaTable, StorageMetaData>,
          ),
          StorageMetaData,
          PrefetchHooks Function()
        > {
  $$StorageMetaTableTableManager(_$AppDatabase db, $StorageMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StorageMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StorageMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StorageMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              StorageMetaCompanion(id: id),
          createCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              StorageMetaCompanion.insert(id: id),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StorageMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StorageMetaTable,
      StorageMetaData,
      $$StorageMetaTableFilterComposer,
      $$StorageMetaTableOrderingComposer,
      $$StorageMetaTableAnnotationComposer,
      $$StorageMetaTableCreateCompanionBuilder,
      $$StorageMetaTableUpdateCompanionBuilder,
      (
        StorageMetaData,
        BaseReferences<_$AppDatabase, $StorageMetaTable, StorageMetaData>,
      ),
      StorageMetaData,
      PrefetchHooks Function()
    >;
typedef $$CopyCheckpointsTableCreateCompanionBuilder =
    CopyCheckpointsCompanion Function({Value<int> id});
typedef $$CopyCheckpointsTableUpdateCompanionBuilder =
    CopyCheckpointsCompanion Function({Value<int> id});

class $$CopyCheckpointsTableFilterComposer
    extends Composer<_$AppDatabase, $CopyCheckpointsTable> {
  $$CopyCheckpointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CopyCheckpointsTableOrderingComposer
    extends Composer<_$AppDatabase, $CopyCheckpointsTable> {
  $$CopyCheckpointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CopyCheckpointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CopyCheckpointsTable> {
  $$CopyCheckpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);
}

class $$CopyCheckpointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CopyCheckpointsTable,
          CopyCheckpoint,
          $$CopyCheckpointsTableFilterComposer,
          $$CopyCheckpointsTableOrderingComposer,
          $$CopyCheckpointsTableAnnotationComposer,
          $$CopyCheckpointsTableCreateCompanionBuilder,
          $$CopyCheckpointsTableUpdateCompanionBuilder,
          (
            CopyCheckpoint,
            BaseReferences<
              _$AppDatabase,
              $CopyCheckpointsTable,
              CopyCheckpoint
            >,
          ),
          CopyCheckpoint,
          PrefetchHooks Function()
        > {
  $$CopyCheckpointsTableTableManager(
    _$AppDatabase db,
    $CopyCheckpointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CopyCheckpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CopyCheckpointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CopyCheckpointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              CopyCheckpointsCompanion(id: id),
          createCompanionCallback: ({Value<int> id = const Value.absent()}) =>
              CopyCheckpointsCompanion.insert(id: id),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CopyCheckpointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CopyCheckpointsTable,
      CopyCheckpoint,
      $$CopyCheckpointsTableFilterComposer,
      $$CopyCheckpointsTableOrderingComposer,
      $$CopyCheckpointsTableAnnotationComposer,
      $$CopyCheckpointsTableCreateCompanionBuilder,
      $$CopyCheckpointsTableUpdateCompanionBuilder,
      (
        CopyCheckpoint,
        BaseReferences<_$AppDatabase, $CopyCheckpointsTable, CopyCheckpoint>,
      ),
      CopyCheckpoint,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ChatsTableTableManager get chats =>
      $$ChatsTableTableManager(_db, _db.chats);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$LegacyHandlesTableTableManager get legacyHandles =>
      $$LegacyHandlesTableTableManager(_db, _db.legacyHandles);
  $$ChatParticipantsTableTableManager get chatParticipants =>
      $$ChatParticipantsTableTableManager(_db, _db.chatParticipants);
  $$MessageAttachmentsTableTableManager get messageAttachments =>
      $$MessageAttachmentsTableTableManager(_db, _db.messageAttachments);
  $$StorageMetaTableTableManager get storageMeta =>
      $$StorageMetaTableTableManager(_db, _db.storageMeta);
  $$CopyCheckpointsTableTableManager get copyCheckpoints =>
      $$CopyCheckpointsTableTableManager(_db, _db.copyCheckpoints);
}
