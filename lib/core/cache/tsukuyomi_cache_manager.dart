import 'package:collection/collection.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pool/pool.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/forward/flutter_cache_manager/cache_store.dart';
import 'package:tsukuyomi/forward/flutter_cache_manager/web_helper.dart';
import 'package:tsukuyomi/forward/http/http.dart' as http;
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class TsukuyomiCacheManager extends CacheManager with ImageCacheManager {
  static final _config = Config(App.cachedImagesPath);

  static final _store = CacheStore(_config);

  TsukuyomiCacheManager(DioHttpSource source, HttpSourceImage image)
    // ignore: invalid_use_of_visible_for_testing_member
    : super.custom(
        _config,
        cacheStore: _store,
        webHelper: WebHelper(_store, _DioFileService(source, image)),
      );
}

class _DioFileService extends FileService {
  _DioFileService(this._source, this._image);

  static final _pool = Pool(TsukuyomiCacheManager._config.fileService.concurrentFetches);

  final DioHttpSource _source;

  final HttpSourceImage _image;

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) {
    return _pool.withResource(() async {
      final bytes = await _source.getImageBytes(_image);
      return _DioGetResponse(await _source.getRepaintBytes(bytes));
    });
  }
}

class _DioGetResponse extends HttpGetResponse {
  _DioGetResponse(HttpSourceBytes bytes)
    : fileExtension = '.${bytes.type}',
      super(
        http.StreamedResponse(
          Stream.value(bytes.data),
          bytes.statusCode,
          contentLength: bytes.data.length,
          headers: bytes.responseHeaders.map.map((key, value) => MapEntry(key, value.firstOrNull ?? '')),
        ),
      );

  @override
  final String fileExtension;
}
