import 'package:latlong2/latlong.dart';

const Distance _distance = Distance();

/// The shortest separation, in meters, that can count as a natural gap between
/// two groups. Keeps one metro area together even when its points are sparse.
const double _minimumClusterGapMeters = 80000;

/// The longest separation, in meters, that can still join two places into one
/// group. Without it, points that are all far apart inflate the typical link
/// and merge into one cluster spanning half a continent.
const double _maximumClusterGapMeters = 200000;

/// A link this many times longer than the typical link between neighbouring
/// points is treated as a natural gap.
const double _clusterGapRatio = 4;

/// Splits [points] into geographic clusters wherever there is a natural gap.
///
/// Builds a minimum spanning tree and cuts every link much longer than the
/// typical link, so the threshold adapts to how spread out the points are:
/// a tight neighbourhood and a set of friends spread across a country are
/// both judged against their own spacing rather than a fixed radius.
List<List<int>> clusterFindMyPoints(List<LatLng> points) {
  final n = points.length;
  if (n < 2) {
    return [
      for (var i = 0; i < n; i++) [i],
    ];
  }

  // Prim's algorithm; Find My never has more than a few dozen points.
  final inTree = List<bool>.filled(n, false);
  final best = List<double>.filled(n, double.infinity);
  final parent = List<int>.filled(n, -1);
  best[0] = 0;
  final edges = <(int, int, double)>[];
  for (var step = 0; step < n; step++) {
    var u = -1;
    for (var i = 0; i < n; i++) {
      if (!inTree[i] && (u == -1 || best[i] < best[u])) u = i;
    }
    inTree[u] = true;
    if (parent[u] != -1) edges.add((parent[u], u, best[u]));
    for (var v = 0; v < n; v++) {
      if (inTree[v]) continue;
      final d = _distance.as(LengthUnit.Meter, points[u], points[v]);
      if (d < best[v]) {
        best[v] = d;
        parent[v] = u;
      }
    }
  }

  // Lower median, so a few far-away outliers can't inflate the threshold.
  final lengths = edges.map((e) => e.$3).toList()..sort();
  final typical = lengths[(lengths.length - 1) ~/ 2];
  final gap = (typical * _clusterGapRatio).clamp(_minimumClusterGapMeters, _maximumClusterGapMeters);

  final root = List<int>.generate(n, (i) => i);
  int find(int i) => root[i] == i ? i : root[i] = find(root[i]);
  for (final (a, b, length) in edges) {
    if (length <= gap) root[find(a)] = find(b);
  }

  final clusters = <int, List<int>>{};
  for (var i = 0; i < n; i++) {
    clusters.putIfAbsent(find(i), () => []).add(i);
  }
  return clusters.values.toList();
}

/// Chooses the locations the map should open on.
///
/// With an [anchor] (the user's own location on the People tab) the camera
/// shows the anchor plus whatever is clustered around it, leaving distant
/// friends out of the opening view. Without one, it shows the cluster holding
/// a clear majority of [points], or everything when no cluster does. Every
/// point is still on the map and in the list; this only picks the framing.
List<LatLng> selectFindMyCameraFocus(List<LatLng> points, {LatLng? anchor}) {
  final all = [?anchor, ...points];
  if (all.length < 2) return all;

  final clusters = clusterFindMyPoints(all);
  if (anchor != null) {
    final anchored = clusters.firstWhere((cluster) => cluster.contains(0));
    return [for (final i in anchored) all[i]];
  }

  final largest = clusters.reduce((a, b) => b.length > a.length ? b : a);
  if (largest.length * 2 > all.length) return [for (final i in largest) all[i]];
  return all;
}

/// A logical Find My product to group by owner and physical place.
class FindMyProductPoint {
  const FindMyProductPoint({
    required this.id,
    required this.ownerId,
    required this.location,
    required this.accuracyMeters,
  });

  final String id;
  final String? ownerId;
  final LatLng location;
  final double accuracyMeters;
}

/// Groups devices or items only when Apple says they have the same owner and
/// their reported accuracy areas describe the same physical place.
///
/// The 50 m floor absorbs normal GPS/Wi-Fi disagreement at one home. The
/// 150 m ceiling prevents a very rough fix from swallowing a neighborhood.
/// Unknown owners stay separate because combining them could mix people.
List<List<FindMyProductPoint>> groupFindMyProductsByOwnerAndPlace(List<FindMyProductPoint> points) {
  final groups = <List<FindMyProductPoint>>[
    for (final point in points) [point],
  ];

  bool samePlace(FindMyProductPoint a, FindMyProductPoint b) {
    if (a.ownerId == null || b.ownerId == null || a.ownerId != b.ownerId) return false;
    final threshold = (a.accuracyMeters + b.accuracyMeters).clamp(50.0, 150.0);
    return _distance.as(LengthUnit.Meter, a.location, b.location) <= threshold;
  }

  while (true) {
    var bestA = -1;
    var bestB = -1;
    var bestDistance = double.infinity;
    for (var a = 0; a < groups.length; a++) {
      for (var b = a + 1; b < groups.length; b++) {
        // Complete-link merging avoids a chain of marginal fixes stretching a
        // single "place" across a neighborhood.
        if (!groups[a].every((left) => groups[b].every((right) => samePlace(left, right)))) continue;
        final distance = _distance.as(LengthUnit.Meter, groups[a].first.location, groups[b].first.location);
        if (distance < bestDistance) {
          bestA = a;
          bestB = b;
          bestDistance = distance;
        }
      }
    }
    if (bestA == -1) break;
    groups[bestA].addAll(groups.removeAt(bestB));
  }

  return groups;
}
