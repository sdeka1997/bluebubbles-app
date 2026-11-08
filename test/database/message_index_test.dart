import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reactions are looked up by an indexed field', () {
    final model = jsonDecode(File('lib/generated/objectbox-model.json').readAsStringSync());
    final message = (model['entities'] as List).firstWhere((e) => e['name'] == 'Message');
    final field = (message['properties'] as List).firstWhere((p) => p['name'] == 'associatedMessageGuid');
    expect(field['indexId'], isNotNull, reason: 'without it every reaction lookup reads every message on the phone');
  });
}
