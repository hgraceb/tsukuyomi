import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

extension SourceExtension on Source {
  /// 网络漫画请求头
  Map<String, String>? get headers {
    return switch (this) {
      HttpSource source => source.getRequestHeaders(),
      _ => null,
    };
  }

  /// 本地缓存管理器
  TsukuyomiCacheManager? getImageCacheManager(SourceImage image) {
    return switch (this) {
      DioHttpSource source when image is HttpSourceImage => TsukuyomiCacheManager(source, image),
      _ => null,
    };
  }
}

extension SourceMangaEntriesExtension on SourceMangaEntries {
  /// 前插页面数据
  SourceMangaEntries prepend(SourceMangaEntries page) {
    return switch ((page, this)) {
      (HttpSourceMangaEntries previous, HttpSourceMangaEntries current) => HttpSourceMangaEntries(
        mangas: [...previous.mangas, ...current.mangas],
        nextQuery: current.nextQuery,
      ),
    };
  }
}
