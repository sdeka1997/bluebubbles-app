import 'package:bluebubbles/database/database.dart';
import 'package:bluebubbles/database/models.dart';
import 'package:bluebubbles/database/store/messaging_store.dart';
import 'package:bluebubbles/models/models.dart' show HandleLookupKey;

/// HandleActions' ObjectBox code.
mixin ObjectBoxHandleStore implements HandleStore {
  @override
  Future<int?> saveHandle(Handle handle, {required bool updateColor, required bool matchOnOriginalROWID}) async {
    return Database.runInTransaction(TxMode.write, () {
      Handle? existing;
      if (matchOnOriginalROWID) {
        existing = Handle.findOne(originalROWID: handle.originalROWID);
      } else {
        existing = Handle.findOne(addressAndService: HandleLookupKey(handle.address, handle.service));
      }

      if (existing != null) {
        handle.id = existing.id;
        handle.originalROWID ??= existing.originalROWID;
      }
      // Contact matching is now handled automatically by ContactServiceV2
      if (!updateColor) {
        handle.color = existing?.color ?? handle.color;
      }

      try {
        handle.id = Database.handles.put(handle);
      } on UniqueViolationException catch (_) {}

      // Return just the ID for efficient transfer across isolates
      return handle.id!;
    });
  }

  @override
  Future<List<int>> saveHandles(List<Handle> handles, {required bool matchOnOriginalROWID}) async {
    return Database.runInTransaction(TxMode.write, () {
      /// Match existing to the handles to save, where possible
      for (Handle h in handles) {
        Handle? existing;
        if (matchOnOriginalROWID) {
          existing = Handle.findOne(originalROWID: h.originalROWID);
        } else {
          existing = Handle.findOne(addressAndService: HandleLookupKey(h.address, h.service));
        }

        if (existing != null) {
          h.id = existing.id;
          h.originalROWID ??= existing.originalROWID;
        }
        // Contact matching is now handled automatically by ContactServiceV2
      }

      List<int> insertedIds = Database.handles.putMany(handles);
      for (int i = 0; i < insertedIds.length; i++) {
        handles[i].id = insertedIds[i];
      }

      // Return just the IDs for efficient transfer across isolates
      return handles.map((e) => e.id!).toList();
    });
  }

  @override
  Future<int?> findHandleId({int? id, int? originalROWID, String? address, String? service}) async {
    return Database.runInTransaction(TxMode.read, () {
      final handleBox = Database.handles;

      Handle? result;

      if (id != null && id != 0) {
        result = handleBox.get(id);
        if (result == null) {
          // Try finding by originalROWID if direct ID lookup fails
          final query = handleBox.query(Handle_.originalROWID.equals(id)).build();
          query.limit = 1;
          result = query.findFirst();
          query.close();
        }
      } else if (originalROWID != null) {
        final query = handleBox.query(Handle_.originalROWID.equals(originalROWID)).build();
        query.limit = 1;
        result = query.findFirst();
        query.close();
      } else if (address != null && service != null) {
        final query = handleBox.query(Handle_.address.equals(address) & Handle_.service.equals(service)).build();
        query.limit = 1;
        result = query.findFirst();
        query.close();
      }

      // Return just the ID for efficient transfer across isolates
      return result?.id;
    });
  }

  @override
  Future<List<int>> allHandleIds() async {
    return Database.runInTransaction(TxMode.read, () {
      final handleBox = Database.handles;

      final query = handleBox.query().build();
      final results = query.find();
      query.close();

      // Return just the IDs for efficient transfer across isolates
      return results.map((e) => e.id!).toList();
    });
  }

  @override
  Future<int> handleCount() async => Database.handles.count();

  @override
  Future<List<Handle>> handlesWithoutRowId() async {
    final query = (Database.handles.query(Handle_.originalROWID.isNull())..order(Handle_.id)).build();
    try {
      return query.find();
    } finally {
      query.close();
    }
  }

  @override
  Future<List<Handle>> allHandles() async => Database.handles.getAll();

  @override
  Future<void> clearHandles() async {
    Database.handles.removeAll();
  }

  @override
  Future<Handle?> handleById(int id) async => Database.handles.get(id);

  @override
  Future<List<Handle>> handlesByIds(List<int> ids) async => Database.handles.getMany(ids).whereType<Handle>().toList();
}
