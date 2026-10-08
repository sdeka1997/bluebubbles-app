import 'package:bluebubbles/app/layouts/findmy/findmy_camera.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

// Reference points; only their relative distances matter.
const seattle = LatLng(47.6062, -122.3321);
const bellevue = LatLng(47.6101, -122.2015);
const redmond = LatLng(47.6740, -122.1215);
const kirkland = LatLng(47.6769, -122.2060);
const dallas = LatLng(32.7767, -96.7970);
const plano = LatLng(33.0198, -96.6989);
const frisco = LatLng(33.1507, -96.8236);
const arlington = LatLng(32.7357, -97.1081);
const austin = LatLng(30.2672, -97.7431);
const miami = LatLng(25.7617, -80.1918);
const montana = LatLng(46.8721, -113.9940);

void main() {
  group('selectFindMyCameraFocus without an anchor', () {
    test('opens on the clear majority and leaves a lone outlier out', () {
      final focus = selectFindMyCameraFocus([seattle, bellevue, redmond, kirkland, dallas]);
      expect(focus, unorderedEquals([seattle, bellevue, redmond, kirkland]));
    });

    test('fits everything when two groups are the same size', () {
      final focus = selectFindMyCameraFocus([seattle, bellevue, dallas, plano]);
      expect(focus, unorderedEquals([seattle, bellevue, dallas, plano]));
    });

    test('fits both when there are only two far-apart locations', () {
      expect(selectFindMyCameraFocus([seattle, dallas]), unorderedEquals([seattle, dallas]));
    });

    test('keeps a single location', () {
      expect(selectFindMyCameraFocus([dallas]), [dallas]);
    });

    test('is empty with no locations', () {
      expect(selectFindMyCameraFocus([]), isEmpty);
    });
  });

  group('selectFindMyCameraFocus with an anchor', () {
    test('frames the anchor with nearby friends and leaves distant ones out', () {
      final focus = selectFindMyCameraFocus([plano, frisco, arlington, austin, miami], anchor: dallas);
      expect(focus, unorderedEquals([dallas, plano, frisco, arlington]));
    });

    test('frames only the anchor when nobody is nearby', () {
      expect(selectFindMyCameraFocus([dallas, plano, seattle], anchor: montana), [montana]);
    });

    test('frames only the anchor with no friends', () {
      expect(selectFindMyCameraFocus([], anchor: montana), [montana]);
    });
  });

  test('frames a home friend cluster but not friends hundreds of miles away', () {
    // A few hundred miles away should never count as nearby.
    const houston = LatLng(29.7604, -95.3698);
    final focus = selectFindMyCameraFocus([plano, frisco, houston, seattle], anchor: dallas);
    expect(focus, unorderedEquals([dallas, plano, frisco]));
  });

  test('clusterFindMyPoints keeps a metro area together', () {
    final clusters = clusterFindMyPoints([dallas, plano, frisco, arlington]);
    expect(clusters, hasLength(1));
  });

  group('groupOverlappingFindMyMarkers', () {
    Marker marker(String key, LatLng point) => Marker(key: ValueKey(key), point: point, child: const SizedBox());
    final camera = MapCamera(
      crs: const Epsg3857(),
      center: dallas,
      zoom: 13,
      rotation: 0,
      nonRotatedSize: const Size(400, 800),
    );

    test('stacks co-located devices even when the user is in the same spot', () {
      final groups = groupOverlappingFindMyMarkers([
        marker('current', dallas),
        marker('device-a', dallas),
        marker('device-b', dallas),
        marker('device-c', const LatLng(32.7768, -96.7971)),
        marker('device-d', plano),
      ], camera);
      final keys = groups.map((g) => g.map((m) => (m.key as ValueKey).value).toList()).toList();
      expect(keys, [
        ['current'],
        ['device-a', 'device-b', 'device-c'],
        ['device-d'],
      ]);
    });
  });
}
