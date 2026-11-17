import 'dart:ui';

import 'package:tsukuyomi_html/dom.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

part 'package:tsukuyomi_source/src/http/source_http.dart';
part 'package:tsukuyomi_source/src/stub/source_stub.dart';

/// 漫画源
sealed class Source {
  /// 漫画源的唯一标识
  abstract final int id;

  /// 漫画源的显示名称
  abstract final String name;

  /// 获取分页漫画数据
  Future<SourcePage<SourceManga>> getSourceMangas(covariant SourceQuery query);

  /// 获取漫画章节详情
  Future<SourceManga> getMangaDetails(covariant SourceManga manga);

  /// 获取章节图片列表
  Future<Iterable<SourceImage>> getChapterImages(covariant SourceChapter chapter);

  /// 获取章节图片数据
  Future<SourceBytes> getImageBytes(covariant SourceImage image);

  /// 获取章节重绘图片
  Future<SourceBytes> getRepaintBytes(covariant SourceBytes bytes);
}
