import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';

class HandleActions {
  static Future<int> saveHandleAsync(dynamic data) async {
    final handleData = data['handleData'] as Map<String, dynamic>;
    final updateColor = data['updateColor'] as bool;
    final matchOnOriginalROWID = data['matchOnOriginalROWID'] as bool;

    final handle = Handle.fromMap(handleData);

    // Format the address before entering the transaction (async not allowed inside)
    await handle.updateFormattedAddress();

    final id = await MessagingStore.current
        .saveHandle(handle, updateColor: updateColor, matchOnOriginalROWID: matchOnOriginalROWID);
    return id!;
  }

  static Future<List<int>> bulkSaveHandlesAsync(dynamic data) async {
    final handlesData = (data['handlesData'] as List).cast<Map<String, dynamic>>();
    final matchOnOriginalROWID = data['matchOnOriginalROWID'] as bool;

    final handles = handlesData.map((e) => Handle.fromMap(e)).toList();

    // Format addresses before entering the transaction (async not allowed inside)
    for (Handle h in handles) {
      await h.updateFormattedAddress();
    }

    return MessagingStore.current.saveHandles(handles, matchOnOriginalROWID: matchOnOriginalROWID);
  }

  static Future<int?> findOneHandleAsync(dynamic data) async {
    return MessagingStore.current.findHandleId(
      id: data['id'] as int?,
      originalROWID: data['originalROWID'] as int?,
      address: data['address'] as String?,
      service: data['service'] as String?,
    );
  }

  static Future<List<int>> findHandlesAsync(dynamic data) => MessagingStore.current.allHandleIds();
}
