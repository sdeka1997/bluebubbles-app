import 'dart:collection';

// Relations of the messaging entities: a message's chat and sender, a chat's
// participants, a handle's contacts, and so on.
//
// An entity read from SQLite carries only the stored ids. Its row mapper marks
// each relation [Rel.loadedFromSqlite] / [RelList.loadedFromSqlite], and the
// repository fills it (relation_fill.dart). Reading a relation the repository
// did not fill is a bug that would show up as a missing avatar, name or
// attachment, so a debug assert throws instead. A relation of an entity built
// in memory (from the server, or new) is filled from the start.

/// A link to one entity, by its local id.
class Rel<T> {
  Rel({T? target, int? targetId}) {
    if (target != null) {
      this.target = target;
    } else if (targetId != null) {
      this.targetId = targetId;
    }
  }

  int _id = 0;
  T? _target;
  bool _filled = true;
  String _label = 'relation';

  /// Called by the row mapper: [id] is the stored foreign key (null or 0: none).
  void loadedFromSqlite(int? id, {required String label}) {
    _id = id ?? 0;
    _target = null;
    _filled = _id == 0;
    _label = label;
  }

  /// The repository's fill: the target for the stored id (null when the row is gone).
  void fill(T? target) {
    _target = target;
    _filled = true;
  }

  bool get isFilled => _filled;

  T? get target {
    assert(_filled, '$_label read before the repository filled it');
    return _target;
  }

  set target(T? object) {
    _target = object;
    _id = object == null ? 0 : _idOf(object);
    _filled = true;
  }

  /// The target's id (0: none). A target saved after it was set reports the
  /// id it was saved with.
  int get targetId {
    final target = _target;
    return target == null ? _id : _idOf(target);
  }

  /// Points at the entity [id]; its target is unknown until filled.
  set targetId(int? id) {
    if ((id ?? 0) == targetId) return;
    _id = id ?? 0;
    _target = null;
    _filled = _id == 0;
  }

  bool get hasValue => targetId != 0 || _target != null;

  static int _idOf(Object? entity) => ((entity as dynamic).id as int?) ?? 0;
}

/// Links to many entities, in order.
class RelList<T> extends ListBase<T> {
  RelList({List<T>? items}) : _items = items ?? <T>[];

  final List<T> _items;

  /// Null when usable; for an entity read from SQLite, the label until the
  /// repository fills it.
  String? _unfilled;

  void loadedFromSqlite({required String label}) => _unfilled = label;

  /// The repository's fill: every stored member, in its order.
  void fill(Iterable<T> items) {
    _unfilled = null;
    _items.addAll(items);
  }

  bool get isFilled => _unfilled == null;

  void _check() {
    assert(_unfilled == null, '$_unfilled read before the repository filled it');
  }

  @override
  int get length {
    _check();
    return _items.length;
  }

  @override
  set length(int newLength) => _items.length = newLength;

  @override
  T operator [](int index) {
    _check();
    return _items[index];
  }

  @override
  void operator []=(int index, T value) => _items[index] = value;

  @override
  void add(T element) => _items.add(element);

  @override
  void addAll(Iterable<T> iterable) => _items.addAll(iterable);

  @override
  void insert(int index, T element) => _items.insert(index, element);

  @override
  void insertAll(int index, Iterable<T> iterable) => _items.insertAll(index, iterable);

  @override
  List<T> toList({bool growable = true}) {
    _check();
    return _items.toList(growable: growable);
  }
}
