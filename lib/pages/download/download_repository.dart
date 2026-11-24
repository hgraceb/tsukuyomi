import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';

part 'download_repository.freezed.dart';

part 'download_repository.g.dart';

@freezed
class DownloadWithExtra with _$DownloadWithExtra {
  const factory DownloadWithExtra({
    required DatabaseDownload download,
    required DatabaseChapter chapter,
    required DatabaseManga manga,
  }) = _DownloadWithExtra;
}

class DownloadRepository {
  const DownloadRepository._(this.database);

  final TsukuyomiDatabase database;

  Future<int> deleteDownload(DatabaseDownload download) async {
    return database.delete(database.downloadTable).delete(download);
  }

  Future<bool> updateDownload(DatabaseDownload download) async {
    return database.update(database.downloadTable).replace(download);
  }

  Future<bool> clearDownloadError(DatabaseDownload download) async {
    final query = database.update(database.downloadTable);
    query.whereSamePrimaryKey(download);
    return await query.write(const DownloadTableCompanion(error: Value(null))) > 0;
  }

  Future<bool> insertDownload(DownloadTableCompanion download) async {
    final query = database.into(database.downloadTable);
    final update = const DownloadTableCompanion(error: Value(null));
    return await query.insertReturningOrNull(download, onConflict: DoUpdate((_) => update, where: (row) => row.error.isNotNull())) != null;
  }

  Future<List<DownloadWithExtra>> queryDownloadsPartitionBySource(int limit) {
    return database
        .downloadsPartitionBySource(limit)
        .map((row) => DownloadWithExtra(download: row.download.toDatabaseDownload(), chapter: row.chapter, manga: row.manga))
        .get();
  }

  Stream<List<DownloadWithExtra>> watchDownloads() {
    final download = database.downloadTable;
    final chapter = database.chapterTable;
    final manga = database.mangaTable;
    return database
        .select(download)
        .join([innerJoin(chapter, chapter.id.equalsExp(download.chapter)), innerJoin(manga, manga.id.equalsExp(download.manga))])
        .map((row) => DownloadWithExtra(download: row.readTable(download), chapter: row.readTable(chapter), manga: row.readTable(manga)))
        .watch();
  }

  Stream<List<DatabaseDownload>> watchDownloadsByManga(int mangaId) {
    final query = database.select(database.downloadTable);
    query.where((tbl) => tbl.manga.equals(mangaId));
    return query.watch();
  }

  Future<List<DatabaseDownload>> queryDownloadsByManga(int mangaId) {
    final query = database.select(database.downloadTable);
    query.where((tbl) => tbl.manga.equals(mangaId));
    return query.get();
  }
}

@riverpod
DownloadRepository downloadRepository(DownloadRepositoryRef ref) {
  return DownloadRepository._(ref.watch(databaseProvider));
}
