import 'dart:async';
import 'dart:convert';

import 'package:bluebubbles/services/network/api/base_api.dart';
import 'package:bluebubbles/services/network/api/chat_api.dart';
import 'package:bluebubbles/services/network/api/recoverable_delete_receipt.dart';
import 'package:bluebubbles/services/network/http_service.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions options) handler;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future? cancelFuture) async {
    lastRequest = options;
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

class TestBaseApi implements BaseApi {
  TestBaseApi(this.dio);

  @override
  final Dio dio;
  @override
  String get origin => 'https://server.example';
  @override
  String get apiRoot => '$origin/api/v1';
  @override
  Map<String, String> get headers => const <String, String>{};
  @override
  Map<String, dynamic> buildQueryParams([Map<String, dynamic> params = const {}]) => <String, dynamic>{
    ...params,
    'guid': 'auth',
  };
  @override
  Future<Response> runApiGuarded(
    Future<Response> Function() func, {
    bool checkOrigin = true,
    bool retryCloudflare502 = true,
  }) => func();
  @override
  Future<Response> returnSuccessOrError(Response response) =>
      response.statusCode == 200 ? Future<Response>.value(response) : Future<Response>.error(response);
}

class ProductionPathHttpService extends HttpService {
  @override
  Map<String, dynamic> buildQueryParams([Map<String, dynamic> params = const {}]) => <String, dynamic>{
    ...params,
    'guid': 'auth',
  };
}

class CapturingLogger extends BaseLogger {
  final List<String> messages = <String>[];

  @override
  void info(dynamic log, {String? tag, Object? error, StackTrace? trace}) => messages.add(log.toString());

  @override
  void error(dynamic log, {String? tag, Object? error, StackTrace? trace}) => messages.add(log.toString());
}

ResponseBody jsonResponse(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

Map<String, Object?> envelope(String state, {String? failureCode}) => <String, Object?>{
  'data': <String, Object?>{
    'attemptId': 'abcdefghijklmnop',
    'state': state,
    'failureCode': failureCode,
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-01T00:00:01.000Z',
  },
};

void main() {
  tearDown(() async => GetIt.I.reset());

  test('submit uses exact path and body and parses every receipt state', () async {
    for (final state in <String>['pending', 'succeeded', 'definitiveFailure']) {
      final adapter = StubAdapter((_) => jsonResponse(200, envelope(state, failureCode: 'failure-code')));
      final dio = Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter;
      final result = await ChatApi(
        TestBaseApi(dio),
      ).submitRecoverableDeleteAttempt(chatGuid: 'iMessage;-;secret-guid', attemptId: 'abcdefghijklmnop');

      expect(adapter.lastRequest?.method, 'POST');
      expect(adapter.lastRequest?.uri.path, '/api/v1/chat/delete/recoverable/attempts');
      expect(adapter.lastRequest?.data, <String, Object>{
        'chatGuid': 'iMessage;-;secret-guid',
        'attemptId': 'abcdefghijklmnop',
      });
      expect(adapter.lastRequest?.uri.toString(), isNot(contains('secret-guid')));
      expect(
        result,
        isA<RecoverableDeleteReceiptResult>()
            .having((value) => value.receipt.attemptId, 'attemptId', 'abcdefghijklmnop')
            .having((value) => value.receipt.state.name, 'state', state)
            .having((value) => value.receipt.failureCode, 'failureCode', 'failure-code'),
      );
    }
  });

  test('submit classifies only real 400 and 409 as rejected without dispatch', () async {
    for (final status in <int>[400, 409]) {
      final adapter = StubAdapter((_) => jsonResponse(status, <String, Object>{'error': 'rejected'}));
      final dio = Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter;
      final result = await ChatApi(
        TestBaseApi(dio),
      ).submitRecoverableDeleteAttempt(chatGuid: 'chat', attemptId: 'abcdefghijklmnop');
      expect(result, isA<RecoverableDeleteSubmitRejectedNoDispatch>());
    }
  });

  test('submit classifies every other HTTP, transport, timeout, and parse failure as ambiguous', () async {
    for (final status in <int>[408, 500, 504]) {
      final adapter = StubAdapter((_) => jsonResponse(status, <String, Object>{'error': 'maybe'}));
      final dio = Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter;
      expect(
        await ChatApi(TestBaseApi(dio)).submitRecoverableDeleteAttempt(chatGuid: 'chat', attemptId: 'abcdefghijklmnop'),
        isA<RecoverableDeleteAttemptAmbiguous>(),
      );
    }

    for (final type in <DioExceptionType>[DioExceptionType.connectionError, DioExceptionType.receiveTimeout]) {
      final adapter = StubAdapter((options) => throw DioException(requestOptions: options, type: type));
      final dio = Dio()..httpClientAdapter = adapter;
      expect(
        await ChatApi(TestBaseApi(dio)).submitRecoverableDeleteAttempt(chatGuid: 'chat', attemptId: 'abcdefghijklmnop'),
        isA<RecoverableDeleteAttemptAmbiguous>(),
      );
    }

    final malformed = StubAdapter((_) => jsonResponse(200, <String, Object>{'data': 'wrong'}));
    final malformedDio = Dio()..httpClientAdapter = malformed;
    expect(
      await ChatApi(
        TestBaseApi(malformedDio),
      ).submitRecoverableDeleteAttempt(chatGuid: 'chat', attemptId: 'abcdefghijklmnop'),
      isA<RecoverableDeleteAttemptAmbiguous>(),
    );
  });

  test('submit treats a forged receipt attempt id as ambiguous', () async {
    final forged = envelope('pending');
    (forged['data']! as Map<String, Object?>)['attemptId'] = 'bbbbbbbbbbbbbbbb';
    final adapter = StubAdapter((_) => jsonResponse(200, forged));
    final dio = Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter;

    final result = await ChatApi(
      TestBaseApi(dio),
    ).submitRecoverableDeleteAttempt(chatGuid: 'chat', attemptId: 'abcdefghijklmnop');

    expect(result, isA<RecoverableDeleteAttemptAmbiguous>());
  });

  test('lookup rejects malformed attempt id without making a network call', () async {
    var requests = 0;
    final adapter = StubAdapter((_) {
      requests++;
      return jsonResponse(200, envelope('pending'));
    });
    final dio = Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter;

    final result = await ChatApi(TestBaseApi(dio)).getRecoverableDeleteAttempt('../not-valid');

    expect(result, isA<RecoverableDeleteAttemptAmbiguous>());
    expect(requests, 0);
    expect(adapter.lastRequest, isNull);
  });

  test('lookup uses exact path, parses receipts, and maps only 404 to not recorded', () async {
    final successAdapter = StubAdapter((_) => jsonResponse(200, envelope('pending')));
    final successDio = Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = successAdapter;
    final success = await ChatApi(TestBaseApi(successDio)).getRecoverableDeleteAttempt('abcdefghijklmnop');
    expect(success, isA<RecoverableDeleteReceiptResult>());
    expect(successAdapter.lastRequest?.method, 'GET');
    expect(successAdapter.lastRequest?.uri.path, '/api/v1/chat/delete/recoverable/attempts/abcdefghijklmnop');

    for (final status in <int>[400, 404, 408, 500, 504]) {
      final adapter = StubAdapter((_) => jsonResponse(status, <String, Object>{'error': 'x'}));
      final dio = Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter;
      final result = await ChatApi(TestBaseApi(dio)).getRecoverableDeleteAttempt('abcdefghijklmnop');
      expect(
        result,
        status == 404 ? isA<RecoverableDeleteAttemptNotRecorded>() : isA<RecoverableDeleteAttemptAmbiguous>(),
      );
    }

    final malformedAdapter = StubAdapter((_) => jsonResponse(200, <String, Object>{'data': <String, Object>{}}));
    final malformedDio = Dio()..httpClientAdapter = malformedAdapter;
    expect(
      await ChatApi(TestBaseApi(malformedDio)).getRecoverableDeleteAttempt('abcdefghijklmnop'),
      isA<RecoverableDeleteAttemptAmbiguous>(),
    );
  });

  test('production Cloudflare 502 receipt submit is attempted once and remains ambiguous', () async {
    var requests = 0;
    final adapter = StubAdapter((_) {
      requests++;
      return requests == 1
          ? jsonResponse(502, <String, Object>{'error': 'ambiguous'})
          : jsonResponse(200, envelope('succeeded'));
    });
    final service = ProductionPathHttpService()
      ..originOverride = 'https://receipt.trycloudflare.com'
      ..dio = (Dio(BaseOptions(validateStatus: (_) => true))..httpClientAdapter = adapter);
    service.dio.interceptors.add(ApiInterceptor());
    GetIt.I.registerSingleton<BaseLogger>(CapturingLogger());
    GetIt.I.registerSingleton<HttpService>(service);

    final result = await ChatApi(
      service,
    ).submitRecoverableDeleteAttempt(chatGuid: 'iMessage;-;secret-guid', attemptId: 'abcdefghijklmnop');

    expect(result, isA<RecoverableDeleteAttemptAmbiguous>());
    expect(requests, 1);
  });

  test('secure generated attempt ids match the server contract and do not repeat', () {
    final ids = List<String>.generate(200, (_) => generateRecoverableDeleteAttemptId());
    final pattern = RegExp(r'^[A-Za-z0-9_-]{16,128}$');
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids.every(pattern.hasMatch), isTrue);
    expect(ids.every((id) => id.length == 32), isTrue);
  });

  test('production interceptor seam redacts receipt submit body on failure', () async {
    final logger = CapturingLogger();
    GetIt.I.registerSingleton<BaseLogger>(logger);
    final adapter = StubAdapter((options) {
      throw DioException(
        requestOptions: options,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 500,
          data: <String, Object>{'echo': 'iMessage;-;must-not-log'},
        ),
        error: 'transport echoed body iMessage;-;must-not-log',
      );
    });
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(ApiInterceptor());

    final result = await ChatApi(
      TestBaseApi(dio),
    ).submitRecoverableDeleteAttempt(chatGuid: 'iMessage;-;must-not-log', attemptId: 'abcdefghijklmnop');

    expect(result, isA<RecoverableDeleteAttemptAmbiguous>());
    expect(logger.messages.join('\n'), isNot(contains('iMessage;-;must-not-log')));
    expect(logger.messages.join('\n'), contains('Error: [REDACTED]'));
    expect(logger.messages.join('\n'), contains('Request Data: [REDACTED]'));
    expect(logger.messages.join('\n'), contains('Response Data: [REDACTED]'));
    expect(adapter.lastRequest?.extra[ApiInterceptor.redactRequestDataKey], isTrue);
  });

  test('ApiInterceptor preserves ordinary error detail without the sensitive marker', () async {
    final logger = CapturingLogger();
    GetIt.I.registerSingleton<BaseLogger>(logger);
    final adapter = StubAdapter(
      (options) => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: 'ordinary transport detail',
      ),
    );
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(ApiInterceptor());

    await expectLater(dio.get<Object?>('https://server.example/api/v1/status'), throwsA(isA<DioException>()));

    expect(logger.messages.join('\n'), contains('Error: ordinary transport detail'));
  });

  test('ApiInterceptor synthetic timeout response remains ambiguous', () async {
    final logger = CapturingLogger();
    GetIt.I.registerSingleton<BaseLogger>(logger);
    final adapter = StubAdapter(
      (options) => throw DioException(requestOptions: options, type: DioExceptionType.receiveTimeout),
    );
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(ApiInterceptor());

    final result = await ChatApi(
      TestBaseApi(dio),
    ).submitRecoverableDeleteAttempt(chatGuid: 'chat', attemptId: 'abcdefghijklmnop');

    expect(result, isA<RecoverableDeleteAttemptAmbiguous>());
    expect(logger.messages.join('\n'), contains('Response Status: No Response'));
  });
}
