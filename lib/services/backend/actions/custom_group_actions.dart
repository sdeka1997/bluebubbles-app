import 'package:bluebubbles/database/store/messaging_store.dart';

class CustomGroupActions {
  static Future<int> create(dynamic data) async {
    final name = data['name'] as String;
    // Dedupe so a repeated guid in the input can't create duplicate rows in
    // the group<->chat relation.
    final chatGuids = (data['chatGuids'] as List).cast<String>().toSet();
    return MessagingStore.current.createCustomGroup(name, chatGuids);
  }

  static Future<int> rename(dynamic data) async {
    final id = data['id'] as int;
    final name = data['name'] as String;
    return MessagingStore.current.renameCustomGroup(id, name);
  }

  static Future<int> updateChats(dynamic data) async {
    final id = data['id'] as int;
    // Dedupe so a repeated guid in the input can't create duplicate rows in
    // the group<->chat relation.
    final chatGuids = (data['chatGuids'] as List).cast<String>().toSet();
    return MessagingStore.current.setCustomGroupChats(id, chatGuids);
  }

  static Future<int> setShowUnreadBadge(dynamic data) async {
    final id = data['id'] as int;
    final value = data['value'] as bool;
    return MessagingStore.current.setCustomGroupShowUnreadBadge(id, value);
  }

  static Future<List<int>> getAllIds(dynamic data) => MessagingStore.current.customGroupIds();

  static Future<void> reorder(dynamic data) async {
    final ids = (data['ids'] as List).cast<int>();
    await MessagingStore.current.reorderCustomGroups(ids);
  }

  static Future<void> delete(dynamic data) async {
    final id = data['id'] as int;
    await MessagingStore.current.deleteCustomGroup(id);
  }
}
