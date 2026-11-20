import 'package:collection/collection.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pool/pool.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/forward/flutter_cache_manager/cache_store.dart';
import 'package:tsukuyomi/forward/flutter_cache_manager/web_helper.dart';
import 'package:tsukuyomi/forward/http/http.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class TsukuyomiCacheManager extends CacheManager with ImageCacheManager {
  static const _cacheKey = App.cachedImagesPath;

  static final _config = Config(_cacheKey);

  static final _store = CacheStore(_config);

  factory TsukuyomiCacheManager(DioHttpSource source, HttpSourceImage extra) => TsukuyomiCacheManager._(_DioFileService(source, extra));

  // ignore: invalid_use_of_visible_for_testing_member
  TsukuyomiCacheManager._(_DioFileService fetcher) : super.custom(_config, cacheStore: _store, webHelper: WebHelper(_store, fetcher));
}

class _DioGetResponse extends HttpGetResponse {
  _DioGetResponse(this.fileExtension, super._response);

  @override
  final String fileExtension;
}

class _DioFileService extends FileService {
  _DioFileService(this._source, this._image);

  final DioHttpSource _source;

  final HttpSourceImage _image;

  static final _pool = Pool(TsukuyomiCacheManager._config.fileService.concurrentFetches);

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) {
    return _pool.withResource(() async {
      final imageBytes = await _source.getImageBytes(_image);
      final repaintBytes = await _source.getRepaintBytes(imageBytes);
      final fileExtension = '.${repaintBytes.type}';
      final stream = Stream.value(repaintBytes.data);
      final statusCode = repaintBytes.statusCode;
      final contentLength = repaintBytes.data.length;
      final headers = repaintBytes.responseHeaders.map.map((key, value) => MapEntry(key, value.firstOrNull ?? ''));
      return _DioGetResponse(fileExtension, StreamedResponse(stream, statusCode, contentLength: contentLength, headers: headers));
    });
  }
}
