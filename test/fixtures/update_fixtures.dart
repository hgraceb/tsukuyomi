import 'dart:async';

import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi/source/delegate/source_stub.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

DatabaseManga mangaFixture(int id, {int source = 1}) => DatabaseManga(
  id: id,
  source: source,
  url: 'manga-url-$id',
  title: 'manga-title-$id',
  cover: 'manga-cover',
  favorite: true,
  auto: true,
  lastCheckAt: null,
);

List<DatabaseChapter> chaptersFixture(int mangaId, {int total = 7, int publicCount = 5}) => [
  for (var id = 1; id <= total; id++)
    DatabaseChapter(
      id: mangaId * 10000 + id,
      manga: mangaId,
      index: id,
      title: 'chapter-title-$id',
      url: 'chapter-url-$mangaId-$id',
      date: 'chapter-date',
      public: id <= publicCount,
      images: 0,
      progress: 0,
    ),
];

UpdateReport updateReportFixture({
  UpdatePhase phase = UpdatePhase.finished,
  int totalTargets = 2,
  List<UpdateReportItem> items = const [],
  String? message,
}) => UpdateReport(
  version: UpdateReport.currentVersion,
  phase: phase,
  scanKind: UpdateScanKind.full,
  sessionId: 'scan-session',
  totalTargets: totalTargets,
  items: items,
  startedAt: DateTime(2026, 10, 7, 18),
  message: message,
);

UpdateReportItem updateReportItemFixture(int id) => UpdateReportItem(
  sourceId: 1,
  sourceName: 'source-name',
  mangaId: id,
  mangaTitle: 'manga-title-$id',
  outcome: UpdateOutcome.updated,
  insertCount: 1,
  deleteCount: 0,
  updateCount: 0,
  sourceCount: 7,
  enqueuedCount: 2,
  enqueueFailedCount: 0,
  skippedDownloaded: 2,
  skippedQueued: 1,
  skippedUnavailable: 2,
  failedChapters: [],
);

class UpdateSourceFixture extends NoInstalledSource {
  UpdateSourceFixture({
    int id = 1,
    this.chapters = const [HttpSourceChapter(url: 'chapter-url', name: 'chapter-title', date: 'chapter-date')],
    this.error,
    this.pending,
  }) : super(id);

  final Iterable<SourceChapter> chapters;
  final Object? error;
  final Future<void>? pending;
  final _requested = Completer<void>();
  int calls = 0;

  Future<void> get requested => _requested.future;

  @override
  String get name => 'source-name';

  @override
  Future<Iterable<SourceChapter>> getMangaChapters(SourceManga manga) async {
    calls++;
    if (!_requested.isCompleted) _requested.complete();
    await pending;
    if (error != null) throw error!;
    return chapters;
  }
}
