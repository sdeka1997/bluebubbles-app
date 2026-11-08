import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/helpers/types/helpers/service_twin_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports a thread shown as a hidden chat, with every copy', () {
    final shown = Chat(id: 1, guid: 'SMS;-;+15550000001', threadKey: 'T', isFilteredAsSpam: true);
    final real = Chat(id: 2, guid: 'iMessage;-;+15550000001', threadKey: 'T');
    final lines = threadDiagnostics([shown, real], listed: {});
    expect(lines, hasLength(1));
    expect(lines.single, contains('thread T shown as SMS;-;+15550000001 [spam, not listed]'));
    expect(lines.single, contains('iMessage;-;+15550000001'));
  });

  test('reports a lone chat that is neither listed nor hidden on purpose', () {
    final lost = Chat(id: 3, guid: 'iMessage;-;+15550000002', threadKey: 'U');
    expect(threadDiagnostics([lost], listed: {}).single, contains('[not listed]'));
  });

  test('a listed thread and a deleted chat are not reported', () {
    final ok = Chat(id: 4, guid: 'a', threadKey: 'V');
    final gone = Chat(id: 5, guid: 'b', threadKey: 'W', dateDeleted: DateTime(2026));
    expect(threadDiagnostics([ok, gone], listed: {'a'}), isEmpty);
  });
}
