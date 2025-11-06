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

  Future<void> insertDownload(Insertable<DatabaseDownload> download) async {
    await insertDownloads([download]);
  }

  Future<void> insertDownloads(Iterable<Insertable<DatabaseDownload>> downloads) async {
    if (downloads.isEmpty) return;
    await database.batch((batch) {
      batch.insertAll<DownloadTable, DatabaseDownload>(
        database.downloadTable,
        downloads,
        onConflict: DoUpdate.withExcluded(
          // 更新下载信息 TODO 判断下载错误时是否需要重置下载进度
          (old, excluded) => DownloadTableCompanion.custom(
            error: excluded.error,
            total: excluded.total,
            progress: excluded.progress,
          ),
          // 只更新下载失败的数据
          where: (old, excluded) => old.error.isNotNull(),
        ),
      );
    });
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
}

@riverpod
DownloadRepository downloadRepository(DownloadRepositoryRef ref) {
  return DownloadRepository._(ref.watch(databaseProvider));
}
