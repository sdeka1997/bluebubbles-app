import 'package:bluebubbles/helpers/ui/edit_unsend_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sent = DateTime.utc(2026, 10, 27, 18, 0, 0);

  group('canUndoSend', () {
    test('is offered right after sending', () {
      expect(canUndoSend(sent, now: sent.add(const Duration(seconds: 30))), isTrue);
    });

    test('is hidden in the last seconds before Apple closes the 2 minute window', () {
      expect(canUndoSend(sent, now: sent.add(const Duration(minutes: 1, seconds: 55))), isFalse);
    });

    test('is hidden once the window has closed', () {
      expect(canUndoSend(sent, now: sent.add(const Duration(minutes: 3))), isFalse);
    });

    test('is hidden without a send time', () {
      expect(canUndoSend(null, now: sent), isFalse);
    });
  });

  group('canEdit', () {
    test('is offered within the 15 minute window', () {
      expect(canEditSent(sent, now: sent.add(const Duration(minutes: 10))), isTrue);
    });

    test('is hidden in the last 30 seconds before Apple closes the window', () {
      expect(canEditSent(sent, now: sent.add(const Duration(minutes: 14, seconds: 40))), isFalse);
    });

    test('is hidden once the window has closed', () {
      expect(canEditSent(sent, now: sent.add(const Duration(minutes: 16))), isFalse);
    });
  });
}
