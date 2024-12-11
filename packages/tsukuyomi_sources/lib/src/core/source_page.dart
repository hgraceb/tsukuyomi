import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

part 'package:tsukuyomi_sources/src/http/source_http_page.dart';

/// 漫画源页面数据
sealed class SourcePage<T> {
  SourcePage({
    this.next = false,
    required Iterable<T> data,
  }) : data = data.toList(growable: false);

  /// 是否有下一页
  final bool next;

  /// 当前页面数据
  final List<T> data;

  /// 当前筛选条件
  late final SourceQuery query;
}
