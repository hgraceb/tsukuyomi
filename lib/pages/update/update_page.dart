import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/providers/update/update_manager.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

import 'update_controller.dart';
import 'update_progress_provider.dart';
import 'update_retry_controller.dart';
import 'update_summary.dart';

/// 更新页面
class UpdatePage extends ConsumerStatefulWidget {
  const UpdatePage({super.key});

  @override
  ConsumerState<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends ConsumerState<UpdatePage> with SingleTickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat(reverse: false);
    _iconAnimation = Tween(begin: 0.0, end: 1.0).animate(_iconController);
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final selection = ref.watch(updateControllerProvider);
    final controller = ref.read(updateControllerProvider.notifier);
    final manager = ref.watch(updateManagerProvider);
    final report = ref.watch(updateReportStoreProvider);
    final progressCache = ref.watch(updateProgressCacheProvider(report?.sessionId));
    final scanner = ref.read(updateManagerProvider.notifier);
    final running = manager.isLoading;
    final error = manager.hasError || report?.message?.isNotEmpty == true;
    final filter = selection ?? UpdateFilter.all;
    final results = report?.items ?? [];
    final items = results.where(filter.matches).toList()..sort(compareUpdateItems);
    final itemIndexes = {for (var index = 0; index < items.length; index++) items[index].mangaId: index};
    final showSummary = running || error || report != null && report.phase != UpdatePhase.idle;
    final pending = report?.pendingCount ?? 0;
    final skipped = report?.skippedCount ?? 0;
    final scanning = report?.phase == UpdatePhase.running;
    final summary = Flexible(
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: UpdateSummary(
          report: report,
          selection: selection,
          onChanged: controller.onFilterChanged,
        ),
      ),
    );

    return TsukuyomiScaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            TsukuyomiSliverAppBar(
              title: Text(l10n.updateTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: showSummary ? [summary] : null,
            ),
            if (pending > 0 || skipped > 0) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
                  child: Text(
                    scanning ? l10n.updatePendingSummary(pending, skipped) : l10n.updateUncheckedSummary(pending, skipped),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
            if (items.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 96.0),
                sliver: SliverPrototypeExtentList.builder(
                  prototypeItem: const ListTile(title: Text(''), subtitle: Text('')),
                  itemCount: items.length,
                  findChildIndexCallback: (key) => key is ValueKey<int> ? itemIndexes[key.value] : null,
                  itemBuilder: (context, index) => _UpdateItem(
                    key: ValueKey(items[index].mangaId),
                    item: items[index],
                    iconAnimation: _iconAnimation,
                    progressCache: progressCache,
                    scanning: scanning,
                  ),
                ),
              ),
            ] else if (filter != UpdateFilter.all) ...[
              SliverFillRemaining(hasScrollBody: false, child: Center(child: Text(l10n.updateFilterEmpty))),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: running ? scanner.stop : scanner.scan,
        child: Icon(running ? Icons.stop_outlined : Icons.sync_outlined),
      ),
    );
  }
}

class _UpdateItem extends ConsumerWidget {
  const _UpdateItem({super.key, required this.item, required this.iconAnimation, required this.progressCache, required this.scanning});

  final UpdateReportItem item;

  final Animation<double> iconAnimation;

  final UpdateProgressCache progressCache;

  final bool scanning;

  /// 更新列表项的标题
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

  /// 更新列表项的副标题
  Widget _buildSubTitle(TsukuyomiLocalizations l10n, Color color) {
    final outcome = switch (item.outcome) {
      UpdateOutcome.pending => scanning ? l10n.updatePending : l10n.updateUnchecked,
      UpdateOutcome.checking => scanning ? l10n.updateChecking : l10n.updateUnchecked,
      UpdateOutcome.skipped => l10n.updateSkipped,
      UpdateOutcome.unchecked => l10n.updateUnchecked,
      UpdateOutcome.progressError => l10n.updateOutcomeProgressError,
      UpdateOutcome.updated => l10n.updateOutcomeUpdated,
      UpdateOutcome.noUpdate => l10n.updateOutcomeNoUpdate,
      UpdateOutcome.chaptersEmpty => l10n.updateOutcomeChaptersEmpty,
      UpdateOutcome.sourceUnavailable => l10n.updateOutcomeSourceUnavailable,
      UpdateOutcome.networkError => l10n.updateOutcomeNetworkError,
      UpdateOutcome.parseError => l10n.updateOutcomeParseError,
      UpdateOutcome.storageError => l10n.updateOutcomeStorageError,
      UpdateOutcome.enqueueFailed => l10n.updateOutcomeEnqueueFailed,
    };

    return Row(
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
    );
  }

  /// 根据重试状态或检查结果构建列表项末尾组件
  IconButton _buildTrailing(BuildContext context, WidgetRef ref, Widget statusIcon) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final retrying = ref.watch(updateRetryControllerProvider(item.mangaId));
    if (retrying) {
      return IconButton(
        tooltip: l10n.retry,
        disabledColor: colors.onSurface,
        onPressed: null,
        icon: AnimatedWaitingDownloadIcon(animation: iconAnimation),
      );
    }
    if (item.outcome.canRetry) {
      return IconButton(
        tooltip: l10n.retry,
        color: item.outcome.isFailure ? colors.error : colors.tertiary,
        icon: const Icon(Icons.refresh_outlined),
        onPressed: ref.read(updateRetryControllerProvider(item.mangaId).notifier).retry,
      );
    }
    if (item.outcome.isPending) {
      final checking = scanning && item.outcome == UpdateOutcome.checking;
      return IconButton(
        disabledColor: colors.onSurfaceVariant,
        onPressed: null,
        icon: checking ? AnimatedWaitingDownloadIcon(animation: iconAnimation) : const Icon(Icons.schedule_outlined),
      );
    }
    return IconButton(onPressed: null, icon: statusIcon);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final progress = item.outcome.canReadProgress ? ref.watch(updateProgressProvider(progressCache, item.mangaId)) : const UpdateProgress();
    final unknownError = progress.hasError && !progress.hasValue;
    final completed = unknownError ? 0 : progress.completed;
    final total = unknownError ? 0 : progress.total;
    final complete = progress.hasValue && !progress.hasError && total > 0 && completed == total;
    final color = _getStatusColor(colors, error: item.outcome.isFailure, warning: item.outcome.isWarning || progress.hasError);
    final completeIcon = Icon(Icons.check_circle_outline, size: 24.0, color: colors.onSurface);
    final progressIcon = _buildProgress(completed, total, color);

    return TsukuyomiIconButtonListTile(
      title: _buildTitle(l10n.updateProgress(completed, total)),
      subtitle: _buildSubTitle(l10n, color),
      trailing: _buildTrailing(context, ref, complete ? completeIcon : progressIcon),
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
