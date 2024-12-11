part 'package:tsukuyomi_sources/src/http/source_http_manga.dart';

/// 漫画源漫画数据
sealed class SourceManga {
  const SourceManga({
    required this.url,
    required this.name,
    required this.cover,
  });

  /// 漫画地址
  final String url;

  /// 漫画名称
  final String name;

  /// 漫画封面
  final String cover;
}
