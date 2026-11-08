/// Represents the messaging service type for a chat.
///
/// Derived from the GUID prefix (the part before `;-;` or `;+;`).
/// Add new service types here.
enum ChatServiceType {
  iMessage(label: 'iMessage'),
  sms(label: 'SMS'),
  rcs(label: 'RCS');

  const ChatServiceType({required this.label});

  final String label;

  /// Apple supports Tapbacks in iMessage, RCS and SMS conversations.
  bool get supportsTapbacks => true;

  /// Returns the server-side method string for this service type.
  String get method {
    switch (this) {
      case ChatServiceType.iMessage:
        return 'iMessage';
      case ChatServiceType.sms:
        return 'SMS';
      case ChatServiceType.rcs:
        return 'RCS';
    }
  }

  /// The service a new message to [recipients] starts on, from the Mac's iMessage
  /// answer for each one ([status], null while unknown): text once any phone number
  /// is off iMessage, otherwise iMessage like stock. Emails only reach iMessage.
  /// The Mac itself upgrades a text to RCS where it can.
  static ChatServiceType forNewChat(Iterable<({String address, ChatServiceType? status})> recipients) {
    final texting = recipients.any((r) => !r.address.contains('@') && r.status?.isIMessageService == false);
    return texting ? ChatServiceType.sms : ChatServiceType.iMessage;
  }

  /// Whether chats of this type are iMessage chats.
  bool get isIMessageService => this == ChatServiceType.iMessage;

  /// Placeholder shown in the message composer.
  String get composerLabel => isIMessageService ? 'iMessage' : 'Text Message • $label';

  /// The service the conversation is using now. Messages can file a message in
  /// another service's record for the same contact (RCS messages in an older SMS
  /// chat), so the newest message's service wins over the chat's own.
  static ChatServiceType current(ChatServiceType chatService, {String? latestMessageService}) {
    switch (latestMessageService?.toUpperCase()) {
      case 'IMESSAGE':
        return ChatServiceType.iMessage;
      case 'SMS':
        return ChatServiceType.sms;
      case 'RCS':
        return ChatServiceType.rcs;
      default:
        return chatService;
    }
  }

  /// Uses the service reported by Messages, falling back to the legacy GUID
  /// prefix for older servers or an unknown future service.
  static ChatServiceType fromServer(String? serviceName, String guid) {
    switch (serviceName?.toUpperCase()) {
      case 'IMESSAGE':
        return ChatServiceType.iMessage;
      case 'SMS':
        return ChatServiceType.sms;
      case 'RCS':
        return ChatServiceType.rcs;
      default:
        return fromGuid(guid);
    }
  }

  /// Parses the service type from a chat GUID by inspecting the prefix
  /// before the first `;-;` or `;+;` separator.
  ///
  /// Examples:
  ///   `iMessage;-;+12345678901` → [ChatServiceType.iMessage]
  ///   `SMS;-;+12345678901`       → [ChatServiceType.sms]
  ///   `chat1a2b3c...`            → [ChatServiceType.iMessage] (group chat, no prefix)
  static ChatServiceType fromGuid(String guid) {
    int sepIdx = guid.indexOf(';-;');
    if (sepIdx == -1) sepIdx = guid.indexOf(';+;');
    if (sepIdx == -1) return ChatServiceType.iMessage;

    final prefix = guid.substring(0, sepIdx).toUpperCase();
    switch (prefix) {
      case 'SMS':
        return ChatServiceType.sms;
      case 'RCS':
        return ChatServiceType.rcs;
      default:
        return ChatServiceType.iMessage;
    }
  }
}
