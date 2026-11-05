import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/database/database.dart' show DatabaseManga;
import 'package:tsukuyomi/pages/chapter/providers/chapter_sync_with_source.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/library/library_repository.dart';
import 'package:tsukuyomi/pages/manga/manga_repository.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/pages/source/source_repository.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/pages/update/update_progress_provider.dart';
import 'package:tsukuyomi/providers/download/download_manager_provider.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/providers/update/update_service.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

import 'update_fixtures.dart';

UpdateReportItem retryFailureFixture(int id) => updateReportItemFixture(id).copyWith(
  outcome: UpdateOutcome.networkError,
  message: 'previous-error-$id',
);

/// 使用真实重试、扫描、更新服务和报告存储，仅替换外部数据与下载执行
Future<ProviderContainer> createUpdateRetryContainer({
  UpdateReport? report,
  UpdateSourceFixture? source,
  Future<Source> Function()? loadSource,
  UpdateMangasFixture? mangas,
  UpdateDownloadsFixture? downloads,
  Map<int, UpdateSyncFixture> syncs = const {},
  Map<int, Set<String>> downloaded = const {},
  List<Override> overrides = const [],
}) async {
  final currentSource = source ?? UpdateSourceFixture();
  final repository = mangas ?? UpdateMangasFixture([mangaFixture(1)]);
  final currentReport = report ?? updateReportFixture(items: [retryFailureFixture(1)]);
  SharedPreferences.setMockInitialValues({
    Keys.updateReportLatest: jsonEncode(currentReport.toJson()),
  });
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
      mangaRepositoryProvider.overrideWithValue(repository),
      sourceRepositoryProvider.overrideWithValue(UpdateSourcesFixture()),
      libraryRepositoryProvider.overrideWithValue(UpdateLibraryFixture(repository.mangas.values.toList())),
      sourceByIdProvider(1).overrideWith((ref) => loadSource?.call() ?? Future.value(currentSource)),
      for (final manga in repository.mangas.values) ...[
        chapterSyncWithSourceProvider(currentSource, manga).overrideWithValue(syncs[manga.id] ?? UpdateSyncFixture()),
      ],
      for (final id in {...repository.mangas.keys, ...currentReport.items.map((item) => item.mangaId)}) ...[
        chaptersStreamByMangaProvider(id).overrideWith((ref) => Stream.value(chaptersFixture(id))),
        updateDownloadedChaptersProvider(id).overrideWith(
          (ref) async => downloaded[id] ?? {'chapter-title-1', 'chapter-title-2'},
        ),
      ],
      downloadServiceProvider.overrideWithValue(downloads ?? UpdateDownloadsFixture()),
      downloadManagerProvider.overrideWithValue(UpdateDownloadManagerFixture()),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

UpdateReport? readUpdateReportFixture(ProviderContainer container) {
  final json = container.read(sharedPreferencesProvider).getString(Keys.updateReportLatest);
  return json == null ? null : UpdateReport.fromJson(jsonDecode(json) as Map<String, dynamic>);
}

class UpdateMangasFixture implements MangaRepository {
  UpdateMangasFixture(List<DatabaseManga> mangas, {this.pending}) : mangas = {for (final manga in mangas) manga.id: manga};

  final Map<int, DatabaseManga> mangas;
  final Future<void>? pending;
  final _requested = Completer<void>();
  final checkedAt = <int, DateTime>{};
  Object? error;
  final errors = <int, Object>{};
  int queries = 0;

  Future<void> get requested => _requested.future;

  @override
  Future<DatabaseManga> queryManga(int mangaId) async => (await queryMangaByIdOrNull(mangaId))!;

  @override
  Future<DatabaseManga?> queryMangaByIdOrNull(int mangaId) async {
    queries++;
    if (!_requested.isCompleted) _requested.complete();
    await pending;
    if (error != null) throw error!;
    if (errors.containsKey(mangaId)) throw errors[mangaId]!;
    return mangas[mangaId];
  }

  @override
  Future<int> updateLastCheckAt(int mangaId, DateTime date) async {
    checkedAt[mangaId] = date;
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class UpdateLibraryFixture implements LibraryRepository {
  UpdateLibraryFixture(this.mangas, {this.pending});

  final List<DatabaseManga> mangas;
  final Future<void>? pending;
  final _requested = Completer<void>();
  int queries = 0;

  Future<void> get requested => _requested.future;

  @override
  Future<List<DatabaseManga>> queryAutoMangas({List<int>? mangaIds}) async {
    queries++;
    if (!_requested.isCompleted) _requested.complete();
    await pending;
    return mangas.where((manga) => manga.favorite && manga.auto && (mangaIds == null || mangaIds.contains(manga.id))).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class UpdateSyncFixture implements ChapterSyncWithSource {
  UpdateSyncFixture([this.pending]);

  final Future<void>? pending;
  final _requested = Completer<void>();
  ChapterSyncResult result = const ChapterSyncResult(insertCount: 1, deleteCount: 0, updateCount: 0, sourceCount: 1);
  Object? error;
  int calls = 0;

  Future<void> get requested => _requested.future;

  @override
  Future<ChapterSyncResult> apply(Iterable<SourceChapter> sourceChapters) async {
    calls++;
    if (!_requested.isCompleted) _requested.complete();
    await pending;
    if (error != null) throw error!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class UpdateDownloadsFixture implements DownloadService {
  final mangas = <DatabaseManga>[];
  final errors = <int, Object>{};
  final refreshed = <int>[];
  DownloadEnqueueResult result = const DownloadEnqueueResult(enqueuedCount: 1);

  @override
  Future<DownloadEnqueueResult> enqueueAutoDownloads(Source source, DatabaseManga manga) async {
    mangas.add(manga);
    final error = errors[manga.id];
    if (error != null) throw error;
    return result;
  }

  @override
  Future<void> refreshDownloadedByManga(Source source, DatabaseManga manga) async => refreshed.add(manga.id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class UpdateDownloadManagerFixture implements DownloadManager {
  @override
  Future<void> next() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 观察调用者何时取得真实服务的 Future，不替换更新逻辑
class UpdateServiceCallsFixture implements UpdateService {
  UpdateServiceCallsFixture(this.service);

  final UpdateService service;
  final calls = <int>[];
  final _requested = <int, Completer<void>>{};

  Future<void> waitForCall(int count) {
    if (calls.length >= count) return Future.value();
    return (_requested.putIfAbsent(count, Completer<void>.new)).future;
  }

  @override
  Future<UpdateReportItem> updateManga(Source source, DatabaseManga manga) {
    final future = service.updateManga(source, manga);
    calls.add(manga.id);
    _requested.remove(calls.length)?.complete();
    return future;
  }

  @override
  Future<UpdateReportItem> updateMangaAndSaveReport(Source source, DatabaseManga manga) => service.updateMangaAndSaveReport(source, manga);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
