import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/pages/update/update_page.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/providers/update/update_manager.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

void main() {
  setUpAll(() => TsukuyomiLocalizations.delegate.load(const Locale('zh')));

  testWidgets('Scan controls follow manager state and display live report counts', (tester) async {
    final manager = _Manager();
    final container = await _pumpPage(tester, manager: manager);

    expect(manager._scans, 0);
    expect(find.text('尚未检查'), findsOneWidget);
    await tester.tap(find.byTooltip('扫描书架'));
    await tester.pump();
    expect(manager._scans, 1);
    expect(find.byTooltip('扫描书架'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    final report = _report(phase: UpdatePhase.running, items: [_item(1)]);
    await container.read(updateReportStoreProvider.notifier).save(report);
    await tester.pump();
    expect(find.text('已检查 1 / 2 部'), findsOneWidget);
    expect(find.text('入队 2 章 · 警告 0 部 · 失败 0 部'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.5);

    await tester.tap(find.byTooltip('当前漫画处理完成后停止扫描'));
    await tester.pump();
    expect(manager._stops, 1);
    expect(find.byTooltip('扫描书架'), findsNothing);

    await container.read(updateReportStoreProvider.notifier).save(report.copyWith(phase: UpdatePhase.cancelled));
    manager._finish();
    await tester.pumpAndSettle();
    expect(find.text('扫描已停止'), findsOneWidget);
    expect(find.text('漫画1'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byTooltip('扫描书架'), findsOneWidget);
  });

  testWidgets('Restored interrupted results retain warnings, failure counts and error details on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(360.0, 800.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final manager = _Manager();
    const error = 'chapter-url: insert-error\nstart-error';
    await _pumpPage(
      tester,
      manager: manager,
      textScale: 1.3,
      report: _report(
        phase: UpdatePhase.running,
        items: [
          _item(1).copyWith(
            outcome: UpdateOutcome.enqueueFailed,
            sourceCount: 8,
            enqueueFailedCount: 1,
            failedChapters: ['chapter-url'],
            message: error,
          ),
          _item(2).copyWith(
            outcome: UpdateOutcome.chaptersEmpty,
            sourceCount: 0,
            insertCount: 0,
            enqueuedCount: 0,
            skippedDownloaded: 0,
            skippedQueued: 0,
            skippedUnavailable: 0,
          ),
        ],
      ),
    );

    expect(manager._scans, 0);
    expect(find.text('上次扫描已中断'), findsOneWidget);
    expect(find.text('已检查 2 / 2 部'), findsOneWidget);
    expect(find.text('入队 2 章 · 警告 1 部 · 失败 1 部'), findsOneWidget);
    expect(find.text('示例漫画源 · 加入或启动下载失败'), findsOneWidget);
    expect(find.text('示例漫画源 · 章节列表为空'), findsOneWidget);
    expect(find.text('章节 8 · 新增 1 · 移除 0\n入队 2 · 入队失败 1'), findsOneWidget);
    expect(find.text('跳过：已下载 2 · 已排队 1 · 未公开 2'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('查看错误详情'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SelectableText, error), findsOneWidget);
    expect(find.text('复制错误'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Scan and save errors remain visible and are not shown as an empty target list', (tester) async {
    final manager = _Manager();
    final container = await _pumpPage(
      tester,
      manager: manager,
      report: _report(message: 'query-error').copyWith(totalTargets: 0),
    );
    expect(find.widgetWithText(SelectableText, 'query-error'), findsOneWidget);
    expect(find.text('没有开启自动下载的收藏漫画'), findsNothing);

    manager._fail(StateError('save-error'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SelectableText, 'query-error\nBad state: save-error'), findsOneWidget);
    expect(find.byTooltip('扫描书架'), findsOneWidget);

    manager._finish();
    await container.read(updateReportStoreProvider.notifier).save(_report().copyWith(totalTargets: 0));
    await tester.pumpAndSettle();
    expect(find.text('没有开启自动下载的收藏漫画'), findsOneWidget);
  });
}

Future<ProviderContainer> _pumpPage(WidgetTester tester, {required _Manager manager, UpdateReport? report, double textScale = 1.0}) async {
  SharedPreferences.setMockInitialValues({if (report != null) UpdateReportStore.reportKey: jsonEncode(report.toJson())});
  final preferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      updateManagerProvider.overrideWith(() => manager),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('zh'),
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

UpdateReport _report({UpdatePhase phase = UpdatePhase.finished, List<UpdateReportItem> items = const [], String? message}) => UpdateReport(
  version: UpdateReport.currentVersion,
  phase: phase,
  scanKind: UpdateScanKind.full,
  sessionId: 'scan-session',
  totalTargets: 2,
  items: items,
  startedAt: DateTime(2026, 10, 6, 18),
  message: message,
);

UpdateReportItem _item(int id) => UpdateReportItem(
  sourceId: 1,
  sourceName: '示例漫画源',
  mangaId: id,
  mangaTitle: '漫画$id',
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
