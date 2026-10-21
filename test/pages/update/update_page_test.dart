import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/database/database.dart' show DatabaseChapter;
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/pages/update/update_page.dart';
import 'package:tsukuyomi/pages/update/update_filter.dart';
import 'package:tsukuyomi/pages/update/update_progress_provider.dart';
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
    await tester.tap(find.byTooltip('Scan library'));
    await tester.pump();
    expect(manager._scans, 1);
    expect(_summaryCounts(tester), [0, 0, 0, 0]);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.stop_outlined), findsOneWidget);

    final report = updateReportFixture(phase: UpdatePhase.running, items: [updateReportItemFixture(1)]);
    await container.read(updateReportStoreProvider.notifier).save(report);
    await tester.pumpAndSettle();
    expect(_summaryCounts(tester), [0, 0, 1, 2]);
    expect(find.text('2 / 5'), findsOneWidget);
    final summary = find.descendant(of: find.byType(SliverAppBar), matching: find.byType(AnimatedProgressCircleIcon));
    expect(tester.widget<AnimatedProgressCircleIcon>(summary).progress, 0.5);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.tap(find.byTooltip('Stop scanning after the current manga'));
    await tester.pump();
    expect(manager._stops, 1);
    expect(find.byTooltip('Scan library'), findsNothing);
    await container.read(updateReportStoreProvider.notifier).save(report.copyWith(phase: UpdatePhase.cancelled));
    manager._finish();
    await tester.pumpAndSettle();
    expect(_summaryCounts(tester), [0, 0, 1, 2]);
    expect(find.byTooltip('Scan library'), findsOneWidget);
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
        items: [
          updateReportItemFixture(1).copyWith(outcome: UpdateOutcome.enqueueFailed, message: 'queue-error', sourceCount: 8),
          updateReportItemFixture(2).copyWith(outcome: UpdateOutcome.chaptersEmpty, sourceCount: 0),
        ],
      ),
    );

    expect(container.read(updateReportStoreProvider)!.phase, UpdatePhase.interrupted);
    final colors = Theme.of(tester.element(find.text('Queue / start failed'))).colorScheme;
    expect(_summaryCounts(tester), [1, 1, 0, 2]);
    expect(tester.widget<Text>(_countText(UpdateFilter.failure)).style?.color, colors.error);
    expect(tester.widget<Text>(_countText(UpdateFilter.warning)).style?.color, colors.tertiary);
    expect(tester.widget<Text>(_countText(UpdateFilter.success)).style?.color, colors.onSurface);
    expect(tester.widget<Text>(find.text('Queue / start failed')).style?.color, colors.error);
    expect(tester.widget<Text>(find.text('No chapters')).style?.color, colors.tertiary);
    expect(find.text('2 / 5'), findsOneWidget);
    expect(find.text('0 / 0'), findsOneWidget);
    expect(_progress(tester, 'manga-title-2'), 0.0);
    expect(find.byIcon(Icons.info_outline), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Summary counts only completed outcomes while scan progress includes errors and warnings', (tester) async {
    final items = [
      updateReportItemFixture(1).copyWith(outcome: UpdateOutcome.networkError),
      updateReportItemFixture(2).copyWith(outcome: UpdateOutcome.chaptersEmpty),
      updateReportItemFixture(3).copyWith(outcome: UpdateOutcome.chaptersReduced),
      updateReportItemFixture(4),
      updateReportItemFixture(5).copyWith(outcome: UpdateOutcome.noUpdate),
      updateReportItemFixture(6),
    ];
    for (final locale in [const Locale('en'), const Locale('zh')]) {
      final manager = _Manager();
      final report = updateReportFixture(totalTargets: 10, items: items);
      final container = await _pumpPage(tester, manager: manager, report: report, locale: locale, mangaIds: [7, 8, 9, 10]);
      final store = container.read(updateReportStoreProvider.notifier);
      final summaryIcon = find.descendant(of: find.byType(SliverAppBar), matching: find.byType(AnimatedProgressCircleIcon));

      for (final phase in [UpdatePhase.running, UpdatePhase.cancelled, UpdatePhase.interrupted]) {
        if (phase == UpdatePhase.running) {
          await manager.scan();
        } else {
          manager._finish();
        }
        await store.save(report.copyWith(phase: phase));
        await tester.pumpAndSettle();
        expect(_summaryCounts(tester), [1, 2, 3, 10]);
        expect(tester.widget<AnimatedProgressCircleIcon>(summaryIcon).progress, 0.6);
        final label = locale.languageCode == 'en'
            ? '1 errors · 2 warnings · 3 successful checks / 10 manga'
            : '错误 1 部 · 警告 2 部 · 成功 3 部 / 总数 10 部';
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }

      final completed = [...items, for (var id = 7; id <= 10; id++) updateReportItemFixture(id)];
      await store.save(report.copyWith(items: completed));
      await tester.pumpAndSettle();
      expect(_summaryCounts(tester), [1, 2, 7, 10]);
      final summaryCheck = find.descendant(of: find.byType(SliverAppBar), matching: find.byIcon(Icons.check_circle_outline));
      expect(summaryCheck, findsOneWidget);
      expect(summaryIcon, findsNothing);

      for (final total in [10, 0]) {
        await store.save(report.copyWith(items: [], totalTargets: total));
        await tester.pumpAndSettle();
        expect(_summaryCounts(tester), [0, 0, 0, total]);
        expect(tester.widget<AnimatedProgressCircleIcon>(summaryIcon).progress, 0.0);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Scan completion checks retain outcome colors and require a fully finished scan', (tester) async {
    for (final outcome in [UpdateOutcome.updated, UpdateOutcome.chaptersEmpty, UpdateOutcome.networkError]) {
      final manager = _Manager();
      final report = updateReportFixture(totalTargets: 1, items: [updateReportItemFixture(1).copyWith(outcome: outcome)]);
      final container = await _pumpPage(tester, manager: manager, report: report);
      final store = container.read(updateReportStoreProvider.notifier);
      final summaryCheck = find.descendant(of: find.byType(SliverAppBar), matching: find.byIcon(Icons.check_circle_outline));
      final summaryProgress = find.descendant(of: find.byType(SliverAppBar), matching: find.byType(AnimatedProgressCircleIcon));
      expect(summaryCheck, findsOneWidget);
      expect(_completionIcon('manga-title-1'), findsNothing);
      final colors = Theme.of(tester.element(summaryCheck)).colorScheme;
      final color = switch (outcome) {
        UpdateOutcome.chaptersEmpty => colors.tertiary,
        UpdateOutcome.networkError => colors.error,
        _ => colors.onSurface,
      };
      expect(tester.widget<Icon>(summaryCheck).color, color);

      for (final phase in [UpdatePhase.running, UpdatePhase.cancelled, UpdatePhase.interrupted]) {
        if (phase == UpdatePhase.running) {
          await manager.scan();
        } else {
          manager._finish();
        }
        await store.save(report.copyWith(phase: phase));
        await tester.pumpAndSettle();
        expect(summaryCheck, findsNothing);
        expect(tester.widget<AnimatedProgressCircleIcon>(summaryProgress).progress, 1.0);
      }

      await store.save(report.copyWith(totalTargets: 2));
      await tester.pumpAndSettle();
      expect(summaryCheck, findsNothing);
      expect(tester.widget<AnimatedProgressCircleIcon>(summaryProgress).progress, 0.5);

      await store.save(report.copyWith(message: 'fixture-scan-error'));
      await tester.pumpAndSettle();
      expect(summaryCheck, findsNothing);
      expect(IconTheme.of(tester.element(summaryProgress)).color, colors.error);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Global errors color the summary icon and empty results have no prompts', (tester) async {
    final manager = _Manager();
    final container = await _pumpPage(
      tester,
      manager: manager,
      report: updateReportFixture(message: 'query-error').copyWith(totalTargets: 0),
    );
    final summaryIcon = find.descendant(of: find.byType(SliverAppBar), matching: find.byType(AnimatedProgressCircleIcon));
    Color? iconColor() => IconTheme.of(tester.element(summaryIcon)).color;
    final colors = Theme.of(tester.element(summaryIcon)).colorScheme;
    expect(_summaryCounts(tester), [0, 0, 0, 0]);
    expect(iconColor(), colors.error);
    expect(find.byType(ListTile), findsNothing);

    await container.read(updateReportStoreProvider.notifier).save(updateReportFixture().copyWith(totalTargets: 0));
    manager._fail(StateError('save-error'));
    await tester.pumpAndSettle();
    expect(iconColor(), colors.error);
    expect(find.byTooltip('Scan library'), findsOneWidget);
    manager._finish();
    await tester.pumpAndSettle();
    expect(iconColor(), colors.onSurface);
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
    await tester.pumpAndSettle();
    expect(find.text('5 / 5'), findsOneWidget);
    expect(_completionIcon('manga-title-1'), findsOneWidget);

    chapters.add(chaptersFixture(1, publicCount: 6));
    await tester.pumpAndSettle();
    expect(find.text('6 / 6'), findsOneWidget);
    expect(_completionIcon('manga-title-1'), findsOneWidget);

    chapters.add(chaptersFixture(1, total: 9, publicCount: 8));
    await tester.pumpAndSettle();
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
        updateReportItemFixture(3).copyWith(outcome: UpdateOutcome.chaptersReduced),
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
    for (var id = 1; id <= 3; id++) {
      expect(_completionIcon('manga-title-$id'), findsOneWidget);
      expect(tester.widget<Icon>(_completionIcon('manga-title-$id')).color, colors.onSurface);
    }
    expect(_completionIcon('manga-title-4'), findsNothing);
    expect(_progress(tester, 'manga-title-4'), 0.8);
    expect(_completionIcon('manga-title-5'), findsNothing);
    expect(_progress(tester, 'manga-title-5'), 0.0);
    expect(find.text('0 / 0'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Request failed')).style?.color, colors.error);
    expect(tester.widget<Text>(find.text('Chapters removed')).style?.color, colors.tertiary);
    expect(_summaryCounts(tester), [1, 1, 3, 5]);
    expect(container.read(updateReportStoreProvider), report);
    expect(tester.takeException(), isNull);
  });

  for (final input in ['chapters', 'downloads']) {
    testWidgets('Retained complete counts do not show a check while $input reload or fail', (tester) async {
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
      await tester.pumpAndSettle();
      expect(find.text('5 / 5'), findsOneWidget);
      expect(_completionIcon('manga-title-1'), findsNothing);
      expect(_progress(tester, 'manga-title-1'), 1.0);

      pending.completeError(StateError('fixture-$input-error'));
      await tester.pumpAndSettle();
      expect(find.text('5 / 5'), findsOneWidget);
      expect(_completionIcon('manga-title-1'), findsNothing);
      final icon = find.descendant(of: find.widgetWithText(ListTile, 'manga-title-1'), matching: find.byType(AnimatedProgressCircleIcon));
      expect(IconTheme.of(tester.element(icon)).color, Theme.of(tester.element(icon)).colorScheme.error);

      pending = null;
      container.invalidate(provider);
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    expect(first.isCompleted, isFalse);
    expect(_progress(tester, 'manga-title-2'), 6 / 7);

    first.complete({'chapter-title-1', 'chapter-title-5', 'removed-chapter'});
    await tester.pumpAndSettle();
    expect(_progress(tester, 'manga-title-1'), 1 / 3);
    expect(_progress(tester, 'manga-title-2'), 6 / 7);
    expect(container.read(updateReportStoreProvider), report);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A local progress error leaves other manga and scan results observable', (tester) async {
    final error = StateError('fixture-directory-error');
    final report = updateReportFixture(items: [updateReportItemFixture(1), updateReportItemFixture(2)]);
    final container = await _pumpPage(
      tester,
      manager: _Manager(),
      report: report,
      downloadedForManga: (id) {
        if (id == 1) throw error;
        return {'chapter-title-1', 'chapter-title-2', 'chapter-title-3'};
      },
    );

    final firstIcon = find.descendant(
      of: find.widgetWithText(ListTile, 'manga-title-1'),
      matching: find.byType(AnimatedProgressCircleIcon),
    );
    final colors = Theme.of(tester.element(firstIcon)).colorScheme;
    expect(container.read(updateDownloadedChaptersProvider(1)).error, same(error));
    expect(IconTheme.of(tester.element(firstIcon)).color, colors.error);
    expect(_progress(tester, 'manga-title-2'), 0.6);
    expect(container.read(updateReportStoreProvider), report);
    expect(report.failureCount, 0);
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
    await tester.pumpAndSettle();
    expect(find.text('20 / 40'), findsOneWidget);
    expect(_progress(tester, 'manga-title-40'), 0.5);
    expect(container.read(updateReportStoreProvider), report);
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
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    expect(_paintedProgress(tester, 'manga-title-40'), 0.0);
    last.complete({for (var id = 1; id <= 20; id++) 'chapter-title-$id'});
    await tester.pumpAndSettle();
    expect(_paintedProgress(tester, 'manga-title-40'), 0.5);

    await tester.scrollUntilVisible(find.text('manga-title-1'), -500.0, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(_completionIcon('manga-title-1'), findsOneWidget);
    expect(find.descendant(of: find.widgetWithText(ListTile, 'manga-title-1'), matching: find.text('1 / 1')), findsOneWidget);
    expect(container.read(updateReportStoreProvider), report);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Four counts filter sorted source titles without changing the report or totals', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final report = updateReportFixture(
        totalTargets: 10,
        items: [
          updateReportItemFixture(1).copyWith(sourceName: 'B', mangaTitle: 'A'),
          updateReportItemFixture(2).copyWith(sourceName: 'A', mangaTitle: 'Z', outcome: UpdateOutcome.networkError),
          updateReportItemFixture(3).copyWith(sourceName: 'A', mangaTitle: 'A', outcome: UpdateOutcome.chaptersEmpty),
          updateReportItemFixture(4).copyWith(sourceName: 'A', mangaTitle: 'M', outcome: UpdateOutcome.noUpdate),
        ],
      );
      final container = await _pumpPage(tester, manager: _Manager(), report: report);
      List<int> ids() {
        final visible = [
          for (var id = 1; id <= 4; id++)
            if (find.byKey(ValueKey(id)).evaluate().isNotEmpty) id,
        ];
        double top(int id) => tester.getTopLeft(find.byKey(ValueKey(id))).dy;
        return visible..sort((a, b) => top(a).compareTo(top(b)));
      }

      expect(ids(), [3, 4, 2, 1]);
      final tile = tester.widget<ListTile>(find.widgetWithText(ListTile, 'Z'));
      expect(find.descendant(of: find.byWidget(tile.title!), matching: find.text('A')), findsOneWidget);
      expect(find.descendant(of: find.byWidget(tile.subtitle!), matching: find.text('Z')), findsOneWidget);

      for (final filter in [UpdateFilter.failure, UpdateFilter.warning, UpdateFilter.success]) {
        await tester.tap(_countButton(filter));
        await tester.pumpAndSettle();
        expect(ids(), switch (filter) {
          UpdateFilter.failure => [2],
          UpdateFilter.warning => [3],
          _ => [4, 1],
        });
        expect(_summaryCounts(tester), [1, 1, 2, 10]);
        final data = tester.getSemantics(_countButton(filter)).getSemanticsData();
        expect(data.flagsCollection.isSelected.toBoolOrNull(), isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(container.read(updateReportStoreProvider), report);
      }
      await tester.tap(_countButton(UpdateFilter.success));
      await tester.pumpAndSettle();
      expect(ids(), [3, 4, 2, 1]);
      for (var repeat = 0; repeat < 2; repeat++) {
        await tester.tap(_countButton(UpdateFilter.all));
        await tester.pumpAndSettle();
        expect(ids(), [3, 4, 2, 1]);
      }
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('A zero-count filter is clearable and scan arrivals keep filtering until a new session', (tester) async {
    final manager = _Manager();
    final report = updateReportFixture(totalTargets: 10, items: [updateReportItemFixture(1).copyWith(sourceName: 'B')]);
    final container = await _pumpPage(tester, manager: manager, report: report, mangaIds: [2, 3]);
    final store = container.read(updateReportStoreProvider.notifier);
    await manager.scan();
    await tester.tap(_countButton(UpdateFilter.failure));
    await tester.pumpAndSettle();
    expect(find.text('No results for this filter'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    final matching = updateReportItemFixture(2).copyWith(sourceName: 'A', outcome: UpdateOutcome.parseError);
    await store.save(report.copyWith(items: [...report.items, matching]));
    await tester.pumpAndSettle();
    expect(find.text('manga-title-1'), findsNothing);
    expect(find.text('manga-title-2'), findsOneWidget);
    expect(_summaryCounts(tester), [1, 0, 1, 10]);
    expect(_paintedProgress(tester, 'manga-title-2'), 0.4);
    await store.save(report.copyWith(items: [...report.items, matching, updateReportItemFixture(3)]));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(_summaryCounts(tester), [1, 0, 2, 10]);
    await tester.tap(_countButton(UpdateFilter.all));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(3));
    await tester.tap(_countButton(UpdateFilter.failure));
    await tester.pumpAndSettle();
    await store.save(report.copyWith(sessionId: 'next-scan'));
    await tester.pumpAndSettle();
    expect(find.text('manga-title-1'), findsOneWidget);
    expect(find.text('No results for this filter'), findsNothing);
    expect(tester.getSize(_countButton(UpdateFilter.all)).height, greaterThanOrEqualTo(44.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Count badges stay compact and grow into capsules for large values on narrow screens', (tester) async {
    _narrowScreen(tester);
    final report = updateReportFixture(totalTargets: 1, items: [updateReportItemFixture(1)]);
    final container = await _pumpPage(tester, manager: _Manager(), report: report);
    Finder badge(UpdateFilter filter) => find.descendant(
      of: _countButton(filter),
      matching: find.byWidgetPredicate((widget) => widget is Container && widget.decoration is ShapeDecoration),
    );
    final small = tester.getSize(badge(UpdateFilter.all));
    expect(small, const Size(36.0, 36.0));
    expect(tester.getSize(_countButton(UpdateFilter.all)).height, greaterThan(small.height));
    for (final count in [12, 123, 12345]) {
      await container.read(updateReportStoreProvider.notifier).save(report.copyWith(totalTargets: count));
      await tester.pumpAndSettle();
      final large = tester.getSize(badge(UpdateFilter.all));
      expect(large.height, small.height);
      expect(large.width, greaterThanOrEqualTo(large.height));
      expect(tester.renderObject<RenderParagraph>(_countText(UpdateFilter.all)).didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    }
    expect(tester.getSize(badge(UpdateFilter.all)).width, greaterThan(small.width));
  });

  testWidgets('Large counts and fonts keep all four actions accessible in both languages', (tester) async {
    tester.view.physicalSize = const Size(320.0, 800.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final locale in [const Locale('en'), const Locale('zh')]) {
      await _pumpPage(tester, manager: _Manager(), locale: locale, textScale: 1.3, report: updateReportFixture(totalTargets: 12345));
      expect(_summaryCounts(tester), [0, 0, 0, 12345]);
      expect(tester.widget<SliverAppBar>(find.byType(SliverAppBar)).bottom, isNotNull);
      final all = _countButton(UpdateFilter.all);
      await tester.ensureVisible(all);
      await tester.tap(all);
      await tester.pumpAndSettle();
      expect(tester.renderObject<RenderParagraph>(_countText(UpdateFilter.all)).didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('The last result can scroll above the floating scan button', (tester) async {
    await _pumpPage(
      tester,
      manager: _Manager(),
      report: updateReportFixture(items: [for (var id = 1; id <= 12; id++) updateReportItemFixture(id)]).copyWith(totalTargets: 12),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0.0, -1600.0));
    await tester.pumpAndSettle();
    final last = tester.getRect(find.widgetWithText(ListTile, 'manga-title-9'));
    final button = tester.getRect(find.byType(FloatingActionButton));
    expect(last.bottom, lessThanOrEqualTo(button.top));
    expect(tester.takeException(), isNull);
  });
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
  SharedPreferences.setMockInitialValues({if (report != null) UpdateReportStore.reportKey: jsonEncode(report.toJson())});
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
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: TsukuyomiTheme(container.read(themePredefinedProvider).first).themeData,
        locale: locale,
        localizationsDelegates: TsukuyomiLocalizations.localizationsDelegates,
        supportedLocales: TsukuyomiLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const UpdatePage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void _narrowScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(360.0, 800.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Finder _countButton(UpdateFilter filter) => find.byKey(ValueKey(filter));

Finder _countText(UpdateFilter filter) => find.descendant(of: _countButton(filter), matching: find.byType(Text));

List<int> _summaryCounts(WidgetTester tester) => [
  for (final filter in [UpdateFilter.failure, UpdateFilter.warning, UpdateFilter.success, UpdateFilter.all])
    int.parse(tester.widget<Text>(_countText(filter)).data!),
];

Finder _completionIcon(String title) {
  final tile = find.widgetWithText(ListTile, title);
  return find.descendant(of: tile, matching: find.byIcon(Icons.check_circle_outline));
}

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
