import 'dart:io';

import 'package:path/path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

part 'downloaded_info_provider.g.dart';

@riverpod
class DownloadedChapters extends _$DownloadedChapters {
  @override
  Set<String> build(String path) {
    // 获取漫画下载文件夹
    final directory = Directory(path);
    // 已下载本地章节列表
    final chapters = <String>{};
    // 下载路径不存在
    if (!directory.existsSync()) return chapters;
    // 遍历本地文件列表
    for (final entity in directory.listSync(recursive: false, followLinks: false)) {
      // 筛选文件夹
      if (entity is! Directory) continue;
      // 获取文件夹名称
      final name = basename(entity.path).trim();
      // 排除临时文件夹
      if (name.isNotEmpty && !name.startsWith(App.prefixTemp)) chapters.add(name);
    }
    return chapters;
  }

  void update(String chapter) {
    if (chapter.isEmpty) return;
    final exists = Directory(join(path, chapter)).existsSync();
    if (exists && !state.contains(chapter)) {
      state = {...state..add(chapter)};
    } else if (!exists && state.contains(chapter)) {
      state = {...state..remove(chapter)};
    }
  }
}

@riverpod
class DownloadedImages extends _$DownloadedImages {
  @override
  List<LocalSourceImage> build(String path) {
    // 获取章节下载文件夹
    final directory = Directory(path);
    // 已下载本地图片列表
    final images = <LocalSourceImage>[];
    // 章节下载文件夹不存在
    if (!directory.existsSync()) return images;
    // 遍历本地文件列表
    for (final entity in directory.listSync(recursive: false, followLinks: false)) {
      // 筛选文件
      if (entity is File) images.add(LocalSourceImage(url: entity.path));
    }
    return images;
  }
}
