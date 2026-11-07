import 'dart:convert';
import 'dart:ui';

import 'package:bluebubbles/database/global/payload_data.dart';
import 'package:bluebubbles/helpers/types/constants.dart' show PayloadType;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a media size with decimals survives a save and reload unchanged', () {
    final metadata = MediaMetadata(size: const Size(123.5, 456.25), url: 'https://example.com/a.png');
    final once = MediaMetadata.fromJson(jsonDecode(jsonEncode(metadata.toJson())));
    expect(once.size, const Size(123.5, 456.25));
    final twice = MediaMetadata.fromJson(jsonDecode(jsonEncode(once.toJson())));
    expect(twice.toJson(), metadata.toJson());
  });

  test('the size string Apple sends, with braces and spaces, still parses', () {
    expect(MediaMetadata.fromJson({'size': '{1200, 630.5}'}).size, const Size(1200, 630.5));
    expect(MediaMetadata.fromJson({'size': {'width': '1200.5', 'height': 630}}).size, const Size(1200.5, 630));
  });

  test('a stored link preview payload reloads to the same JSON', () {
    final payload = PayloadData(
      type: PayloadType.url,
      urlData: [UrlPreviewData(imageMetadata: MediaMetadata(size: const Size(1.5, 2.75)), url: 'https://example.com')],
    );
    final json = jsonEncode(payload.toJson());
    expect(jsonEncode(PayloadData.fromJson(jsonDecode(json)).toJson()), json);
  });
}
