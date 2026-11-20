import 'dart:async';

import 'package:dio/dio.dart' show Headers;
import 'package:file/file.dart' show File;
import 'package:file/memory.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/core/cache/tsukuyomi_cache_manager.dart';
import 'package:tsukuyomi/forward/flutter_cache_manager/cache_store.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

void main() {
  late Config config;
  late CacheStore store;

  setUp(() {
    config = Config('test', fileSystem: _CacheFiles(), repo: NonStoringObjectProvider());
    store = CacheStore(config);
  });

  tearDown(() => store.dispose());

  Stream<FileResponse> read(_ImageSource source, HttpSourceImage image) {
    final cache = TsukuyomiCacheManager.withStore(source, image, store, config);
    return cache.getImageFile(image.url, withProgress: true);
  }

  test('Images share the fetch limit through repaint and queued requests resume after failure and success', () async {
    final limit = config.fileService.concurrentFetches;
    final gates = List.generate(limit + 2, (_) => Completer<void>());
    final source = _ImageSource((bytes) async {
      await gates[bytes.extra as int].future;
      return bytes;
    });
    final downloads = List.generate(gates.length, (index) {
      final image = HttpSourceImage(url: 'https://example.invalid/$index', extra: index);
      return read(source, image).last;
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
    const image = HttpSourceImage(url: 'https://example.invalid/page.jpg');
    final headers = Headers.fromMap({
      'Cache-Control': ['max-age=30'],
      'ETag': ['W/"aBc"'],
      'Content-Type': ['image/jpeg'],
      'Content-Length': ['800'],
    });
    final source = _ImageSource((bytes) async => bytes.copyWith(type: 'webp', data: [1, 2], statusCode: 202, responseHeaders: headers));

    final start = DateTime.now();
    final events = await read(source, image).toList();
    final progress = events.whereType<DownloadProgress>().last;
    expect((progress.downloaded, progress.totalSize), (2, 2));
    final result = events.last as FileInfo;
    expect(result.file.path, endsWith('.webp'));
    expect(await result.file.readAsBytes(), [1, 2]);
    expect(result.statusCode, 202);
    final received = result.validTill.subtract(const Duration(seconds: 30));
    expect(received.isBefore(start), isFalse);
    expect(received.isAfter(DateTime.now()), isFalse);
    expect((await store.retrieveCacheData(image.url))?.eTag, 'W/"aBc"');

    final cached = await read(source, image).single as FileInfo;
    expect(cached.source, FileSource.Cache);
    expect(source.requests, [image]);
  });
}

class _ImageSource extends Fake implements DioHttpSource {
  _ImageSource(this.repaint);

  final Future<HttpSourceBytes> Function(HttpSourceBytes) repaint;
  final requests = <HttpSourceImage>[];

  @override
  Future<HttpSourceBytes> getImageBytes(HttpSourceImage image) async {
    requests.add(image);
    return HttpSourceBytes(type: 'jpg', data: [0], extra: image.extra, statusCode: 200, responseHeaders: Headers());
  }

  @override
  Future<HttpSourceBytes> getRepaintBytes(HttpSourceBytes bytes) => repaint(bytes);
}

class _CacheFiles implements FileSystem {
  final _files = MemoryFileSystem();

  @override
  Future<File> createFile(String name) async => _files.file(name);
}
