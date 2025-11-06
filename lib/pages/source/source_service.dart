import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/source/source_repository.dart';
import 'package:tsukuyomi/providers/providers.dart';
import 'package:tsukuyomi/source/source.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

part 'source_service.g.dart';

class SourceService {
  const SourceService._(this.repository);

  final SourceRepository repository;

  Future<DatabaseSource?> getSourceOrNull(int sourceId) {
    return repository.querySourceOrNull(sourceId);
  }

  Stream<List<DatabaseSource>> watchSources() {
    return repository.watchSources();
  }
}

@riverpod
SourceService sourceService(SourceServiceRef ref) {
  return SourceService._(ref.watch(sourceRepositoryProvider));
}

@riverpod
Stream<List<DatabaseSource>> sourcesStream(SourcesStreamRef ref) {
  return ref.watch(sourceServiceProvider).watchSources();
}

@riverpod
Future<SourcePage<SourceManga>> searchMangas(SearchMangasRef ref, Source source, SourceQuery query) async {
  final page = await source.getSourceMangas(query);
  if (page.data.isEmpty) throw const TsukuyomiSourceException.mangasNotFound('search');
  return page..query = query;
}

@riverpod
Future<Source> sourceById(SourceByIdRef ref, int sourceId) async {
  // TODO 如果获取成功则设置漫画源缓存时间
  final source = await ref.watch(sourceServiceProvider).getSourceOrNull(sourceId);
  if (source == null) return NoInstalledSource(sourceId);
  const main = 'main() => TsukuyomiSource();';
  // TODO 漫画源解析错误处理、修改漫画源代码压缩和解压缩方式，如：使用 zip 或者 7z 压缩算法
  final delegate = await compute((_) => eval('${utf8.decode(base64.decode(source.source))}\n$main', libraries: evalLibraries), null);
  return IsolateDioHttpSource(delegate: delegate, preferences: ref.read(sharedPreferencesProvider));
}
