part 'package:tsukuyomi_sources/src/http/source_http_query.dart';

/// 漫画源查询数据
sealed class SourceQuery {
  SourceQuery({
    this.page = 1,
    required this.keyword,
  }) : assert(page > 0);

  /// 当前页
  final int page;

  /// 关键词
  final String keyword;
}
