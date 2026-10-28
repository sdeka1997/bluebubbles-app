import 'dart:async';
import 'dart:io';

import 'package:bluebubbles/services/backend/sync/sync_retry.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isTransientSyncError', () {
    test('a failed DNS lookup during a network handoff is transient', () {
      expect(
        isTransientSyncError(const SocketException("Failed host lookup: 'x.trycloudflare.com'",
            osError: OSError('No address associated with hostname', 7))),
        isTrue,
      );
    });

    test('the same failure reported across the isolate as a string is transient', () {
      // The sync isolate returns errors as their toString().
      expect(
        isTransientSyncError("SocketException: Failed host lookup: 'x.trycloudflare.com' "
            "(OS Error: No address associated with hostname, errno = 7)"),
        isTrue,
      );
    });

    test('a connection closed mid-response is transient', () {
      expect(isTransientSyncError(const HttpException('Connection closed while receiving data')), isTrue);
      expect(isTransientSyncError('HttpException: Connection closed while receiving data'), isTrue);
    });

    test('a timeout is transient', () {
      expect(isTransientSyncError(TimeoutException('timed out')), isTrue);
      expect(
        isTransientSyncError(
            DioException(requestOptions: RequestOptions(path: '/'), type: DioExceptionType.receiveTimeout)),
        isTrue,
      );
    });

    test('a dio connection error is transient', () {
      expect(
        isTransientSyncError(
            DioException(requestOptions: RequestOptions(path: '/'), type: DioExceptionType.connectionError)),
        isTrue,
      );
    });

    test('a server or parsing error is not transient', () {
      expect(isTransientSyncError(Exception('Unexpected null value')), isFalse);
      expect(isTransientSyncError(const FormatException('bad json')), isFalse);
      expect(
        isTransientSyncError(
            DioException(requestOptions: RequestOptions(path: '/'), type: DioExceptionType.badResponse)),
        isFalse,
      );
    });
  });

  group('retryTransientSync', () {
    final waits = <Duration>[];
    Future<void> noWait(Duration d) async => waits.add(d);
    setUp(waits.clear);

    test('a sync that recovers on retry succeeds without surfacing the error', () async {
      var attempts = 0;
      final result = await retryTransientSync(() async {
        if (++attempts == 1) throw const SocketException('Failed host lookup');
        return 'synced';
      }, wait: noWait);

      expect(result, 'synced');
      expect(attempts, 2);
      expect(waits, [const Duration(seconds: 3)]);
    });

    test('a sync that keeps failing surfaces the error once after both retries', () async {
      var attempts = 0;
      await expectLater(
        retryTransientSync<void>(() async {
          attempts++;
          throw const SocketException('Failed host lookup');
        }, wait: noWait),
        throwsA(isA<SocketException>()),
      );

      expect(attempts, 3);
      expect(waits, [const Duration(seconds: 3), const Duration(seconds: 10)]);
    });

    test('a non-network failure surfaces immediately', () async {
      var attempts = 0;
      await expectLater(
        retryTransientSync<void>(() async {
          attempts++;
          throw const FormatException('bad json');
        }, wait: noWait),
        throwsA(isA<FormatException>()),
      );

      expect(attempts, 1);
      expect(waits, isEmpty);
    });
  });
}
