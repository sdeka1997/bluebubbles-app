import 'package:bluebubbles/services/ui/chat/chats_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removes the local chat only after the server confirms the delete', () async {
    final calls = <String>[];
    final ok = await deleteRemoteThenLocal(
      remoteDelete: () async => calls.add('remote'),
      localDelete: () async => calls.add('local'),
      onError: (_, _) => calls.add('error'),
    );
    expect(ok, isTrue);
    expect(calls, ['remote', 'local']);
  });

  test('keeps the local chat when the server delete fails', () async {
    final calls = <String>[];
    final ok = await deleteRemoteThenLocal(
      remoteDelete: () async => throw Exception('Chat still exists'),
      localDelete: () async => calls.add('local'),
      onError: (_, _) => calls.add('error'),
    );
    expect(ok, isFalse);
    expect(calls, ['error']);
  });
}
