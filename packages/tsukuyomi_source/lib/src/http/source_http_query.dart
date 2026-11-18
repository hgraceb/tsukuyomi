part of 'package:tsukuyomi_source/src/core/source_query.dart';

/// 网络漫画源查询数据
class HttpSourceQuery extends SourceQuery {
  HttpSourceQuery({
    super.page,
    required super.keyword,
  });

  /// 下一页查询条件
  HttpSourceQuery get nextPage => HttpSourceQuery(page: page + 1, keyword: keyword);
}
