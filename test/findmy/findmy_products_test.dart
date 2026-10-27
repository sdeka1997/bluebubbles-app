import 'package:bluebubbles/app/layouts/findmy/widgets/findmy_items_tab_view.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:flutter_test/flutter_test.dart';

FindMyDevice device(Map<String, dynamic> values) => FindMyDevice.fromJson({
  'id': values['id'],
  'name': values['name'],
  'deviceModel': values['deviceModel'],
  'deviceClass': values['deviceClass'],
  'modelDisplayName': values['modelDisplayName'],
  'productIdentifier': values['productIdentifier'],
  'serialNumber': values['serialNumber'],
  'isAppleAudioAccessory': values['isAppleAudioAccessory'] ?? false,
  'isConsideredAccessory': values['isConsideredAccessory'] ?? false,
  'groupIdentifier': values['groupIdentifier'],
  'groupName': values['groupName'],
  'location': values['hasLocation'] == false
      ? null
      : {'latitude': 32.0, 'longitude': -96.0},
});

void main() {
  test('AirPods components collapse into one product under Devices', () {
    final all = [
      device({'id': 'phone', 'name': 'Phone', 'deviceClass': 'iPhone'}),
      for (final role in ['left', 'right', 'Case'])
        device({
          'id': 'pods-$role',
          'name': role,
          'deviceModel': 'hawkeye',
          'deviceClass': 'hawkeye',
          'isAppleAudioAccessory': true,
          'isConsideredAccessory': true,
          'groupIdentifier': 'pods-group',
          'groupName': 'AirPods Pro',
        }),
      device({
        'id': 'wallet',
        'name': 'Wallet',
        'deviceModel': 'b389',
        'deviceClass': 'b389',
        'isConsideredAccessory': true,
      }),
    ];

    final devices = findMyDeviceProducts(all);
    final items = findMyItemProducts(all);

    expect(devices.map((e) => e.id), contains('phone'));
    expect(
      devices.where((e) => e.groupIdentifier == 'pods-group'),
      hasLength(1),
    );
    expect(items.map((e) => e.id), ['wallet']);
  });

  test('Sequoia bud labels collapse under the parent and a unique stale orphan is hidden', () {
    const product = 'left-right-product';
    final all = [
      device({
        'id': 'parent',
        'name': 'AirPods Pro',
        'deviceModel': 'AirPods_8228-0',
        'deviceClass': 'Accessory',
        'isConsideredAccessory': true,
      }),
      for (final part in [
        ('Case', 'CASE0001', 'case-product'),
        ('Right Bud', 'RIGHT002', product),
        ('Left Bud', 'ACTIVE26JY', product),
      ])
        device({
          'id': 'grouped-${part.$1}',
          'name': part.$1,
          'serialNumber': part.$2,
          'productIdentifier': part.$3,
          'deviceModel': 'hawkeye',
          'deviceClass': 'hawkeye',
          'isAppleAudioAccessory': true,
          'isConsideredAccessory': true,
          'groupIdentifier': 'active-group',
          'groupName': 'AirPods Pro',
        }),
      device({
        'id': 'stale-left',
        'name': 'Left Bud',
        'serialNumber': 'STALE026JY',
        'productIdentifier': product,
        'deviceModel': 'hawkeye',
        'deviceClass': 'hawkeye',
        'isAppleAudioAccessory': true,
        'isConsideredAccessory': true,
        'groupIdentifier': 'stale-group',
        'hasLocation': false,
      }),
    ];

    final devices = findMyDeviceProducts(all);
    expect(devices.map((item) => item.id), ['parent']);
    expect(
      devices.where((item) => item.displayName == 'AirPods Pro'),
      hasLength(1),
    );
    expect(devices.where((item) => item.displayName == 'Left Bud'), isEmpty);
  });

  test('an ambiguous stale orphan remains visible', () {
    const product = 'same-product';
    FindMyDevice grouped(String id, String group) => device({
      'id': id,
      'name': 'Left Bud',
      'serialNumber': '${id}26JY',
      'productIdentifier': product,
      'deviceModel': 'hawkeye',
      'deviceClass': 'hawkeye',
      'isAppleAudioAccessory': true,
      'isConsideredAccessory': true,
      'groupIdentifier': group,
      'groupName': 'Same Name',
    });
    final orphan = device({
      'id': 'orphan',
      'name': 'Left Bud',
      'serialNumber': 'ORPHAN26JY',
      'productIdentifier': product,
      'deviceModel': 'hawkeye',
      'deviceClass': 'hawkeye',
      'isAppleAudioAccessory': true,
      'isConsideredAccessory': true,
      'groupIdentifier': 'old-group',
      'hasLocation': false,
    });

    final collapsed = collapseFindMyAccessoryComponents([
      grouped('first', 'first-group'),
      grouped('second', 'second-group'),
      orphan,
    ]);
    expect(collapsed.map((item) => item.id), contains('orphan'));
  });

  test('a standalone AirPods parent belongs under Devices', () {
    final airPods = device({
      'id': 'airpods-max',
      'name': 'Headphones',
      'modelDisplayName': 'AirPods Max',
      'deviceClass': 'Accessory',
      'isConsideredAccessory': true,
    });

    expect(findMyDeviceProducts([airPods]), [airPods]);
    expect(findMyItemProducts([airPods]), isEmpty);
  });
}
