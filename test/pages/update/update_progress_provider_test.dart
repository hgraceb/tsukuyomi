import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/database/database.dart' show DatabaseChapter, DatabaseManga;
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/download/providers/download_path_provider.dart';
import 'package:tsukuyomi/pages/download/providers/downloaded_info_provider.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/pages/update/update_progress_provider.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/source/delegate/source_stub.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

import '../../fixtures/update_fixtures.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Completed local chapter notifications reach the manga progress and cached counts', () async {
    final directory = _createDirectory();
    Directory('${directory.path}/chapter-title-1').createSync();
    final report = updateReportFixture(items: [updateReportItemFixture(1)]);
    late Completer<void> chapterDisposal;
    SharedPreferences.setMockInitialValues({Keys.updateReportLatest: jsonEncode(report.toJson())});
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
        mangaStreamByIdProvider(_manga.id).overrideWith((ref) => Stream.value(_manga)),
        chaptersStreamByMangaProvider(_manga.id).overrideWith((ref) => Stream.value(chaptersFixture(_manga.id))),
        sourceByIdProvider(_manga.source).overrideWith((ref) async => _source),
        downloadMangaPathProvider(_source, _manga).overrideWith(() => _MangaPath(directory)),
        downloadedChaptersProvider(directory.path).overrideWith(() {
          chapterDisposal = Completer<void>();
          return _ObservedChapters(chapterDisposal);
        }),
      ],
    );
    addTearDown(container.dispose);
    final owner = container.listen(updateProgressCacheProvider(report.sessionId), (_, _) {});
    final row = container.listen(updateProgressProvider(owner.read(), _manga.id), (_, _) {});
    final raw = container.listen(updateDownloadedChaptersProvider(_manga.id), (_, _) {});

    expect(await container.read(updateDownloadedChaptersProvider(_manga.id).future), {'chapter-title-1'});
    await container.read(chaptersStreamByMangaProvider(_manga.id).future);
    await container.pump();
    expect(row.read(), const UpdateProgress(completed: 1, total: 5, hasValue: true));
    Directory('${directory.path}/chapter-title-2').createSync();
    container.read(downloadedChaptersProvider(directory.path).notifier).update('chapter-title-2');
    await container.pump();
    expect(await container.read(updateDownloadedChaptersProvider(_manga.id).future), {'chapter-title-1', 'chapter-title-2'});
    await container.pump();
    expect(row.read(), const UpdateProgress(completed: 2, total: 5, hasValue: true));

    final disposed = chapterDisposal.future;
    row.close();
    raw.close();
    await container.pump();
    await disposed.timeout(const Duration(seconds: 2));
    await container.pump();
    expect(container.exists(chaptersStreamByMangaProvider(_manga.id)), isFalse);
    expect(container.exists(updateDownloadedChaptersProvider(_manga.id)), isFalse);
    expect(container.exists(downloadedChaptersProvider(directory.path)), isFalse);

    Directory('${directory.path}/chapter-title-3').createSync();
    final returned = container.listen(updateProgressProvider(owner.read(), _manga.id), (_, _) {});
    expect(returned.read(), const UpdateProgress(completed: 2, total: 5, hasValue: true));
    await container.read(updateDownloadedChaptersProvider(_manga.id).future);
    await container.read(chaptersStreamByMangaProvider(_manga.id).future);
    await container.pump();
    expect(returned.read(), const UpdateProgress(completed: 3, total: 5, hasValue: true));
  });

  for (final stage in ['manga', 'source', 'path', 'path-error']) {
    test('Leaving during $stage initialization does not leave data subscriptions behind', () async {
      final directory = _createDirectory();
      Directory('${directory.path}/chapter-title-1').createSync();
      final pending = Completer<void>();
      final requested = Completer<void>();
      final atPath = stage.startsWith('path');
      final container = ProviderContainer(
        overrides: [
          mangaStreamByIdProvider(_manga.id).overrideWith((ref) async* {
            if (stage == 'manga') {
              requested.complete();
              await pending.future;
            }
            yield _manga;
          }),
          sourceByIdProvider(_manga.source).overrideWith((ref) async {
            if (stage == 'source') {
              requested.complete();
              await pending.future;
            }
            return _source;
          }),
          downloadMangaPathProvider(_source, _manga).overrideWith(
            () => atPath ? _PendingMangaPath(directory, pending.future, requested) : _MangaPath(directory),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(updateDownloadedChaptersProvider(_manga.id), (_, _) {});
      final read = container.read(updateDownloadedChaptersProvider(_manga.id).future);
      await requested.future;
      subscription.close();
      await container.pump();

      if (stage == 'path-error') {
        final error = StateError('path-read-error');
        final failed = expectLater(read, throwsA(same(error)));
        pending.completeError(error);
        await failed;
      } else {
        pending.complete();
        expect(await read, {'chapter-title-1'});
      }
      await container.pump();
      expect(container.exists(updateDownloadedChaptersProvider(_manga.id)), isFalse);
      expect(container.exists(mangaStreamByIdProvider(_manga.id)), isFalse);
      expect(container.exists(sourceByIdProvider(_manga.source)), isFalse);
      expect(container.exists(downloadedByMangaProvider(_source, _manga)), isFalse);
      expect(container.exists(downloadedChaptersProvider(directory.path)), isFalse);
    });
  }

  for (final failPath in [false, true]) {
    test('Chapter image reads release their subscriptions after leaving during path loading: failure=$failPath', () async {
      final directory = _createDirectory();
      final image = File(p.join(directory.path, '001.jpg'))..writeAsBytesSync([1, 2, 3]);
      final chapter = chaptersFixture(_manga.id).first;
      final pending = Completer<void>();
      final requested = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          downloadChapterPathProvider(
            _source,
            _manga,
            chapter,
          ).overrideWith(() => _PendingChapterPath(directory, pending.future, requested)),
        ],
      );
      addTearDown(container.dispose);
      final provider = downloadedByChapterProvider(_source, _manga, chapter);
      final subscription = container.listen(provider, (_, _) {});
      final read = container.read(provider.future);
      await requested.future;
      subscription.close();
      await container.pump();

      if (failPath) {
        final error = StateError('chapter-path-error');
        final failed = expectLater(read, throwsA(same(error)));
        pending.completeError(error);
        await failed;
      } else {
        pending.complete();
        expect((await read).map((item) => item.url), [image.path]);
      }
      await container.pump();
      expect(container.exists(provider), isFalse);
      expect(container.exists(downloadChapterPathProvider(_source, _manga, chapter)), isFalse);
      expect(container.exists(downloadedImagesProvider(directory.path)), isFalse);
    });
  }

  test('Download progress loading errors remain observable', () async {
    final error = StateError('source-error');
    final container = ProviderContainer(
      overrides: [
        mangaStreamByIdProvider(_manga.id).overrideWith((ref) => Stream.value(_manga)),
        sourceByIdProvider(_manga.source).overrideWith((ref) async => throw error),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(updateDownloadedChaptersProvider(_manga.id), (_, _) {});

    await expectLater(container.read(updateDownloadedChaptersProvider(_manga.id).future), throwsA(same(error)));
    expect(container.read(updateDownloadedChaptersProvider(_manga.id)).error, same(error));
    subscription.close();
    await container.pump();
    expect(container.exists(updateDownloadedChaptersProvider(_manga.id)), isFalse);
    expect(container.exists(sourceByIdProvider(_manga.source)), isFalse);
  });
}

Directory _createDirectory() {
  final root = Directory('${Directory.current.path}/.dart_tool');
  final directory = root.createTempSync('update-progress-');
  addTearDown(() {
    if (directory.parent.absolute.path != root.absolute.path) throw StateError('Unexpected test directory');
    directory.deleteSync(recursive: true);
  });
  return directory;
}

class _MangaPath extends DownloadMangaPath {
  _MangaPath(this._directory);

  final Directory _directory;

  @override
  Future<Directory> build(Source source, DatabaseManga manga) async => _directory;
}

class _ObservedChapters extends DownloadedChapters {
  _ObservedChapters(this.disposed);

  final Completer<void> disposed;

  @override
  Set<String> build(String path) {
    ref.onDispose(() {
      if (!disposed.isCompleted) disposed.complete();
    });
    return super.build(path);
  }
}

class _PendingMangaPath extends _MangaPath {
  _PendingMangaPath(super.directory, this.pending, this.requested);

  final Future<void> pending;

  final Completer<void> requested;

  @override
  Future<Directory> build(Source source, DatabaseManga manga) async {
    if (!requested.isCompleted) requested.complete();
    await pending;
    return super.build(source, manga);
  }
}

class _PendingChapterPath extends DownloadChapterPath {
  _PendingChapterPath(this.directory, this.pending, this.requested);

  final Directory directory;

  final Future<void> pending;

  final Completer<void> requested;

  @override
  Future<Directory> build(Source source, DatabaseManga manga, DatabaseChapter chapter) async {
    if (!requested.isCompleted) requested.complete();
    await pending;
    return directory;
  }
}
