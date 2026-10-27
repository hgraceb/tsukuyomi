import 'package:flutter/material.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

import 'update_controller.dart';

/// 更新统计与结果筛选
class UpdateSummary extends StatelessWidget {
  const UpdateSummary({super.key, required this.report, required this.selection, required this.onChanged, required this.progress});

  final UpdateReport? report;
  final UpdateFilter? selection;
  final ValueChanged<UpdateFilter> onChanged;
  final Widget progress;

  InlineSpan _buildCount(UpdateFilter filter, int count, TextStyle style) {
    final muted = selection != null && selection != filter;
    final color = style.color!;
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: InkWell(
        onTap: () => onChanged(filter),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 6.0),
          child: Text(
            '$count',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // 行内组件由 Text.rich 统一缩放
            textScaler: TextScaler.noScaling,
            style: muted ? style.copyWith(color: color.withValues(alpha: color.a / 3.0)) : style,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = theme.textTheme.bodyLarge!.copyWith(color: colors.onSurface, fontFeatures: const [FontFeature.tabularFigures()]);
    final mutedColor = colors.onSurface.withValues(alpha: colors.onSurface.a / 3.0);
    final separatorStyle = selection == null ? style : style.copyWith(color: mutedColor);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                _buildCount(UpdateFilter.failure, report?.failureCount ?? 0, style.copyWith(color: colors.error)),
                TextSpan(text: ' · ', style: separatorStyle),
                _buildCount(UpdateFilter.warning, report?.warningCount ?? 0, style.copyWith(color: colors.tertiary)),
                TextSpan(text: ' · ', style: separatorStyle),
                _buildCount(UpdateFilter.success, report?.successCount ?? 0, style),
                TextSpan(text: ' / ', style: separatorStyle),
                _buildCount(UpdateFilter.all, report?.totalTargets ?? 0, style),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        const SizedBox(width: 16.0),
        progress,
      ],
    );
  }
}
