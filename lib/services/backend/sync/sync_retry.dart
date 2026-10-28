import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// Delays before each quiet retry of a failed incremental sync. A Wi-Fi to
/// cellular handoff drops DNS and open connections for a few seconds; the
/// socket is usually back well inside this window.
const List<Duration> syncRetryDelays = [Duration(seconds: 3), Duration(seconds: 10)];

/// Whether [error] is a network blip worth retrying rather than reporting.
/// Errors from the sync isolate arrive as their `toString()`, so strings are
/// matched by the same markers.
bool isTransientSyncError(Object error) {
  if (error is DioException) {
    return const {
          DioExceptionType.connectionError,
          DioExceptionType.connectionTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.receiveTimeout,
        }.contains(error.type) ||
        (error.error != null && isTransientSyncError(error.error!));
  }
  if (error is SocketException || error is TimeoutException) return true;
  final text = error.toString();
  return text.contains('SocketException') ||
      text.contains('Failed host lookup') ||
      text.contains('Connection closed') ||
      text.contains('Connection reset') ||
      text.contains('TimeoutException') ||
      text.contains('DioExceptionType.connectionError') ||
      text.contains('DioExceptionType.connectionTimeout') ||
      text.contains('DioExceptionType.receiveTimeout') ||
      text.contains('DioExceptionType.sendTimeout');
}

/// Runs [attempt], retrying after each of [syncRetryDelays] while it fails
/// with a transient network error. Any other error, or the last transient
/// one, is rethrown.
Future<T> retryTransientSync<T>(
  Future<T> Function() attempt, {
  Future<void> Function(Duration delay) wait = _wait,
}) async {
  for (final delay in syncRetryDelays) {
    try {
      return await attempt();
    } catch (e) {
      if (!isTransientSyncError(e)) rethrow;
    }
    await wait(delay);
  }
  return attempt();
}

Future<void> _wait(Duration delay) => Future.delayed(delay);
