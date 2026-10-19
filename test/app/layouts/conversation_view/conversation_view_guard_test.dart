import 'package:bluebubbles/app/layouts/conversation_view/pages/conversation_view.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/filesystem/filesystem_service.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/backend/sync/recoverable_delete_journal.dart';
import 'package:bluebubbles/services/ui/chat/chats_service.dart';
import 'package:bluebubbles/services/ui/chat/conversation_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:universal_io/io.dart';

class _MemoryStore implements RecoverableDeleteJournalStore {
  String? raw;
  @override
  String? read() => raw;
  @override
  Future<void> write(String value) async => raw = value;
}

void main() {
  setUp(() {
    GetIt.I.registerSingleton<FilesystemService>(FilesystemService()..appDocDir = Directory.systemTemp);
    GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = Settings());
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('a suppressed chat renders nothing, pops itself and explains once', (tester) async {
    final notices = <String>[];
    late ChatsService service;
    await tester.runAsync(() async {
      final journal = RecoverableDeleteJournal.testing(_MemoryStore());
      await journal.hydrate();
      await journal.recordSubmitted(
        serverIdentity: 'server-a',
        chatGuid: 'suppressed',
        attemptId: 'abababababababab',
        startedAt: DateTime.utc(2026, 1, 1),
      );
      service = ChatsService(
        journal: journal,
        configuredServerIdentity: () => 'server-a',
        noticeSink: (title, _, _) => notices.add(title),
      );
    });
    GetIt.I.registerSingleton<ChatsService>(service);
    final navigator = GlobalKey<NavigatorState>();
    final chat = Chat(id: 1, guid: 'suppressed', hasUnreadMessage: false);

    await tester.pumpWidget(MaterialApp(navigatorKey: navigator, home: const Text('home')));
    navigator.currentState!.push(MaterialPageRoute(builder: (_) => ConversationView(chat: chat)));
    await tester.pumpAndSettle();

    expect(find.byType(ConversationView), findsNothing);
    expect(find.text('home'), findsOneWidget);
    expect(notices, ['Deletion is being confirmed']);
    expect(Get.isRegistered<ConversationViewController>(tag: chat.guid), isFalse);
    expect(service.chatStates.containsKey(chat.guid), isFalse);
    expect(service.activeChat, isNull);
  });
}
