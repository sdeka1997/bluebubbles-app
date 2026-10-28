import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// Delays before each quiet retry of a failed incremental sync, about two
/// minutes in all. A Wi-Fi to cellular handoff drops DNS for a few seconds,
/// and a quick tunnel's freshly issued hostname can fail to resolve for well
/// over a minute, so a short window still ends in the error toast.
const List<Duration> syncRetryDelays = [
  Duration(seconds: 5),
  Duration(seconds: 15),
  Duration(seconds: 30),
  Duration(seconds: 60),
];

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
/// with a transient network error, and telling [onRetry] before each wait.
/// Any other error, or the last transient one, is rethrown.
Future<T> retryTransientSync<T>(
  Future<T> Function() attempt, {
  Future<void> Function(Duration delay) wait = _wait,
  void Function(Object error, Duration delay)? onRetry,
}) async {
  for (final delay in syncRetryDelays) {
    try {
      return await attempt();
    } catch (e) {
      if (!isTransientSyncError(e)) rethrow;
      onRetry?.call(e, delay);
    }
    await wait(delay);
  }
  return attempt();
}

Future<void> _wait(Duration delay) => Future.delayed(delay);
