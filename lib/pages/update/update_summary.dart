import 'package:flutter/material.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

import 'update_filter.dart';

/// 更新统计与结果类别筛选
class UpdateSummary extends StatelessWidget {
  const UpdateSummary({super.key, required this.report, required this.selection, required this.onChanged, required this.progress});

  final UpdateReport? report;
  final UpdateFilter? selection;
  final ValueChanged<UpdateFilter> onChanged;
  final Widget progress;

  List<int> get _counts => [report?.failureCount ?? 0, report?.warningCount ?? 0, report?.successCount ?? 0, report?.totalTargets ?? 0];

  @override
  Widget build(BuildContext context) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final counts = _counts;
    final separatorOpacity = selection == null ? 1.0 : 1 / 3;
    final separatorColor = colors.onSurface.withValues(alpha: colors.onSurface.a * separatorOpacity);
    final labels = [
      l10n.updateFilterErrors(counts[0]),
      l10n.updateFilterWarnings(counts[1]),
      l10n.updateFilterSuccesses(counts[2]),
      l10n.updateFilterAll(counts[3]),
    ];
    final filters = [UpdateFilter.failure, UpdateFilter.warning, UpdateFilter.success, UpdateFilter.all];
    final countColors = [colors.error, colors.tertiary, colors.onSurface, colors.onSurface];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                for (var index = 0; index < counts.length; index++) ...[
                  if (index > 0) ...[
                    TextSpan(
                      text: index == 3 ? ' / ' : ' · ',
                      style: TextStyle(color: separatorColor),
                    ),
                  ],
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _UpdateCountButton(
                      key: ValueKey(filters[index]),
                      count: counts[index],
                      color: countColors[index],
                      label: labels[index],
                      selected: selection == filters[index],
                      muted: selection != null && selection != filters[index],
                      onPressed: () => onChanged(filters[index]),
                    ),
                  ),
                ],
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _countStyle(context),
          ),
        ),
        const SizedBox(width: 16.0),
        Semantics(
          label: l10n.updateSummary(counts[0], counts[1], counts[2], counts[3]),
          excludeSemantics: true,
          child: progress,
        ),
      ],
    );
  }
}

class _UpdateCountButton extends StatelessWidget {
  const _UpdateCountButton({
    super.key,
    required this.count,
    required this.color,
    required this.label,
    required this.selected,
    required this.muted,
    required this.onPressed,
  });

  final int count;
  final Color color;
  final String label;
  final bool selected;
  final bool muted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textColor = muted ? color.withValues(alpha: color.a / 3.0) : color;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 6.0),
              // 行内组件由 Text.rich 统一缩放，避免字号重复放大
              child: MediaQuery.withNoTextScaling(
                child: Text(
                  '$count',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _countStyle(context).copyWith(color: textColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _countStyle(BuildContext context) {
  final style = Theme.of(context).textTheme.bodyLarge!;
  return style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
