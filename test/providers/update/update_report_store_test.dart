import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

UpdateReport _report(String sessionId) => UpdateReport(
  version: UpdateReport.currentVersion,
  phase: UpdatePhase.finished,
  scanKind: UpdateScanKind.partial,
  sessionId: sessionId,
  totalTargets: 1,
  startedAt: DateTime(2020, 1, 2, 3, 4),
  finishedAt: DateTime(2020, 1, 2, 3, 5),
  items: [
    UpdateReportItem(
      sourceId: 1,
      sourceName: 'source-name',
      mangaId: 2,
      mangaTitle: 'manga-title',
      outcome: UpdateOutcome.enqueueFailed,
      insertCount: 3,
      deleteCount: 4,
      updateCount: 5,
      sourceCount: 6,
      enqueuedCount: 7,
      enqueueFailedCount: 1,
      skippedDownloaded: 8,
      skippedQueued: 9,
      failedChapters: const ['chapter-url'],
      updatedAt: DateTime(2020, 1, 2, 3, 5),
      message: 'message',
    ),
  ],
);

ProviderContainer _container(SharedPreferences preferences) {
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Read no report before the first save', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    expect(_container(preferences).read(updateReportStoreProvider), isNull);
  });

  test('Save JSON and restore the complete report in a new container', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = _container(preferences);
    final report = _report('session-id');

    await container.read(updateReportStoreProvider.notifier).save(report);
    expect(container.read(updateReportStoreProvider), report);
    final json = jsonDecode(preferences.getString(UpdateReportStore.reportKey)!);
    expect(json['items'].single['mangaTitle'], 'manga-title');
    final restored = _container(preferences);
    expect(restored.read(updateReportStoreProvider), report);
  });

  test('Saves keep their order and continue after a storage failure', () async {
    final preferences = _Preferences();
    final container = _container(preferences);
    final store = container.read(updateReportStoreProvider.notifier);
    final first = store.save(_report('first-session'));
    final failed = expectLater(first, throwsStateError);
    final secondReport = _report('second-session');
    final second = store.save(secondReport);

    await Future<void>.delayed(Duration.zero);
    expect(preferences.savedSessions, ['first-session']);
    preferences.pending.single.complete(false);
    await failed;
    await Future<void>.delayed(Duration.zero);
    expect(preferences.savedSessions, ['first-session', 'second-session']);
    preferences.pending.last.complete(true);
    await second;
    expect(container.read(updateReportStoreProvider), secondReport);
  });
}

class _Preferences implements SharedPreferences {
  final List<String> savedSessions = [];
  final List<Completer<bool>> pending = [];

  @override
  String? getString(String key) => null;

  @override
  Future<bool> setString(String key, String value) {
    savedSessions.add((jsonDecode(value) as Map<String, dynamic>)['sessionId'] as String);
    final save = Completer<bool>();
    pending.add(save);
    return save.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
