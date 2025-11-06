import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

part 'download_path_provider.g.dart';

@riverpod
class DownloadMangaPath extends _$DownloadMangaPath {
  @override
  Future<Directory> build(Source source, DatabaseManga manga) async {
    // 设备文档文件夹路径
    final documents = await getApplicationDocumentsDirectory();
    // 应用下载文件夹路径
    final downloads = join(documents.path, App.name, App.downloadsPath);
    // 漫画下载文件夹路径
    return Directory(join(downloads, source.name, manga.title));
  }
}

@riverpod
class DownloadChapterPath extends _$DownloadChapterPath {
  @override
  Future<Directory> build(Source source, DatabaseManga manga, DatabaseChapter chapter) async {
    // 获取漫画下载文件夹路径
    final directory = await ref.watch(downloadMangaPathProvider(source, manga).future);
    // 漫画章节下载文件夹路径
    return Directory(join(directory.path, chapter.title));
  }
}

@riverpod
class DownloadChapterTempPath extends _$DownloadChapterTempPath {
  @override
  Future<Directory> build(Source source, DatabaseManga manga, DatabaseChapter chapter) async {
    // 获取漫画下载文件夹路径
    final directory = await ref.watch(downloadMangaPathProvider(source, manga).future);
    // 漫画章节下载文件夹路径
    return Directory(join(directory.path, '${App.prefixTemp}${chapter.title}'));
  }
}
