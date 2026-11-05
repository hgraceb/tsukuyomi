import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/providers/error/error_handler_provider.dart';
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
  message: 'scan-message',
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
      skippedUnavailable: 10,
      failedChapters: const ['chapter-url'],
      updatedAt: DateTime(2020, 1, 2, 3, 5),
      message: 'message',
    ),
  ],
);

ProviderContainer _container(SharedPreferences preferences, {_Errors? errors}) {
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      if (errors != null) errorHandlerProvider.overrideWithValue(errors),
    ],
  );
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

  for (final (reason, invalid) in [
    ('malformed JSON', '{'),
    ('wrong root type', '[]'),
    ('missing required fields', '{}'),
    ('unknown outcome', jsonEncode(_report('invalid').toJson()).replaceFirst('enqueueFailed', 'removedOutcome')),
    ('wrong field type', jsonEncode(_report('invalid').toJson()).replaceFirst('"totalTargets":1', '"totalTargets":"invalid"')),
  ]) {
    test('Unreadable report is discarded and a new save can replace it: $reason', () async {
      SharedPreferences.setMockInitialValues({Keys.updateReportLatest: invalid});
      final preferences = await SharedPreferences.getInstance();
      final errors = _Errors();
      final container = _container(preferences, errors: errors);

      expect(container.read(updateReportStoreProvider), isNull);
      expect(errors.errors, hasLength(1));

      final report = _report('recovered');
      await container.read(updateReportStoreProvider.notifier).save(report);
      expect(_container(preferences).read(updateReportStoreProvider), report);
    });
  }

  test('Save JSON and restore the complete report in a new container', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = _container(preferences);
    final report = _report('session-id');

    await container.read(updateReportStoreProvider.notifier).save(report);
    expect(container.read(updateReportStoreProvider), report);
    final json = jsonDecode(preferences.getString(Keys.updateReportLatest)!);
    expect(json['items'].single['mangaTitle'], 'manga-title');
    final restored = _container(preferences);
    expect(restored.read(updateReportStoreProvider), report);
  });

  test('Updates compose on the latest report before pending saves complete', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = _container(preferences);
    final store = container.read(updateReportStoreProvider.notifier);
    final report = _report('session-id');
    final first = store.save(report);
    final second = store.update(report.sessionId, (current) => current.copyWith(totalTargets: 3));
    final third = store.update(report.sessionId, (current) => current.copyWith(message: 'new-message'));

    await Future.wait([first, second, third]);

    final expected = report.copyWith(totalTargets: 3, message: 'new-message');
    expect(container.read(updateReportStoreProvider), expected);
    expect(_container(preferences).read(updateReportStoreProvider), expected);
  });

  test('Updates for a missing or replaced scan do not change the report', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = _container(preferences);
    final store = container.read(updateReportStoreProvider.notifier);
    var calls = 0;
    UpdateReport update(UpdateReport report) {
      calls++;
      return report.copyWith(totalTargets: 5);
    }

    await store.update('old-session', update);
    expect(container.read(updateReportStoreProvider), isNull);
    final report = _report('new-session');
    await store.save(report);
    await store.update('old-session', update);

    expect(calls, 0);
    expect(container.read(updateReportStoreProvider), report);
    expect(_container(preferences).read(updateReportStoreProvider), report);
  });

  test('Saves keep their order and continue after a storage failure', () async {
    final preferences = _Preferences();
    final container = _container(preferences);
    final store = container.read(updateReportStoreProvider.notifier);
    final first = store.save(_report('first-session'));
    final failed = expectLater(first, throwsStateError);
    final secondReport = _report('second-session');
    final second = store.save(secondReport);

    await preferences.waitForSave(1);
    expect(preferences.savedSessions, ['first-session']);
    preferences.pending.single.complete(false);
    await failed;
    await preferences.waitForSave(2);
    expect(preferences.savedSessions, ['first-session', 'second-session']);
    preferences.pending.last.complete(true);
    await second;
    expect(container.read(updateReportStoreProvider), secondReport);
  });

  test('Debug report reads and writes preserve the Release report', () async {
    final release = jsonEncode(_report('release-session').toJson());
    final debug = _report('debug-session');
    SharedPreferences.setMockInitialValues({
      'update.report.latest': release,
      'debug.update.report.latest': jsonEncode(debug.toJson()),
    });
    final preferences = await SharedPreferences.getInstance();
    final container = _container(preferences);
    expect(container.read(updateReportStoreProvider), debug);

    final updated = _report('updated-debug-session');
    await container.read(updateReportStoreProvider.notifier).save(updated);
    await preferences.reload();
    expect(_container(preferences).read(updateReportStoreProvider), updated);
    expect(preferences.getString('update.report.latest'), release);
  });

  test('Restore a running report as interrupted and retain completed results', () async {
    final report = _report('unfinished-session').copyWith(
      phase: UpdatePhase.running,
      scanKind: UpdateScanKind.full,
      totalTargets: 3,
      finishedAt: null,
    );
    final unfinished = report.copyWith(
      items: [
        ...report.items,
        report.items.single.copyWith(mangaId: 3, outcome: UpdateOutcome.pending),
        report.items.single.copyWith(mangaId: 4, outcome: UpdateOutcome.checking),
      ],
    );
    SharedPreferences.setMockInitialValues({Keys.updateReportLatest: jsonEncode(unfinished.toJson())});
    final preferences = await SharedPreferences.getInstance();
    final container = _container(preferences);

    final restored = container.read(updateReportStoreProvider)!;
    expect(restored.phase, UpdatePhase.interrupted);
    expect(restored.items.first, report.items.single);
    expect(restored.items.skip(1).map((item) => item.outcome), [UpdateOutcome.unchecked, UpdateOutcome.unchecked]);
    expect(restored.totalTargets, 3);
    expect(restored.finishedAt, isNull);
    await container.read(updateReportStoreProvider.notifier).save(restored);
    expect(_container(preferences).read(updateReportStoreProvider), restored);
  });
}

class _Errors implements ErrorHandler {
  final errors = <Object>[];

  @override
  void print(Object error, [StackTrace? stackTrace]) => errors.add(error);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Preferences implements SharedPreferences {
  final List<String> savedSessions = [];
  final List<Completer<bool>> pending = [];
  final _started = <int, Completer<void>>{};

  Future<void> waitForSave(int count) => _started.putIfAbsent(count, Completer<void>.new).future;

  @override
  String? getString(String key) => null;

  @override
  Future<bool> setString(String key, String value) {
    savedSessions.add((jsonDecode(value) as Map<String, dynamic>)['sessionId'] as String);
    final save = Completer<bool>();
    pending.add(save);
    _started.putIfAbsent(savedSessions.length, Completer<void>.new).complete();
    return save.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
