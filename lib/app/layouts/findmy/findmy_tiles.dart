import 'dart:async';

import 'package:bluebubbles/utils/logger/logger.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart';

/// Tries per tile download. OpenStreetMap answers in well under a second, so
/// four tries ride out a dropped connection without holding a tile for long.
const int findMyTileAttempts = 4;

/// The longest a single try may take. A tile is tens of kilobytes; a try that
/// has not finished by now is a stalled connection, not a slow one.
const Duration findMyTileAttemptTimeout = Duration(seconds: 15);

/// Rounds of fetching a failed tile again while it stays on screen. With the
/// backoff below that keeps trying for about a minute; after that only the
/// app resuming or the network coming back tries again.
const int findMyTileReloadLimit = 5;

/// The wait before try [retry] (1-based) of one download: 0.5 s doubling, so
/// a brief drop recovers at once and a rate limit is not hammered.
Duration findMyTileRetryDelay(int retry) {
  const first = Duration(milliseconds: 500);
  const longest = Duration(seconds: 4);
  final delay = first * (1 << (retry - 1));
  return delay > longest ? longest : delay;
}

/// The wait before reload round [reload] (0-based) of a failed tile: 2 s
/// doubling, so a short outage heals quickly and a long one costs little.
Duration findMyTileReloadDelay(int reload) {
  const first = Duration(seconds: 2);
  const longest = Duration(seconds: 30);
  final delay = first * (1 << reload);
  return delay > longest ? longest : delay;
}

/// A tile download that failed every try. Its message deliberately mentions
/// neither a closed nor a cancelled request: flutter_map draws a blank tile,
/// and reports nothing, for a client error that does.
class FindMyTileDownloadException extends ClientException {
  FindMyTileDownloadException(Object lastError, Uri url)
    : super('Map tile download failed after $findMyTileAttempts tries (${lastError.runtimeType})', url);
}

/// Retries tile downloads that fail in transit, which the default client
/// never does: it retries only a 503 response, not a dropped connection.
///
/// Reads the whole body inside each try, so a connection that drops while the
/// image is arriving is retried too. A request the map aborted (the tile left
/// the screen) is never retried.
class FindMyTileClient extends BaseClient {
  FindMyTileClient(this._inner);

  final Client _inner;
  bool _closed = false;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final body = await request.finalize().toBytes();
    final abortTrigger = request is Abortable ? request.abortTrigger : null;
    var aborted = false;
    if (abortTrigger != null) unawaited(abortTrigger.whenComplete(() => aborted = true));

    for (var attempt = 1; ; attempt++) {
      if (aborted) throw RequestAbortedException(request.url);
      // Each try has its own trigger, so a stalled try can be torn down
      // without aborting the request as a whole.
      final stop = Completer<void>();
      abortTrigger?.whenComplete(() => stop.isCompleted ? null : stop.complete());
      final copy = AbortableRequest(request.method, request.url, abortTrigger: stop.future)
        ..headers.addAll(request.headers)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection
        ..bodyBytes = body;

      try {
        final (response, bytes) = await () async {
          final response = await _inner.send(copy);
          return (response, await response.stream.toBytes());
        }().timeout(findMyTileAttemptTimeout);
        final retryable = response.statusCode == 429 || response.statusCode >= 500;
        if (!retryable || attempt == findMyTileAttempts) {
          return StreamedResponse(
            Stream.value(bytes),
            response.statusCode,
            contentLength: bytes.length,
            request: request,
            headers: response.headers,
            isRedirect: response.isRedirect,
            persistentConnection: response.persistentConnection,
            reasonPhrase: response.reasonPhrase,
          );
        }
      } on RequestAbortedException {
        rethrow;
      } catch (e) {
        if (aborted) throw RequestAbortedException(request.url);
        // A closed client means the map is gone; let flutter_map drop the tile quietly.
        if (_closed) rethrow;
        if (attempt == findMyTileAttempts) throw FindMyTileDownloadException(e, request.url);
      } finally {
        if (!stop.isCompleted) stop.complete();
      }

      await Future.any([Future<void>.delayed(findMyTileRetryDelay(attempt)), ?abortTrigger]);
    }
  }

  @override
  void close() {
    _closed = true;
    _inner.close();
  }
}

/// The one tile layer the Find My map draws, with the HTTP client behind it.
///
/// A tile that still fails after [FindMyTileClient]'s tries is fetched again
/// in place, on a backoff and a limited number of times, without touching the
/// camera or the tiles that did load. [reload] starts over for every tile
/// still failing, for when the app resumes or the network comes back.
class FindMyTileLoader {
  FindMyTileLoader({Client? httpClient, MapCachingProvider? cachingProvider})
    : _client = FindMyTileClient(httpClient ?? Client()) {
    tileProvider = NetworkTileProvider(httpClient: _client, cachingProvider: cachingProvider);
  }

  final FindMyTileClient _client;
  final Map<TileCoordinates, TileImage> _failed = {};
  final Map<TileCoordinates, int> _reloads = {};
  Timer? _reloadTimer;
  bool _disposed = false;

  late final NetworkTileProvider tileProvider;

  /// Built once, so no rebuild of the map ever swaps the provider or client.
  late final TileLayer layer = TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.bluebubbles.app',
    tileProvider: tileProvider,
    errorTileCallback: _onTileError,
    // Drop a failed image once its tile leaves the screen, so panning back fetches it afresh.
    evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
  );

  void _onTileError(TileImage tile, Object error, StackTrace? stackTrace) {
    if (_disposed) return;
    final c = tile.coordinates;
    Logger.warn("Map tile ${c.z}/${c.x}/${c.y} failed to load (${error.runtimeType})", tag: 'FindMyMap');
    _failed[c] = tile;
    _scheduleReload();
  }

  void _scheduleReload() {
    // Tiles the layer has discarded since they failed can never be drawn again.
    _failed.removeWhere((_, tile) => tile.cancelLoading.isCompleted);
    if (_reloadTimer?.isActive ?? false) return;
    final due = _failed.keys.map((c) => _reloads[c] ?? 0).where((n) => n < findMyTileReloadLimit);
    if (due.isEmpty) return;
    _reloadTimer = Timer(findMyTileReloadDelay(due.reduce((a, b) => a < b ? a : b)), _reloadFailed);
  }

  void _reloadFailed() {
    if (_disposed) return;
    final due = _failed.entries.where((e) => (_reloads[e.key] ?? 0) < findMyTileReloadLimit).toList();
    for (final entry in due) {
      _failed.remove(entry.key);
      _reloads[entry.key] = (_reloads[entry.key] ?? 0) + 1;
      // A no-op for a tile the layer has since discarded.
      entry.value.load();
    }
  }

  /// Fetches every failed tile again now and resets their reload budgets.
  void reload() {
    if (_disposed) return;
    _reloadTimer?.cancel();
    _reloads.clear();
    _reloadFailed();
  }

  void dispose() {
    _disposed = true;
    _reloadTimer?.cancel();
    _failed.clear();
    _client.close();
  }
}
