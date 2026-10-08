import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
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

/// Markers closer than this on screen, in logical pixels, are drawn as one.
const double _overlapDistance = 30;

/// Groups [markers] that would overlap at the [camera]'s current zoom.
///
/// Each group keeps the order of [markers], so the first marker in a group is
/// the one drawn on top. The user's own location is never grouped.
List<List<Marker>> groupOverlappingFindMyMarkers(List<Marker> markers, MapCamera camera) {
  final groups = <List<Marker>>[];
  final anchors = <Offset>[];
  for (final marker in markers) {
    final key = (marker.key as ValueKey?)?.value;
    final position = camera.projectAtZoom(marker.point, camera.zoom);
    if (key != 'current') {
      var index = -1;
      for (var i = 0; i < groups.length; i++) {
        final groupKey = (groups[i].first.key as ValueKey?)?.value;
        if (groupKey != 'current' && (anchors[i] - position).distance < _overlapDistance) {
          index = i;
          break;
        }
      }
      if (index != -1) {
        groups[index].add(marker);
        continue;
      }
    }
    groups.add([marker]);
    anchors.add(position);
  }
  return groups;
}
