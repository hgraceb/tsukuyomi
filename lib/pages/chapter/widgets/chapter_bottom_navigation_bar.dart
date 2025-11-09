import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChapterBottomNavigationBar extends StatelessWidget {
  const ChapterBottomNavigationBar({
    super.key,
    required this.min,
    required this.max,
    required this.visible,
    required this.progress,
    required this.onChanged,
    required this.elevation,
    required this.backgroundColor,
  }) : assert(min <= max);

  final int min;

  final int max;

  final int progress;

  final bool visible;

  final double elevation;

  final Color backgroundColor;

  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    // 安全边距
    final padding = MediaQuery.paddingOf(context);
    // 水平方向最小安全边距（一般是状态栏和导航栏）
    final minimum = math.max(padding.left, padding.right);

    return SafeArea(
      // 移动端状态栏和导航栏横屏适配
      minimum: padding.copyWith(left: minimum, right: minimum),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: kToolbarHeight,
          child: Card(
            elevation: elevation,
            color: backgroundColor,
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kToolbarHeight / 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      '${progress.clamp(min, max)}',
                      style: const TextStyle(
                        // 设置数字等宽避免滚动条宽度快速变动 TODO (#00) 判断是否需要优化宽度跳动处理
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Flexible(
                    child: Slider(
                      min: min.toDouble(),
                      max: max.toDouble(),
                      value: progress.clamp(min, max).toDouble(),
                      onChanged: onChanged,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      '$max',
                      style: const TextStyle(
                        // 设置数字等宽避免滚动条宽度快速变动 TODO (#00) 判断是否需要优化宽度跳动处理
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
            .animate(target: visible ? 1.0 : 0.0)
            .fade(begin: 0.0, end: 1.0, curve: Curves.easeInOutCubic)
            .slideY(begin: 1.0, end: 0.0),
      ),
    );
  }
}
