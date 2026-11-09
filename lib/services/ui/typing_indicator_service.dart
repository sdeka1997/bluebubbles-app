import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/services/backend/interfaces/chat_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

// ignore: non_constant_identifier_names
TypingIndicatorService get TypingIndicatorSvc => GetIt.I<TypingIndicatorService>();

class TypingIndicatorService extends GetxController {
  String? _activeTypingChatGuid;

  bool get isTyping => _activeTypingChatGuid != null;

  Future<void> startTyping(String chatGuid) async {
    _activeTypingChatGuid = chatGuid;
    await Future.wait((await _threadGuids(chatGuid)).map((guid) => ChatInterface.startTyping(chatGuid: guid)));
  }

  Future<void> stopTyping(String chatGuid) async {
    if (_activeTypingChatGuid == chatGuid) _activeTypingChatGuid = null;
    await Future.wait((await _threadGuids(chatGuid)).map((guid) => ChatInterface.stopTyping(chatGuid: guid)));
  }

  /// Stops the active typing indicator for any chat.
  /// Called by LifecycleService before the app backgrounds.
  /// Must complete before GlobalIsolate.drainAndStop() is invoked so the
  /// HTTP request has a chance to succeed.
  Future<void> stopAllTyping() async {
    if (_activeTypingChatGuid == null) return;
    final guid = _activeTypingChatGuid!;
    _activeTypingChatGuid = null;
    await Future.wait((await _threadGuids(guid)).map((g) => ChatInterface.stopTyping(chatGuid: g)));
  }

  /// Every Apple chat in [chatGuid]'s thread, so whichever copy the others are
  /// reading shows it. Messages sends typing where the service carries it.
  Future<List<String>> _threadGuids(String chatGuid) async {
    if (kIsWeb) return [chatGuid];
    final chat = await MessagingStore.current.chatByGuid(chatGuid);
    if (chat == null) return [chatGuid];
    return (await MessagingStore.current.threadChatsOf(chat)).map((c) => c.guid).toList();
  }
}
