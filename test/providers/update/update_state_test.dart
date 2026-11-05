import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

void main() {
  test('Empty source is a retryable failure and does not expose stale local progress', () {
    expect(UpdateOutcome.chaptersEmpty.isFailure, isTrue);
    expect(UpdateOutcome.chaptersEmpty.isWarning, isFalse);
    expect(UpdateOutcome.chaptersEmpty.canRetry, isTrue);
    expect(UpdateOutcome.chaptersEmpty.canReadProgress, isFalse);
  });

  test('Progress failures and interrupted or skipped checks can be retried', () {
    for (final outcome in [UpdateOutcome.progressError, UpdateOutcome.unchecked, UpdateOutcome.skipped]) {
      expect(outcome.isWarning, isTrue);
      expect(outcome.isSuccess, isFalse);
      expect(outcome.canRetry, isTrue);
    }
    for (final outcome in [UpdateOutcome.pending, UpdateOutcome.checking, UpdateOutcome.updated, UpdateOutcome.noUpdate]) {
      expect(outcome.canRetry, isFalse);
    }
    expect(UpdateOutcome.enqueueFailed.canReadProgress, isTrue);
  });

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
