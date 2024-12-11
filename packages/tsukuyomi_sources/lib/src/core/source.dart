import 'dart:ui';

import 'package:tsukuyomi_html/dom.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

part 'package:tsukuyomi_sources/src/http/source_http.dart';
part 'package:tsukuyomi_sources/src/stub/source_stub.dart';

/// 漫画源
sealed class Source {
  /// 漫画源唯一标识
  abstract final int id;

  /// 漫画源显示名称
  abstract final String name;

  /// 获取漫画详情列表
  Future<SourcePage<SourceManga>> getSourceMangas(covariant SourceQuery query);

  /// 获取漫画章节列表
  Future<Iterable<SourceChapter>> getMangaChapters(covariant SourceManga manga);

  /// 获取章节图片列表
  Future<Iterable<SourceImage>> getChapterImages(covariant SourceChapter chapter);

  /// 获取章节图片数据
  Future<SourceBytes> getImageBytes(covariant SourceImage image);

  /// 获取章节重绘图片
  Future<SourceBytes> getRepaintBytes(covariant SourceBytes bytes);
}
