// Send routes answer only once iMessage has acted, which can take minutes, so
// they wait as long as the server does instead of the usual request timeout.
import 'dart:convert';
import 'dart:typed_data';

import 'package:bluebubbles/database/global/platform_file.dart';
import 'package:bluebubbles/database/global/settings.dart';
import 'package:bluebubbles/services/backend/settings/settings_service.dart';
import 'package:bluebubbles/services/network/api/base_api.dart';
import 'package:bluebubbles/services/network/api/chat_api.dart';
import 'package:bluebubbles/services/network/api/message_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class _Capture implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'status': 200, 'data': {}}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Api implements BaseApi {
  _Api(this.dio);

  @override
  final Dio dio;
  @override
  String get origin => 'http://server';
  @override
  String get apiRoot => 'http://server/api/v1';
  @override
  Map<String, String> get headers => const {};
  @override
  Map<String, dynamic> buildQueryParams([Map<String, dynamic> params = const {}]) => params;
  @override
  Future<Response> runApiGuarded(Future<Response> Function() func, {bool checkOrigin = true}) => func();
  @override
  Future<Response> returnSuccessOrError(Response r) async => r;
}

void main() {
  late _Capture adapter;
  late _Api api;
  const usual = Duration(seconds: 30);

  setUp(() {
    GetIt.I.registerSingleton<SettingsService>(SettingsService()..settings = Settings());
    adapter = _Capture();
    api = _Api(
      Dio(BaseOptions(connectTimeout: usual, receiveTimeout: usual, sendTimeout: usual))..httpClientAdapter = adapter,
    );
  });
  tearDown(() => GetIt.I.reset());

  test('every route that waits on iMessage waits as long as the server does', () async {
    final messages = MessageApi(api);
    final routes = <String, Future<Response> Function()>{
      'message/text': () => messages.sendText('chat', 'temp', 'hi'),
      'message/attachment': () =>
          messages.sendAttachment('chat', 'temp', PlatformFile(name: 'a.txt', size: 1, path: 'pubspec.yaml')),
      'message/multipart': () => messages.sendMultipart('chat', 'temp', [
        {'text': 'hi', 'partIndex': 0},
      ]),
      'message/react': () => messages.sendTapback('chat', 'hi', 'guid', 'love'),
      'message/guid/unsend': () => messages.unsend('guid'),
      'message/guid/edit': () => messages.edit('guid', 'new', 'Edited to "new"'),
      'message/guid/notify': () => messages.notify('guid'),
      'chat/new': () => ChatApi(api).create(['ana@example.com'], 'hi', 'iMessage'),
    };
    for (final MapEntry(key: route, value: call) in routes.entries) {
      adapter.requests.clear();
      await call();
      final request = adapter.requests.single;
      expect(request.path, endsWith('/$route'));
      expect(request.receiveTimeout, MessageApi.awaitsIMessageTimeout, reason: route);
    }
    expect(MessageApi.awaitsIMessageTimeout, greaterThan(const Duration(minutes: 5)), reason: 'v2 answers within 300s');
  });

  test('other routes keep the usual request timeout', () async {
    await MessageApi(api).fetchOne('guid');
    expect(adapter.requests.single.receiveTimeout, usual);
  });
}
