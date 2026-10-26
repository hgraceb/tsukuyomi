import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/providers/update/update_manager.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

import 'update_controller.dart';
import 'update_filter.dart';
import 'update_progress_provider.dart';
import 'update_sort.dart';
import 'update_summary.dart';

/// 更新页面
class UpdatePage extends ConsumerWidget {
  const UpdatePage({super.key});

  /// 更新统计的扫描进度
  Widget _buildSummaryProgress(BuildContext context, UpdateReport? report, bool running, bool error) {
    final colors = Theme.of(context).colorScheme;
    final failures = report?.failureCount ?? 0;
    final warnings = report?.warningCount ?? 0;
    final processed = report?.items.length ?? 0;
    final total = report?.totalTargets ?? 0;
    final color = _getStatusColor(colors, error: error || failures > 0, warning: warnings > 0);
    final complete = !running && !error && report?.phase == UpdatePhase.finished && total > 0 && processed == total;
    if (running && total == 0) {
      return SizedBox.square(dimension: 24.0, child: CircularProgressIndicator(strokeWidth: 2.0, color: color));
    }
    return complete ? Icon(Icons.check_circle_outline, size: 24.0, color: color) : _buildProgress(processed, total, color);
  }

  /// 更新页面的应用栏
  Widget _buildAppBar(BuildContext context, UpdateSummary? summary) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final title = Text(l10n.updateTitle, maxLines: 1, overflow: TextOverflow.ellipsis);
    if (summary == null) return TsukuyomiSliverAppBar(title: title);

    final summarySize = summary.size(context);
    final painter = TextPainter(
      text: TextSpan(text: l10n.updateTitle, style: Theme.of(context).textTheme.titleLarge),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = MediaQuery.sizeOf(context).width - MediaQuery.paddingOf(context).horizontal;
    final summaryBelow = width < summarySize.width + painter.width + 48.0;
    painter.dispose();

    return TsukuyomiSliverAppBar(
      title: title,
      actions: summaryBelow ? null : [Padding(padding: const EdgeInsets.only(right: 8.0), child: summary)],
      bottom: summaryBelow ? _buildSummaryBottom(summary, summarySize) : null,
    );
  }

  /// 窄屏下显示在应用栏底部的更新统计
  PreferredSizeWidget _buildSummaryBottom(UpdateSummary summary, Size size) {
    return PreferredSize(
      preferredSize: Size.fromHeight(size.height + 8.0),
      child: SizedBox(
        height: size.height + 8.0,
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: summary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final selection = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    final manager = ref.watch(updateManagerProvider);
    final report = ref.watch(updateReportStoreProvider);
    final scanner = ref.read(updateManagerProvider.notifier);
    final running = manager.isLoading;
    final error = manager.hasError || report?.message?.isNotEmpty == true;
    final filter = selection ?? UpdateFilter.all;
    final results = report?.items ?? [];
    final items = results.where(filter.matches).toList()..sort(compareUpdateItems);
    final itemIndexes = {for (var index = 0; index < items.length; index++) items[index].mangaId: index};
    final showSummary = running || error || report != null && report.phase != UpdatePhase.idle;
    final summary = UpdateSummary(
      report: report,
      selection: selection,
      onChanged: controller.onFilterChanged,
      progress: _buildSummaryProgress(context, report, running, error),
    );

    return TsukuyomiScaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context, showSummary ? summary : null),
            if (items.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 96.0),
                sliver: SliverPrototypeExtentList.builder(
                  prototypeItem: const ListTile(title: Text(''), subtitle: Text('')),
                  itemCount: items.length,
                  findChildIndexCallback: (key) => key is ValueKey<int> ? itemIndexes[key.value] : null,
                  itemBuilder: (context, index) => _UpdateItem(key: ValueKey(items[index].mangaId), item: items[index]),
                ),
              ),
            ] else if (filter != UpdateFilter.all) ...[
              SliverFillRemaining(hasScrollBody: false, child: Center(child: Text(l10n.updateFilterEmpty))),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: running ? l10n.updateStopScan : l10n.updateStartScan,
        onPressed: running ? scanner.stop : scanner.scan,
        child: Icon(running ? Icons.stop_outlined : Icons.sync_outlined),
      ),
    );
  }
}

class _UpdateItem extends ConsumerWidget {
  const _UpdateItem({super.key, required this.item});

  final UpdateReportItem item;

  Widget _buildTitle(String count) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(item.sourceName, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ConstrainedBox(
            constraints: constraints.copyWith(minWidth: 0.0),
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                count,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final chapters = ref.watch(chaptersStreamByMangaProvider(item.mangaId));
    final downloaded = ref.watch(updateDownloadedChaptersProvider(item.mangaId));
    final publicChapters = (chapters.valueOrNull ?? []).where((chapter) => chapter.public);
    final completed = publicChapters.where((chapter) => downloaded.valueOrNull?.contains(chapter.title) == true).length;
    final total = publicChapters.length;
    final progressError = chapters.hasError || downloaded.hasError;
    final progressLoading = chapters.isLoading || downloaded.isLoading;
    final complete = !progressError && !progressLoading && total > 0 && completed == total;
    final color = _getStatusColor(colors, error: item.outcome.isFailure, warning: item.outcome.isWarning);
    final outcome = switch (item.outcome) {
      UpdateOutcome.updated => l10n.updateOutcomeUpdated,
      UpdateOutcome.noUpdate => l10n.updateOutcomeNoUpdate,
      UpdateOutcome.chaptersEmpty => l10n.updateOutcomeChaptersEmpty,
      UpdateOutcome.chaptersReduced => l10n.updateOutcomeChaptersReduced,
      UpdateOutcome.sourceUnavailable => l10n.updateOutcomeSourceUnavailable,
      UpdateOutcome.networkError => l10n.updateOutcomeNetworkError,
      UpdateOutcome.parseError => l10n.updateOutcomeParseError,
      UpdateOutcome.storageError => l10n.updateOutcomeStorageError,
      UpdateOutcome.enqueueFailed => l10n.updateOutcomeEnqueueFailed,
    };
    final completeIcon = Icon(Icons.check_circle_outline, size: 24.0, color: colors.onSurface);
    final progressIcon = _buildProgress(completed, total, progressError ? colors.error : color);

    return ListTile(
      title: _buildTitle(l10n.updateProgress(completed, total)),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(item.mangaTitle, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8.0),
          Flexible(
            child: Text(
              outcome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
      trailing: SizedBox.square(
        dimension: 48.0,
        child: Center(child: complete ? completeIcon : progressIcon),
      ),
      onTap: () => context.pushNamed(TsukuyomiRouter.manga.name, params: {'mangaId': '${item.mangaId}'}),
    );
  }
}

Widget _buildProgress(int completed, int total, Color color) {
  return IconTheme(
    data: IconThemeData(size: 24.0, color: color),
    child: AnimatedProgressCircleIcon(progress: total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0),
  );
}

Color _getStatusColor(ColorScheme colors, {required bool error, required bool warning}) {
  if (error) return colors.error;
  if (warning) return colors.tertiary;
  return colors.onSurface;
}
