import 'dart:async';

import 'package:dio/dio.dart';

/// Where one Find My source (friends or devices) stands in the current load.
enum FindMyLoad { idle, loading, loaded, failed }

class FindMySourceState {
  const FindMySourceState._(this.load, {this.updatedAt, this.error});

  static const FindMySourceState idle = FindMySourceState._(FindMyLoad.idle);

  final FindMyLoad load;

  /// When this source last loaded from the server, kept through later loads.
  final DateTime? updatedAt;

  /// Why the last load failed, in words fit for the screen.
  final String? error;

  FindMySourceState loading() => FindMySourceState._(FindMyLoad.loading, updatedAt: updatedAt);

  FindMySourceState loaded(DateTime at) => FindMySourceState._(FindMyLoad.loaded, updatedAt: at);

  FindMySourceState failed(String reason) => FindMySourceState._(FindMyLoad.failed, updatedAt: updatedAt, error: reason);

  bool get isLoading => load == FindMyLoad.loading;
}

/// A Find My request the page stopped waiting on.
class FindMyDeadlineException implements Exception {
  const FindMyDeadlineException(this.deadline);

  final Duration deadline;

  @override
  String toString() => 'No answer within ${deadline.inSeconds} s';
}

/// A short, user-facing reason for a failed Find My request.
String describeFindMyError(Object error) {
  if (error is FindMyDeadlineException) return error.toString();
  if (error is Response) return 'The server answered ${error.statusCode}';
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status != null) return 'The server answered $status';
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'The server took too long to answer',
      DioExceptionType.cancel => 'The request was cancelled',
      _ => 'Could not reach the server',
    };
  }
  if (error is FormatException || error is TypeError) return 'The server sent data the app could not read';
  if (error is TimeoutException) return 'The server took too long to answer';
  return error.toString();
}
