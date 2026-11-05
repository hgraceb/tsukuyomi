import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';

part 'chapter_repository.g.dart';

class ChapterRepository {
  const ChapterRepository._(this.database);

  final TsukuyomiDatabase database;

  Future<List<DatabaseChapter>> queryChaptersByMangaId(int mangaId) {
    final query = database.select(database.chapterTable);
    query.where((tbl) => tbl.manga.equals(mangaId));
    return query.get();
  }

  Stream<DatabaseChapter> watchChapter(int chapterId) {
    final query = database.select(database.chapterTable);
    query.where((tbl) => tbl.id.equals(chapterId));
    return query.watchSingle();
  }

  Future<bool> updateChapter(ChapterTableCompanion chapter) async {
    final query = database.update(database.chapterTable);
    query.whereSamePrimaryKey(chapter);
    return await query.write(chapter) > 0;
  }

  Future<void> batch({Iterable<int>? deletes, Iterable<ChapterTableCompanion>? inserts, Iterable<ChapterTableCompanion>? updates}) {
    return database.batch((batch) {
      if (deletes != null && deletes.isNotEmpty) batch.deleteWhere(database.chapterTable, (row) => row.id.isIn(deletes));
      if (inserts != null && inserts.isNotEmpty) batch.insertAll(database.chapterTable, inserts);
      if (updates != null) {
        for (final chapter in updates) {
          batch.update(database.chapterTable, chapter, where: (row) => row.id.equals(chapter.id.value));
        }
      }
    });
  }
}

@riverpod
ChapterRepository chapterRepository(ChapterRepositoryRef ref) {
  return ChapterRepository._(ref.watch(databaseProvider));
}
