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

  Future<Completer<void>> fillPool(String prefix) async {
    final limit = cache.config.fileService.concurrentFetches;
    final full = Completer<void>();
    final first = Completer<void>();
    final rest = Completer<void>();
    var repainting = 0;
    final blockers = _ImageSource();
    blockers.repaint = (bytes) async {
      if (++repainting == limit) full.complete();
      await (bytes.extra == 0 ? first : rest).future;
      return bytes;
    };
    final downloads = List.generate(limit, (index) {
      final image = HttpSourceImage(url: 'https://example.invalid/$prefix/$index', extra: index);
      return TsukuyomiCacheManager(blockers, image).getImageFile(image.url).single;
    });
    addTearDown(() async {
      if (!first.isCompleted) first.complete();
      rest.complete();
      await Future.wait(downloads);
    });
    await full.future;
    return first;
  }

  Future<void> waitForActiveDownloads(TsukuyomiCacheManager manager, int count) async {
    final active = Stream.periodic(const Duration(milliseconds: 5), (_) => manager.webHelper.concurrentCalls);
    await active.where((value) => value == count).timeout(const Duration(seconds: 5)).first;
  }

  test('Queued reads resume after success and failure and share one download for the same image', () async {
    final slot = await fillPool('queue');
    const failed = HttpSourceImage(url: 'https://example.invalid/failure', extra: 'fail');
    const shared = HttpSourceImage(url: 'https://example.invalid/shared');
    source.repaint = (bytes) async {
      if (bytes.extra == 'fail') throw StateError('Repaint failed');
      return bytes.copyWith(data: [1, 2]);
    };
    final failing = TsukuyomiCacheManager(source, failed);
    final failure = expectLater(failing.getImageFile(failed.url).single, throwsStateError);
    await waitForActiveDownloads(failing, 1);
    final manager = TsukuyomiCacheManager(source, shared);
    final reads = List.generate(2, (_) => manager.getImageFile(shared.url).cast<FileInfo>().single);
    await waitForActiveDownloads(manager, 1);
    expect(source.requests, isEmpty);

    slot.complete();
    await failure;
    final files = await Future.wait(reads);
    expect(source.requests, [failed, shared]);
    expect(files.map((info) => info.source), everyElement(FileSource.Online));
    expect(files.first.file.path, files.last.file.path);
    expect(await files.first.file.readAsBytes(), [1, 2]);
  });

  test('Canceling the only reader while queued still caches the repainted image', () async {
    final slot = await fillPool('cancel');
    const image = HttpSourceImage(url: 'https://example.invalid/canceled');
    source.repaint = (bytes) async => bytes.copyWith(data: [3, 4]);
    final manager = TsukuyomiCacheManager(source, image);
    final listener = manager.getImageFile(image.url).listen(null);
    await waitForActiveDownloads(manager, 1);
    expect(source.requests, isEmpty);
    await listener.cancel();

    slot.complete();
    await waitForActiveDownloads(manager, 0);
    final cached = await manager.getFileFromCache(image.url);
    expect(await cached?.file.readAsBytes(), [3, 4]);
    expect(source.requests, [image]);
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
