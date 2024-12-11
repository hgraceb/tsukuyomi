import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

class AnimatedProgressCircleIcon extends ImplicitlyAnimatedWidget {
  const AnimatedProgressCircleIcon({
    super.key,
    super.curve,
    required this.progress,
    Duration duration = const Duration(microseconds: 300),
  })  : assert(progress >= 0.0 && progress <= 1.0),
        super(duration: duration);

  final double progress;

  @override
  AnimatedWidgetBaseState<AnimatedProgressCircleIcon> createState() => _AnimatedProgressCircleIconState();
}

class _AnimatedProgressCircleIconState extends AnimatedWidgetBaseState<AnimatedProgressCircleIcon> {
  Tween<double>? _progress;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _progress = visitor(_progress, widget.progress, (dynamic value) => Tween<double>(begin: value as double)) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return IconBuilder(
      builder: (color) => ProgressCircleIconPainter(
        color: color,
        progress: _progress!.evaluate(animation),
      ),
    );
  }
}

class ProgressCircleIconPainter extends CircleIconPainter {
  ProgressCircleIconPainter({required super.color, required this.progress});

  final double progress;

  @mustCallSuper
  @override
  void paint(Canvas canvas, Size size) {
    super.paint(canvas, size);
    final rect = Rect.fromCircle(center: center, radius: 6.0);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, true, fillPaint);
  }

  @mustCallSuper
  @override
  bool shouldRepaint(ProgressCircleIconPainter oldDelegate) {
    return super.shouldRepaint(oldDelegate) || progress != oldDelegate.progress;
  }
}
