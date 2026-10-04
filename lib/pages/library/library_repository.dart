import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';

part 'library_repository.g.dart';

class LibraryRepository {
  const LibraryRepository._(this.database);

  final TsukuyomiDatabase database;

  Stream<List<DatabaseManga>> watchFavoriteMangas() {
    final query = database.select(database.mangaTable);
    query.where((row) => row.favorite.equals(true));
    return query.watch();
  }

  /// 全局扫描目标：收藏且标记自动下载的漫画（一次性查询，partial 时仅限指定 id）
  Future<List<DatabaseManga>> queryAutoMangas({List<int>? mangaIds}) {
    final query = database.select(database.mangaTable);
    query.where((row) => row.favorite.equals(true) & row.auto.equals(true));
    if (mangaIds != null) query.where((row) => row.id.isIn(mangaIds));
    return query.get();
  }
}

@riverpod
LibraryRepository libraryRepository(LibraryRepositoryRef ref) {
  return LibraryRepository._(ref.watch(databaseProvider));
}
