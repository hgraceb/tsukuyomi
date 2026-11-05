import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/database/database.dart' show DatabaseChapter;
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/pages/update/update_controller.dart';
import 'package:tsukuyomi/pages/update/update_page.dart';
import 'package:tsukuyomi/pages/update/update_progress_provider.dart';
import 'package:tsukuyomi/pages/update/update_summary.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/providers/theme/theme_predefined_provider.dart';
import 'package:tsukuyomi/providers/update/update_manager.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

import '../../fixtures/update_fixtures.dart';

final _downloadedProvider = StateProvider<Set<String>>(
  (ref) => {'chapter-title-1', 'chapter-title-2', 'chapter-title-7', 'removed-chapter'},
);

void main() {
  setUpAll(() async {
    await TsukuyomiLocalizations.delegate.load(const Locale('zh'));
    await TsukuyomiLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('The default page is blank and the floating controls follow scan state', (tester) async {
    final manager = _Manager();
    final container = await _pumpPage(tester, manager: manager);

    expect(manager._scans, 0);
    expect(find.text('Updates'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(AnimatedProgressCircleIcon), findsNothing);
    final button = tester.getRect(find.byType(FloatingActionButton));
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(button.center.dx, greaterThan(size.width * 0.8));
    expect(button.center.dy, greaterThan(size.height * 0.8));
    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.sync_outlined));
    await tester.pump();
    expect(manager._scans, 1);
    expect(_summaryCounts(tester), [0, 0, 0, 0]);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.stop_outlined), findsOneWidget);

    final report = updateReportFixture(phase: UpdatePhase.running, items: [updateReportItemFixture(1)]);
    await container.read(updateReportStoreProvider.notifier).save(report);
    await _pumpFrames(tester);
    expect(_summaryCounts(tester), [0, 0, 1, 2]);
    expect(find.text('2 / 5'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.stop_outlined));
    await tester.pump();
    expect(manager._stops, 1);
    expect(find.widgetWithIcon(FloatingActionButton, Icons.sync_outlined), findsNothing);
    await container.read(updateReportStoreProvider.notifier).save(report.copyWith(phase: UpdatePhase.cancelled));
    manager._finish();
    await _pumpFrames(tester);
    expect(_summaryCounts(tester), [0, 0, 1, 2]);
    expect(find.widgetWithIcon(FloatingActionButton, Icons.sync_outlined), findsOneWidget);
  });

  testWidgets('Errors and warnings have separate counts and colors without detail dialogs', (tester) async {
    _narrowScreen(tester);
    final container = await _pumpPage(
      tester,
      manager: _Manager(),
      textScale: 1.3,
      chapterStream: (id) => Stream.value(id == 2 ? [] : chaptersFixture(id)),
      report: updateReportFixture(
        phase: UpdatePhase.running,
        totalTargets: 3,
        items: [
          updateReportItemFixture(1).copyWith(outcome: UpdateOutcome.enqueueFailed, message: 'queue-error', sourceCount: 8),
          updateReportItemFixture(2).copyWith(outcome: UpdateOutcome.chaptersEmpty, sourceCount: 0),
          updateReportItemFixture(3).copyWith(outcome: UpdateOutcome.skipped),
        ],
      ),
    );

    expect(container.read(updateReportStoreProvider)!.phase, UpdatePhase.interrupted);
    final colors = Theme.of(tester.element(find.text('Download scheduling failed'))).colorScheme;
    expect(_summaryCounts(tester), [2, 1, 0, 3]);
    expect(tester.widget<Text>(_countText(UpdateFilter.failure)).style?.color, colors.error);
    expect(tester.widget<Text>(_countText(UpdateFilter.warning)).style?.color, colors.tertiary);
    expect(tester.widget<Text>(_countText(UpdateFilter.success)).style?.color, colors.onSurface);
    expect(tester.widget<Text>(_countText(UpdateFilter.all)).style?.color, colors.onSurface);
    expect(tester.widget<Text>(find.text('Download scheduling failed')).style?.color, colors.error);
    expect(tester.widget<Text>(find.text('Source returned no chapters')).style?.color, colors.error);
    expect(tester.widget<Text>(find.text('Skipped')).style?.color, colors.tertiary);
    expect(find.text('2 / 5'), findsOneWidget);
    expect(find.text('0 / 0'), findsNWidgets(2));
    expect(tester.widget<IconButton>(_retryButton('manga-title-2')).color, colors.error);
    expect(find.byIcon(Icons.info_outline), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Summary counts only completed outcomes across scan phases without a progress icon', (tester) async {
    final items = [
      updateReportItemFixture(1).copyWith(outcome: UpdateOutcome.networkError),
      updateReportItemFixture(2).copyWith(outcome: UpdateOutcome.chaptersEmpty),
      updateReportItemFixture(3).copyWith(outcome: UpdateOutcome.skipped),
      updateReportItemFixture(4),
      updateReportItemFixture(5).copyWith(outcome: UpdateOutcome.noUpdate),
      updateReportItemFixture(6),
    ];
    for (final locale in [const Locale('en'), const Locale('zh')]) {
      final manager = _Manager();
      final report = updateReportFixture(totalTargets: 10, items: items);
      final container = await _pumpPage(tester, manager: manager, report: report, locale: locale, mangaIds: [7, 8, 9, 10]);
      final store = container.read(updateReportStoreProvider.notifier);
      final summaryIcons = find.descendant(of: find.byType(SliverAppBar), matching: find.byType(Icon));

      for (final phase in [UpdatePhase.running, UpdatePhase.cancelled, UpdatePhase.interrupted]) {
        if (phase == UpdatePhase.running) {
          await manager.scan();
        } else {
          manager._finish();
        }
        await store.save(report.copyWith(phase: phase));
        await _pumpFrames(tester);
        expect(_summaryCounts(tester), [2, 1, 3, 10]);
        expect(summaryIcons, findsNothing);
      }

      final completed = [...items, for (var id = 7; id <= 10; id++) updateReportItemFixture(id)];
      await store.save(report.copyWith(items: completed));
      await _pumpFrames(tester);
      expect(_summaryCounts(tester), [2, 1, 7, 10]);
      expect(summaryIcons, findsNothing);

      for (final total in [10, 0]) {
        await store.save(report.copyWith(items: [], totalTargets: total));
        await _pumpFrames(tester);
        expect(_summaryCounts(tester), [0, 0, 0, total]);
        expect(summaryIcons, findsNothing);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpFrames(tester);
    }
  });

  testWidgets('Global errors keep counts visible and empty results have no prompts', (tester) async {
    final manager = _Manager();
    final container = await _pumpPage(
      tester,
      manager: manager,
      report: updateReportFixture(message: 'query-error').copyWith(totalTargets: 0),
    );
    final summaryIcons = find.descendant(of: find.byType(SliverAppBar), matching: find.byType(Icon));
    expect(_summaryCounts(tester), [0, 0, 0, 0]);
    expect(summaryIcons, findsNothing);
    expect(find.byType(ListTile), findsNothing);

    await container.read(updateReportStoreProvider.notifier).save(updateReportFixture().copyWith(totalTargets: 0));
    manager._fail(StateError('save-error'));
    await _pumpFrames(tester);
    expect(summaryIcons, findsNothing);
    expect(find.widgetWithIcon(FloatingActionButton, Icons.sync_outlined), findsOneWidget);
    manager._finish();
    await _pumpFrames(tester);
    expect(summaryIcons, findsNothing);
    expect(_summaryCounts(tester), [0, 0, 0, 0]);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Public chapter downloads update live after scanning without rewriting the report', (tester) async {
    final chapters = StreamController<List<DatabaseChapter>>();
    addTearDown(chapters.close);
    chapters.add(chaptersFixture(1));
    final container = await _pumpPage(
      tester,
      manager: _Manager(),
      chapterStream: (_) => chapters.stream,
      report: updateReportFixture(items: [updateReportItemFixture(1)]).copyWith(totalTargets: 1),
    );
    final report = container.read(updateReportStoreProvider);
    expect(find.text('2 / 5'), findsOneWidget);
    expect(_progress(tester, 'manga-title-1'), 0.4);
    container.read(_downloadedProvider.notifier).state = {for (var id = 1; id <= 7; id++) 'chapter-title-$id', 'removed-chapter'};
    await _pumpFrames(tester);
    expect(find.text('5 / 5'), findsOneWidget);
    expect(_completionIcon('manga-title-1'), findsOneWidget);

    chapters.add(chaptersFixture(1, publicCount: 6));
    await _pumpFrames(tester);
    expect(find.text('6 / 6'), findsOneWidget);
    expect(_completionIcon('manga-title-1'), findsOneWidget);

    chapters.add(chaptersFixture(1, total: 9, publicCount: 8));
    await _pumpFrames(tester);
    expect(find.text('7 / 8'), findsOneWidget);
    expect(_completionIcon('manga-title-1'), findsNothing);
    expect(_progress(tester, 'manga-title-1'), 7 / 8);
    expect(container.read(updateReportStoreProvider), report);
    expect(_summaryCounts(tester), [0, 0, 1, 1]);
  });

  testWidgets('Only complete public downloads show a check while scan outcomes remain visible', (tester) async {
    final report = updateReportFixture(
      totalTargets: 5,
      items: [
        updateReportItemFixture(1),
        updateReportItemFixture(2).copyWith(outcome: UpdateOutcome.networkError),
        updateReportItemFixture(3).copyWith(deleteCount: 2),
        updateReportItemFixture(4).copyWith(outcome: UpdateOutcome.noUpdate),
        updateReportItemFixture(5),
      ],
    );
    final container = await _pumpPage(
      tester,
      manager: _Manager(),
      report: report,
      chapterStream: (id) => Stream.value(chaptersFixture(id, publicCount: id == 5 ? 0 : 5)),
      downloadedForManga: (id) {
        final count = id == 4 ? 4 : 7;
        return {for (var chapter = 1; chapter <= count; chapter++) 'chapter-title-$chapter', 'removed-chapter'};
      },
    );
    final colors = Theme.of(tester.element(find.text('Request failed'))).colorScheme;
    for (final id in [1, 3]) {
      expect(_completionIcon('manga-title-$id'), findsOneWidget);
      expect(tester.widget<Icon>(_completionIcon('manga-title-$id')).color, colors.onSurface);
    }
    expect(_completionIcon('manga-title-2'), findsNothing);
    expect(find.descendant(of: find.widgetWithText(ListTile, 'manga-title-2'), matching: find.byTooltip('Retry')), findsOneWidget);
    expect(_completionIcon('manga-title-4'), findsNothing);
    expect(_progress(tester, 'manga-title-4'), 0.8);
    expect(_completionIcon('manga-title-5'), findsNothing);
    expect(_progress(tester, 'manga-title-5'), 0.0);
    expect(find.text('0 / 0'), findsNWidgets(2));
    expect(tester.widget<Text>(find.text('Request failed')).style?.color, colors.error);
    expect(_summaryCounts(tester), [1, 0, 4, 5]);
    expect(container.read(updateReportStoreProvider), report);
    expect(tester.takeException(), isNull);
  });

  for (final input in ['chapters', 'downloads']) {
    testWidgets('Retained complete counts keep their check while $input reload and expose failures', (tester) async {
      Completer<void>? pending;
      final report = updateReportFixture(totalTargets: 1, items: [updateReportItemFixture(1)]);
      final container = await _pumpPage(
        tester,
        manager: _Manager(),
        report: report,
        chapterStream: (_) async* {
          if (input == 'chapters') await pending?.future;
          yield chaptersFixture(1);
        },
        downloadedForManga: (_) async {
          if (input == 'downloads') await pending?.future;
          return {for (var id = 1; id <= 5; id++) 'chapter-title-$id'};
        },
      );
      expect(_completionIcon('manga-title-1'), findsOneWidget);
      final ProviderOrFamily provider = input == 'chapters' ? chaptersStreamByMangaProvider(1) : updateDownloadedChaptersProvider(1);

      pending = Completer<void>();
      container.invalidate(provider);
      await _pumpFrames(tester);
      expect(find.text('5 / 5'), findsOneWidget);
      expect(_completionIcon('manga-title-1'), findsOneWidget);

      pending.completeError(StateError('fixture-$input-error'));
      await _pumpFrames(tester);
      expect(find.text('5 / 5'), findsOneWidget);
      expect(_completionIcon('manga-title-1'), findsNothing);
      final button = _retryButton('manga-title-1');
      expect(tester.widget<IconButton>(button).color, Theme.of(tester.element(button)).colorScheme.tertiary);
      expect(_summaryCounts(tester), [0, 1, 0, 1]);

      pending = null;
      container.invalidate(provider);
      await _pumpFrames(tester);
      expect(_completionIcon('manga-title-1'), findsOneWidget);
      expect(container.read(updateReportStoreProvider), report);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Long names and chapter counts remain readable in both languages on narrow screens', (tester) async {
    _narrowScreen(tester);
    final item = updateReportItemFixture(1).copyWith(
      mangaTitle: '这是一部名称很长的示例漫画 A manga with a very long title',
      sourceName: '名称很长的示例漫画源 A source with a very long name',
      sourceCount: 1002,
      enqueuedCount: 1,
    );
    for (final locale in [const Locale('zh'), const Locale('en')]) {
      await _pumpPage(
        tester,
        manager: _Manager(),
        locale: locale,
        textScale: 1.3,
        chapterStream: (id) => Stream.value(chaptersFixture(id, total: 1002, publicCount: 1000)),
        downloaded: {for (var id = 1; id <= 999; id++) 'chapter-title-$id', 'chapter-title-1002'},
        report: updateReportFixture(items: [item]).copyWith(totalTargets: 1),
      );
      expect(find.text(item.mangaTitle), findsOneWidget);
      expect(find.text('999 / 1000'), findsOneWidget);
      expect(tester.renderObject<RenderParagraph>(find.text('999 / 1000')).didExceedMaxLines, isFalse);
      expect(_summaryCounts(tester), [0, 0, 1, 1]);
      for (final filter in UpdateFilter.values) {
        expect(tester.renderObject<RenderParagraph>(_countText(filter)).didExceedMaxLines, isFalse);
      }
      expect(_progress(tester, item.mangaTitle), 0.999);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpFrames(tester);
    }
  });

  testWidgets('Delayed local progress resolves independently for each manga', (tester) async {
    final first = Completer<Set<String>>();
    final second = Completer<Set<String>>();
    final report = updateReportFixture(items: [updateReportItemFixture(1), updateReportItemFixture(2)]);
    final container = await _pumpPage(
      tester,
      manager: _Manager(),
      report: report,
      chapterStream: (id) => Stream.value(chaptersFixture(id, total: id == 1 ? 5 : 9, publicCount: id == 1 ? 3 : 7)),
      downloadedForManga: (id) => id == 1 ? first.future : second.future,
    );

    second.complete({for (var id = 1; id <= 6; id++) 'chapter-title-$id'});
    await _pumpFrames(tester);
    expect(first.isCompleted, isFalse);
    expect(_progress(tester, 'manga-title-2'), 6 / 7);

    first.complete({'chapter-title-1', 'chapter-title-5', 'removed-chapter'});
    await _pumpFrames(tester);
    expect(_progress(tester, 'manga-title-1'), 1 / 3);
    expect(_progress(tester, 'manga-title-2'), 6 / 7);
    expect(container.read(updateReportStoreProvider), report);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A local progress error and recovery move the row between filters without rewriting scan results', (tester) async {
    final error = StateError('fixture-directory-error');
    var fail = true;
    final report = updateReportFixture(items: [updateReportItemFixture(1), updateReportItemFixture(2)]);
    final container = await _pumpPage(
      tester,
      manager: _Manager(),
      report: report,
      downloadedForManga: (id) {
        if (id == 1 && fail) throw error;
        return {'chapter-title-1', 'chapter-title-2', 'chapter-title-3'};
      },
    );

    final firstIcon = _retryButton('manga-title-1');
    final colors = Theme.of(tester.element(firstIcon)).colorScheme;
    expect(container.read(updateDownloadedChaptersProvider(1)).error, same(error));
    expect(tester.widget<IconButton>(firstIcon).color, colors.tertiary);
    expect(_summaryCounts(tester), [0, 1, 1, 2]);
    expect(_progress(tester, 'manga-title-2'), 0.6);
    expect(container.read(updateReportStoreProvider), report);
    expect(report.failureCount, 0);

    await tester.tap(_countButton(UpdateFilter.warning));
    await _pumpFrames(tester);
    expect(find.text('manga-title-1'), findsOneWidget);
    expect(find.text('manga-title-2'), findsNothing);
    fail = false;
    container.invalidate(updateDownloadedChaptersProvider(1));
    await _pumpFrames(tester);
    expect(_summaryCounts(tester), [0, 0, 2, 2]);
    expect(find.text('No results for this filter'), findsOneWidget);
    await tester.tap(_countButton(UpdateFilter.success));
    await _pumpFrames(tester);
    expect(find.text('manga-title-1'), findsOneWidget);
    expect(find.text('manga-title-2'), findsOneWidget);
    expect(container.read(updateReportStoreProvider), report);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A large offline report retains different public progress after scrolling', (tester) async {
    final report = updateReportFixture(
      totalTargets: 40,
      items: [for (var id = 1; id <= 40; id++) updateReportItemFixture(id).copyWith(sourceName: 'source-${id.toString().padLeft(2, '0')}')],
    );
    final container = await _pumpPage(
      tester,
      manager: _Manager(),
      report: report,
      chapterStream: (id) => Stream.value(chaptersFixture(id, total: id + 2, publicCount: id)),
      downloadedForManga: (id) => {for (var chapter = 1; chapter <= id ~/ 2; chapter++) 'chapter-title-$chapter'},
    );

    expect(_progress(tester, 'manga-title-1'), 0.0);
    expect(_progress(tester, 'manga-title-2'), 0.5);
    await tester.scrollUntilVisible(find.text('manga-title-40'), 500.0, scrollable: find.byType(Scrollable).first);
    await _pumpFrames(tester);
    expect(find.text('20 / 40'), findsOneWidget);
    expect(_progress(tester, 'manga-title-40'), 0.5);
    expect(container.read(updateReportStoreProvider), report);
    expect(tester.takeException(), isNull);
  });

  for (final complete in [false, true]) {
    testWidgets('A 200-row report restores its cached counts and painted icon before delayed reads finish: complete=$complete', (
      tester,
    ) async {
      final chapterReads = <int, int>{};
      final downloadReads = <int, int>{};
      Completer<void>? chaptersPending;
      Completer<void>? downloadsPending;
      var firstTotal = 5;
      var firstDownloaded = complete ? 5 : 2;
      final report = updateReportFixture(
        totalTargets: 200,
        items: [
          for (var id = 1; id <= 200; id++) updateReportItemFixture(id).copyWith(sourceName: 'source-${id.toString().padLeft(3, '0')}'),
        ],
      );
      final container = await _pumpPage(
        tester,
        manager: _Manager(),
        report: report,
        chapterStream: (id) {
          chapterReads.update(id, (reads) => reads + 1, ifAbsent: () => 1);
          final total = id == 1 ? firstTotal : id % 11 + 1;
          final value = chaptersFixture(id, total: total + 2, publicCount: total);
          return id == 1 && chaptersPending != null ? Stream.fromFuture(chaptersPending.future.then((_) => value)) : Stream.value(value);
        },
        downloadedForManga: (id) async {
          downloadReads.update(id, (reads) => reads + 1, ifAbsent: () => 1);
          final count = id == 1 ? firstDownloaded : id % (id % 11 + 1);
          final value = {for (var chapter = 1; chapter <= count; chapter++) 'chapter-title-$chapter'};
          if (id == 1) await downloadsPending?.future;
          return value;
        },
      );
      final initialCount = '$firstDownloaded / 5';
      void expectCached() {
        final row = find.widgetWithText(ListTile, 'manga-title-1');
        expect(find.descendant(of: row, matching: find.text(initialCount)), findsOneWidget);
        if (complete) {
          expect(_completionIcon('manga-title-1'), findsOneWidget);
        } else {
          expect(_paintedProgress(tester, 'manga-title-1'), 0.4);
        }
      }

      expectCached();
      final cache = container.read(updateProgressCacheProvider(report.sessionId));
      final saved = container.read(sharedPreferencesProvider).getString(Keys.updateReportLatest);
      await tester.scrollUntilVisible(find.text('manga-title-200'), 500.0, scrollable: find.byType(Scrollable).first);
      await _pumpFrames(tester);
      expect(find.text('manga-title-1'), findsNothing);
      expect(container.exists(updateProgressProvider(cache, 1)), isFalse);
      expect(container.exists(chaptersStreamByMangaProvider(1)), isFalse);
      expect(container.exists(updateDownloadedChaptersProvider(1)), isFalse);

      chaptersPending = Completer<void>();
      downloadsPending = Completer<void>();
      firstTotal = 8;
      firstDownloaded = 3;
      await tester.scrollUntilVisible(find.text('manga-title-1'), -500.0, scrollable: find.byType(Scrollable).first);
      await tester.pump();
      expectCached();
      expect(chapterReads[1], 2);
      expect(downloadReads[1], 2);
      if (complete) {
        downloadsPending.complete();
      } else {
        chaptersPending.complete();
      }
      await _pumpFrames(tester);
      expectCached();
      if (complete) {
        chaptersPending.complete();
      } else {
        downloadsPending.complete();
      }
      await _pumpFrames(tester);
      final returned = find.widgetWithText(ListTile, 'manga-title-1');
      expect(find.descendant(of: returned, matching: find.text('3 / 8')), findsOneWidget);
      expect(_completionIcon('manga-title-1'), findsNothing);
      expect(_paintedProgress(tester, 'manga-title-1'), 3 / 8);
      expect(container.read(updateReportStoreProvider), report);
      expect(container.read(sharedPreferencesProvider).getString(Keys.updateReportLatest), saved);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Filtering a complete manga out and back retains its icon while progress reloads', (tester) async {
    Completer<void>? pending;
    final report = updateReportFixture(
      items: [
        updateReportItemFixture(1),
        updateReportItemFixture(2).copyWith(outcome: UpdateOutcome.skipped),
      ],
    );
    final container = await _pumpPage(
      tester,
      manager: _Manager(),
      report: report,
      downloadedForManga: (id) async {
        if (id == 1) await pending?.future;
        return {for (var chapter = 1; chapter <= 5; chapter++) 'chapter-title-$chapter'};
      },
    );
    expect(_completionIcon('manga-title-1'), findsOneWidget);
    await tester.tap(_countButton(UpdateFilter.warning));
    await _pumpFrames(tester);
    expect(find.text('manga-title-1'), findsNothing);
    expect(container.exists(updateDownloadedChaptersProvider(1)), isFalse);

    pending = Completer<void>();
    await tester.tap(_countButton(UpdateFilter.all));
    await _pumpFrames(tester);
    expect(_completionIcon('manga-title-1'), findsOneWidget);
    expect(_summaryCounts(tester), [0, 1, 1, 2]);
    pending.complete();
    await _pumpFrames(tester);
    expect(_completionIcon('manga-title-1'), findsOneWidget);
    expect(container.read(updateReportStoreProvider), report);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A new report reloads the same manga with its first-read display instead of the previous report icon', (tester) async {
    Completer<void>? chaptersPending;
    Completer<void>? downloadsPending;
    var downloaded = 5;
    final report = updateReportFixture(totalTargets: 1, items: [updateReportItemFixture(1)]);
    final container = await _pumpPage(
      tester,
      manager: _Manager(),
      report: report,
      chapterStream: (_) async* {
        await chaptersPending?.future;
        yield chaptersFixture(1);
      },
      downloadedForManga: (_) async {
        final value = {for (var id = 1; id <= downloaded; id++) 'chapter-title-$id'};
        await downloadsPending?.future;
        return value;
      },
    );
    expect(_completionIcon('manga-title-1'), findsOneWidget);
    final store = container.read(updateReportStoreProvider.notifier);
    final next = report.copyWith(sessionId: 'next-session', items: []);
    await store.save(next);
    await _pumpFrames(tester);
    expect(find.text('manga-title-1'), findsNothing);
    expect(container.exists(chaptersStreamByMangaProvider(1)), isFalse);
    expect(container.exists(updateDownloadedChaptersProvider(1)), isFalse);

    chaptersPending = Completer<void>();
    downloadsPending = Completer<void>();
    downloaded = 2;
    await store.save(next.copyWith(items: report.items));
    await tester.pump();
    expect(find.text('0 / 0'), findsOneWidget);
    expect(_completionIcon('manga-title-1'), findsNothing);
    chaptersPending.complete();
    await _pumpFrames(tester);
    expect(find.text('0 / 5'), findsOneWidget);
    downloadsPending.complete();
    await _pumpFrames(tester);
    expect(find.text('2 / 5'), findsOneWidget);
    expect(_paintedProgress(tester, 'manga-title-1'), 0.4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sorting source-name changes keeps painted progress with each manga from the first frame', (tester) async {
    final report = updateReportFixture(items: [updateReportItemFixture(1), updateReportItemFixture(2)]);
    final container = await _pumpPage(
      tester,
      manager: _Manager(),
      report: report,
      downloadedForManga: (id) => {for (var chapter = 1; chapter <= (id == 1 ? 4 : 1); chapter++) 'chapter-title-$chapter'},
    );
    expect(_paintedProgress(tester, 'manga-title-1'), 0.8);
    expect(_paintedProgress(tester, 'manga-title-2'), 0.2);

    await container
        .read(updateReportStoreProvider.notifier)
        .save(report.copyWith(items: report.items.map((item) => item.copyWith(sourceName: item.mangaId == 1 ? 'Z' : 'A')).toList()));
    await tester.pump();

    expect(find.descendant(of: find.widgetWithText(ListTile, 'manga-title-1'), matching: find.text('4 / 5')), findsOneWidget);
    expect(find.descendant(of: find.widgetWithText(ListTile, 'manga-title-2'), matching: find.text('1 / 5')), findsOneWidget);
    expect(_paintedProgress(tester, 'manga-title-1'), 0.8);
    expect(_paintedProgress(tester, 'manga-title-2'), 0.2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Replacing a report row does not lend its painted progress to a pending manga', (tester) async {
    final second = Completer<Set<String>>();
    final report = updateReportFixture(items: [updateReportItemFixture(1)]);
    final container = await _pumpPage(
      tester,
      manager: _Manager(),
      report: report,
      mangaIds: [2],
      downloadedForManga: (id) => id == 1 ? {'chapter-title-1', 'chapter-title-2'} : second.future,
    );
    expect(_paintedProgress(tester, 'manga-title-1'), 0.4);

    await container.read(updateReportStoreProvider.notifier).save(report.copyWith(items: [updateReportItemFixture(2)]));
    await tester.pump();
    expect(find.text('manga-title-1'), findsNothing);
    expect(second.isCompleted, isFalse);
    expect(_progress(tester, 'manga-title-2'), 0.0);
    expect(_paintedProgress(tester, 'manga-title-2'), 0.0);

    second.complete({'chapter-title-1'});
    await _pumpFrames(tester);
    expect(_paintedProgress(tester, 'manga-title-2'), 0.2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Moving a manga preserves its own in-flight progress animation', (tester) async {
    final report = updateReportFixture(items: [updateReportItemFixture(1), updateReportItemFixture(2)]);
    final container = await _pumpPage(
      tester,
      manager: _Manager(),
      report: report,
      chapterStream: (id) => Stream.value(chaptersFixture(id, total: id * 5, publicCount: id * 5)),
      downloaded: {'chapter-title-1'},
    );

    container.read(_downloadedProvider.notifier).state = {for (var id = 1; id <= 4; id++) 'chapter-title-$id'};
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(microseconds: 100));
    final firstProgress = _paintedProgress(tester, 'manga-title-1');
    final secondProgress = _paintedProgress(tester, 'manga-title-2');
    expect(firstProgress, inExclusiveRange(0.2, 0.8));
    expect(secondProgress, inExclusiveRange(0.1, 0.4));

    await container
        .read(updateReportStoreProvider.notifier)
        .save(report.copyWith(items: report.items.map((item) => item.copyWith(sourceName: item.mangaId == 1 ? 'Z' : 'A')).toList()));
    await tester.pump();
    expect(_paintedProgress(tester, 'manga-title-1'), firstProgress);
    expect(_paintedProgress(tester, 'manga-title-2'), secondProgress);
    await _pumpFrames(tester);
    expect(_paintedProgress(tester, 'manga-title-1'), 0.8);
    expect(_paintedProgress(tester, 'manga-title-2'), 0.4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Scrolling away while local progress is pending keeps late results with their manga', (tester) async {
    final first = Completer<Set<String>>();
    final last = Completer<Set<String>>();
    final report = updateReportFixture(
      totalTargets: 40,
      items: [for (var id = 1; id <= 40; id++) updateReportItemFixture(id).copyWith(sourceName: 'source-${id.toString().padLeft(2, '0')}')],
    );
    final container = await _pumpPage(
      tester,
      manager: _Manager(),
      report: report,
      chapterStream: (id) => Stream.value(chaptersFixture(id, total: id + 2, publicCount: id)),
      downloadedForManga: (id) => switch (id) {
        1 => first.future,
        40 => last.future,
        _ => {for (var chapter = 1; chapter <= id ~/ 2; chapter++) 'chapter-title-$chapter'},
      },
    );

    expect(_paintedProgress(tester, 'manga-title-1'), 0.0);
    await tester.scrollUntilVisible(find.text('manga-title-40'), 500.0, scrollable: find.byType(Scrollable).first);
    expect(find.text('manga-title-1'), findsNothing);
    expect(last.isCompleted, isFalse);
    expect(_paintedProgress(tester, 'manga-title-40'), 0.0);

    first.complete({'chapter-title-1'});
    await _pumpFrames(tester);
    expect(_paintedProgress(tester, 'manga-title-40'), 0.0);
    last.complete({for (var id = 1; id <= 20; id++) 'chapter-title-$id'});
    await _pumpFrames(tester);
    expect(_paintedProgress(tester, 'manga-title-40'), 0.5);

    await tester.scrollUntilVisible(find.text('manga-title-1'), -500.0, scrollable: find.byType(Scrollable).first);
    await _pumpFrames(tester);
    expect(_completionIcon('manga-title-1'), findsOneWidget);
    expect(find.descendant(of: find.widgetWithText(ListTile, 'manga-title-1'), matching: find.text('1 / 1')), findsOneWidget);
    expect(container.read(updateReportStoreProvider), report);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Four counts filter sorted source titles without changing the report or totals', (tester) async {
    final report = updateReportFixture(
      totalTargets: 10,
      items: [
        updateReportItemFixture(1).copyWith(sourceName: 'B', mangaTitle: 'A'),
        updateReportItemFixture(2).copyWith(sourceName: 'A', mangaTitle: 'Z', outcome: UpdateOutcome.networkError),
        updateReportItemFixture(3).copyWith(sourceName: 'A', mangaTitle: 'A', outcome: UpdateOutcome.skipped),
        updateReportItemFixture(4).copyWith(sourceName: 'A', mangaTitle: 'M', outcome: UpdateOutcome.noUpdate),
      ],
    );
    final container = await _pumpPage(tester, manager: _Manager(), report: report);
    List<int> ids() {
      final visible = [
        for (var id = 1; id <= 4; id++) ...[
          if (find.byKey(ValueKey(id)).evaluate().isNotEmpty) id,
        ],
      ];
      double top(int id) => tester.getTopLeft(find.byKey(ValueKey(id))).dy;
      return visible..sort((a, b) => top(a).compareTo(top(b)));
    }

    expect(ids(), [3, 4, 2, 1]);
    final colors = Theme.of(tester.element(find.byType(UpdateSummary))).colorScheme;
    final countColors = {
      UpdateFilter.failure: colors.error,
      UpdateFilter.warning: colors.tertiary,
      UpdateFilter.success: colors.onSurface,
      UpdateFilter.all: colors.onSurface,
    };
    List<TextSpan> separators() => (tester.widget<Text>(_summaryText()).textSpan! as TextSpan).children!.whereType<TextSpan>().toList();
    expect(separators(), hasLength(3));
    void expectSelection(UpdateFilter? selection) {
      for (final candidate in UpdateFilter.values) {
        final style = tester.widget<Text>(_countText(candidate)).style!;
        final original = countColors[candidate]!;
        final muted = selection != null && candidate != selection;
        final expected = muted ? original.withValues(alpha: original.a / 3.0) : original;
        expect(style.color, expected);
        expect(style.decoration, isNot(TextDecoration.underline));
      }
      final separatorColor = selection == null ? colors.onSurface : colors.onSurface.withValues(alpha: colors.onSurface.a / 3.0);
      expect(separators().map((span) => span.style?.color), everyElement(separatorColor));
    }

    expectSelection(null);
    final tile = tester.widget<ListTile>(find.widgetWithText(ListTile, 'Z'));
    expect(find.descendant(of: find.byWidget(tile.title!), matching: find.text('A')), findsOneWidget);
    expect(find.descendant(of: find.byWidget(tile.subtitle!), matching: find.text('Z')), findsOneWidget);

    for (final filter in [UpdateFilter.failure, UpdateFilter.warning, UpdateFilter.success]) {
      await tester.tap(_countButton(filter));
      await _pumpFrames(tester);
      expect(ids(), switch (filter) {
        UpdateFilter.failure => [2],
        UpdateFilter.warning => [3],
        _ => [4, 1],
      });
      expect(_summaryCounts(tester), [1, 1, 2, 10]);
      expectSelection(filter);
      expect(container.read(updateReportStoreProvider), report);
    }
    await tester.tap(_countButton(UpdateFilter.success));
    await _pumpFrames(tester);
    expect(ids(), [3, 4, 2, 1]);
    expectSelection(null);
    for (var repeat = 0; repeat < 4; repeat++) {
      await tester.tap(_countButton(UpdateFilter.all));
      await _pumpFrames(tester);
      expect(ids(), [3, 4, 2, 1]);
      expectSelection(repeat.isEven ? UpdateFilter.all : null);
      expect(_summaryCounts(tester), [1, 1, 2, 10]);
      expect(container.read(updateReportStoreProvider), report);
    }
    await tester.tap(_countButton(UpdateFilter.failure));
    await _pumpFrames(tester);
    expect(ids(), [2]);
    await tester.tap(_countButton(UpdateFilter.all));
    await _pumpFrames(tester);
    expect(ids(), [3, 4, 2, 1]);
    expectSelection(UpdateFilter.all);
    await tester.tap(_countButton(UpdateFilter.warning));
    await _pumpFrames(tester);
    expect(ids(), [3]);
    expectSelection(UpdateFilter.warning);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A zero-count filter is clearable and scan arrivals keep filtering until a new session', (tester) async {
    final manager = _Manager();
    final report = updateReportFixture(totalTargets: 10, items: [updateReportItemFixture(1).copyWith(sourceName: 'B')]);
    final container = await _pumpPage(tester, manager: manager, report: report, mangaIds: [2, 3]);
    final store = container.read(updateReportStoreProvider.notifier);
    await manager.scan();
    await tester.tap(_countButton(UpdateFilter.failure));
    await _pumpFrames(tester);
    expect(find.text('No results for this filter'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    final matching = updateReportItemFixture(2).copyWith(sourceName: 'A', outcome: UpdateOutcome.parseError);
    await store.save(report.copyWith(items: [...report.items, matching]));
    await _pumpFrames(tester);
    expect(find.text('manga-title-1'), findsNothing);
    expect(find.text('manga-title-2'), findsOneWidget);
    expect(_summaryCounts(tester), [1, 0, 1, 10]);
    expect(find.text('0 / 0'), findsOneWidget);
    expect(_retryButton('manga-title-2'), findsOneWidget);
    await store.save(report.copyWith(items: [...report.items, matching, updateReportItemFixture(3)]));
    await _pumpFrames(tester);
    expect(find.byType(ListTile), findsOneWidget);
    expect(_summaryCounts(tester), [1, 0, 2, 10]);
    await tester.tap(_countButton(UpdateFilter.all));
    await _pumpFrames(tester);
    expect(find.byType(ListTile), findsNWidgets(3));
    await tester.tap(_countButton(UpdateFilter.failure));
    await _pumpFrames(tester);
    await store.save(report.copyWith(sessionId: 'next-scan'));
    await _pumpFrames(tester);
    expect(find.text('manga-title-1'), findsOneWidget);
    expect(find.text('No results for this filter'), findsNothing);
    final colors = Theme.of(tester.element(find.byType(UpdateSummary))).colorScheme;
    expect(tester.widget<Text>(_countText(UpdateFilter.failure)).style?.color, colors.error);
    await tester.tap(_countButton(UpdateFilter.all));
    await _pumpFrames(tester);
    expect(tester.widget<Text>(_countText(UpdateFilter.failure)).style?.color, colors.error.withValues(alpha: colors.error.a / 3.0));
    await store.save(report.copyWith(sessionId: 'third-scan'));
    await _pumpFrames(tester);
    expect(tester.widget<Text>(_countText(UpdateFilter.failure)).style?.color, colors.error);
    expect(find.text('manga-title-1'), findsOneWidget);
    expect(tester.getSize(_countButton(UpdateFilter.all)).height, lessThan(36.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Counts retain compact text spacing without persistent button decoration', (tester) async {
    _narrowScreen(tester);
    final report = updateReportFixture(totalTargets: 1, items: [updateReportItemFixture(1)]);
    final container = await _pumpPage(tester, manager: _Manager(), report: report);
    for (final filter in UpdateFilter.values) {
      expect(find.descendant(of: _countButton(filter), matching: find.byType(DecoratedBox)), findsNothing);
      expect(tester.widget<Text>(_countText(filter)).style?.decoration, isNot(TextDecoration.underline));
      final button = tester.getSize(_countButton(filter));
      expect(button.width, closeTo(button.height, 0.01));
      final count = tester.getRect(_countText(filter));
      await tester.tapAt(Offset(count.left - 4.0, count.center.dy));
      await _pumpFrames(tester);
      expect(tester.widget<UpdateSummary>(find.byType(UpdateSummary)).selection, filter);
      await tester.tapAt(Offset(count.right + 4.0, count.center.dy));
      await _pumpFrames(tester);
      expect(tester.widget<UpdateSummary>(find.byType(UpdateSummary)).selection, isNull);
    }
    var width = tester.getSize(_countButton(UpdateFilter.all)).width;
    for (final count in [12, 123, 12345]) {
      await container.read(updateReportStoreProvider.notifier).save(report.copyWith(totalTargets: count));
      await _pumpFrames(tester);
      final expandedWidth = tester.getSize(_countButton(UpdateFilter.all)).width;
      expect(expandedWidth, greaterThan(width));
      width = expandedWidth;
      expect(find.descendant(of: _countButton(UpdateFilter.all), matching: find.byType(DecoratedBox)), findsNothing);
      expect(tester.renderObject<RenderParagraph>(_countText(UpdateFilter.all)).didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Large counts and fonts use single-line ellipsis in both languages', (tester) async {
    tester.view.physicalSize = const Size(320.0, 800.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final locale in [const Locale('en'), const Locale('zh')]) {
      await _pumpPage(
        tester,
        manager: _Manager(),
        locale: locale,
        textScale: 1.3,
        report: updateReportFixture(totalTargets: 1234567890123456789),
      );
      expect(_summaryCounts(tester), [0, 0, 0, 1234567890123456789]);
      expect(tester.widget<SliverAppBar>(find.byType(SliverAppBar)).bottom, isNull);
      final text = tester.widget<Text>(_summaryText());
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.renderObject<RenderParagraph>(_summaryText()).didExceedMaxLines, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpFrames(tester);
    }
  });

  testWidgets('Single-line summary preserves filtering across window sizes and side safe areas', (tester) async {
    tester.view.physicalSize = const Size(800.0, 800.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await _pumpPage(
      tester,
      manager: _Manager(),
      textScale: 1.3,
      report: updateReportFixture(
        totalTargets: 1234567890123456789,
        items: [
          updateReportItemFixture(1).copyWith(outcome: UpdateOutcome.networkError),
          updateReportItemFixture(2),
        ],
      ),
    );
    SliverAppBar appBar() => tester.widget<SliverAppBar>(find.byType(SliverAppBar));
    expect(appBar().bottom, isNull);
    await tester.tap(_countButton(UpdateFilter.failure));
    await _pumpFrames(tester);
    for (final safeArea in [true, false]) {
      tester.view.padding = safeArea ? const FakeViewPadding(left: 300.0, right: 300.0) : const FakeViewPadding();
      await _pumpFrames(tester);
      expect(appBar().bottom, isNull);
      expect(tester.renderObject<RenderParagraph>(_summaryText()).didExceedMaxLines, safeArea);
      expect(find.text('manga-title-1'), findsOneWidget);
      expect(find.text('manga-title-2'), findsNothing);
      expect(_summaryCounts(tester), [1, 0, 1, 1234567890123456789]);
      expect(tester.widget<UpdateSummary>(find.byType(UpdateSummary)).selection, UpdateFilter.failure);
      expect(tester.takeException(), isNull);
    }
    tester.view.physicalSize = const Size(320.0, 800.0);
    await _pumpFrames(tester);
    expect(appBar().bottom, isNull);
    expect(tester.renderObject<RenderParagraph>(_summaryText()).didExceedMaxLines, isTrue);
    tester.view.physicalSize = const Size(800.0, 800.0);
    await _pumpFrames(tester);
    await tester.tap(_countButton(UpdateFilter.all));
    await _pumpFrames(tester);
    expect(find.text('manga-title-2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('The last result can scroll above the floating scan button', (tester) async {
    await _pumpPage(
      tester,
      manager: _Manager(),
      report: updateReportFixture(items: [for (var id = 1; id <= 12; id++) updateReportItemFixture(id)]).copyWith(totalTargets: 12),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0.0, -1600.0));
    await _pumpFrames(tester);
    final last = tester.getRect(find.widgetWithText(ListTile, 'manga-title-9'));
    final button = tester.getRect(find.byType(FloatingActionButton));
    expect(last.bottom, lessThanOrEqualTo(button.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Update status buttons retain icon size and align text and icons at 16dp',
    (tester) async {
      for (final complete in [false, true]) {
        await _pumpPage(
          tester,
          manager: _Manager(),
          report: updateReportFixture(items: [updateReportItemFixture(1)]),
          downloaded: complete ? {for (var i = 1; i <= 5; i++) 'chapter-title-$i'} : {},
        );
        final row = find.widgetWithText(ListTile, 'manga-title-1');
        expect(find.widgetWithText(TsukuyomiIconButtonListTile, 'manga-title-1'), findsOneWidget);
        final tile = tester.widget<ListTile>(row);
        final button = find.descendant(of: row, matching: find.byType(IconButton));
        final trailing = complete ? find.byIcon(Icons.check_circle_outline) : find.byType(AnimatedProgressCircleIcon);
        final icon = find.descendant(of: row, matching: trailing);
        final margin = tester.getRect(row).right - tester.getRect(icon).right;
        expect(margin, 16.0);
        expect(tester.getSize(icon), const Size.square(24.0));
        expect(tester.getRect(find.text('source-name')).left - tester.getRect(row).left, 16.0);
        expect(tester.getRect(icon).left - tester.getRect(find.byWidget(tile.title!)).right, 16.0);
        expect(tester.getRect(icon).left - tester.getRect(find.byWidget(tile.subtitle!)).right, 16.0);
        expect(tester.getSize(button), const Size.square(48.0));
        expect(tester.getSize(find.descendant(of: button, matching: find.byType(InkWell))), const Size.square(40.0));
        expect(tester.widget<IconButton>(button).onPressed, isNull);
        if (!complete) {
          final paint = find.descendant(of: trailing, matching: find.byType(CustomPaint));
          expect(tester.getSize(paint), const Size.square(24.0));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpFrames(tester);
      }
    },
    variant: TargetPlatformVariant.all(),
  );
}

Future<ProviderContainer> _pumpPage(
  WidgetTester tester, {
  required _Manager manager,
  UpdateReport? report,
  double textScale = 1.0,
  Locale locale = const Locale('en'),
  Stream<List<DatabaseChapter>> Function(int)? chapterStream,
  Set<String>? downloaded,
  FutureOr<Set<String>> Function(int)? downloadedForManga,
  Iterable<int> mangaIds = const [],
}) async {
  SharedPreferences.setMockInitialValues({if (report != null) Keys.updateReportLatest: jsonEncode(report.toJson())});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      updateManagerProvider.overrideWith(() => manager),
      if (downloaded != null) _downloadedProvider.overrideWith((ref) => downloaded),
      for (final id in {1, ...mangaIds, ...?report?.items.map((item) => item.mangaId)}) ...[
        chaptersStreamByMangaProvider(id).overrideWith((ref) => chapterStream?.call(id) ?? Stream.value(chaptersFixture(id))),
        updateDownloadedChaptersProvider(id).overrideWith((ref) async => downloadedForManga?.call(id) ?? ref.watch(_downloadedProvider)),
      ],
    ],
  );
  addTearDown(container.dispose);
  final app = MaterialApp(
    theme: TsukuyomiTheme(container.read(themePredefinedProvider).first).themeData,
    locale: locale,
    localizationsDelegates: TsukuyomiLocalizations.localizationsDelegates,
    supportedLocales: TsukuyomiLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const UpdatePage(),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: app,
    ),
  );
  await _pumpFrames(tester);
  // 首批异步数据可能在上一帧才触发进度动画，继续推进到绘制完成
  await tester.pump(const Duration(seconds: 1));
  return container;
}

void _narrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(360.0, 800.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder _countButton(UpdateFilter filter) {
  final index = [UpdateFilter.failure, UpdateFilter.warning, UpdateFilter.success, UpdateFilter.all].indexOf(filter);
  return find.descendant(of: find.byType(UpdateSummary), matching: find.byType(InkWell)).at(index);
}

Finder _summaryText() => find.descendant(
  of: find.byType(UpdateSummary),
  matching: find.byWidgetPredicate((widget) => widget is Text && widget.textSpan != null),
);

Finder _countText(UpdateFilter filter) => find.descendant(of: _countButton(filter), matching: find.byType(Text));

List<int> _summaryCounts(WidgetTester tester) => [
  for (final filter in [UpdateFilter.failure, UpdateFilter.warning, UpdateFilter.success, UpdateFilter.all])
    int.parse(tester.widget<Text>(_countText(filter)).data!),
];

Finder _completionIcon(String title) {
  final tile = find.widgetWithText(ListTile, title);
  return find.descendant(of: tile, matching: find.byIcon(Icons.check_circle_outline));
}

Finder _retryButton(String title) => find.descendant(of: find.widgetWithText(ListTile, title), matching: find.byType(IconButton));

double _progress(WidgetTester tester, String title) => tester
    .widget<AnimatedProgressCircleIcon>(
      find.descendant(of: find.widgetWithText(ListTile, title), matching: find.byType(AnimatedProgressCircleIcon)),
    )
    .progress;

double _paintedProgress(WidgetTester tester, String title) {
  final icon = tester.widget<CustomPaint>(
    find.descendant(
      of: find.widgetWithText(ListTile, title),
      matching: find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is ProgressCircleIconPainter),
    ),
  );
  return (icon.painter! as ProgressCircleIconPainter).progress;
}

class _Manager extends UpdateManager {
  int _scans = 0;
  int _stops = 0;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<void> scan() async {
    _scans++;
    state = const AsyncLoading();
  }

  @override
  void stop() => _stops++;

  void _finish() => state = const AsyncData(null);

  void _fail(Object error) => state = AsyncError(error, StackTrace.current);
}

// 页面共享动画持续循环，仅推进有限的进度、路由和滚动动画
Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}
