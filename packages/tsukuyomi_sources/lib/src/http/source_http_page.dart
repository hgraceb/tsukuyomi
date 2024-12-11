part of 'package:tsukuyomi_sources/src/core/source_page.dart';

/// 网络漫画源页面数据
class HttpSourcePage<T> extends SourcePage<T> {
  HttpSourcePage({
    super.next,
    required super.data,
  });
}
