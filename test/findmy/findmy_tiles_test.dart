import 'dart:async';

import 'package:bluebubbles/app/layouts/findmy/findmy_tiles.dart';
import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

/// The total wait the client spends between its attempts at one tile.
Duration get allRetryDelays => [
  for (var retry = 1; retry < findMyTileAttempts; retry++) findMyTileRetryDelay(retry),
].fold(Duration.zero, (a, b) => a + b);

ClientException closedConnection(Uri url) =>
    ClientException('Connection closed before full header was received', url);

void main() {
  setUp(() => GetIt.I.registerSingleton<BaseLogger>(BaseLogger()));
  tearDown(() => GetIt.I.reset());

  group('FindMyTileClient', () {
    final url = Uri.parse('https://tile.openstreetmap.org/1/0/0.png');

    test('retries a connection that closed before the headers arrived', () {
      fakeAsync((async) {
        var calls = 0;
        final client = FindMyTileClient(
          MockClient((request) async {
            calls++;
            if (calls == 1) throw closedConnection(request.url);
            return MockClient.pngResponse(request: request);
          }),
        );
        int? status;
        client.get(url).then((response) => status = response.statusCode);
        async.elapse(allRetryDelays);
        expect(status, 200);
        expect(calls, 2);
      });
    });

    test('retries a connection that dropped while the body was arriving', () {
      fakeAsync((async) {
        var calls = 0;
        final client = FindMyTileClient(
          MockClient.streaming((request, _) async {
            calls++;
            if (calls == 1) {
              return StreamedResponse(
                Stream<List<int>>.error(ClientException('Connection closed while receiving data', request.url)),
                200,
              );
            }
            final png = MockClient.pngResponse(request: request);
            return StreamedResponse(Stream.value(png.bodyBytes), 200, headers: png.headers);
          }),
        );
        List<int>? body;
        client.get(url).then((response) => body = response.bodyBytes);
        async.elapse(allRetryDelays);
        expect(body, MockClient.pngResponse().bodyBytes);
        expect(calls, 2);
      });
    });

    test('retries a rate limit or server error but not a client error', () {
      fakeAsync((async) {
        final statuses = [429, 503, 200];
        var calls = 0;
        final client = FindMyTileClient(MockClient((request) async => Response('', statuses[calls++])));
        int? status;
        client.get(url).then((response) => status = response.statusCode);
        async.elapse(allRetryDelays);
        expect(status, 200);
        expect(calls, 3);

        var notFoundCalls = 0;
        final notFound = FindMyTileClient(MockClient((request) async {
          notFoundCalls++;
          return Response('', 404);
        }));
        notFound.get(url).then((response) => status = response.statusCode);
        async.elapse(allRetryDelays);
        expect(status, 404);
        expect(notFoundCalls, 1);
      });
    });

    test('never retries a request the map aborted', () {
      fakeAsync((async) {
        var calls = 0;
        final abort = Completer<void>();
        final client = FindMyTileClient(
          MockClient((request) async {
            calls++;
            throw closedConnection(request.url);
          }),
        );
        Object? error;
        client
            .send(AbortableRequest('GET', url, abortTrigger: abort.future))
            .then<void>((_) {}, onError: (Object e) => error = e);
        async.flushMicrotasks();
        abort.complete();
        async.elapse(allRetryDelays);
        expect(calls, 1);
        expect(error, isA<RequestAbortedException>());
      });
    });

    test('gives up with an error flutter_map does not mistake for a cancelled request', () {
      fakeAsync((async) {
        var calls = 0;
        final client = FindMyTileClient(
          MockClient((request) async {
            calls++;
            throw closedConnection(request.url);
          }),
        );
        Object? error;
        client.get(url).then<void>((_) {}, onError: (Object e) => error = e);
        async.elapse(allRetryDelays * 2);
        expect(calls, findMyTileAttempts);
        expect(error, isA<ClientException>());
        final message = (error as ClientException).message;
        // flutter_map draws a transparent tile, and never reports an error,
        // for a ClientException whose message mentions either word.
        expect(message, isNot(contains('closed')));
        expect(message, isNot(contains('cancel')));
      });
    });
  });

  group('FindMyTileLoader', () {
    Widget map(FindMyTileLoader loader, MapController controller) => MaterialApp(
      home: Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: FlutterMap(
            mapController: controller,
            options: const MapOptions(initialCenter: LatLng(0, 0), initialZoom: 1),
            children: [loader.layer],
          ),
        ),
      ),
    );

    Iterable<RawImage> drawnTiles(WidgetTester tester) => tester
        .widgetList<RawImage>(find.descendant(of: find.byType(TileLayer), matching: find.byType(RawImage)))
        .where((image) => image.image != null);

    /// Lets the engine decode tile images, which happens outside fake time.
    Future<void> decodeTiles(WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    // Tile images outlive a test in the shared image cache.
    setUp(() => PaintingBinding.instance.imageCache.clear());

    testWidgets('a tile whose download failed is fetched again and drawn without moving the camera', (tester) async {
      var online = false;
      final requests = <String, int>{};
      final loader = FindMyTileLoader(
        httpClient: MockClient((request) async {
          requests.update(request.url.path, (n) => n + 1, ifAbsent: () => 1);
          if (!online) throw closedConnection(request.url);
          return MockClient.pngResponse(request: request);
        }),
        cachingProvider: const DisabledMapCachingProvider(),
      );
      final controller = MapController();
      await tester.pumpWidget(map(loader, controller));
      await tester.pump(allRetryDelays + const Duration(milliseconds: 100));

      expect(requests, isNotEmpty);
      expect(requests.values, everyElement(findMyTileAttempts));
      expect(drawnTiles(tester), isEmpty);
      final center = controller.camera.center;
      final zoom = controller.camera.zoom;

      online = true;
      await tester.pump(findMyTileReloadDelay(0));
      await decodeTiles(tester);

      expect(requests.values, everyElement(findMyTileAttempts + 1));
      expect(drawnTiles(tester), hasLength(greaterThanOrEqualTo(requests.length)));
      expect(controller.camera.center, center);
      expect(controller.camera.zoom, zoom);

      // Nothing is failing now, so coming back to the app fetches nothing.
      loader.reload();
      await tester.pump(findMyTileReloadDelay(0));
      expect(requests.values, everyElement(findMyTileAttempts + 1));

      await tester.pumpWidget(const SizedBox());
      loader.dispose();
    });

    testWidgets('stops reloading a tile that keeps failing, until the network comes back', (tester) async {
      var online = false;
      final requests = <String, int>{};
      final loader = FindMyTileLoader(
        httpClient: MockClient((request) async {
          requests.update(request.url.path, (n) => n + 1, ifAbsent: () => 1);
          if (!online) throw closedConnection(request.url);
          return MockClient.pngResponse(request: request);
        }),
        cachingProvider: const DisabledMapCachingProvider(),
      );
      await tester.pumpWidget(map(loader, MapController()));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(seconds: 15));
      }

      const bounded = findMyTileAttempts * (1 + findMyTileReloadLimit);
      expect(requests, isNotEmpty);
      expect(requests.values, everyElement(bounded));

      online = true;
      loader.reload();
      await tester.pump();
      await decodeTiles(tester);
      expect(requests.values, everyElement(bounded + 1));
      expect(drawnTiles(tester), isNotEmpty);

      await tester.pumpWidget(const SizedBox());
      loader.dispose();
    });

  });
}
