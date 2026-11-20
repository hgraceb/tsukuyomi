@TestOn('windows || linux')
library;

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart' show Headers;
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/core/cache/tsukuyomi_cache_manager.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

void main() {
  final messenger = TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger;
  final source = _ImageSource();
  const page = HttpSourceImage(url: 'https://example.invalid/page.jpg');
  late final cache = TsukuyomiCacheManager(source, page);

  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('tsukuyomi-image-cache-');
    messenger.setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (_) async => directory.path);
    addTearDown(() => directory.delete(recursive: true));
    addTearDown(cache.dispose);
  });

  setUp(source.requests.clear);

  test('Images share the fetch limit through repaint and queued requests resume after failure and success', () async {
    final limit = cache.config.fileService.concurrentFetches;
    final gates = List.generate(limit + 2, (_) => Completer<void>());
    source.repaint = (bytes) async {
      await gates[bytes.extra as int].future;
      return bytes;
    };
    final downloads = List.generate(gates.length, (index) {
      final image = HttpSourceImage(url: 'https://example.invalid/$index', extra: index);
      return TsukuyomiCacheManager(source, image).webHelper.fileFetcher.get(image.url);
    });
    addTearDown(() async {
      for (final gate in gates) {
        if (!gate.isCompleted) gate.complete();
      }
      await Future.wait(downloads.skip(1));
    });

    await pumpEventQueue();
    expect(source.requests, hasLength(limit));
    final failure = expectLater(downloads[0], throwsStateError);
    gates[0].completeError(StateError('Repaint failed'));
    await failure;
    await pumpEventQueue();
    expect(source.requests, hasLength(limit + 1));

    gates[1].complete();
    await downloads[1];
    await pumpEventQueue();
    expect(source.requests, hasLength(limit + 2));
  });

  test('The cache stores repainted bytes and honors mixed-case response headers', () async {
    final headers = Headers.fromMap({
      'Cache-Control': ['max-age=30'],
      'ETag': ['W/"aBc"'],
      'Content-Type': ['image/jpeg'],
      'Content-Length': ['800'],
    });
    source.repaint = (bytes) async => bytes.copyWith(type: 'webp', data: [1, 2], statusCode: 202, responseHeaders: headers);

    final start = DateTime.now();
    final events = await cache.getImageFile(page.url, withProgress: true).toList();
    final progress = events.whereType<DownloadProgress>().last;
    expect((progress.downloaded, progress.totalSize), (2, 2));
    final result = events.last as FileInfo;
    expect(result.file.path, endsWith('.webp'));
    expect(await result.file.readAsBytes(), [1, 2]);
    expect(result.statusCode, 202);
    final received = result.validTill.subtract(const Duration(seconds: 30));
    expect(received.isBefore(start), isFalse);
    expect(received.isAfter(DateTime.now()), isFalse);
    expect((await cache.store.retrieveCacheData(page.url))?.eTag, 'W/"aBc"');

    final cached = await TsukuyomiCacheManager(source, page).getImageFile(page.url).single as FileInfo;
    expect(cached.source, FileSource.Cache);
    expect(source.requests, [page]);
  });
}

class _ImageSource extends Fake implements DioHttpSource {
  late Future<HttpSourceBytes> Function(HttpSourceBytes) repaint;
  final requests = <HttpSourceImage>[];

  @override
  Future<HttpSourceBytes> getImageBytes(HttpSourceImage image) async {
    requests.add(image);
    return HttpSourceBytes(type: 'jpg', data: [0], extra: image.extra, statusCode: 200, responseHeaders: Headers());
  }

  @override
  Future<HttpSourceBytes> getRepaintBytes(HttpSourceBytes bytes) => repaint(bytes);
}
