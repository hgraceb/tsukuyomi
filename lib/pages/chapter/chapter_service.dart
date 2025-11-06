import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

import 'chapter_repository.dart';
import 'providers/chapter_sync_with_source.dart';

part 'chapter_service.g.dart';

class ChapterService {
  ChapterService._({required this.ref});

  final ChapterServiceRef ref;

  Future<bool> updateChapter(DatabaseChapter chapter) {
    return ref.read(chapterRepositoryProvider).updateChapter(chapter.toUpdatable());
  }

  Future<void> syncWithSource(Source source, DatabaseManga manga) async {
    await ref.read(chapterSyncWithSourceProvider(source, manga)).sync();
  }
}

@riverpod
ChapterService chapterService(ChapterServiceRef ref) {
  return ChapterService._(ref: ref);
}

@riverpod
Stream<DatabaseChapter> chapterStreamById(ChapterStreamByIdRef ref, int chapterId) {
  return ref.watch(chapterRepositoryProvider).watchChapter(chapterId);
}

@riverpod
Future<List<SourceImage>> chapterImages(ChapterImagesRef ref, Source source, DatabaseManga manga, DatabaseChapter chapter) async {
  final directory = await ref.read(downloadServiceProvider).getChapterDir(source, manga, chapter);
  final images = switch (directory.existsSync()) {
    true => await ref.read(downloadedByChapterProvider(source, manga, chapter).future),
    false => await source.getChapterImages(chapter.toHttpSourceChapter()),
  };
  // 章节图片列表获取失败
  if (images.isEmpty) throw TsukuyomiDownloadException.imagesNotFound(chapter.title);
  // 更新当前章节下载状态
  await ref.read(downloadServiceProvider).refreshDownloadedByChapter(source, manga, chapter);
  // 返回章节图片列表信息
  return images.toList(growable: false);
}
