part of 'package:tsukuyomi_sources/src/core/source_manga.dart';

/// 网络漫画源漫画数据
class HttpSourceManga extends SourceManga {
  const HttpSourceManga({
    required super.url,
    required super.name,
    required super.cover,
  });
}
