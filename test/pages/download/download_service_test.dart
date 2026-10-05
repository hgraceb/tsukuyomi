import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/chapter/chapter_repository.dart';
import 'package:tsukuyomi/pages/download/download_repository.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/download/providers/download_path_provider.dart';
import 'package:tsukuyomi/providers/download/download_manager_provider.dart';
import 'package:tsukuyomi/source/delegate/source_stub.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

final _source = NoInstalledSource(1);

const _manga = DatabaseManga(
  id: 1,
  source: 1,
  url: 'manga-url',
  title: 'manga-title',
  cover: 'manga-cover',
  favorite: true,
  auto: true,
  lastCheckAt: null,
);

DatabaseChapter _chapter(int id, {bool public = true}) => DatabaseChapter(
  id: id,
  manga: 1,
  index: 0,
  title: 'chapter-title-$id',
  url: 'chapter-url-$id',
  date: 'chapter-date',
  public: public,
  images: 0,
  progress: 0,
);

DatabaseDownload _download(int id, {String? error}) => DatabaseDownload(
  source: 1,
  manga: 1,
  chapter: id,
  total: 10,
  progress: 4,
  error: error,
);

void main() {
  test('Only favorite auto manga can enqueue automatically', () async {
    final chapters = _Chapters([_chapter(1)]);
    final downloads = _Downloads([]);
    final manager = _Manager();
    final container = _createContainer(chapters, downloads, manager);
    final service = container.read(downloadServiceProvider);

    expect(await service.enqueueAutoDownloads(_source, _manga.copyWith(auto: false)), const DownloadEnqueueResult());
    expect(await service.enqueueAutoDownloads(_source, _manga.copyWith(favorite: false)), const DownloadEnqueueResult());
    expect(chapters.queries, 0);
    expect(downloads.inserted, isEmpty);
    expect(manager.wakes, 0);
  });

  test('Enqueue missing chapters, skip completed and queued, resume failed progress', () async {
    final chapters = _Chapters([_chapter(5, public: false), _chapter(4), _chapter(3), _chapter(2), _chapter(1)]);
    final downloads = _Downloads([_download(3), _download(4, error: 'download-error')]);
    final manager = _Manager();
    final container = _createContainer(chapters, downloads, manager, completed: {2});
    final service = container.read(downloadServiceProvider);

    final result = await service.enqueueAutoDownloads(_source, _manga);
    expect(result, const DownloadEnqueueResult(enqueuedCount: 2, skippedDownloaded: 1, skippedQueued: 1, skippedUnavailable: 1));
    expect(downloads.inserted, [1]);
    expect(downloads.updated, [_download(4)]);
    expect(manager.wakes, 1);

    final repeated = await service.enqueueAutoDownloads(_source, _manga);
    expect(repeated, const DownloadEnqueueResult(skippedDownloaded: 1, skippedQueued: 3, skippedUnavailable: 1));
    expect(downloads.inserted, [1]);
    expect(downloads.updated, [_download(4)]);
    expect(manager.wakes, 2);
  });

  test('A chapter failure does not stop others', () async {
    final chapters = _Chapters([_chapter(1), _chapter(2)]);
    final downloads = _Downloads([], failChapter: 1);
    final manager = _Manager();
    final container = _createContainer(chapters, downloads, manager);

    final result = await container.read(downloadServiceProvider).enqueueAutoDownloads(_source, _manga);
    expect(result.enqueuedCount, 1);
    expect(downloads.inserted, [2]);
    expect(result.failedChapters.keys, ['chapter-url-1']);
    expect(result.failedChapters['chapter-url-1'], contains('insert-error'));
    expect(manager.wakes, 1);
  });
}

ProviderContainer _createContainer(_Chapters chapters, _Downloads downloads, _Manager manager, {Set<int> completed = const {}}) {
  final container = ProviderContainer(
    overrides: [
      chapterRepositoryProvider.overrideWithValue(chapters),
      downloadRepositoryProvider.overrideWithValue(downloads),
      downloadManagerProvider.overrideWithValue(manager),
      for (final chapter in chapters.chapters)
        downloadChapterPathProvider(_source, _manga, chapter).overrideWith(() => _ChapterPath(completed.contains(chapter.id))),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

class _Chapters implements ChapterRepository {
  _Chapters(this.chapters);
  final List<DatabaseChapter> chapters;
  int queries = 0;

  @override
  Future<List<DatabaseChapter>> queryChaptersByMangaId(int mangaId) async {
    queries++;
    return chapters.toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Downloads implements DownloadRepository {
  _Downloads(this.rows, {this.failChapter});
  final List<DatabaseDownload> rows;
  final int? failChapter;
  final List<int> inserted = [];
  final List<DatabaseDownload> updated = [];

  @override
  Future<List<DatabaseDownload>> queryDownloadsByManga(int mangaId) async => rows.toList();

  @override
  Future<void> insertDownload(Insertable<DatabaseDownload> row) async {
    final value = row as DownloadTableCompanion;
    if (value.chapter.value == failChapter) throw StateError('insert-error');
    inserted.add(value.chapter.value);
    rows.add(
      DatabaseDownload(
        source: value.source.value,
        manga: value.manga.value,
        chapter: value.chapter.value,
        total: 0,
        progress: 0,
        error: null,
      ),
    );
  }

  @override
  Future<bool> updateDownload(DatabaseDownload row) async {
    updated.add(row);
    rows[rows.indexWhere((it) => it.chapter == row.chapter)] = row;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Manager implements DownloadManager {
  int wakes = 0;

  @override
  Future<void> next() async {
    wakes++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ChapterPath extends DownloadChapterPath {
  _ChapterPath(this.completed);
  final bool completed;

  @override
  Future<Directory> build(Source source, DatabaseManga manga, DatabaseChapter chapter) async => _Directory(completed);
}

class _Directory implements Directory {
  _Directory(this.completed);
  final bool completed;

  @override
  Future<bool> exists() async => completed;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
