import 'dart:convert';
import 'dart:math';

const String recoverableDeleteAttemptIdPattern = r'^[A-Za-z0-9_-]{16,128}$';
final RegExp recoverableDeleteAttemptIdRegExp = RegExp(recoverableDeleteAttemptIdPattern);

String generateRecoverableDeleteAttemptId() {
  final random = Random.secure();
  final bytes = List<int>.generate(24, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

enum RecoverableDeleteReceiptState { pending, succeeded, definitiveFailure }

class RecoverableDeleteReceipt {
  const RecoverableDeleteReceipt({
    required this.attemptId,
    required this.state,
    required this.failureCode,
    required this.createdAt,
    required this.updatedAt,
  });

  final String attemptId;
  final RecoverableDeleteReceiptState state;
  final String? failureCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  static RecoverableDeleteReceipt? tryParse(Object? envelope, {required String expectedAttemptId}) {
    try {
      if (envelope is! Map || envelope['data'] is! Map) return null;
      final data = envelope['data'] as Map;
      final attemptId = data['attemptId'];
      final stateValue = data['state'];
      final failureCode = data['failureCode'];
      final createdAtValue = data['createdAt'];
      final updatedAtValue = data['updatedAt'];
      if (attemptId is! String ||
          attemptId != expectedAttemptId ||
          !recoverableDeleteAttemptIdRegExp.hasMatch(attemptId) ||
          stateValue is! String ||
          (failureCode != null && failureCode is! String) ||
          createdAtValue is! String ||
          updatedAtValue is! String) {
        return null;
      }
      final state = switch (stateValue) {
        'pending' => RecoverableDeleteReceiptState.pending,
        'succeeded' => RecoverableDeleteReceiptState.succeeded,
        'definitiveFailure' => RecoverableDeleteReceiptState.definitiveFailure,
        _ => null,
      };
      if (state == null) return null;
      return RecoverableDeleteReceipt(
        attemptId: attemptId,
        state: state,
        failureCode: failureCode as String?,
        createdAt: DateTime.parse(createdAtValue),
        updatedAt: DateTime.parse(updatedAtValue),
      );
    } on Object {
      return null;
    }
  }
}

sealed class RecoverableDeleteAttemptResult {
  const RecoverableDeleteAttemptResult();
}

final class RecoverableDeleteReceiptResult extends RecoverableDeleteAttemptResult {
  const RecoverableDeleteReceiptResult(this.receipt);
  final RecoverableDeleteReceipt receipt;
}

final class RecoverableDeleteSubmitRejectedNoDispatch extends RecoverableDeleteAttemptResult {
  const RecoverableDeleteSubmitRejectedNoDispatch();
}

final class RecoverableDeleteAttemptNotRecorded extends RecoverableDeleteAttemptResult {
  const RecoverableDeleteAttemptNotRecorded();
}

final class RecoverableDeleteAttemptAmbiguous extends RecoverableDeleteAttemptResult {
  const RecoverableDeleteAttemptAmbiguous();
}
