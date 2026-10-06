import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/providers/update/update_manager.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

/// 更新页面
class UpdatePage extends ConsumerWidget {
  const UpdatePage({super.key});

  Widget _buildSummary(BuildContext context, UpdateReport? report, bool running, String message) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final phase = running ? UpdatePhase.running : report?.phase ?? UpdatePhase.idle;
    final time = (report?.finishedAt ?? report?.startedAt)?.toLocal();
    final material = MaterialLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(switch (phase) {
            UpdatePhase.idle => l10n.updateIdle,
            UpdatePhase.running => l10n.updateRunning,
            UpdatePhase.cancelled => l10n.updateCancelled,
            UpdatePhase.finished => l10n.updateFinished,
            UpdatePhase.interrupted => l10n.updateInterrupted,
          }),
          if (time != null) ...[
            Text('${material.formatMediumDate(time)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(time))}'),
          ],
          if (report != null) ...[
            Text(l10n.updateProgress(report.items.length, report.totalTargets)),
            Text(
              l10n.updateSummary(
                report.items.fold<int>(0, (count, item) => count + item.enqueuedCount),
                report.warningCount,
                report.failureCount,
              ),
            ),
          ],
          if (running) ...[
            const SizedBox(height: 8.0),
            LinearProgressIndicator(value: report == null || report.totalTargets == 0 ? null : report.items.length / report.totalTargets),
          ],
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            SelectableText(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, UpdateReportItem item) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final theme = Theme.of(context);
    final outcome = item.outcome;
    final outcomeText = switch (outcome) {
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

    return ListTile(
      title: Text(item.mangaTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${item.sourceName} · $outcomeText', style: TextStyle(color: outcome.isFailure ? theme.colorScheme.error : null)),
          Text(l10n.updateChanges(item.sourceCount, item.insertCount, item.deleteCount, item.enqueuedCount, item.enqueueFailedCount)),
          Text(l10n.updateSkipped(item.skippedDownloaded, item.skippedQueued, item.skippedUnavailable)),
        ],
      ),
      trailing: _buildTrailing(context, item),
      onTap: () => context.pushNamed(TsukuyomiRouter.manga.name, params: {'mangaId': '${item.mangaId}'}),
    );
  }

  Widget? _buildTrailing(BuildContext context, UpdateReportItem item) {
    final message = item.message;
    if (message == null) return null;
    final l10n = TsukuyomiLocalizations.of(context)!;
    return IconButton(
      tooltip: l10n.updateErrorDetails,
      icon: const Icon(Icons.info_outline),
      onPressed: () => _showErrorDetails(context, item.mangaTitle, message),
    );
  }

  Future<void> _showErrorDetails(BuildContext context, String title, String message) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: SelectableText(message)),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: message)),
            child: Text(l10n.updateCopyError),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final manager = ref.watch(updateManagerProvider);
    final report = ref.watch(updateReportStoreProvider);
    final controller = ref.read(updateManagerProvider.notifier);
    final running = manager.isLoading;
    final items = report?.items ?? [];
    final message = {report?.message, manager.error?.toString()}.whereType<String>().join('\n');
    var emptyText = l10n.updateNoResults;
    if (report == null || report.phase == UpdatePhase.idle) {
      emptyText = l10n.updateEmpty;
    } else if (report.phase == UpdatePhase.finished && report.totalTargets == 0 && message.isEmpty) {
      emptyText = l10n.updateNoTargets;
    }
    if (running) emptyText = l10n.updateNoResults;

    return TsukuyomiScaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            TsukuyomiSliverAppBar(
              title: Text(l10n.updateTitle),
              actions: [
                if (running) ...[
                  IconButton(tooltip: l10n.updateStopScan, icon: const Icon(Icons.stop_outlined), onPressed: controller.stop),
                ] else ...[
                  IconButton(tooltip: l10n.updateStartScan, icon: const Icon(Icons.refresh_outlined), onPressed: controller.scan),
                ],
              ],
            ),
            SliverToBoxAdapter(child: _buildSummary(context, report, running, message)),
            if (items.isEmpty) ...[
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(emptyText, textAlign: TextAlign.center),
                  ),
                ),
              ),
            ] else ...[
              SliverList.builder(itemCount: items.length, itemBuilder: (context, index) => _buildItem(context, items[index])),
            ],
          ],
        ),
      ),
    );
  }
}
