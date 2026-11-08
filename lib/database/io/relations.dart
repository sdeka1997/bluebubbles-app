import 'package:objectbox/objectbox.dart' as obx;

// Relations of the messaging entities (S2 switch plan, commit 3).
//
// On the ObjectBox path these behave exactly as ObjectBox's own ToOne/ToMany:
// every member delegates to it. (They keep ObjectBox's class names because the
// generator recognises a relation field by that name; the ObjectBox model and
// generated code stay byte-identical.)
//
// An entity read from SQLite has no store to lazy-load from. Its row mapper
// marks each relation [ToOne.loadedFromSqlite] / [ToMany.loadedFromSqlite]
// with the stored id, and the repository fills it. Reading a relation the
// repository did not fill is a bug that would show up as a missing avatar,
// name or attachment, so a debug assert throws instead.

/// The names the entity files use (S2 switch plan section 2).
typedef Rel<T> = ToOne<T>;
typedef RelList<T> = ToMany<T>;

class ToOne<T> extends obx.ToOne<T> {
  ToOne({super.target, super.targetId});

  /// Non-null for an entity read from SQLite.
  _RowOne<T>? _row;

  /// Called by the row mapper: [id] is the stored foreign key (null or 0: none).
  void loadedFromSqlite(int? id, {required String label}) => _row = _RowOne(id ?? 0, label);

  /// The repository's fill: the target for the stored id (null when the row is gone).
  void fill(T? target) {
    final row = _row;
    if (row == null) {
      super.target = target;
      return;
    }
    row
      ..target = target
      ..filled = true;
  }

  bool get isFilled => _row?.filled ?? true;

  @override
  T? get target {
    final row = _row;
    if (row == null) return super.target;
    assert(row.filled, '${row.label} read before the repository filled it');
    return row.target;
  }

  @override
  set target(T? object) {
    final row = _row;
    if (row == null) {
      super.target = object;
      return;
    }
    row
      ..target = object
      ..id = object == null ? 0 : ((object as dynamic).id as int? ?? 0)
      ..filled = true;
  }

  @override
  int get targetId => _row?.id ?? super.targetId;

  @override
  set targetId(int? id) {
    final row = _row;
    if (row == null) {
      super.targetId = id;
      return;
    }
    if ((id ?? 0) == row.id) return;
    row
      ..id = id ?? 0
      ..target = null
      ..filled = row.id == 0;
  }

  @override
  bool get hasValue => _row == null ? super.hasValue : _row!.id != 0;
}

class _RowOne<T> {
  _RowOne(this.id, this.label) : filled = id == 0;

  int id;
  final String label;
  T? target;
  bool filled;
}

class ToMany<T> extends obx.ToMany<T> {
  ToMany({super.items});

  /// Null on the ObjectBox path; for an entity read from SQLite, the label
  /// until the repository fills it.
  String? _unfilled;
  bool _fromSqlite = false;

  void loadedFromSqlite({required String label}) {
    _fromSqlite = true;
    _unfilled = label;
  }

  /// The repository's fill: every stored member, in its order.
  void fill(Iterable<T> items) {
    _unfilled = null;
    super.addAll(items);
  }

  bool get isFilled => _unfilled == null;
  bool get isFromSqlite => _fromSqlite;

  void _check() {
    assert(_unfilled == null, '$_unfilled read before the repository filled it');
  }

  @override
  int get length {
    _check();
    return super.length;
  }

  @override
  T operator [](int index) {
    _check();
    return super[index];
  }

  @override
  List<T> toList({bool growable = true}) {
    _check();
    return super.toList(growable: growable);
  }
}
