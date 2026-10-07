import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';

part 'update_progress_provider.g.dart';

/// 按漫画 id 监听本地已下载章节
@riverpod
Future<Set<String>> updateDownloadedChapters(UpdateDownloadedChaptersRef ref, int mangaId) async {
  final manga = await ref.watch(mangaStreamByIdProvider(mangaId).future);
  final source = await ref.watch(sourceByIdProvider(manga.source).future);
  return ref.watch(downloadedByMangaProvider(source, manga).future);
}
