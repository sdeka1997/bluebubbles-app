import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The chat list builds message rows lazily. A row whose State keeps itself
// alive (AutomaticKeepAliveClientMixin, or any widget inside it doing so) is
// never released once built, so scrolling back through a chat held every
// row, image and preview passed: 90 swipes took one chat from 630 MB to
// 1.7 GB. Rows must be free to go when they leave the screen; anything that
// has to outlive a row (players, fetched previews) lives on the chat
// controller or on disk, not in the row's State.
void main() {
  test('no widget in a message row keeps itself alive', () {
    final dir = Directory('lib/app/layouts/conversation_view/widgets/message');
    final offenders = [
      for (final f in dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')))
        if (RegExp(r'AutomaticKeepAliveClientMixin|wantKeepAlive').hasMatch(f.readAsStringSync())) f.path,
    ]..sort();
    expect(offenders, isEmpty);
  });
}
