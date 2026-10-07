import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/providers/update/update_manager.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

import 'update_progress_provider.dart';

const _warningColor = Color(0xffffb74d);

Widget _buildProgress(int completed, int total, Color color) {
  return IconTheme(
    data: IconThemeData(size: 24.0, color: color),
    child: AnimatedProgressCircleIcon(progress: total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0),
  );
}

/// 更新页面
class UpdatePage extends ConsumerWidget {
  const UpdatePage({super.key});

  Widget _buildSummary(BuildContext context, UpdateReport? report, bool running, bool error) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final failures = report?.failureCount ?? 0;
    final warnings = report?.warningCount ?? 0;
    final processed = report?.items.length ?? 0;
    final total = report?.totalTargets ?? 0;
    final color = error || failures > 0
        ? colors.error
        : warnings > 0
        ? _warningColor
        : colors.onSurface;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Semantics(
        label: l10n.updateSummary(failures, warnings, processed, total),
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$failures',
                    style: TextStyle(color: colors.error),
                  ),
                  const TextSpan(text: ' · '),
                  TextSpan(
                    text: '$warnings',
                    style: const TextStyle(color: _warningColor),
                  ),
                  TextSpan(text: ' · $processed / $total'),
                ],
              ),
              style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
            const SizedBox(width: 16.0),
            if (running && total == 0) ...[
              SizedBox.square(dimension: 24.0, child: CircularProgressIndicator(strokeWidth: 2.0, color: color)),
            ] else ...[
              _buildProgress(processed, total, color),
            ],
          ],
        ),
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
    final error = manager.hasError || report?.message?.isNotEmpty == true;
    final items = report?.items ?? [];
    final showSummary = running || error || report != null && report.phase != UpdatePhase.idle;

    return TsukuyomiScaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            TsukuyomiSliverAppBar(
              title: Text(l10n.updateTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: showSummary ? [_buildSummary(context, report, running, error)] : null,
            ),
            if (items.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 96.0),
                sliver: SliverPrototypeExtentList.builder(
                  prototypeItem: const ListTile(title: Text(''), subtitle: Text('')),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _UpdateItem(item: items[index]),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: running ? l10n.updateStopScan : l10n.updateStartScan,
        onPressed: running ? controller.stop : controller.scan,
        child: Icon(running ? Icons.stop_outlined : Icons.sync_outlined),
      ),
    );
  }
}

class _UpdateItem extends ConsumerWidget {
  const _UpdateItem({required this.item});

  final UpdateReportItem item;

  Widget _buildTitle(String count) {
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(item.mangaTitle, maxLines: 1, overflow: TextOverflow.ellipsis)),
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
    final color = item.outcome.isFailure
        ? colors.error
        : item.outcome.isWarning
        ? _warningColor
        : colors.onSurface;
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

    return ListTile(
      title: _buildTitle(l10n.updateProgress(completed, total)),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(item.sourceName, maxLines: 1, overflow: TextOverflow.ellipsis)),
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
        child: Center(child: _buildProgress(completed, total, chapters.hasError || downloaded.hasError ? colors.error : color)),
      ),
      onTap: () => context.pushNamed(TsukuyomiRouter.manga.name, params: {'mangaId': '${item.mangaId}'}),
    );
  }
}
