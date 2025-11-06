import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/download/download_repository.dart';
import 'package:tsukuyomi/pages/download/providers/download_path_provider.dart';
import 'package:tsukuyomi/providers/providers.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

import 'providers/downloaded_info_provider.dart';

part 'download_service.g.dart';

class DownloadService {
  DownloadService._({required this.ref});

  final DownloadServiceRef ref;

  /// 获取漫画下载文件夹路径
  Future<Directory> getMangaDir(Source source, DatabaseManga manga) {
    return ref.read(downloadMangaPathProvider(source, manga).future);
  }

  /// 获取章节下载文件夹路径
  Future<Directory> getChapterDir(Source source, DatabaseManga manga, DatabaseChapter chapter) {
    return ref.read(downloadChapterPathProvider(source, manga, chapter).future);
  }

  /// 创建章节临时文件夹路径
  Future<Directory> createTempChapterDir(Source source, DatabaseManga manga, DatabaseChapter chapter) async {
    final temp = await ref.read(downloadChapterTempPathProvider(source, manga, chapter).future);
    if (!temp.existsSync()) temp.createSync(recursive: true);
    return temp;
  }

  /// 更新章节下载数据
  Future<bool> updateDownload(DatabaseDownload download) async {
    return ref.read(downloadRepositoryProvider).updateDownload(download);
  }

  /// 继续下载章节数据
  Future<void> resumeDownload(DatabaseDownload download) async {
    await updateDownload(download.copyWith(error: null));
    await ref.read(downloadManagerProvider).next();
  }

  /// 删除章节下载数据
  Future<int> deleteDownload(DatabaseDownload download) async {
    await ref.read(downloadManagerProvider).remove(download);
    return ref.read(downloadRepositoryProvider).deleteDownload(download);
  }

  /// 插入章节下载数据
  Future<void> insertDownload(int source, DatabaseChapter chapter) async {
    await ref.read(downloadRepositoryProvider).insertDownload(chapter.toDownloadable(source));
    await ref.read(downloadManagerProvider).next();
  }

  /// 更新漫画下载状态
  Future<void> refreshDownloadedByManga(Source source, DatabaseManga manga) async {
    final chaptersDirectory = await getMangaDir(source, manga);
    ref.invalidate(downloadedChaptersProvider(chaptersDirectory.path));
  }

  /// 更新章节下载状态
  Future<void> refreshDownloadedByChapter(Source source, DatabaseManga manga, DatabaseChapter chapter) async {
    final chaptersDirectory = await getMangaDir(source, manga);
    final imagesDirectory = await getChapterDir(source, manga, chapter);
    ref.read(downloadedChaptersProvider(chaptersDirectory.path).notifier).update(chapter.title);
    ref.invalidate(downloadedImagesProvider(imagesDirectory.path));
  }

  /// 根据漫画源进行分区并查询每个分区内优先级最高的章节下载数据
  Future<List<DownloadWithExtra>> queryDownloadsPartitionBySource(int limit) {
    final downloadRepository = ref.read(downloadRepositoryProvider);
    return downloadRepository.queryDownloadsPartitionBySource(limit);
  }
}

@riverpod
DownloadService downloadService(DownloadServiceRef ref) {
  return DownloadService._(ref: ref);
}

@riverpod
Stream<List<DownloadWithExtra>> downloadsStream(DownloadsStreamRef ref) {
  return ref.read(downloadRepositoryProvider).watchDownloads();
}

@riverpod
Stream<List<DatabaseDownload>> downloadsStreamByManga(DownloadsStreamByMangaRef ref, int mangaId) {
  return ref.read(downloadRepositoryProvider).watchDownloadsByManga(mangaId);
}

@riverpod
Future<List<DownloadTask>> downloadingByManga(DownloadingByMangaRef ref, int mangaId) async {
  return ref.watch(downloadQueueProvider).where((it) => it.manga.id == mangaId).toList(growable: false);
}

@riverpod
Future<Set<String>> downloadedByManga(DownloadedByMangaRef ref, Source source, DatabaseManga manga) async {
  // 漫画下载路径
  final directory = await ref.watch(downloadMangaPathProvider(source, manga).future);
  // 监听下载漫画
  return ref.watch(downloadedChaptersProvider(directory.path));
}

@riverpod
Future<List<LocalSourceImage>> downloadedByChapter(AutoDisposeRef ref, Source source, DatabaseManga manga, DatabaseChapter chapter) async {
  // 章节下载路径
  final directory = await ref.watch(downloadChapterPathProvider(source, manga, chapter).future);
  // 监听下载章节
  return ref.watch(downloadedImagesProvider(directory.path));
}
