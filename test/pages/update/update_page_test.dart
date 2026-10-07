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
import 'package:tsukuyomi/pages/update/update_progress_provider.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/providers/theme/theme_predefined_provider.dart';
import 'package:tsukuyomi/providers/update/update_manager.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

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
    expect(find.text('0 · 0 · 0 / 0'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.stop_outlined), findsOneWidget);

    final report = _report(phase: UpdatePhase.running, items: [_item(1)]);
    await container.read(updateReportStoreProvider.notifier).save(report);
    await tester.pumpAndSettle();
    expect(find.text('0 · 0 · 1 / 2'), findsOneWidget);
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
    expect(find.text('0 · 0 · 1 / 2'), findsOneWidget);
    expect(find.byTooltip('Scan library'), findsOneWidget);
  });

  testWidgets('Errors and warnings have separate counts and colors without detail dialogs', (tester) async {
    _narrowScreen(tester);
    final container = await _pumpPage(
      tester,
      manager: _Manager(),
      textScale: 1.3,
      chapterStream: (id) => Stream.value(id == 2 ? [] : _chapters(id)),
      report: _report(
        phase: UpdatePhase.running,
        items: [
          _item(1).copyWith(outcome: UpdateOutcome.enqueueFailed, message: 'queue-error', sourceCount: 8),
          _item(2).copyWith(outcome: UpdateOutcome.chaptersEmpty, sourceCount: 0),
        ],
      ),
    );

    expect(container.read(updateReportStoreProvider)!.phase, UpdatePhase.interrupted);
    final summary = tester.widget<Text>(find.text('1 · 1 · 2 / 2'));
    final spans = (summary.textSpan! as TextSpan).children!;
    final colors = Theme.of(tester.element(find.text('Queue / start failed'))).colorScheme;
    expect(spans[0].style?.color, colors.error);
    expect(spans[2].style?.color, colors.tertiary);
    expect(summary.style?.color, colors.onSurface);
    expect(tester.widget<Text>(find.text('Queue / start failed')).style?.color, colors.error);
    expect(tester.widget<Text>(find.text('No chapters')).style?.color, colors.tertiary);
    expect(find.text('2 / 5'), findsOneWidget);
    expect(find.text('0 / 0'), findsOneWidget);
    expect(_progress(tester, 'manga-title-2'), 0.0);
    expect(find.byIcon(Icons.info_outline), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Global errors color the summary icon and empty results have no prompts', (tester) async {
    final manager = _Manager();
    final container = await _pumpPage(
      tester,
      manager: manager,
      report: _report(message: 'query-error').copyWith(totalTargets: 0),
    );
    final summaryIcon = find.descendant(of: find.byType(SliverAppBar), matching: find.byType(AnimatedProgressCircleIcon));
    Color? iconColor() => IconTheme.of(tester.element(summaryIcon)).color;
    final colors = Theme.of(tester.element(summaryIcon)).colorScheme;
    expect(find.text('0 · 0 · 0 / 0'), findsOneWidget);
    expect(iconColor(), colors.error);
    expect(find.byType(ListTile), findsNothing);

    await container.read(updateReportStoreProvider.notifier).save(_report().copyWith(totalTargets: 0));
    manager._fail(StateError('save-error'));
    await tester.pumpAndSettle();
    expect(iconColor(), colors.error);
    expect(find.byTooltip('Scan library'), findsOneWidget);
    manager._finish();
    await tester.pumpAndSettle();
    expect(iconColor(), colors.onSurface);
    expect(find.byType(Text), findsNWidgets(2));
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Public chapter downloads update live after scanning without rewriting the report', (tester) async {
    final chapters = StreamController<List<DatabaseChapter>>();
    addTearDown(chapters.close);
    chapters.add(_chapters(1));
    final container = await _pumpPage(
      tester,
      manager: _Manager(),
      chapterStream: (_) => chapters.stream,
      report: _report(items: [_item(1)]).copyWith(totalTargets: 1),
    );
    final report = container.read(updateReportStoreProvider);
    expect(find.text('2 / 5'), findsOneWidget);
    expect(_progress(tester, 'manga-title-1'), 0.4);
    container.read(_downloadedProvider.notifier).state = {for (var id = 1; id <= 7; id++) 'chapter-title-$id', 'removed-chapter'};
    await tester.pumpAndSettle();
    expect(find.text('5 / 5'), findsOneWidget);
    expect(_progress(tester, 'manga-title-1'), 1.0);

    chapters.add(_chapters(1, publicCount: 6));
    await tester.pumpAndSettle();
    expect(find.text('6 / 6'), findsOneWidget);
    expect(_progress(tester, 'manga-title-1'), 1.0);
    expect(container.read(updateReportStoreProvider), report);
    expect(find.text('0 · 0 · 1 / 1'), findsOneWidget);
  });

  testWidgets('Long names and chapter counts remain readable in both languages on narrow screens', (tester) async {
    _narrowScreen(tester);
    final item = _item(1).copyWith(
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
        chapterStream: (id) => Stream.value(_chapters(id, total: 1002, publicCount: 1000)),
        downloaded: {for (var id = 1; id <= 999; id++) 'chapter-title-$id', 'chapter-title-1002'},
        report: _report(items: [item]).copyWith(totalTargets: 1),
      );
      expect(find.text(item.mangaTitle), findsOneWidget);
      expect(find.text('999 / 1000'), findsOneWidget);
      expect(tester.renderObject<RenderParagraph>(find.text('999 / 1000')).didExceedMaxLines, isFalse);
      expect(find.text('0 · 0 · 1 / 1'), findsOneWidget);
      expect(tester.renderObject<RenderParagraph>(find.text('0 · 0 · 1 / 1')).didExceedMaxLines, isFalse);
      expect(_progress(tester, item.mangaTitle), 0.999);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });

  testWidgets('The last result can scroll above the floating scan button', (tester) async {
    await _pumpPage(
      tester,
      manager: _Manager(),
      report: _report(items: [for (var id = 1; id <= 12; id++) _item(id)]).copyWith(totalTargets: 12),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0.0, -1600.0));
    await tester.pumpAndSettle();
    final last = tester.getRect(find.widgetWithText(ListTile, 'manga-title-12'));
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
}) async {
  SharedPreferences.setMockInitialValues({if (report != null) UpdateReportStore.reportKey: jsonEncode(report.toJson())});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      updateManagerProvider.overrideWith(() => manager),
      if (downloaded != null) _downloadedProvider.overrideWith((ref) => downloaded),
      for (final id in {1, ...?report?.items.map((item) => item.mangaId)}) ...[
        chaptersStreamByMangaProvider(id).overrideWith((ref) => chapterStream?.call(id) ?? Stream.value(_chapters(id))),
        updateDownloadedChaptersProvider(id).overrideWith((ref) async => ref.watch(_downloadedProvider)),
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

double _progress(WidgetTester tester, String title) => tester
    .widget<AnimatedProgressCircleIcon>(
      find.descendant(of: find.widgetWithText(ListTile, title), matching: find.byType(AnimatedProgressCircleIcon)),
    )
    .progress;

List<DatabaseChapter> _chapters(int mangaId, {int total = 7, int publicCount = 5}) => [
  for (var id = 1; id <= total; id++)
    DatabaseChapter(
      id: id,
      manga: mangaId,
      index: id,
      title: 'chapter-title-$id',
      url: 'chapter-url-$id',
      date: 'chapter-date',
      public: id <= publicCount,
      images: 0,
      progress: 0,
    ),
];

UpdateReport _report({UpdatePhase phase = UpdatePhase.finished, List<UpdateReportItem> items = const [], String? message}) => UpdateReport(
  version: UpdateReport.currentVersion,
  phase: phase,
  scanKind: UpdateScanKind.full,
  sessionId: 'scan-session',
  totalTargets: 2,
  items: items,
  startedAt: DateTime(2026, 10, 7, 18),
  message: message,
);

UpdateReportItem _item(int id) => UpdateReportItem(
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
