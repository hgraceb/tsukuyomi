import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';

part 'manga_repository.g.dart';

class MangaRepository {
  const MangaRepository._(this.database);

  final TsukuyomiDatabase database;

  Future<int> upsertManga(MangaTableCompanion manga) async {
    final table = database.mangaTable;
    final row = await database.into(table).insertReturning(manga, onConflict: DoUpdate((_) => manga, target: [table.source, table.url]));
    return row.id;
  }

  Future<int> updateManga(MangaTableCompanion manga) async {
    final query = database.update(database.mangaTable);
    query.whereSamePrimaryKey(manga);
    await query.write(manga.copyWith(id: const Value.absent()));
    return manga.id.value;
  }

  Future<int> updateLastCheckAt(int mangaId, DateTime checkedAt) {
    final query = database.update(database.mangaTable);
    query.where((row) => row.id.equals(mangaId));
    return query.write(MangaTableCompanion(lastCheckAt: Value(checkedAt)));
  }

  Future<DatabaseManga> queryManga(int mangaId) {
    final query = database.select(database.mangaTable);
    query.where((tbl) => tbl.id.equals(mangaId));
    return query.getSingle();
  }

  Future<DatabaseManga?> queryMangaByIdOrNull(int mangaId) {
    final query = database.select(database.mangaTable);
    query.where((row) => row.id.equals(mangaId));
    return query.getSingleOrNull();
  }

  Stream<DatabaseManga> watchManga(int mangaId) {
    final query = database.select(database.mangaTable);
    query.where((tbl) => tbl.id.equals(mangaId));
    return query.watchSingle();
  }

  Stream<List<DatabaseChapter>> watchChapters(int mangaId) {
    final query = database.select(database.chapterTable);
    query.where((tbl) => tbl.manga.equals(mangaId));
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.index), (tbl) => OrderingTerm.asc(tbl.id)]);
    return query.watch();
  }
}

@riverpod
MangaRepository mangaRepository(MangaRepositoryRef ref) {
  return MangaRepository._(ref.watch(databaseProvider));
}
