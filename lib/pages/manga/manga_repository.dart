import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';

part 'manga_repository.g.dart';

class MangaRepository {
  const MangaRepository._(this.database);

  final TsukuyomiDatabase database;

  Future<int> insertManga(MangaTableCompanion manga) async {
    return await database.into(database.mangaTable).insert(manga);
  }

  Future<int> updateManga(MangaTableCompanion manga) async {
    await database.update(database.mangaTable).replace(manga);
    return manga.id.value;
  }

  Future<DatabaseManga?> queryMangaOrNull(int source, String url) {
    final query = database.select(database.mangaTable);
    query.where((row) => row.source.equals(source));
    query.where((row) => row.url.equals(url));
    return query.getSingleOrNull();
  }

  Future<DatabaseManga> queryManga(int mangaId) {
    final query = database.select(database.mangaTable);
    query.where((tbl) => tbl.id.equals(mangaId));
    return query.getSingle();
  }

  Stream<DatabaseManga> watchManga(int mangaId) {
    final query = database.select(database.mangaTable);
    query.where((tbl) => tbl.id.equals(mangaId));
    return query.watchSingle();
  }

  Stream<List<DatabaseChapter>> watchChapters(int mangaId) {
    final query = database.select(database.chapterTable);
    query.where((tbl) => tbl.manga.equals(mangaId));
    return query.watch();
  }
}

@riverpod
MangaRepository mangaRepository(MangaRepositoryRef ref) {
  return MangaRepository._(ref.watch(databaseProvider));
}
