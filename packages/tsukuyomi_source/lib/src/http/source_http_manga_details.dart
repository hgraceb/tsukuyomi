part of 'package:tsukuyomi_source/src/core/source_manga_details.dart';

/// 网络漫画源漫画详情
class HttpSourceMangaDetails extends SourceMangaDetails implements HttpSourceManga {
  const HttpSourceMangaDetails({
    required super.url,
    required super.name,
    required super.cover,
    required this.chapters,
    super.status,
    super.description,
    super.authors,
    super.tags,
    super.languages,
  });

  @override
  final List<HttpSourceChapter> chapters;
}
