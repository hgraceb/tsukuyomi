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

  Future<bool> updateChapter(ChapterTableCompanion chapter) {
    return database.update(database.chapterTable).replace(chapter);
  }

  Future<void> batch({Iterable<int>? deletes, Iterable<ChapterTableCompanion>? inserts, Iterable<ChapterTableCompanion>? updates}) {
    return database.batch((batch) {
      if (deletes != null && deletes.isNotEmpty) batch.deleteWhere(database.chapterTable, (row) => row.id.isIn(deletes));
      if (inserts != null && inserts.isNotEmpty) batch.insertAll(database.chapterTable, inserts);
      if (updates != null && updates.isNotEmpty) batch.replaceAll(database.chapterTable, updates);
    });
  }
}

@riverpod
ChapterRepository chapterRepository(ChapterRepositoryRef ref) {
  return ChapterRepository._(ref.watch(databaseProvider));
}
