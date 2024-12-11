import 'dart:math';

import 'package:flutter/material.dart';

/// 圆形进度图标画笔 TODO 进度变化动效
class CircularProgressIndicatorPainter extends CustomPainter {
  /// 范围在 0.0-1.0 的进度值
  final double value;

  /// 图标颜色
  final Color color;

  const CircularProgressIndicatorPainter({
    required this.value,
    required this.color,
  }) : assert(value >= 0.0 && value <= 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    // 圆心位置
    Offset center = Offset(size.width / 2, size.height / 2);

    // 圆环背景画笔
    final paintBackground = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.width * 4 / 24) / 2;
    // 绘制圆环背景
    canvas.drawCircle(center, (size.width * 18 / 24) / 2, paintBackground);

    // 扇形进度画笔
    final paintProgress = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    Rect rect = Rect.fromCircle(
      center: center,
      radius: (size.width * 12 / 24) / 2,
    );
    // 绘制扇形进度
    canvas.drawArc(rect, -pi / 2, 2 * pi * value, true, paintProgress);
  }

  @override
  bool shouldRepaint(CircularProgressIndicatorPainter oldDelegate) {
    return value != oldDelegate.value || color != oldDelegate.color;
  }
}
