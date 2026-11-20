import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

class NoInstalledSource extends StubSource {
  NoInstalledSource(this.id);

  @override
  final int id;

  @override
  late final String name = '$id';

  @override
  Future<SourceMangaEntries> getMangaEntries(SourceQuery query) => throw TsukuyomiSourceException.notInstalled(id);

  @override
  Future<SourceMangaDetails> getMangaDetails(SourceManga manga) => throw TsukuyomiSourceException.notInstalled(id);

  @override
  Future<SourceChapterImages> getChapterImages(SourceChapter chapter) => throw TsukuyomiSourceException.notInstalled(id);

  @override
  Future<SourceImageBytes> getImageBytes(SourceImage image) => throw TsukuyomiSourceException.notInstalled(id);

  @override
  Future<SourceImageBytes> getRepaintBytes(SourceImageBytes bytes) => throw TsukuyomiSourceException.notInstalled(id);
}
