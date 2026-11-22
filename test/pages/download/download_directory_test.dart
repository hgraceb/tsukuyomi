import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart'; // ignore: depend_on_referenced_packages
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/pages/chapter/chapter_service.dart';
import 'package:tsukuyomi/pages/download/download_directory.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/download/providers/downloaded_info_provider.dart';
import 'package:tsukuyomi/source/delegate/source_stub.dart';

import '../../fixtures/update_fixtures.dart';

void main() {
  final title = 'A${'字' * 96}XYZ';
  final name = 'A${'字' * 74}...b199c447493c';

  test('Keep titles through 240 UTF-8 bytes and hash the full title above the limit', () {
    final ascii = 'a' * 240;
    final emoji = '📖' * 60;
    expect(downloadDirectoryName(ascii), ascii);
    expect(downloadDirectoryName(emoji), emoji);
    expect(downloadDirectoryName('${ascii}a'), startsWith('${'a' * 225}...'));
    expect(utf8.encode(downloadDirectoryName('${ascii}a')).length, 240);
    expect(downloadDirectoryName('${ascii}b'), isNot(downloadDirectoryName('${ascii}a')));
    expect(downloadDirectoryName('$emoji📖'), startsWith('${'📖' * 56}...'));
    expect(downloadDirectoryName(title), name);
    expect(utf8.encode(name).length, 238);
  });

  group('Download directories', () {
    late Directory documents;
    late ProviderContainer container;
    final source = NoInstalledSource(1);
    final manga = mangaFixture(1);
    final firstChapter = chaptersFixture(manga.id).first;

    setUp(() async {
      documents = await Directory.systemTemp.createTemp('tsukuyomi-download-');
      final paths = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _DownloadPaths(documents.path);
      container = ProviderContainer();
      addTearDown(() async {
        container.dispose();
        PathProviderPlatform.instance = paths;
        await documents.delete(recursive: true);
      });
    });

    test('Create a chapter under the shortened manga directory', () async {
      final service = container.read(downloadServiceProvider);
      final temp = await service.createTempChapterDir(source, manga.copyWith(title: title), firstChapter);
      expect(p.basename(temp.parent.path), name);
      expect(await temp.exists(), isTrue);
    });

    test('Download, rename, rescan and read a shortened chapter directory offline', () async {
      final chapter = firstChapter.copyWith(title: '話' * 81);
      final service = container.read(downloadServiceProvider);
      final mangaDir = await service.getMangaDir(source, manga);
      final chapterDir = await service.getChapterDir(source, manga, chapter);
      final chapterName = p.basename(chapterDir.path);
      expect(utf8.encode(chapterName).length, 240);
      final temp = await service.createTempChapterDir(source, manga, chapter);
      expect(p.basename(temp.path), '${App.prefixTemp}$chapterName');
      expect(utf8.encode(p.basename(temp.path)).length, 248);
      await File(p.join(temp.path, '001.jpg')).writeAsBytes([1, 2, 3]);
      expect((await service.createTempChapterDir(source, manga, chapter)).path, temp.path);

      final downloaded = downloadedChaptersProvider(mangaDir.path);
      final subscription = container.listen(downloaded, (_, _) {});
      final beforeDownload = subscription.read();
      await temp.rename(chapterDir.path);
      await service.refreshDownloadedByChapter(source, manga, chapter);
      expect(beforeDownload, isEmpty);
      expect(subscription.read(), {chapterName});
      container.invalidate(downloaded);
      expect(subscription.read(), {chapterName});
      final images = await container.read(chapterImagesProvider(source, manga, chapter).future);
      expect(images.single.url, p.join(chapterDir.path, '001.jpg'));
      expect(await File(images.single.url).readAsBytes(), [1, 2, 3]);
    });

    test('Find existing full-title downloads and resume existing full-title temporary directories', () async {
      final chapter = firstChapter.copyWith(title: '話' * 81);
      final oldManga = manga.copyWith(title: '本' * 81);
      final oldDir = Directory(p.join(documents.path, App.name, App.downloadsPath, source.name, oldManga.title));
      await oldDir.create(recursive: true);
      final service = container.read(downloadServiceProvider);
      expect((await service.getMangaDir(source, oldManga)).path, oldDir.path);

      final mangaDir = await service.getMangaDir(source, manga);
      final oldTemp = Directory(p.join(mangaDir.path, '${App.prefixTemp}${chapter.title}'));
      await oldTemp.create(recursive: true);
      await File(p.join(oldTemp.path, '001.jpg')).writeAsBytes([1]);

      final resumed = await service.createTempChapterDir(source, manga, chapter);
      expect(resumed.path, oldTemp.path);
      expect(await File(p.join(resumed.path, '001.jpg')).readAsBytes(), [1]);
      final oldChapter = await resumed.rename(p.join(mangaDir.path, chapter.title));
      final chapterDir = await service.getChapterDir(source, manga, chapter);
      expect(chapterDir.path, oldChapter.path);
      final downloaded = downloadedChaptersProvider(mangaDir.path);
      final subscription = container.listen(downloaded, (_, _) {});
      final beforeRemoval = subscription.read();
      await oldChapter.delete(recursive: true);
      await service.refreshDownloadedByChapter(source, manga, chapter);
      expect(beforeRemoval, {downloadDirectoryName(chapter.title)});
      expect(subscription.read(), isEmpty);
    });
  });
}

class _DownloadPaths extends PathProviderPlatform {
  _DownloadPaths(this.path);

  final String path;

  @override
  Future<String> getApplicationDocumentsPath() async => path;
}
