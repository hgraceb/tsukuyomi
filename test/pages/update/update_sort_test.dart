import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/pages/update/update_controller.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

import '../../fixtures/update_fixtures.dart';

void main() {
  test('Each completed outcome belongs to exactly one filter', () {
    final outcomes = [
      UpdateOutcome.updated,
      UpdateOutcome.networkError,
      UpdateOutcome.chaptersReduced,
      UpdateOutcome.noUpdate,
      UpdateOutcome.enqueueFailed,
      UpdateOutcome.chaptersEmpty,
      UpdateOutcome.sourceUnavailable,
      UpdateOutcome.parseError,
      UpdateOutcome.storageError,
    ];
    final items = [for (var i = 0; i < outcomes.length; i++) updateReportItemFixture(i + 1).copyWith(outcome: outcomes[i])];
    expect(items.where(UpdateFilter.failure.matches).map((item) => item.mangaId), [2, 5, 7, 8, 9]);
    expect(items.where(UpdateFilter.warning.matches).map((item) => item.mangaId), [3, 6]);
    expect(items.where(UpdateFilter.success.matches).map((item) => item.mangaId), [1, 4]);
    expect(items.where(UpdateFilter.all.matches), items);
    for (final item in items) {
      expect([UpdateFilter.failure, UpdateFilter.warning, UpdateFilter.success].where((filter) => filter.matches(item)), hasLength(1));
    }
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
