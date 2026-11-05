import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/chapter/chapter_repository.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

part 'chapter_sync_with_source.freezed.dart';
part 'chapter_sync_with_source.g.dart';

class ChapterSyncWithSource {
  ChapterSyncWithSource._({required this.source, required this.manga, required this.chapterRepository});

  final Source source;

  final DatabaseManga manga;

  final ChapterRepository chapterRepository;

  Future<ChapterSyncResult> sync() async {
    final sourceChapters = await source.getMangaChapters(manga.toHttpSourceManga());
    return apply(sourceChapters);
  }

  Future<ChapterSyncResult> apply(Iterable<SourceChapter> sourceChapters) async {
    // 同一漫画内按 URL 识别章节，重复项保留源返回的第一项
    final chapterUrls = <String>{};
    final chapters = sourceChapters.where((chapter) => chapterUrls.add(chapter.url)).toList(growable: false);
    // 空返回可能是源失效，保留本地章节和关联数据
    if (chapters.isEmpty) {
      return const ChapterSyncResult(insertCount: 0, deleteCount: 0, updateCount: 0, sourceCount: 0);
    }
    final databaseChapters = await chapterRepository.queryChaptersByMangaId(manga.id);
    final deletes = <int>[];
    final inserts = <ChapterTableCompanion>[];
    final updates = <ChapterTableCompanion>[];
    // 仅统计内容变化，位置调整不计为章节更新
    var updateCount = 0;

    // 获取待删除的章节列表
    final deletedChapters = databaseChapters.where((row) => !chapterUrls.contains(row.url));
    deletes.addAll(deletedChapters.map((row) => row.id));

    // 获取待更新和插入的章节列表 TODO 完善章节数据
    for (final (index, sourceChapter) in chapters.indexed) {
      final databaseChapter = databaseChapters.firstWhereOrNull((row) => sourceChapter.url == row.url);
      if (databaseChapter == null) {
        inserts.add(sourceChapter.toInsertable(manga.id, index: index));
      } else {
        final update = sourceChapter.toUpdatable(databaseChapter.id);
        final titleChanged = update.title.value != databaseChapter.title;
        final dateChanged = update.date.value != databaseChapter.date;
        final publicChanged = update.public.value != databaseChapter.public;
        if (titleChanged || dateChanged || publicChanged) {
          updates.add(update.copyWith(index: Value(index)));
          updateCount++;
        } else if (databaseChapter.index != index) {
          updates.add(ChapterTableCompanion(id: Value(databaseChapter.id), index: Value(index)));
        }
      }
    }

    await chapterRepository.batch(deletes: deletes, inserts: inserts, updates: updates);
    return ChapterSyncResult(
      insertCount: inserts.length,
      deleteCount: deletes.length,
      updateCount: updateCount,
      sourceCount: chapters.length,
    );
  }
}

@riverpod
ChapterSyncWithSource chapterSyncWithSource(ChapterSyncWithSourceRef ref, Source source, DatabaseManga manga) {
  return ChapterSyncWithSource._(source: source, manga: manga, chapterRepository: ref.watch(chapterRepositoryProvider));
}

@freezed
class ChapterSyncResult with _$ChapterSyncResult {
  const factory ChapterSyncResult({
    required int insertCount,
    required int deleteCount,
    required int updateCount,
    required int sourceCount,
  }) = _ChapterSyncResult;
}
