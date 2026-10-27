import 'package:bluebubbles/database/models.dart';
import 'package:flutter/material.dart';

/// What to draw for a Find My device or item: the owner's chosen emoji when it
/// has one, otherwise an icon for its kind.
class FindMyGlyph {
  final IconData? icon;
  final String? emoji;

  const FindMyGlyph.icon(IconData this.icon) : emoji = null;

  const FindMyGlyph.emoji(String this.emoji) : icon = null;
}

/// Shared by the map pins and the Devices/Items rows so both agree.
FindMyGlyph findMyGlyph(FindMyDevice device) {
  final model = '${device.deviceModel ?? ''} ${device.modelDisplayName ?? ''}'.toLowerCase();
  // AirPods report a placeholder emoji (😀), so they keep the headphones icon.
  if (device.isAppleAudioAccessory || model.contains('airpods')) return const FindMyGlyph.icon(Icons.headphones);

  final emoji = device.role?['emoji'] as String?;
  if (emoji != null && emoji.isNotEmpty) return FindMyGlyph.emoji(emoji);

  switch (device.deviceClass?.toLowerCase()) {
    case 'iphone':
      return const FindMyGlyph.icon(Icons.phone_iphone);
    case 'ipad':
      return const FindMyGlyph.icon(Icons.tablet_mac);
    case 'watch':
      return const FindMyGlyph.icon(Icons.watch);
  }
  if (device.isMac == true) return const FindMyGlyph.icon(Icons.laptop_mac);
  if (device.isConsideredAccessory) return const FindMyGlyph.icon(Icons.sell);
  return const FindMyGlyph.icon(Icons.devices);
}
