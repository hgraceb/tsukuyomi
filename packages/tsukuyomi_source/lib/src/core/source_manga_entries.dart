import 'package:tsukuyomi_source/tsukuyomi_source.dart';

part 'package:tsukuyomi_source/src/http/source_http_manga_entries.dart';

/// 漫画条目查询结果
sealed class SourceMangaEntries {
  /// 当前页的漫画条目
  List<SourceManga> get mangas;

  /// 下一页查询条件，末页为空
  SourceQuery? get nextQuery;
}
