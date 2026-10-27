import 'package:bluebubbles/app/layouts/findmy/findmy_device_glyph.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Field values are taken from a real Find My device list (macOS Sequoia).
FindMyDevice device(Map<String, dynamic> values) => FindMyDevice.fromJson({
  'id': 'id',
  'deviceClass': values['deviceClass'],
  'deviceModel': values['deviceModel'],
  'modelDisplayName': values['modelDisplayName'],
  'isMac': values['isMac'] ?? false,
  'isAppleAudioAccessory': values['isAppleAudioAccessory'] ?? false,
  'isConsideredAccessory': values['isConsideredAccessory'] ?? false,
  'role': values['role'],
});

void main() {
  test('Apple devices get an icon for their kind', () {
    expect(findMyGlyph(device({'deviceClass': 'iPhone', 'deviceModel': 'iPhone16-1-18-0'})).icon, Icons.phone_iphone);
    expect(findMyGlyph(device({'deviceClass': 'iPad', 'deviceModel': 'iPad15_7-1-3-0'})).icon, Icons.tablet_mac);
    expect(findMyGlyph(device({'deviceClass': 'Watch', 'deviceModel': 'Watch6_9-1-27-0'})).icon, Icons.watch);
    expect(
        findMyGlyph(device({'deviceClass': 'MacBookAir', 'deviceModel': 'Mac16_13-skyblue', 'isMac': true})).icon,
        Icons.laptop_mac);
  });

  test('AirPods are headphones whether Apple lists them as a device or an item', () {
    // Under Devices, Apple sends only the model name: no audio or accessory flag.
    expect(findMyGlyph(device({'deviceClass': 'Accessory', 'deviceModel': 'AirPods_8206'})).icon, Icons.headphones);
    expect(
        findMyGlyph(device({
          'deviceClass': 'hawkeye',
          'deviceModel': 'hawkeye',
          'modelDisplayName': 'AirPods Pro (2nd generation)',
          'isAppleAudioAccessory': true,
          'isConsideredAccessory': true,
          'role': {'emoji': '😀', 'name': 'Custom Name'},
        })).icon,
        Icons.headphones);
  });

  test('an item shows the emoji its owner chose', () {
    final wallet = findMyGlyph(device({
      'deviceClass': 'b389',
      'deviceModel': 'b389',
      'modelDisplayName': 'AirTag',
      'isConsideredAccessory': true,
      'role': {'emoji': '💳', 'name': 'Wallet'},
    }));
    expect(wallet.emoji, '💳');
    expect(wallet.icon, isNull);
  });

  test('an item without an emoji gets a tag', () {
    expect(
        findMyGlyph(device({'deviceClass': 'b389', 'modelDisplayName': 'AirTag', 'isConsideredAccessory': true})).icon,
        Icons.sell);
  });
}
