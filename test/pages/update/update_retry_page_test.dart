import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/pages/update/update_controller.dart';
import 'package:tsukuyomi/pages/update/update_page.dart';
import 'package:tsukuyomi/pages/update/update_retry_controller.dart';
import 'package:tsukuyomi/pages/update/update_summary.dart';
import 'package:tsukuyomi/providers/theme/theme_predefined_provider.dart';
import 'package:tsukuyomi/providers/update/update_manager.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_service.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

import '../../fixtures/update_fixtures.dart';
import '../../fixtures/update_retry_fixtures.dart';

void main() {
  setUpAll(() async {
    await TsukuyomiLocalizations.delegate.load(const Locale('zh'));
    await TsukuyomiLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets(
    'Failure actions and passive status icons retain their final native button behavior',
    (tester) async {
      final source = UpdateSourceFixture();
      final container = await createUpdateRetryContainer(
        source: source,
        mangas: UpdateMangasFixture([for (var id = 1; id <= 4; id++) mangaFixture(id)]),
        report: updateReportFixture(
          totalTargets: 4,
          items: [
            retryFailureFixture(1),
            updateReportItemFixture(2).copyWith(outcome: UpdateOutcome.skipped),
            updateReportItemFixture(3),
            updateReportItemFixture(4),
          ],
        ),
        downloaded: {1: _allChapters, 3: _allChapters},
      );
      await _pumpPage(tester, container, locale: const Locale('zh'));

      expect(find.byTooltip('重试'), findsNWidgets(2));
      expect(tester.widget<IconButton>(_button(1)).onPressed, isNotNull);
      expect(tester.widget<IconButton>(_button(1)).color, Theme.of(tester.element(_button(1))).colorScheme.error);
      expect(find.descendant(of: _row(1), matching: find.byIcon(Icons.check_circle_outline)), findsNothing);
      expect(find.descendant(of: _row(3), matching: find.byIcon(Icons.check_circle_outline)), findsOneWidget);
      expect(find.descendant(of: _row(4), matching: find.byType(AnimatedProgressCircleIcon)), findsOneWidget);
      expect(tester.widget<IconButton>(_button(2)).onPressed, isNotNull);
      expect(tester.widget<IconButton>(_button(2)).color, Theme.of(tester.element(_button(2))).colorScheme.tertiary);
      for (final id in [3, 4]) {
        expect(tester.widget<IconButton>(_button(id)).onPressed, isNull);
      }
      expect(tester.getSize(_button(1)), const Size.square(48.0));
      expect(_summaryCounts(tester), [1, 1, 2, 4]);
      expect(source.calls, 0);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.windows, TargetPlatform.android}),
  );

  testWidgets('A successful retry preserves other results, the selected filter and persisted JSON', (tester) async {
    final pending = Completer<void>();
    final source = UpdateSourceFixture(pending: pending.future);
    final previous = updateReportFixture(
      totalTargets: 3,
      items: [retryFailureFixture(1), retryFailureFixture(2), updateReportItemFixture(3)],
    );
    final downloads = UpdateDownloadsFixture();
    final container = await createUpdateRetryContainer(
      source: source,
      downloads: downloads,
      report: previous,
      mangas: UpdateMangasFixture([for (var id = 1; id <= 3; id++) mangaFixture(id)]),
    );
    await _pumpPage(tester, container);
    await tester.tap(_countButton(UpdateFilter.failure));
    await _pumpFrames(tester);

    await tester.tap(_button(1));
    await tester.pump();
    await _pumpUntil(tester, () => source.calls == 1);
    expect(_busyIcon(1), findsOneWidget);
    expect(tester.widget<IconButton>(_button(1)).onPressed, isNull);
    expect(tester.widget<IconButton>(_button(2)).onPressed, isNotNull);
    expect(find.widgetWithIcon(FloatingActionButton, Icons.sync_outlined), findsOneWidget);
    await container.read(updateRetryControllerProvider(1).notifier).retry();
    expect(source.calls, 1);

    pending.complete();
    await _pumpFrames(tester);

    final report = container.read(updateReportStoreProvider)!;
    expect(report, previous.copyWith(items: [report.items.first, previous.items[1], previous.items[2]]));
    expect(report.items.first.outcome, UpdateOutcome.updated);
    expect(readUpdateReportFixture(container), report);
    expect(container.read(updateControllerProvider), UpdateFilter.failure);
    expect(_row(1), findsNothing);
    expect(_row(2), findsOneWidget);
    expect(_summaryCounts(tester), [1, 0, 2, 3]);
    expect(downloads.mangas.map((manga) => manga.id), [1]);

    await tester.tap(_countButton(UpdateFilter.all));
    await _pumpFrames(tester);
    expect(_row(1), findsOneWidget);
    expect(_row(2), findsOneWidget);
    expect(_row(3), findsOneWidget);
    expect(_busyIcon(1), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A failed retry remains actionable and can recover through the real controller', (tester) async {
    final source = UpdateSourceFixture();
    final downloads = UpdateDownloadsFixture()..errors[1] = StateError('queue-error');
    final sync = UpdateSyncFixture();
    final previous = updateReportFixture(items: [retryFailureFixture(1), updateReportItemFixture(2)]);
    final container = await createUpdateRetryContainer(source: source, downloads: downloads, report: previous, syncs: {1: sync});
    await _pumpPage(tester, container);

    await tester.tap(_button(1));
    await _pumpFrames(tester);
    final failed = container.read(updateReportStoreProvider)!.items.first;
    expect(failed.outcome, UpdateOutcome.enqueueFailed);
    expect(failed.message, contains('queue-error'));
    expect(tester.widget<IconButton>(_button(1)).onPressed, isNotNull);
    expect(container.read(updateRetryControllerProvider(1)), isFalse);
    expect(container.read(updateReportStoreProvider)!.items.last, previous.items.last);

    downloads.errors.clear();
    await tester.tap(_button(1));
    await _pumpFrames(tester);
    expect(source.calls, 2);
    expect(sync.calls, 2);
    expect(readUpdateReportFixture(container)!.items.first.outcome, UpdateOutcome.updated);
    expect(readUpdateReportFixture(container)!.items.first.message, isNull);
    expect(_busyIcon(1), findsNothing);
    expect(tester.widget<IconButton>(_button(1)).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('An empty retry response remains an error and allows another attempt', (tester) async {
    final source = UpdateSourceFixture(chapters: []);
    final sync = UpdateSyncFixture();
    final downloads = UpdateDownloadsFixture();
    final container = await createUpdateRetryContainer(
      source: source,
      downloads: downloads,
      syncs: {1: sync},
      report: updateReportFixture(totalTargets: 1, items: [retryFailureFixture(1)]),
    );
    await _pumpPage(tester, container);

    await tester.tap(_button(1));
    await _pumpFrames(tester);

    expect(readUpdateReportFixture(container)!.items.single.outcome, UpdateOutcome.chaptersEmpty);
    expect(find.text('Source returned no chapters'), findsOneWidget);
    expect(tester.widget<IconButton>(_button(1)).onPressed, isNotNull);
    expect(tester.widget<IconButton>(_button(1)).color, Theme.of(tester.element(_button(1))).colorScheme.error);
    expect(_summaryCounts(tester), [1, 0, 0, 1]);
    await container.read(updateRetryControllerProvider(1).notifier).retry();
    expect(source.calls, 2);
    expect(sync.calls, 0);
    expect(downloads.mangas, isEmpty);
    await _pumpFrames(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Concurrent retries keep their busy indicators with each manga through reordering', (tester) async {
    final pending = [Completer<void>(), Completer<void>()];
    final syncs = {1: UpdateSyncFixture(pending[0].future), 2: UpdateSyncFixture(pending[1].future)};
    final container = await createUpdateRetryContainer(
      report: updateReportFixture(items: [retryFailureFixture(1), retryFailureFixture(2)]),
      mangas: UpdateMangasFixture([mangaFixture(1), mangaFixture(2)]),
      syncs: syncs,
    );
    await _pumpPage(tester, container);
    await tester.tap(_button(1));
    await tester.pump();
    await _pumpUntil(tester, () => syncs[1]!.calls == 1);
    await tester.pump(const Duration(milliseconds: 375));
    expect(_busyIcon(1), findsOneWidget);
    expect(tester.widget<IconButton>(_button(1)).onPressed, isNull);

    await tester.tap(_button(2));
    await tester.pump();
    await _pumpUntil(tester, () => syncs[2]!.calls == 1);
    expect(_busyIcon(2), findsOneWidget);
    expect(tester.widget<IconButton>(_button(2)).onPressed, isNull);

    final store = container.read(updateReportStoreProvider.notifier);
    final report = container.read(updateReportStoreProvider)!;
    await store.update(
      report.sessionId,
      (current) => current.copyWith(
        items: [
          current.items[0].copyWith(sourceName: 'Z'),
          current.items[1].copyWith(sourceName: 'A'),
        ],
      ),
    );
    await tester.pump();
    for (final id in [1, 2]) {
      expect(_busyIcon(id), findsOneWidget);
      expect(tester.widget<IconButton>(_button(id)).onPressed, isNull);
    }
    expect(tester.getSize(find.descendant(of: _busyIcon(2), matching: find.byType(CustomPaint))), const Size.square(24.0));

    pending[0].complete();
    await _pumpFrames(tester);
    expect(container.read(updateRetryControllerProvider(1)), isFalse);
    expect(_busyIcon(1), findsNothing);
    expect(container.read(updateRetryControllerProvider(2)), isTrue);
    expect(_busyIcon(2), findsOneWidget);
    pending[1].complete();
    await _pumpFrames(tester);
    expect(container.read(updateRetryControllerProvider(2)), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'The disabled retry keeps native row navigation without starting another source request',
    (tester) async {
      final pending = Completer<void>();
      final source = UpdateSourceFixture(pending: pending.future);
      final container = await createUpdateRetryContainer(source: source);
      final router = await _pumpPage(tester, container);
      await tester.tap(_button(1));
      await tester.pump();
      await _pumpUntil(tester, () => source.calls == 1);
      expect(tester.widget<IconButton>(_button(1)).onPressed, isNull);

      await tester.tap(_button(1));
      await _pumpFrames(tester);
      expect(find.text('detail-1'), findsOneWidget);
      expect(source.calls, 1);
      pending.complete();
      await _pumpFrames(tester);
      expect(readUpdateReportFixture(container)!.items.single.outcome, UpdateOutcome.updated);

      router.pop();
      await _pumpFrames(tester);
      expect(_row(1), findsOneWidget);
      expect(_busyIcon(1), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant({TargetPlatform.windows, TargetPlatform.android}),
  );

  for (final stopScan in [false, true]) {
    testWidgets('A global scan shares the pending retry and records its own report: stop=$stopScan', (tester) async {
      final pending = Completer<void>();
      final source = UpdateSourceFixture(pending: pending.future);
      final downloads = UpdateDownloadsFixture();
      final previous = updateReportFixture(items: [retryFailureFixture(1), updateReportItemFixture(2)]);
      late UpdateServiceCallsFixture updates;
      final container = await createUpdateRetryContainer(
        source: source,
        downloads: downloads,
        report: previous,
        mangas: UpdateMangasFixture([mangaFixture(1), mangaFixture(2)]),
        overrides: [updateServiceProvider.overrideWith((ref) => updates = UpdateServiceCallsFixture(updateService(ref)))],
      );
      await _pumpPage(tester, container);
      await tester.tap(_countButton(UpdateFilter.failure));
      await _pumpFrames(tester);
      await tester.tap(_button(1));
      await tester.pump();
      await _pumpUntil(tester, () => source.calls == 1);

      await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.sync_outlined));
      await tester.pump();
      await _pumpUntil(tester, () => updates.calls.length == 2);
      expect(source.calls, 1);
      expect(container.read(updateReportStoreProvider)!.sessionId, isNot(previous.sessionId));
      expect(container.read(updateControllerProvider), isNull);
      expect(find.widgetWithIcon(FloatingActionButton, Icons.stop_outlined), findsOneWidget);
      if (stopScan) {
        await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.stop_outlined));
      }
      pending.complete();
      await _pumpFrames(tester);

      final report = readUpdateReportFixture(container)!;
      expect(report.phase, stopScan ? UpdatePhase.cancelled : UpdatePhase.finished);
      expect(report.totalTargets, 2);
      expect(report.items.map((item) => item.mangaId), [1, 2]);
      expect(report.items.map((item) => item.outcome), [
        UpdateOutcome.updated,
        stopScan ? UpdateOutcome.unchecked : UpdateOutcome.updated,
      ]);
      expect(downloads.mangas.map((manga) => manga.id), stopScan ? [1] : [1, 2]);
      expect(source.calls, stopScan ? 1 : 2);
      expect(container.read(updateManagerProvider).isLoading, isFalse);
      expect(find.widgetWithIcon(FloatingActionButton, Icons.sync_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Removing the page releases its animation while the retry still saves its result', (tester) async {
    final pending = Completer<void>();
    final source = UpdateSourceFixture(pending: pending.future);
    final container = await createUpdateRetryContainer(source: source);
    await _pumpPage(tester, container);
    await tester.tap(_button(1));
    await tester.pump();
    await _pumpUntil(tester, () => source.calls == 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    pending.complete();
    await _pumpFrames(tester);
    expect(readUpdateReportFixture(container)!.items.single.outcome, UpdateOutcome.updated);
    expect(source.calls, 1);
    expect(tester.takeException(), isNull);
  });
}

final _allChapters = {for (var id = 1; id <= 5; id++) 'chapter-title-$id'};

Future<GoRouter> _pumpPage(WidgetTester tester, ProviderContainer container, {Locale locale = const Locale('en')}) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const UpdatePage()),
      GoRoute(
        name: TsukuyomiRouter.manga.name,
        path: '/manga/:mangaId',
        builder: (context, state) => Scaffold(body: Text('detail-${state.params['mangaId']}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: TsukuyomiTheme(container.read(themePredefinedProvider).first).themeData,
        locale: locale,
        localizationsDelegates: TsukuyomiLocalizations.localizationsDelegates,
        supportedLocales: TsukuyomiLocalizations.supportedLocales,
      ),
    ),
  );
  await _pumpUntil(tester, () => find.byType(UpdatePage).evaluate().isNotEmpty);
  await _pumpFrames(tester);
  return router;
}

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 20 && !ready(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(ready(), isTrue);
}

Finder _row(int id) => find.widgetWithText(ListTile, 'manga-title-$id');

Finder _button(int id) => find.descendant(of: _row(id), matching: find.byType(IconButton));

Finder _busyIcon(int id) => find.descendant(
  of: _row(id),
  matching: find.byWidgetPredicate((widget) => widget is AnimatedProgressCircleIcon && widget.progress == 0.0),
);

Finder _countButton(UpdateFilter filter) {
  final index = [UpdateFilter.failure, UpdateFilter.warning, UpdateFilter.success, UpdateFilter.all].indexOf(filter);
  return find.descendant(of: find.byType(UpdateSummary), matching: find.byType(InkWell)).at(index);
}

List<int> _summaryCounts(WidgetTester tester) => [
  for (final filter in [UpdateFilter.failure, UpdateFilter.warning, UpdateFilter.success, UpdateFilter.all])
    int.parse(tester.widget<Text>(find.descendant(of: _countButton(filter), matching: find.byType(Text))).data!),
];
