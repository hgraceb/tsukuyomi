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
    final databaseChapters = await chapterRepository.queryChaptersByMangaId(manga.id);
    final deletes = <int>[];
    final inserts = <ChapterTableCompanion>[];
    final updates = <ChapterTableCompanion>[];

    // 获取待删除的章节列表
    deletes.addAll(databaseChapters.where((row) {
      return !sourceChapters.any((sourceChapter) => sourceChapter.url == row.url);
    }).map((row) => row.id));

    // 获取待更新和插入的章节列表 TODO 完善章节数据
    for (final sourceChapter in sourceChapters) {
      final databaseChapter = databaseChapters.firstWhereOrNull((row) => sourceChapter.url == row.url);
      if (databaseChapter == null) {
        inserts.add(sourceChapter.toInsertable(manga.id));
      } else {
        updates.add(sourceChapter.toUpdatable(databaseChapter));
      }
    }

    await chapterRepository.batch(deletes: deletes, inserts: inserts, updates: updates);
    return ChapterSyncResult(
      insertCount: inserts.length,
      deleteCount: deletes.length,
      updateCount: updates.length,
      sourceCount: sourceChapters.length,
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
