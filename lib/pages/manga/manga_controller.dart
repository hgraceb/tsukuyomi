import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/extension/extension.dart';
import 'package:tsukuyomi/pages/chapter/chapter_service.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/providers/providers.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

part 'manga_controller.freezed.dart';

part 'manga_controller.g.dart';

/// 漫画页面控制器
@riverpod
class MangaController extends _$MangaController with AsyncNotifierMixin {
  Set<String> _downloaded = {};
  List<DatabaseChapter> _chapters = [];
  List<DatabaseDownload> _downloads = [];
  List<DownloadTask> _downloading = [];

  @override
  Future<MangaState> build(String mangaId) async {
    final manga = await listenAsync(
      provider: mangaStreamByIdProvider(int.parse(mangaId)),
      update: (state, data) => state.copyWith(manga: data),
    );
    final source = await listenAsync(
      provider: sourceByIdProvider(manga.source),
      update: (state, data) => state.copyWith(source: data),
    );
    _chapters = await listenAsync(
      provider: chaptersStreamByMangaProvider(manga.id),
      update: (state, data) {
        _chapters = data;
        return state.copyWith(chapters: _getMangaChapters());
      },
    );
    _downloads = await listenAsync(
      provider: downloadsStreamByMangaProvider(manga.id),
      update: (state, data) {
        _downloads = data;
        return state.copyWith(chapters: _getMangaChapters());
      },
    );
    _downloading = await listenAsync(
      provider: downloadingByMangaProvider(manga.id),
      update: (state, data) {
        _downloading = data;
        return state.copyWith(chapters: _getMangaChapters());
      },
    );
    _downloaded = await listenAsync(
      provider: downloadedByMangaProvider(source, manga),
      update: (state, data) {
        _downloaded = data;
        return state.copyWith(chapters: _getMangaChapters());
      },
    );
    return MangaState(
      manga: manga,
      source: source,
      chapters: _getMangaChapters(),
    );
  }

  // TODO 测试数据量较多时是否需要放到 compute 中执行、节流或防抖处理
  List<MangaChapter> _getMangaChapters() {
    if (_chapters.isEmpty) return [];
    return _chapters.map((chapter) {
      // 等待下载的章节
      final download = _downloads.firstWhereOrNull((download) => download.chapter == chapter.id);
      // 正在下载的章节
      final downloading = _downloading.firstWhereOrNull((task) => task.download.chapter == chapter.id)?.download;
      // 章节是否已下载
      final downloaded = _downloaded.contains(chapter.title);
      // 章节是否可观看
      final enabled = downloaded || chapter.public;
      // 章节下载的进度
      double? downloadPercent = downloading != null ? 0.0 : null;
      if (downloaded == true) {
        downloadPercent = 1.0;
      } else if (downloading != null && downloading.total > 0) {
        downloadPercent = clampDouble(downloading.progress / downloading.total, 0.0, 1.0);
      }
      return MangaChapter(chapter: chapter, download: download, downloaded: downloaded, enabled: enabled, downloadPercent: downloadPercent);
    }).toList(growable: false);
  }

  // TODO 判断如何在不进行多次调用的情况下刷新已下载章节数据，如：添加等待刷新的标志位、监听本地文件修改等等
  Future<void> refreshChapters() async {
    if (data == null) return;
    try {
      await ref.read(chapterServiceProvider).syncWithSource(data!.source, data!.manga);
      await ref.read(downloadServiceProvider).refreshDownloadedByManga(data!.source, data!.manga);
    } catch (error, stackTrace) {
      handlerError(error, stackTrace);
    }
  }

  Future<void> insertDownload(DatabaseChapter chapter) async {
    if (data == null) return;
    try {
      await ref.read(downloadServiceProvider).insertDownload(data!.source.id, chapter);
    } catch (error, stackTrace) {
      handlerError(error, stackTrace);
    }
  }

  Future<void> deleteDownload(DatabaseDownload download) async {
    try {
      await ref.read(downloadServiceProvider).deleteDownload(download);
    } catch (error, stackTrace) {
      handlerError(error, stackTrace);
    }
  }

  Future<void> resumeDownload(DatabaseDownload download) async {
    try {
      await ref.read(downloadServiceProvider).resumeDownload(download);
    } catch (error, stackTrace) {
      handlerError(error, stackTrace);
    }
  }

  /// 切换漫画收藏状态
  Future<void> toggleFavorite(DatabaseManga manga) async {
    try {
      await ref.read(mangaServiceProvider).updateManga(manga.copyWith(favorite: !manga.favorite));
    } catch (error, stackTrace) {
      handlerError(error, stackTrace);
    }
  }
}

@freezed
class MangaChapter with _$MangaChapter {
  const factory MangaChapter({
    required DatabaseChapter chapter,
    required DatabaseDownload? download,
    required bool downloaded,
    required bool enabled,
    required double? downloadPercent,
  }) = _MangaChapter;
}

@freezed
class MangaState with _$MangaState {
  const factory MangaState({
    required Source source,
    required DatabaseManga manga,
    required List<MangaChapter> chapters,
  }) = _MangaState;
}
