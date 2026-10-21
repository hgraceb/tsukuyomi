import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/providers/update/update_state.dart';

import 'update_filter.dart';

/// 更新统计与结果类别筛选
class UpdateSummary extends StatelessWidget {
  const UpdateSummary({super.key, required this.report, required this.filter, required this.onChanged, required this.progress});

  final UpdateReport? report;
  final UpdateFilter filter;
  final ValueChanged<UpdateFilter> onChanged;
  final Widget progress;

  List<int> get _counts => [report?.failureCount ?? 0, report?.warningCount ?? 0, report?.successCount ?? 0, report?.totalTargets ?? 0];

  Size size(BuildContext context) {
    final buttons = _counts.map((count) => _countSizes(context, count).target);
    final separators = _measure(context, '··/');
    final width = buttons.fold(0.0, (width, size) => width + size.width) + separators.width + 16.0 + 24.0;
    final height = buttons.fold(24.0, (height, size) => math.max(height, size.height));
    return Size(width, height);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TsukuyomiLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final counts = _counts;
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
        for (var index = 0; index < counts.length; index++) ...[
          if (index > 0) ...[
            Text(index == 3 ? '/' : '·', style: _countStyle(context)),
          ],
          _UpdateCountButton(
            key: ValueKey(filters[index]),
            count: counts[index],
            color: countColors[index],
            label: labels[index],
            selected: filter == filters[index],
            onPressed: () => onChanged(filters[index]),
          ),
        ],
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
    required this.onPressed,
  });

  final int count;
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final sizes = _countSizes(context, count);

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
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: SizedBox.fromSize(
            size: sizes.target,
            child: Center(
              child: Container(
                width: sizes.badge.width,
                height: sizes.badge.height,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: selected ? color.withValues(alpha: 0.12) : null,
                  shape: StadiumBorder(
                    side: BorderSide(color: color.withValues(alpha: selected ? 1.0 : 0.16)),
                  ),
                ),
                child: Text('$count', style: _countStyle(context).copyWith(color: color)),
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

Size _measure(BuildContext context, String text) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: _countStyle(context)),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  final size = painter.size;
  painter.dispose();
  return size;
}

({Size badge, Size target}) _countSizes(BuildContext context, int count) {
  final text = _measure(context, '$count');
  final height = math.max(36.0, text.height + 8.0);
  final badge = Size(math.max(height, text.width + 8.0), height);
  final minimum = Theme.of(context).materialTapTargetSize == MaterialTapTargetSize.padded ? kMinInteractiveDimension : 40.0;
  final target = Size(math.max(minimum, badge.width + 8.0), math.max(minimum, badge.height + 8.0));
  return (badge: badge, target: target);
}
