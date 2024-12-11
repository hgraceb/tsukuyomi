import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/extension/extension.dart';
import 'package:tsukuyomi/pages/chapter/chapter_service.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

part 'download_manager_provider.g.dart';

@Riverpod(keepAlive: true)
class DownloadQueue extends _$DownloadQueue {
  @override
  List<DownloadTask> build() {
    ref.onDispose(() {
      for (final task in state) {
        task.cancel();
      }
    });
    return [];
  }

  void addTask(DownloadTask downloadTask) {
    state = [...state, downloadTask];
  }

  bool remove(DownloadTask downloadTask) {
    final removed = state.remove(downloadTask);
    if (removed) {
      state = [...state];
    }
    return removed;
  }
}

class DownloadTask {
  DownloadTask({required this.ref, required this.source, required this.manga, required this.chapter, required this.download});

  final DownloadManagerRef ref;

  final DioHttpSource source;

  final DatabaseManga manga;

  final DatabaseChapter chapter;

  DatabaseDownload download;

  bool _canceled = false;

  /// 保存漫画章节图片
  Future<void> _saveImageFile(HttpSourceImage image, Directory dir, String name) async {
    final fileFromCache = await source.getImageCacheManager(image)?.getFileFromCache(image.url);
    final cachedImage = fileFromCache?.file;
    if (cachedImage != null) {
      final path = join(dir.path, '$name${extension(cachedImage.path)}');
      await cachedImage.copy(path);
    } else {
      final bytes = await source.getImageBytes(image);
      final repaint = await source.getRepaintBytes(bytes);
      final path = join(dir.path, '$name.${repaint.type}');
      await File(path).writeAsBytes(repaint.data, flush: true);
    }
  }

  /// 获取漫画章节图片列表
  Future<List<HttpSourceImage>> _getChapterImages() async {
    // 检查任务是否已取消
    if (_canceled) throw const TsukuyomiDownloadException.canceled();
    // 获取章节图片列表数据
    final images = await ref.read(chapterImagesProvider(source, manga, chapter).future);
    // 转换图片的类型并返回
    return images.cast<HttpSourceImage>();
  }

  /// 更新下载信息
  Future<void> _updateDownload(DatabaseDownload download, {bool check = true}) async {
    // 检查任务是否已取消
    if (check && _canceled) throw const TsukuyomiDownloadException.canceled();
    // 更新数据库下载信息
    final updated = await ref.read(downloadServiceProvider).updateDownload(this.download = download);
    // 检查数据库更新结果
    if (check && !updated) throw const TsukuyomiDownloadException.databaseError('UPDATE');
  }

  /// 开始下载任务
  void start(VoidCallback callback) async {
    // TODO 设置最小要求的磁盘空间大小，如：200MB
    try {
      // 更新章节下载信息
      await _updateDownload(download.copyWith(error: null));
      // 获取下载服务
      final downloadService = ref.read(downloadServiceProvider);
      // 获取漫画章节下载文件夹
      final dir = await downloadService.getChapterDir(source, manga, chapter);
      // 章节下载文件夹已存在
      if (dir.existsSync()) throw TsukuyomiDownloadException.pathAlreadyExists(dir.path);
      // 获取章节图片列表
      final images = await _getChapterImages();
      // 如果章节图片列表获取失败
      if (images.isEmpty) throw TsukuyomiDownloadException.imagesNotFound(chapter.title);
      // 如果图片列表长度发生变化则重置章节下载进度
      if (images.length != download.total) await _updateDownload(download.copyWith(progress: 0, total: images.length));
      // 获取临时下载文件夹
      final temp = await downloadService.createTempChapterDir(source, manga, chapter);
      // 图片文件名宽度
      final width = (images.length + 1).toString().length;
      // 遍历下载所有图片
      for (final entry in images.asMap().entries) {
        // 跳过已下载图片
        if (entry.key < download.progress) continue;
        // 不包含文件后缀的本地图片文件名，如：001
        final name = '${entry.key + 1}'.padLeft(width, '0');
        // 请求图片数据并保存到本地
        await _saveImageFile(entry.value, temp, name);
        // 更新章节下载进度
        await _updateDownload(download.copyWith(progress: entry.key + 1));
      }
      // 重命名临时文件夹
      temp.renameSync(dir.path);
      // 更新已下载章节信息
      await downloadService.refreshDownloadedByChapter(source, manga, chapter);
      // 删除已完成的下载任务
      await downloadService.deleteDownload(download);
    } catch (error, stackTrace) {
      // TODO 重试处理
      try {
        // 更新章节下载状态
        await _updateDownload(
          download.copyWith(
            // TODO 优化错误信息获取、处理错误信息中包含特殊链接需要解码的情况
            error: error.toString(),
          ),
          check: false,
        );
      } catch (e, s) {
        // 章节状态更新出错 TODO 致命错误，永久减少一次并发下载次数
        log('Download fatal error', error: e, stackTrace: s);
        return;
      }
      // TODO 错误处理、以漫画源为维度进行指数退避延迟，避免同一漫画源连续多次请求下载失败
      log('Download error', error: error, stackTrace: stackTrace);
    }
    // 下载结束（成功或者失败）
    callback();
  }

  /// 取消下载任务 TODO 删除临时文件夹
  Future<void> cancel() async {
    if (_canceled) return;
    _canceled = true;
  }
}

class DownloadManager {
  DownloadManager._({required this.ref}) {
    _queue = ref.read(downloadQueueProvider);
    ref.listen(downloadQueueProvider, (previous, next) => _queue = next);
  }

  final DownloadManagerRef ref;

  /// 当前添加中的下载队列总数
  int _downloads = 0;

  /// 当前是否处于暂停下载状态
  bool _paused = false;

  /// 最大并发下载章节数，默认同一个漫画源只能并发下载一个章节
  final int _maxConcurrent = 3;

  /// 当前正在下载的章节队列
  late List<DownloadTask> _queue;

  /// 添加下载任务
  void _startTask(DownloadTask task) {
    // 将下载任务添加到队列中
    ref.read(downloadQueueProvider.notifier).addTask(task);
    // 开始下载
    task.start(() {
      ref.read(downloadQueueProvider.notifier).remove(task);
      next();
    });
  }

  /// 添加下载队列
  Future<void> _startDownloads() async {
    // 并发下载数已达上限
    if (_queue.length >= _maxConcurrent) return;
    // 避免重复添加下载任务
    if (_downloads++ != 0) return;
    // 筛选下载数据
    for (final entry in await ref.read(downloadServiceProvider).queryDownloadsPartitionBySource(_maxConcurrent)) {
      // 重新判断并发下载数
      if (_queue.length >= _maxConcurrent) break;
      // 如果漫画源已有下载任务在队列中
      if (_queue.any((task) => task.source.id == entry.download.source)) continue;
      // 获取漫画源
      final source = await ref.read(sourceByIdProvider(entry.download.source).future);
      // 如果不是在线漫画源 TODO 处理其他漫画源，如：_StubSource
      if (source is! DioHttpSource) continue;
      // 创建新的下载任务并将自动开始下载
      _startTask(DownloadTask(ref: ref, source: source, manga: entry.manga, chapter: entry.chapter, download: entry.download));
    }
    // 如果有其他下载队列请求被跳过则重新添加一次
    if (_downloads-- != 1) {
      _downloads = 0;
      await _startDownloads();
    }
  }

  /// 取消单个下载任务
  Future<void> remove(DatabaseDownload download) async {
    for (final task in _queue) {
      if (task.download.chapter == download.chapter) {
        unawaited(task.cancel());
      }
    }
  }

  /// 继续下载
  Future<void> next() async {
    if (_paused) return;
    await start();
  }

  /// 开始下载 TODO 优化代码逻辑
  Future<void> start() async {
    // 取消当前暂停状态
    _paused = false;
    await _startDownloads();
  }

  Future<void> stop() async {
    // TODO 暂停所有下载任务
  }
}

@Riverpod(keepAlive: true)
DownloadManager downloadManager(DownloadManagerRef ref) {
  return DownloadManager._(ref: ref);
}
