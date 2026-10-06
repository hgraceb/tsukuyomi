import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

void main() {
  test('UpdateReport serialization', () {
    final report = UpdateReport(
      version: UpdateReport.currentVersion,
      phase: UpdatePhase.finished,
      scanKind: UpdateScanKind.full,
      sessionId: 'session-id',
      totalTargets: 1,
      startedAt: DateTime(2020, 1, 2, 3, 4),
      finishedAt: DateTime(2020, 1, 2, 3, 4),
      message: 'scan-message',
      items: [
        UpdateReportItem(
          sourceId: 1,
          sourceName: 'source-name',
          mangaId: 2,
          mangaTitle: 'manga-title',
          outcome: UpdateOutcome.noUpdate,
          insertCount: 3,
          deleteCount: 4,
          updateCount: 5,
          sourceCount: 6,
          enqueuedCount: 7,
          enqueueFailedCount: 8,
          skippedDownloaded: 9,
          skippedQueued: 10,
          skippedUnavailable: 11,
          failedChapters: const ['chapter-url'],
          updatedAt: DateTime(2020, 1, 2, 3, 4),
          message: 'message',
        ),
      ],
    );
    final back = UpdateReport.fromJson(report.toJson());
    expect(back, report);
  });
}
