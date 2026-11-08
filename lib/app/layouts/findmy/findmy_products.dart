import 'package:bluebubbles/app/layouts/findmy/findmy_friend_sort.dart';
import 'package:bluebubbles/database/models.dart';

bool _hasDisplayLocation(FindMyDevice item) {
  final label = item.address?.label?.trim();
  final address = item.address?.mapItemFullAddress?.trim();
  return (label?.isNotEmpty ?? false) || (address?.isNotEmpty ?? false);
}

/// One part of a set of AirPods (a bud or the case). Apple reports each part
/// with the internal model and class name 'hawkeye', alongside the parent
/// AirPods entry, so the parts collapse into one product.
bool _isAppleAudioComponent(FindMyDevice item) {
  final isHawkeye = item.deviceModel == 'hawkeye' || item.deviceClass == 'hawkeye';
  return item.isAppleAudioAccessory && isHawkeye;
}

String? _componentGroupId(FindMyDevice item) {
  if (!_isAppleAudioComponent(item) || !(item.groupName?.trim().isNotEmpty ?? false)) return null;
  final id = item.groupIdentifier?.trim();
  return (id?.isNotEmpty ?? false) ? id : null;
}

int _locationQuality(FindMyDevice item) {
  if (_hasDisplayLocation(item)) return 2;
  if (isUsableFindMyCoordinate(item.location?.latitude, item.location?.longitude)) return 1;
  return 0;
}

FindMyDevice _bestLocatedComponent(Iterable<FindMyDevice> components) {
  return components.reduce((best, candidate) {
    final quality = _locationQuality(candidate).compareTo(_locationQuality(best));
    if (quality != 0) return quality > 0 ? candidate : best;
    return (candidate.location?.timeStamp ?? 0) > (best.location?.timeStamp ?? 0) ? candidate : best;
  });
}

String? _serialSuffix(FindMyDevice item) {
  final serial = item.serialNumber?.trim();
  return serial != null && serial.length >= 4 ? serial.substring(serial.length - 4) : null;
}

/// Presents one top-level row per Apple audio-accessory group. Weak orphan
/// records are hidden only when they uniquely match a current grouped part;
/// ambiguous records remain visible rather than losing locator data.
List<FindMyDevice> collapseFindMyAccessoryComponents(List<FindMyDevice> items) {
  final componentsByGroup = <String, List<FindMyDevice>>{};
  for (final item in items) {
    final groupId = _componentGroupId(item);
    if (groupId != null) componentsByGroup.putIfAbsent(groupId, () => []).add(item);
  }

  final groupsByName = <String, List<String>>{};
  for (final entry in componentsByGroup.entries) {
    final name = entry.value.first.groupName!.trim().toLowerCase();
    groupsByName.putIfAbsent(name, () => []).add(entry.key);
  }
  final parentsByName = <String, List<FindMyDevice>>{};
  for (final item in items.where((item) => !_isAppleAudioComponent(item) && item.deviceClass == 'Accessory')) {
    final name = item.name?.trim().toLowerCase();
    if (name?.isNotEmpty ?? false) parentsByName.putIfAbsent(name!, () => []).add(item);
  }
  final groupsBackedByUniqueParents = <String>{};
  for (final entry in groupsByName.entries) {
    if (entry.value.length == 1 && parentsByName[entry.key]?.length == 1) {
      groupsBackedByUniqueParents.add(entry.value.single);
    }
  }

  final activeComponents = componentsByGroup.values.expand((components) => components).toList();
  final emittedGroups = <String>{};
  final output = <FindMyDevice>[];
  for (final item in items) {
    final groupId = _componentGroupId(item);
    if (groupId != null) {
      if (groupsBackedByUniqueParents.contains(groupId) || !emittedGroups.add(groupId)) continue;
      output.add(_bestLocatedComponent(componentsByGroup[groupId]!));
      continue;
    }

    final suffix = _serialSuffix(item);
    final product = item.productIdentifier?.trim();
    final isWeakOrphan =
        _isAppleAudioComponent(item) &&
        (item.groupIdentifier?.isNotEmpty ?? false) &&
        !(item.groupName?.isNotEmpty ?? false) &&
        _locationQuality(item) == 0 &&
        suffix != null &&
        (product?.isNotEmpty ?? false);
    if (isWeakOrphan) {
      final matches = activeComponents.where(
        (candidate) =>
            _isAppleAudioComponent(candidate) &&
            candidate.productIdentifier?.trim() == product &&
            _serialSuffix(candidate) == suffix,
      );
      if (matches.length == 1) continue;
    }

    output.add(item);
  }
  return output;
}

/// AirPods and other Apple headphones, which Find My lists under Devices even
/// though Apple flags them as accessories. Under Devices Apple sends no audio
/// flag, only the model, so this reads Apple's model fields and never the
/// name the owner gave the product.
bool isFindMyAudioProduct(FindMyDevice item) {
  if (item.isAppleAudioAccessory) return true;
  final model = [
    item.modelDisplayName,
    item.deviceDisplayName,
    item.deviceModel,
  ].whereType<String>().join(' ').toLowerCase();
  return model.contains('airpods');
}

/// Logical products Apple presents under Devices. AirPods component records
/// are collapsed first, then moved here rather than being treated as Items.
List<FindMyDevice> findMyDeviceProducts(List<FindMyDevice> all) {
  final ordinaryDevices = all.where((item) => !item.isConsideredAccessory);
  final accessories = collapseFindMyAccessoryComponents(all.where((item) => item.isConsideredAccessory).toList());
  return [...ordinaryDevices, ...accessories.where(isFindMyAudioProduct)];
}

/// Logical Find My network items (AirTags, wallets, luggage and compatible
/// third-party trackers), excluding AirPods.
List<FindMyDevice> findMyItemProducts(List<FindMyDevice> all) => collapseFindMyAccessoryComponents(
  all.where((item) => item.isConsideredAccessory).toList(),
).where((item) => !isFindMyAudioProduct(item)).toList();

/// A device list sorted once into what the Devices and Items tabs show, so
/// the tabs, the map and the camera all agree on which is which.
class FindMyProducts {
  final List<FindMyDevice> devices;
  final List<FindMyDevice> items;

  const FindMyProducts(this.devices, this.items);

  static const FindMyProducts empty = FindMyProducts([], []);

  factory FindMyProducts.of(List<FindMyDevice> all) => FindMyProducts(findMyDeviceProducts(all), findMyItemProducts(all));

  /// The products of tab [tab]: 1 is Devices, 2 is Items.
  List<FindMyDevice> of(int tab) => tab == 1 ? devices : items;
}
