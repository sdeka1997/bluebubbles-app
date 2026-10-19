import 'dart:async';

import 'package:bluebubbles/database/models.dart';

typedef ChatOpenGuard = bool Function(String guid);

/// Looks [guid] up only when [canOpen] allows it, and asks again afterwards so a
/// delete that starts during the lookup still keeps the chat closed.
Future<Chat?> resolveOpenableChat(
  String guid, {
  required ChatOpenGuard canOpen,
  required FutureOr<Chat?> Function(String guid) lookup,
}) async {
  if (!canOpen(guid)) return null;
  final chat = await lookup(guid);
  if (chat == null || !canOpen(guid)) return null;
  return chat;
}

/// Runs [open] only when [canOpen] allows [guid]; returns whether it ran.
Future<bool> openIfAllowed(
  String guid, {
  required ChatOpenGuard canOpen,
  required FutureOr<void> Function() open,
}) async {
  if (!canOpen(guid)) return false;
  await open();
  return true;
}


/// Restores a previously active chat only if it is still openable on return.
Future<bool> restoreIfAllowed(
  String guid, {
  required ChatOpenGuard canOpen,
  required FutureOr<void> Function() restore,
}) =>
    openIfAllowed(guid, canOpen: canOpen, open: restore);
