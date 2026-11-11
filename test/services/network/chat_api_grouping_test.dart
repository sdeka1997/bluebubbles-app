import 'dart:convert';
import 'dart:typed_data';

import 'package:bluebubbles/services/network/api/base_api.dart';
import 'package:bluebubbles/services/network/api/chat_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

// The startup grouping/spam check asks the server for only the fields it uses.
class _Capture implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    last = options;
    return ResponseBody.fromString(jsonEncode({'status': 200, 'data': [], 'metadata': {'total': 0}}), 200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
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
  test('the grouping query asks for grouping rows, page by page', () async {
    final adapter = _Capture();
    final api = ChatApi(_Api(Dio()..httpClientAdapter = adapter));
    await api.queryGrouping(offset: 1000, limit: 1000);
    final request = adapter.last!;
    expect(request.path, endsWith('/chat/query'));
    final body = request.data as Map;
    expect(body['with'], ['grouping']);
    expect(body['offset'], 1000);
    expect(body['limit'], 1000);
  });
}
