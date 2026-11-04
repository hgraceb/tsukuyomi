import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/main.dart' show TsukuyomiApp;
import 'package:tsukuyomi/pages/chapter/chapter_repository.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/manga/manga_repository.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/pages/update/update_page.dart';
import 'package:tsukuyomi/pages/update/update_progress_provider.dart';
import 'package:tsukuyomi/pages/update/update_retry_controller.dart';
import 'package:tsukuyomi/providers/providers.dart';
import 'package:tsukuyomi/providers/update/update_manager.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_service.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi/source/source.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

// 本地临时入口：预置全部样例核对真实更新页样式，手动重试使用真实服务与内存数据
// flutter run -d windows -t lib/main_update_pending_demo.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _OfflineHttpOverrides();
  final data = _DemoData();
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _DemoPage()),
      GoRoute(
        name: TsukuyomiRouter.manga.name,
        path: '/manga/:mangaId',
        builder: (context, state) => _DemoDetails(mangaId: int.parse(state.params['mangaId']!)),
      ),
    ],
  );
  runApp(
    ProviderScope(
      overrides: [
        _dataProvider.overrideWith((ref) => data),
        sharedPreferencesProvider.overrideWithValue(_MemoryPreferences()),
        statusBarHeightProvider.overrideWithValue(0),
        routerConfigProvider.overrideWithValue(router),
        databaseProvider.overrideWith((ref) => throw StateError('离线演示不使用真实数据库')),
        updateManagerProvider.overrideWith(() => _DemoManager(data)),
        mangaRepositoryProvider.overrideWithValue(_DemoMangas(data)),
        chapterRepositoryProvider.overrideWithValue(_DemoChapters(data)),
        downloadServiceProvider.overrideWithValue(_DemoDownloads(data)),
        downloadManagerProvider.overrideWithValue(_DemoDownloadManager()),
        for (var id = 1; id <= _sourceNames.length; id++) ...[
          sourceByIdProvider(id).overrideWith((ref) async {
            await Future<void>.delayed(const Duration(milliseconds: 250));
            return id == 5 ? NoInstalledSource(id) : _DemoSource(data, id);
          }),
        ],
        for (var id = 1; id <= _samples.length; id++) ...[
          updateDownloadedChaptersProvider(id).overrideWith((ref) async {
            final (downloaded, delay, fail) = ref.watch(
              _dataProvider.select((data) => (data.downloaded[id] ?? const <String>{}, data.readDelay, id == 14 && data.progressReadError)),
            );
            if (delay > 0) await Future<void>.delayed(Duration(milliseconds: delay));
            if (fail) throw StateError('离线模拟：本地下载进度读取失败');
            return downloaded;
          }),
        ],
      ],
      child: const TsukuyomiApp(),
    ),
  );
}

const _sourceNames = ['01 · 正常结果', '02 · 各类失败', '03 · 已跳过', '04 · 未检查', '05 · 未安装的漫画源'];
const _samples = [
  (title: '有更新 · 部分下载', outcome: UpdateOutcome.updated, total: 8, downloaded: 2, source: 1),
  (title: '无更新 · 下载未完成', outcome: UpdateOutcome.noUpdate, total: 6, downloaded: 2, source: 1),
  (title: '无更新 · 全部已下载', outcome: UpdateOutcome.noUpdate, total: 5, downloaded: 5, source: 1),
  (title: '章节为空 · 可手动重试', outcome: UpdateOutcome.chaptersEmpty, total: 0, downloaded: 0, source: 1),
  (title: '公开章节转付费 · 正常成功', outcome: UpdateOutcome.noUpdate, total: 6, downloaded: 2, source: 1),
  (title: '漫画源不可用 · 不显示旧章节数', outcome: UpdateOutcome.sourceUnavailable, total: 5, downloaded: 0, source: 5),
  (title: '网络请求失败 · 红色重试', outcome: UpdateOutcome.networkError, total: 4, downloaded: 0, source: 2),
  (title: '章节解析失败 · 红色重试', outcome: UpdateOutcome.parseError, total: 3, downloaded: 1, source: 2),
  (title: '数据保存失败 · 红色重试', outcome: UpdateOutcome.storageError, total: 5, downloaded: 2, source: 2),
  (title: '下载安排失败 · 红色重试', outcome: UpdateOutcome.enqueueFailed, total: 6, downloaded: 2, source: 2),
  (title: '未收藏 · 已跳过', outcome: UpdateOutcome.skipped, total: 6, downloaded: 1, source: 3),
  (title: '关闭自动下载 · 已跳过', outcome: UpdateOutcome.skipped, total: 5, downloaded: 2, source: 3),
  (title: '记录已删除 · 已跳过', outcome: UpdateOutcome.skipped, total: 4, downloaded: 1, source: 3),
  (title: '进度读取异常 · 可恢复或整本重试', outcome: UpdateOutcome.noUpdate, total: 7, downloaded: 3, source: 1),
  (title: '停止后未检查 · 警告与重试', outcome: UpdateOutcome.pending, total: 5, downloaded: 2, source: 4),
  (title: '中断后未检查 · 警告与重试', outcome: UpdateOutcome.checking, total: 5, downloaded: 0, source: 4),
];
final _dataProvider = ChangeNotifierProvider<_DemoData>((ref) => throw StateError('需要演示数据'));

class _DemoPage extends ConsumerStatefulWidget {
  const _DemoPage();

  @override
  ConsumerState<_DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends ConsumerState<_DemoPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(updateManagerProvider.notifier).scan());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(_dataProvider);
    final report = ref.watch(updateReportStoreProvider);
    final playing = ref.watch(updateManagerProvider).isLoading;
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('更新页完整状态预览', style: TextStyle(fontWeight: FontWeight.bold)),
                      FilledButton.icon(
                        icon: const Icon(Icons.replay_outlined),
                        label: Text(playing ? '演示中…' : '手动重播'),
                        onPressed: playing
                            ? null
                            : () {
                                if (_scrollController.hasClients) _scrollController.jumpTo(0.0);
                                unawaited(ref.read(updateManagerProvider.notifier).scan());
                              },
                      ),
                      Text('样例 ${report?.totalTargets ?? _samples.length} 条'),
                    ],
                  ),
                  Text(data.caption),
                  Wrap(
                    spacing: 16.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton.icon(
                        icon: Icon(data.progressReadError ? Icons.refresh_outlined : Icons.error_outline),
                        label: Text(data.progressReadError ? '恢复 014 进度读取' : '模拟 014 读取失败'),
                        onPressed: playing || data.active.contains(14) ? null : () => data.setProgressReadError(!data.progressReadError),
                      ),
                      Text('014 本地读取：${data.progressReadError ? '失败' : '正常'} · 模拟源请求 ${data.requests[14] ?? 0} 次'),
                    ],
                  ),
                  const Text('只播放一次，结束后保留全部样例；可滚动、筛选或手动重试。数据仅在内存中，不会请求真实漫画源'),
                  const Text('014：恢复后再模拟失败可查看缓存进度；读取错误不改变顶部统计，行末重试会重新检查整本漫画'),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: PrimaryScrollController(
            controller: _scrollController,
            automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
            child: const UpdatePage(),
          ),
        ),
      ],
    );
  }
}

class _DemoManager extends UpdateManager {
  _DemoManager(this.data);

  final _DemoData data;
  bool _stopped = false;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<void> scan() async {
    if (state.isLoading) return;
    _stopped = false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      while (true) {
        final items = ref.read(updateReportStoreProvider)?.items ?? [];
        final retrying = items.any((item) => ref.read(updateRetryControllerProvider(item.mangaId)));
        if (!retrying && data.active.isEmpty && data.refreshing.isEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      if (_stopped) return;
      data.reset();
      final store = ref.read(updateReportStoreProvider.notifier);
      final report = _report(UpdatePhase.running, [for (var id = 1; id <= _samples.length; id++) _sampleItem(id, UpdateOutcome.pending)]);
      await store.save(report);
      data.describe('清单已一次显示完整，接下来逐项展示状态；本页使用预置结果核对样式，重试仍使用真实控制器');
      await Future<void>.delayed(const Duration(seconds: 2));
      for (var id = 1; id <= _samples.length; id++) {
        if (_stopped) break;
        final sample = _samples[id - 1];
        if (sample.outcome == UpdateOutcome.pending) continue;
        data.describe('正在展示：${sample.title}');
        await store.replaceItem(report.sessionId, _sampleItem(id, UpdateOutcome.checking));
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        if (!sample.outcome.isPending && sample.outcome != UpdateOutcome.skipped) data.requests[id] = 1;
        await store.replaceItem(report.sessionId, _sampleItem(id, sample.outcome));
      }
      await store.update(report.sessionId, (report) => report.copyWith(phase: UpdatePhase.cancelled, finishedAt: DateTime.now()));
      final saved = ref.read(updateReportStoreProvider)!;
      data.describe(_stopped ? '演示已手动停止；点击手动重播可查看全部状态' : '播放结束：014 检查成功但进度读取失败；可切换顶部开关或点击行末重试，观察提示恢复');
      debugPrint(
        '[状态总览结束] 总数 ${saved.totalTargets} / 失败 ${saved.failureCount} / 警告 ${saved.warningCount} / '
        '成功 ${saved.successCount} / 未检查 ${saved.pendingCount} / 跳过 ${saved.skippedCount}',
      );
      debugPrint('[状态总览样例] ${saved.items.map((item) => '${item.mangaId}:${item.outcome.name}').join(', ')}');
    });
  }

  @override
  void stop() => _stopped = true;
}

class _DemoDetails extends ConsumerWidget {
  const _DemoDetails({required this.mangaId});

  final int mangaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_dataProvider);
    final manga = data.mangas[mangaId];
    final report = ref.watch(updateReportStoreProvider);
    final included = report?.items.any((item) => item.mangaId == mangaId) == true;
    return Scaffold(
      appBar: AppBar(title: Text(_manga(mangaId).title)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(included ? '这本漫画已在本轮清单内，刷新结果会替换对应行' : '这本漫画不在本轮清单内，刷新不会添加本轮记录'),
            Text('模拟源请求 ${data.requests[mangaId] ?? 0} 次 · 已下载 ${data.downloaded[mangaId]?.length ?? 0} 章'),
            if (manga == null) ...[
              const Text('数据库记录已被删除，返回更新页仍可查看本轮历史记录'),
            ] else ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('收藏'),
                value: manga.favorite,
                onChanged: (value) => data.setFavorite(mangaId, value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('自动下载'),
                value: manga.auto,
                onChanged: (value) => data.setAuto(mangaId, value),
              ),
              FilledButton(
                onPressed: data.refreshing.contains(mangaId) ? null : () => _refresh(ref, mangaId),
                child: Text(data.refreshing.contains(mangaId) ? '正在刷新' : '手动刷新'),
              ),
            ],
            const SizedBox(height: 16.0),
            const Text('刷新途中可以返回列表；未收藏或关闭自动下载时仍可手动检查，原设置保持不变'),
            TextButton(onPressed: () => context.pop(), child: const Text('返回更新页')),
          ],
        ),
      ),
    );
  }
}

Future<void> _refresh(WidgetRef ref, int id) async {
  final data = ref.read(_dataProvider);
  final manga = data.mangas[id];
  if (manga == null || !data.refreshing.add(id)) return;
  final service = ref.read(updateServiceProvider);
  final source = ref.read(sourceByIdProvider(manga.source).future);
  data.changed();
  try {
    await service.updateMangaAndSaveReport(await source, manga);
  } finally {
    data.refreshing.remove(id);
    data.changed();
  }
}

class _DemoData extends ChangeNotifier {
  _DemoData() {
    reset();
  }

  final mangas = <int, DatabaseManga>{};
  final chapters = <int, List<DatabaseChapter>>{};
  final downloaded = <int, Set<String>>{};
  final queued = <int, Set<String>>{};
  final requests = <int, int>{};
  final active = <int>{};
  final refreshing = <int>{};
  int nextChapterId = 10000000;
  int requestDelay = 1500;
  int readDelay = 300;
  bool progressReadError = true;
  String caption = '即将播放一次完整状态预览';

  void changed() => notifyListeners();

  void describe(String value) {
    caption = value;
    debugPrint('[状态总览] $value');
    changed();
  }

  void setProgressReadError(bool value) {
    progressReadError = value;
    describe(value ? '014 读取失败：保留已确认的进度，检查结果和顶部统计不变' : '014 恢复读取：错误提示自动消失，不增加漫画源请求');
  }

  void reset() {
    progressReadError = true;
    nextChapterId = 10000000;
    mangas.clear();
    chapters.clear();
    downloaded.clear();
    queued.clear();
    requests.clear();
    for (var id = 1; id <= _samples.length; id++) {
      _add(id);
    }
    mangas[11] = mangas[11]!.copyWith(favorite: false);
    mangas[12] = mangas[12]!.copyWith(auto: false);
    mangas.remove(13);
    changed();
  }

  void _add(int id) {
    mangas[id] = _manga(id);
    chapters[id] = [
      for (var index = 1; index <= _chapterCount(id); index++) ...[
        DatabaseChapter(
          id: id * 10000 + index,
          manga: id,
          index: index,
          title: '章节 $index',
          url: 'offline-chapter-$id-$index',
          date: '',
          public: id != 5 || index < _chapterCount(id),
          images: 0,
          progress: 0,
        ),
      ],
    ];
    final sample = _samples[id - 1];
    final completed = sample.downloaded;
    downloaded[id] = {for (var index = 1; index <= completed; index++) '章节 $index'};
    if (sample.outcome == UpdateOutcome.noUpdate) {
      queued[id] = chapters[id]!
          .where((chapter) => chapter.public && !downloaded[id]!.contains(chapter.title))
          .map((chapter) => chapter.title)
          .toSet();
    }
  }

  void setFavorite(int id, bool value) {
    final manga = mangas[id];
    if (manga != null) mangas[id] = manga.copyWith(favorite: value);
    changed();
  }

  void setAuto(int id, bool value) {
    final manga = mangas[id];
    if (manga != null) mangas[id] = manga.copyWith(auto: value);
    changed();
  }
}

class _DemoMangas implements MangaRepository {
  _DemoMangas(this.data);

  final _DemoData data;

  @override
  Future<DatabaseManga?> queryMangaByIdOrNull(int mangaId) async => data.mangas[mangaId];

  @override
  Future<DatabaseManga> queryManga(int mangaId) async => data.mangas[mangaId] ?? (throw StateError('漫画记录已删除'));

  @override
  Future<int> updateLastCheckAt(int mangaId, DateTime checkedAt) async {
    final manga = data.mangas[mangaId];
    if (manga == null) return 0;
    data.mangas[mangaId] = manga.copyWith(lastCheckAt: checkedAt);
    data.changed();
    return 1;
  }

  @override
  Stream<List<DatabaseChapter>> watchChapters(int mangaId) {
    final delay = data.readDelay;
    return Stream<List<DatabaseChapter>>.multi((controller) {
      void emit() => controller.add(data.chapters[mangaId] ?? const []);
      data.addListener(emit);
      emit();
      controller.onCancel = () => data.removeListener(emit);
    }).distinct().asyncMap((chapters) async {
      if (delay > 0) await Future<void>.delayed(Duration(milliseconds: delay));
      return chapters;
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DemoSource extends NoInstalledSource {
  _DemoSource(this.data, super.id);

  final _DemoData data;

  @override
  String get name => _sourceNames[id - 1];

  @override
  Future<Iterable<SourceChapter>> getMangaChapters(SourceManga manga) async {
    final mangaId = int.parse(manga.url.split('-').last);
    final attempt = (data.requests[mangaId] ?? 0) + 1;
    data.requests[mangaId] = attempt;
    data.active.add(mangaId);
    data.changed();
    try {
      await Future<void>.delayed(Duration(milliseconds: data.requestDelay));
      if (attempt == 1 && mangaId == 7) throw TimeoutException('离线模拟请求失败，点击重试后恢复');
      if (attempt == 1 && mangaId == 8) throw const FormatException('离线模拟解析失败，点击重试后恢复');
      if (mangaId == 14) data.progressReadError = false;
      final count = mangaId == 4 ? 5 : _chapterCount(mangaId);
      return [
        for (var index = 1; index <= count; index++) ...[
          HttpSourceChapter(url: 'offline-chapter-$mangaId-$index', name: '章节 $index', public: mangaId != 5 || index < count),
        ],
      ];
    } finally {
      data.active.remove(mangaId);
      data.changed();
    }
  }
}

class _DemoChapters implements ChapterRepository {
  _DemoChapters(this.data);

  final _DemoData data;

  @override
  Future<List<DatabaseChapter>> queryChaptersByMangaId(int mangaId) async {
    if (!data.mangas.containsKey(mangaId)) throw StateError('漫画记录已删除');
    if (mangaId == 9 && data.requests[mangaId] == 1) throw StateError('离线模拟保存失败');
    return data.chapters[mangaId] ?? [];
  }

  @override
  Future<void> batch({Iterable<int>? deletes, Iterable<ChapterTableCompanion>? inserts, Iterable<ChapterTableCompanion>? updates}) async {
    final rows = {
      for (final chapters in data.chapters.values)
        for (final chapter in chapters) chapter.id: chapter,
    };
    final changed = <int>{};
    for (final id in deletes ?? <int>[]) {
      final chapter = rows.remove(id);
      if (chapter != null) changed.add(chapter.manga);
    }
    for (final value in [...?updates, ...?inserts]) {
      final id = value.id.present ? value.id.value : data.nextChapterId++;
      rows[id] = DatabaseChapter(
        id: id,
        manga: value.manga.value,
        index: value.index.value,
        title: value.title.value,
        url: value.url.value,
        date: value.date.value,
        public: value.public.value,
        images: value.images.present ? value.images.value : 0,
        progress: value.progress.present ? value.progress.value : 0,
      );
      changed.add(value.manga.value);
    }
    for (final id in changed) {
      data.chapters[id] = rows.values.where((chapter) => chapter.manga == id).toList();
    }
    data.changed();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DemoDownloads implements DownloadService {
  _DemoDownloads(this.data);

  final _DemoData data;

  @override
  Future<DownloadEnqueueResult> enqueueAutoDownloads(Source source, DatabaseManga manga) async {
    if (manga.id == 10 && data.requests[manga.id] == 1) {
      return const DownloadEnqueueResult(failedChapters: {'章节 1': '离线模拟入队失败，点击重试后恢复'});
    }
    final chapters = (data.chapters[manga.id] ?? []).where((chapter) => chapter.public);
    final downloaded = data.downloaded[manga.id] ?? {};
    final queued = data.queued.putIfAbsent(manga.id, () => {});
    var enqueued = 0;
    var skippedDownloaded = 0;
    var skippedQueued = 0;
    for (final chapter in chapters) {
      if (downloaded.contains(chapter.title)) {
        skippedDownloaded++;
      } else if (queued.add(chapter.title)) {
        enqueued++;
      } else {
        skippedQueued++;
      }
    }
    data.changed();
    return DownloadEnqueueResult(enqueuedCount: enqueued, skippedDownloaded: skippedDownloaded, skippedQueued: skippedQueued);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DemoDownloadManager implements DownloadManager {
  @override
  Future<void> next() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryPreferences implements SharedPreferences {
  final _values = <String, Object>{Keys.themeMode: 2};

  @override
  int? getInt(String key) => _values[key] as int?;

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _OfflineHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => throw StateError('离线演示禁止 HTTP 请求');
}

DatabaseManga _manga(int id) {
  final sample = _samples[id - 1];
  return DatabaseManga(
    id: id,
    source: sample.source,
    url: 'offline-manga-$id',
    title: '${id.toString().padLeft(3, '0')} · ${sample.title}',
    cover: '',
    favorite: true,
    auto: true,
    lastCheckAt: null,
  );
}

int _chapterCount(int id) => _samples[id - 1].total;

UpdateReport _report(UpdatePhase phase, List<UpdateReportItem> items) => UpdateReport(
  version: UpdateReport.currentVersion,
  phase: phase,
  scanKind: UpdateScanKind.full,
  sessionId: 'offline-pending-${DateTime.now().microsecondsSinceEpoch}',
  totalTargets: items.length,
  items: items,
  startedAt: DateTime.now(),
  finishedAt: phase == UpdatePhase.idle || phase == UpdatePhase.running ? null : DateTime.now(),
);

UpdateReportItem _sampleItem(int id, UpdateOutcome outcome) {
  final manga = _manga(id);
  return UpdateReportItem(
    sourceId: manga.source,
    sourceName: _sourceNames[manga.source - 1],
    mangaId: id,
    mangaTitle: manga.title,
    outcome: outcome,
    insertCount: outcome == UpdateOutcome.updated ? 1 : 0,
    deleteCount: 0,
    updateCount: 0,
    sourceCount: _chapterCount(id),
    enqueuedCount: 0,
    enqueueFailedCount: outcome == UpdateOutcome.enqueueFailed ? 1 : 0,
    skippedDownloaded: 0,
    skippedQueued: 0,
    skippedUnavailable: 0,
    failedChapters: outcome == UpdateOutcome.enqueueFailed ? ['章节 1'] : [],
    updatedAt: outcome.isPending ? null : DateTime.now(),
  );
}
