import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/forward/flutter_cache_manager/cache_store.dart';
import 'package:tsukuyomi/forward/flutter_cache_manager/web_helper.dart';
import 'package:tsukuyomi/forward/http/http.dart' as http;
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

class TsukuyomiCacheManager extends CacheManager with ImageCacheManager {
  static const _cacheKey = App.cachedImagesPath;

  static final _config = Config(_cacheKey);

  static final _store = CacheStore(_config);

  factory TsukuyomiCacheManager(DioHttpSource source, HttpSourceImage extra) => TsukuyomiCacheManager._(_DioFileService(source, extra));

  // ignore: invalid_use_of_visible_for_testing_member
  TsukuyomiCacheManager._(_DioFileService fetcher) : super.custom(_config, cacheStore: _store, webHelper: _DioWebHelper(_store, fetcher));
}

class _DioWebHelper extends WebHelper {
  _DioWebHelper(super._store, _DioFileService super.fileFetcher);

  // 共享并发请求计数
  static int _concurrentCalls = 0;

  @override
  int get concurrentCalls => _concurrentCalls;

  @override
  set concurrentCalls(int concurrentCalls) => _concurrentCalls = concurrentCalls;
}

class _DioFileService extends FileService {
  _DioFileService(this._source, this._image);

  final DioHttpSource _source;

  final HttpSourceImage _image;

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    final bytes = await _source.getImageBytes(_image);
    final repaint = await _source.getRepaintBytes(bytes);
    return _DioGetResponse(repaint);
  }
}

class _DioGetResponse implements FileServiceResponse {
  _DioGetResponse(HttpSourceBytes bytes) : fileExtension = '.${bytes.type}' {
    // 所有的响应头数据
    final headers = bytes.responseHeaders;
    // 创建响应数据代理
    _delegate = HttpGetResponse(http.StreamedResponse(
      Stream.value(bytes.data),
      bytes.statusCode,
      contentLength: int.tryParse('${headers[Headers.contentLengthHeader]?.firstOrNull}'),
      headers: headers.map.map((key, value) => MapEntry(key, value.firstOrNull ?? '')),
    ));
  }

  late final FileServiceResponse _delegate;

  @override
  get content => _delegate.content;

  @override
  get contentLength => _delegate.contentLength;

  @override
  get statusCode => _delegate.statusCode;

  @override
  get validTill => _delegate.validTill;

  @override
  get eTag => _delegate.eTag;

  @override
  final String fileExtension;
}
