import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

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

extension SourcePageExtension<T> on SourcePage<T> {
  /// 下页查询条件
  SourceQuery get nextQuery {
    return switch (query) {
      HttpSourceQuery() => HttpSourceQuery(page: query.page + 1, keyword: query.keyword),
    };
  }

  /// 前插页面数据
  SourcePage<T> prepend(SourcePage<T> page) {
    return copyWith(data: [...page.data, ...data]);
  }

  /// 创建对象副本
  SourcePage<T> copyWith({bool? next, List<T>? data, SourceQuery? query}) {
    return switch (this) {
      HttpSourcePage() => HttpSourcePage(
        next: next ?? this.next,
        data: data?.cast<T>() ?? this.data,
      )..query = query ?? this.query,
    };
  }
}
