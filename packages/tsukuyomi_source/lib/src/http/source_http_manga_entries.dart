part of 'package:tsukuyomi_source/src/core/source_manga_entries.dart';

/// 网络漫画条目查询结果
class HttpSourceMangaEntries extends SourceMangaEntries {
  HttpSourceMangaEntries({
    required this.mangas,
    this.nextQuery,
  });

  @override
  final List<HttpSourceManga> mangas;

  @override
  final HttpSourceQuery? nextQuery;
}
