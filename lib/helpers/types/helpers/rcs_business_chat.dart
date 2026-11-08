/// Whether a chat is with an RCS Business Messaging sender. Google addresses
/// every verified business as `<agent>@rbm.goog`; people are phone numbers or
/// email addresses on other domains. These chats stay on the iPhone: their
/// cards, buttons and links can't be shown here, and many of their messages
/// never reach the Mac.
bool isRcsBusinessChat({String? chatIdentifier, String? guid}) =>
    (chatIdentifier ?? '').toLowerCase().endsWith('@rbm.goog') || (guid ?? '').toLowerCase().endsWith('@rbm.goog');
