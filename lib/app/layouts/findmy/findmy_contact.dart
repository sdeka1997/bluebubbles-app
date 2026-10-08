import 'package:bluebubbles/database/models.dart';

/// Returns the real phone/email address Find My supplied for contact matching.
/// A display title is never an address.
String? findMyContactLookupAddress(FindMyFriend friend) {
  final address = (friend.handle?.address ?? friend.handleAddress)?.trim();
  if (address == null || address.isEmpty) return null;
  if (address.contains('@')) return address;
  final digits = address.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 5 ? address : null;
}

/// Matches the same phone-number variants as BlueBubbles' normal contact sync,
/// including numbers that differ only by a 1–3 digit country-code prefix.
bool findMyContactMatchesAddress(ContactV2 contact, String address) {
  if (address.contains('@')) {
    final normalized = ContactV2.normalizeEmail(address);
    return contact.addresses.any(
      (candidate) => candidate.contains('@') && ContactV2.normalizeEmail(candidate) == normalized,
    );
  }

  final wanted = _phoneVariants(address);
  return contact.addresses
      .where((candidate) => !candidate.contains('@'))
      .any((candidate) => _phoneVariants(candidate).any(wanted.contains));
}

Set<String> _phoneVariants(String phone) {
  final normalized = ContactV2.normalizePhoneNumber(phone);
  if (normalized.isEmpty) return const {};
  final variants = <String>{normalized};
  if (normalized.startsWith('+')) {
    variants.add(normalized.substring(1));
    for (var prefixLength = 1; prefixLength <= 3 && prefixLength < normalized.length; prefixLength++) {
      variants.add(normalized.substring(prefixLength + 1));
    }
  } else {
    variants.add('+$normalized');
    for (var prefixLength = 1; prefixLength <= 3 && prefixLength < normalized.length; prefixLength++) {
      final withoutPrefix = normalized.substring(prefixLength);
      variants.add(withoutPrefix);
      variants.add('+$withoutPrefix');
    }
  }
  return variants.where((variant) => variant.isNotEmpty).toSet();
}
