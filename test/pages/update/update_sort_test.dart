import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/pages/update/update_controller.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

import '../../fixtures/update_fixtures.dart';

void main() {
  test('Every outcome belongs to its intended filter, and pending items only appear in all', () {
    final outcomes = [
      UpdateOutcome.updated,
      UpdateOutcome.networkError,
      UpdateOutcome.progressError,
      UpdateOutcome.noUpdate,
      UpdateOutcome.enqueueFailed,
      UpdateOutcome.chaptersEmpty,
      UpdateOutcome.sourceUnavailable,
      UpdateOutcome.parseError,
      UpdateOutcome.storageError,
      UpdateOutcome.skipped,
      UpdateOutcome.unchecked,
    ];
    final items = [for (var i = 0; i < outcomes.length; i++) updateReportItemFixture(i + 1).copyWith(outcome: outcomes[i])];
    expect(items.where(UpdateFilter.failure.matches).map((item) => item.mangaId), [2, 5, 6, 7, 8, 9]);
    expect(items.where(UpdateFilter.warning.matches).map((item) => item.mangaId), [3, 10, 11]);
    expect(items.where(UpdateFilter.success.matches).map((item) => item.mangaId), [1, 4]);
    expect(items.where(UpdateFilter.all.matches), items);
    for (final item in items) {
      expect([UpdateFilter.failure, UpdateFilter.warning, UpdateFilter.success].where((filter) => filter.matches(item)), hasLength(1));
    }
    for (final outcome in [UpdateOutcome.pending, UpdateOutcome.checking]) {
      final item = updateReportItemFixture(1).copyWith(outcome: outcome);
      expect(UpdateFilter.values.where((filter) => filter.matches(item)), [UpdateFilter.all]);
    }
    expect([...outcomes, UpdateOutcome.pending, UpdateOutcome.checking], unorderedEquals(UpdateOutcome.values));
  });

  test('Names sort before ids without modifying report order or counts', () {
    final items = [
      updateReportItemFixture(1).copyWith(sourceId: 2, sourceName: 'Alpha', mangaTitle: 'B'),
      updateReportItemFixture(2).copyWith(sourceId: 2, sourceName: 'Alpha', mangaTitle: 'A'),
      updateReportItemFixture(3).copyWith(sourceId: 3, sourceName: 'Zulu', mangaTitle: 'A'),
      updateReportItemFixture(4).copyWith(sourceId: 1, sourceName: 'Alpha', mangaTitle: 'A'),
      updateReportItemFixture(5).copyWith(sourceId: 1, sourceName: 'Alpha', mangaTitle: 'A'),
    ];

    final report = updateReportFixture(items: items);
    final json = report.toJson();
    final sorted = [...report.items]..sort(compareUpdateItems);
    expect(sorted.map((item) => item.mangaId), [4, 5, 2, 1, 3]);
    expect(report.toJson(), json);
    expect(items.map((item) => item.mangaId), [1, 2, 3, 4, 5]);
  });
}
