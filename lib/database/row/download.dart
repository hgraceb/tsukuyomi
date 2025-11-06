import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tsukuyomi/database/database.dart';

part 'download.freezed.dart';

@freezed
class DatabaseDownload with _$DatabaseDownload, DownloadTableToColumns {
  const DatabaseDownload._();

  const factory DatabaseDownload({
    required int source,
    required int manga,
    required int chapter,
    required int total,
    required int progress,
    required String? error,
  }) = _DatabaseDownload;
}

extension DownloadsPartitionBySourceNestedColumn0Extension on DownloadsPartitionBySourceNestedColumn0 {
  DatabaseDownload toDatabaseDownload() {
    return DatabaseDownload(
      source: source!,
      manga: manga!,
      chapter: chapter!,
      total: total!,
      progress: progress!,
      error: error,
    );
  }
}
