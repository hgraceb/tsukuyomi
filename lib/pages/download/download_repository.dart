import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';

part 'download_repository.freezed.dart';
part 'download_repository.g.dart';

enum DownloadInsertResult { enqueued, skippedQueued, skippedDownloaded }

@freezed
class DownloadWithExtra with _$DownloadWithExtra {
  const factory DownloadWithExtra({
    required DatabaseDownload download,
    required DatabaseChapter chapter,
    required DatabaseManga manga,
  }) = _DownloadWithExtra;

  factory DownloadWithExtra.read(TypedResult row, TsukuyomiDatabase database) => DownloadWithExtra(
    download: row.readTable(database.downloadTable),
    chapter: row.readTable(database.chapterTable),
    manga: row.readTable(database.mangaTable),
  );
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
    query.where((row) => row.error.isNotNull());
    return await query.write(const DownloadTableCompanion(error: Value(null))) > 0;
  }

  Future<bool> hasDownload(DatabaseDownload download) async {
    final query = database.select(database.downloadTable);
    query.whereSamePrimaryKey(download);
    return await query.getSingleOrNull() != null;
  }

  Future<bool> insertDownload(DownloadTableCompanion download) async {
    final query = database.into(database.downloadTable);
    final update = const DownloadTableCompanion(error: Value(null));
    return await query.insertReturningOrNull(download, onConflict: DoUpdate((_) => update, where: (row) => row.error.isNotNull())) != null;
  }

  Future<DownloadInsertResult> insertMissingDownload(DownloadTableCompanion download, Future<bool> Function() isDownloaded) {
    // 下载完成时先保存章节目录再出队，事务保证出队不会插在目录检查和写入之间
    return database.transaction(() async {
      if (await isDownloaded()) return DownloadInsertResult.skippedDownloaded;
      return await insertDownload(download) ? DownloadInsertResult.enqueued : DownloadInsertResult.skippedQueued;
    });
  }

  Future<List<DownloadWithExtra>> queryDownloadsPartitionBySource(int limit) {
    final query = database.downloadsPartitionBySource(limit);
    return query.map((row) => DownloadWithExtra(download: row.download.toDatabaseDownload(), chapter: row.chapter, manga: row.manga)).get();
  }

  Stream<List<DownloadWithExtra>> watchDownloads() {
    final download = database.downloadTable;
    final chapter = database.chapterTable;
    final manga = database.mangaTable;
    final chapterJoin = innerJoin(chapter, chapter.id.equalsExp(download.chapter));
    final mangaJoin = innerJoin(manga, manga.id.equalsExp(download.manga));
    final query = database.select(download).join([chapterJoin, mangaJoin]);
    return query.map((row) => DownloadWithExtra.read(row, database)).watch();
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
