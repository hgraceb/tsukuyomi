import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/database/database.dart' show DatabaseManga;
import 'package:tsukuyomi/pages/download/providers/download_path_provider.dart';
import 'package:tsukuyomi/pages/download/providers/downloaded_info_provider.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/pages/update/update_progress_provider.dart';
import 'package:tsukuyomi/source/delegate/source_stub.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

final _source = NoInstalledSource(1);
const _manga = DatabaseManga(
  id: 1,
  source: 1,
  url: '漫画地址',
  title: '示例漫画',
  cover: '封面地址',
  favorite: true,
  auto: true,
  lastCheckAt: null,
);

void main() {
  test('Manga id resolves the existing download state and reacts to completed chapters', () async {
    final root = Directory('${Directory.current.path}/.dart_tool');
    final directory = root.createTempSync('update-progress-');
    addTearDown(() {
      if (directory.parent.absolute.path != root.absolute.path) throw StateError('Unexpected test directory');
      directory.deleteSync(recursive: true);
    });
    Directory('${directory.path}/第1话').createSync();
    final container = ProviderContainer(
      overrides: [
        mangaStreamByIdProvider(_manga.id).overrideWith((ref) => Stream.value(_manga)),
        sourceByIdProvider(_manga.source).overrideWith((ref) async => _source),
        downloadMangaPathProvider(_source, _manga).overrideWith(() => _MangaPath(directory)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(updateDownloadedChaptersProvider(_manga.id), (_, _) {});

    expect(await container.read(updateDownloadedChaptersProvider(_manga.id).future), {'第1话'});
    Directory('${directory.path}/第2话').createSync();
    container.read(downloadedChaptersProvider(directory.path).notifier).update('第2话');
    await container.pump();
    expect(await container.read(updateDownloadedChaptersProvider(_manga.id).future), {'第1话', '第2话'});
  });

  test('Download progress loading errors remain observable', () async {
    final error = StateError('漫画源加载失败');
    final container = ProviderContainer(
      overrides: [
        mangaStreamByIdProvider(_manga.id).overrideWith((ref) => Stream.value(_manga)),
        sourceByIdProvider(_manga.source).overrideWith((ref) async => throw error),
      ],
    );
    addTearDown(container.dispose);
    container.listen(updateDownloadedChaptersProvider(_manga.id), (_, _) {});

    await expectLater(container.read(updateDownloadedChaptersProvider(_manga.id).future), throwsA(same(error)));
    expect(container.read(updateDownloadedChaptersProvider(_manga.id)).error, same(error));
  });
}

class _MangaPath extends DownloadMangaPath {
  _MangaPath(this._directory);

  final Directory _directory;

  @override
  Future<Directory> build(Source source, DatabaseManga manga) async => _directory;
}
