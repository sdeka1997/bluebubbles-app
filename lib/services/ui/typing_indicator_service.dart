import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/service_twin_helpers.dart';
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
    await Future.wait(_threadGuids(chatGuid).map((guid) => ChatInterface.startTyping(chatGuid: guid)));
  }

  Future<void> stopTyping(String chatGuid) async {
    if (_activeTypingChatGuid == chatGuid) _activeTypingChatGuid = null;
    await Future.wait(_threadGuids(chatGuid).map((guid) => ChatInterface.stopTyping(chatGuid: guid)));
  }

  /// Stops the active typing indicator for any chat.
  /// Called by LifecycleService before the app backgrounds.
  /// Must complete before GlobalIsolate.drainAndStop() is invoked so the
  /// HTTP request has a chance to succeed.
  Future<void> stopAllTyping() async {
    if (_activeTypingChatGuid == null) return;
    final guid = _activeTypingChatGuid!;
    _activeTypingChatGuid = null;
    await Future.wait(_threadGuids(guid).map((g) => ChatInterface.stopTyping(chatGuid: g)));
  }

  /// Every Apple chat in [chatGuid]'s thread, so whichever copy the others are
  /// reading shows it. Messages sends typing where the service carries it.
  List<String> _threadGuids(String chatGuid) {
    if (kIsWeb) return [chatGuid];
    final chat = Chat.findOne(guid: chatGuid);
    if (chat == null) return [chatGuid];
    return findThreadChats(chat).map((c) => c.guid).toList();
  }
}
