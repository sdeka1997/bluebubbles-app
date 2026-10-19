import 'dart:convert';

import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/services/backend/filesystem/filesystem_service.dart';
import 'package:bluebubbles/services/backend/settings/actions/shared_preferences_database_actions.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/backend/settings/shared_preferences_service.dart';
import 'package:bluebubbles/services/backend/sync/recoverable_delete_journal.dart';
import 'package:bluebubbles/services/network/http_service.dart';
import 'package:bluebubbles/services/ui/chat/chats_service.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:universal_io/io.dart';

/// The only faked network piece: everything above the socket is production Dio.
class _ServerAdapter implements HttpClientAdapter {
  _ServerAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future? cancelFuture) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

class _QuietLogger extends BaseLogger {
  final List<String> messages = <String>[];

  @override
  void info(dynamic log, {String? tag, Object? error, StackTrace? trace}) => messages.add(log.toString());

  @override
  void warn(dynamic log, {String? tag, Object? error, StackTrace? trace}) => messages.add(log.toString());

  @override
  void error(dynamic log, {String? tag, Object? error, StackTrace? trace}) => messages.add(log.toString());
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

Map<String, Object?> _receipt(String attemptId, String state) => <String, Object?>{
  'data': <String, Object?>{
    'attemptId': attemptId,
    'state': state,
    'failureCode': null,
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-01T00:00:01.000Z',
  },
};

/// Reads the claim the way a restarted process would: a new prefs cache over the
/// same platform store, hydrated into a separate journal.
Future<RecoverableDeleteJournalEntry?> _durableClaim(String serverIdentity, String chatGuid) async {
  final prefs = SharedPreferencesService()
    // ignore: deprecated_member_use_from_same_package
    ..i = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
  final journal = RecoverableDeleteJournal.testing(
    SharedPreferencesDeleteJournalStore(SharedPreferencesDatabaseActions(prefs)),
  );
  await journal.hydrate();
  expect(journal.state, RecoverableDeleteJournalState.ready);
  return journal.lookup(serverIdentity, chatGuid);
}

Chat _chat(String guid) => Chat(id: guid.hashCode, guid: guid, hasUnreadMessage: false);

void main() {
  late Settings settings;
  late _QuietLogger logger;
  late RecoverableDeleteJournal productionJournal;

  setUpAll(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = SharedPreferencesService()
      // ignore: deprecated_member_use_from_same_package
      ..i = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
    prefs.database = SharedPreferencesDatabaseActions(prefs);
    settings = Settings()..guidAuthKey.value = 'auth-key';
    logger = _QuietLogger();
    GetIt.I.registerSingleton<BaseLogger>(logger);
    GetIt.I.registerSingleton<FilesystemService>(FilesystemService()..appDocDir = Directory.systemTemp);
    GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = settings);
    GetIt.I.registerSingleton<SharedPreferencesService>(prefs);
    final http = HttpService();
    await http.init();
    expect(http.dio.httpClientAdapter, isA<IOHttpClientAdapter>());
    expect(http.dio.interceptors.whereType<ApiInterceptor>(), hasLength(1));
    GetIt.I.registerSingleton<HttpService>(http);
    // The process-wide journal over PrefsSvc.database; nothing in this file resets it.
    productionJournal = RecoverableDeleteJournal();
  });

  tearDownAll(GetIt.I.reset);

  /// Production defaults for identity, journal, submit, lookup, attempt id and clock.
  /// Seams, each because the harness has no ObjectBox store or app UI:
  /// - initialActiveChatsLoader replaces the paged Chat.getChatsAsync list load;
  /// - localChatLookup replaces Chat.findOne;
  /// - localSoftDelete replaces softDeleteChatLocalOnly's ObjectBox write;
  /// - noticeSink replaces showSnackbar, which needs a mounted app.
  ChatsService productionService(Chat chat, List<Chat> softDeleted, List<String> notices) => ChatsService(
    initialActiveChatsLoader: () async => [chat, _chat('vertical-other')],
    localChatLookup: (guid) => guid == chat.guid ? chat : null,
    localSoftDelete: (deleted) async => softDeleted.add(deleted),
    noticeSink: (title, _, type) => notices.add('$title|${type.name}'),
  );

  test('a succeeded receipt over production HTTP deletes locally and clears the durable claim', () async {
    settings.serverAddress.value = 'https://vertical.example';
    const guid = 'iMessage;-;vertical-secret-success';
    final chat = _chat(guid);
    final softDeleted = <Chat>[];
    final notices = <String>[];
    final adapter = _ServerAdapter((options) async {
      final body = options.data as Map;
      final attemptId = body['attemptId'] as String;
      final claim = await _durableClaim('https://vertical.example', guid);
      expect(claim?.attemptId, attemptId, reason: 'the claim must be durable before the POST leaves');
      expect(claim?.phase, RecoverableDeleteJournalPhase.submitted);
      return _json(200, _receipt(attemptId, 'succeeded'));
    });
    HttpSvc.dio.httpClientAdapter = adapter;
    final service = productionService(chat, softDeleted, notices);
    await service.init(force: true);
    expect(productionJournal.state, RecoverableDeleteJournalState.ready, reason: 'init hydrated the shared journal');
    expect(identical(RecoverableDeleteJournal(), productionJournal), isTrue);
    expect(service.chatStates.keys, containsAll(<String>[guid, 'vertical-other']));

    final result = await service.recoverablyDeleteChat(chat).timeout(const Duration(seconds: 5));

    expect(result, isTrue);
    final post = adapter.requests.single;
    expect(post.method, 'POST');
    expect(post.uri.origin, 'https://vertical.example');
    expect(post.uri.path, '/api/v1/chat/delete/recoverable/attempts');
    expect(post.uri.queryParameters, <String, String>{'guid': 'auth-key'});
    expect(post.data, <String, Object>{'chatGuid': guid, 'attemptId': (post.data as Map)['attemptId'] as String});
    expect((post.data as Map).keys, ['chatGuid', 'attemptId']);
    expect(post.extra[ApiInterceptor.redactRequestDataKey], isTrue);
    expect(post.uri.toString(), isNot(contains('vertical-secret')));
    expect(softDeleted, [same(chat)]);
    expect(await _durableClaim('https://vertical.example', guid), isNull);
    expect(productionJournal.lookup('https://vertical.example', guid), isNull);
    expect(service.pendingDeletes, isNot(contains(guid)));
    expect(service.chatStates.keys, ['vertical-other']);
    expect(service.allChats.map((c) => c.guid), ['vertical-other']);
    expect(notices, isEmpty);
    expect(logger.messages.join('\n'), isNot(contains('vertical-secret')));
  });

  test('a Cloudflare 502 is sent once, then a 404 lookup resubmits the same id and pending keeps the claim', () async {
    const origin = 'https://vertical.trycloudflare.com';
    settings.serverAddress.value = origin;
    const guid = 'iMessage;-;vertical-secret-cloudflare';
    final chat = _chat(guid);
    final softDeleted = <Chat>[];
    final notices = <String>[];
    String? attemptId;
    var postCount = 0;
    final adapter = _ServerAdapter((options) async {
      if (options.method == 'POST') {
        postCount++;
        final body = options.data as Map;
        attemptId ??= body['attemptId'] as String;
        expect(body, <String, Object>{'chatGuid': guid, 'attemptId': attemptId!});
        expect((await _durableClaim(origin, guid))?.attemptId, attemptId);
        return postCount == 1
            ? _json(502, <String, Object>{'error': 'bad gateway'})
            : _json(200, _receipt(attemptId!, 'pending'));
      }
      return _json(404, <String, Object>{'error': 'not found'});
    });
    HttpSvc.dio.httpClientAdapter = adapter;
    final service = productionService(chat, softDeleted, notices);
    await service.init(force: true);
    expect(identical(RecoverableDeleteJournal(), productionJournal), isTrue);

    final result = await service.recoverablyDeleteChat(chat).timeout(const Duration(seconds: 5));

    expect(result, isTrue);
    // No Cloudflare retry of the 502 POST: the next request is the lookup.
    expect(adapter.requests.map((r) => '${r.method} ${r.uri.path}'), [
      'POST /api/v1/chat/delete/recoverable/attempts',
      'GET /api/v1/chat/delete/recoverable/attempts/$attemptId',
      'POST /api/v1/chat/delete/recoverable/attempts',
    ]);
    expect(adapter.requests.every((r) => r.uri.origin == origin), isTrue);
    expect(adapter.requests.every((r) => !r.uri.toString().contains('vertical-secret')), isTrue);
    final posts = adapter.requests.where((r) => r.method == 'POST');
    expect(posts.every((r) => r.extra[ApiInterceptor.redactRequestDataKey] == true), isTrue);
    final durable = await _durableClaim(origin, guid);
    expect(durable?.attemptId, attemptId);
    expect(durable?.phase, RecoverableDeleteJournalPhase.submitted);
    expect(productionJournal.lookup(origin, guid)?.attemptId, attemptId);
    expect(softDeleted, isEmpty);
    expect(service.pendingDeletes, contains(guid));
    expect(service.isRecoverableDeleteSuppressed(guid), isTrue);
    expect(service.chatStates.keys, ['vertical-other']);
    expect(service.allChats.map((c) => c.guid), ['vertical-other']);
    expect(notices, ['Deletion is being confirmed|info']);
    expect(logger.messages.join('\n'), isNot(contains('vertical-secret')));
  });
}
