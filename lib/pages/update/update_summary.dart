import 'package:flutter/material.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

import 'update_controller.dart';

/// 更新统计与结果筛选
class UpdateSummary extends StatelessWidget {
  const UpdateSummary({super.key, required this.report, required this.selection, required this.onChanged});

  final UpdateReport? report;

  final UpdateFilter? selection;

  final ValueChanged<UpdateFilter> onChanged;

  InlineSpan _buildCount(UpdateFilter filter, int count, TextStyle style) {
    final muted = selection != null && selection != filter;
    final color = style.color!;
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: InkWell(
        onTap: () => onChanged(filter),
        borderRadius: BorderRadius.circular(15.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 30.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 3.0),
            child: Text(
              '$count',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              textScaler: TextScaler.noScaling, // 行内组件由 Text.rich 统一缩放
              style: muted ? style.copyWith(color: color.withValues(alpha: color.a / 3.0)) : style,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mutedColor = colors.onSurface.withValues(alpha: colors.onSurface.a / 3.0);
    final style = theme.textTheme.bodyLarge!.copyWith(color: colors.onSurface, fontFeatures: const [FontFeature.tabularFigures()]);
    final separatorStyle = selection == null ? style : style.copyWith(color: mutedColor);

    return Text.rich(
      TextSpan(
        children: [
          _buildCount(UpdateFilter.failure, report?.failureCount ?? 0, style.copyWith(color: colors.error)),
          TextSpan(text: '·', style: separatorStyle),
          _buildCount(UpdateFilter.warning, report?.warningCount ?? 0, style.copyWith(color: colors.tertiary)),
          TextSpan(text: '·', style: separatorStyle),
          _buildCount(UpdateFilter.success, report?.successCount ?? 0, style),
          TextSpan(text: '/', style: separatorStyle),
          _buildCount(UpdateFilter.all, report?.totalTargets ?? 0, style),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}
