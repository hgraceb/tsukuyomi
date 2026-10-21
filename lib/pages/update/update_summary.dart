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
    final buttons = _counts.map((count) => _countSize(context, count));
    final separators = _measure(context, ' ·  ·  / ');
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
            Opacity(
              opacity: filter == UpdateFilter.all ? 1.0 : 0.4,
              child: Text(index == 3 ? ' / ' : ' · ', style: _countStyle(context)),
            ),
          ],
          _UpdateCountButton(
            key: ValueKey(filters[index]),
            count: counts[index],
            color: countColors[index],
            label: labels[index],
            selected: filter == filters[index],
            muted: filter != UpdateFilter.all && filter != filters[index],
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
    final size = _countSize(context, count);
    final textColor = muted ? color.withValues(alpha: color.a * 0.4) : color;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: _UpdateCountFeedback(
          onTap: onPressed,
          child: SizedBox.fromSize(
            size: size,
            child: Center(
              child: Text(
                '$count',
                style: _countStyle(context).copyWith(color: textColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateCountFeedback extends InkResponse {
  const _UpdateCountFeedback({required super.onTap, required super.child})
    : super(
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        customBorder: const StadiumBorder(),
        // 仅保留按压高亮，避免与扩散水波纹叠出两圈
        splashFactory: NoSplash.splashFactory,
      );

  @override
  RectCallback getRectCallback(RenderBox referenceBox) => () {
    final size = referenceBox.size;
    return Rect.fromCenter(center: size.center(Offset.zero), width: math.max(size.height, size.width), height: size.height);
  };
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

Size _countSize(BuildContext context, int count) {
  final text = _measure(context, '$count');
  return Size(text.width + 4.0, math.max(36.0, text.height + 12.0));
}
