import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

class NoInstalledSource extends StubSource {
  NoInstalledSource(this.id);

  @override
  final int id;

  @override
  late final String name = '$id';

  @override
  Future<SourcePage<SourceManga>> getSourceMangas(SourceQuery query) => throw TsukuyomiSourceException.notInstalled(id);

  @override
  Future<Iterable<SourceChapter>> getMangaChapters(SourceManga manga) => throw TsukuyomiSourceException.notInstalled(id);

  @override
  Future<Iterable<SourceImage>> getChapterImages(SourceChapter chapter) => throw TsukuyomiSourceException.notInstalled(id);

  @override
  Future<SourceBytes> getImageBytes(SourceImage image) => throw TsukuyomiSourceException.notInstalled(id);

  @override
  Future<SourceBytes> getRepaintBytes(SourceBytes bytes) => throw TsukuyomiSourceException.notInstalled(id);
}
