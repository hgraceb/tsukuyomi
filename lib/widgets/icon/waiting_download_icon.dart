import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

class AnimatedWaitingDownloadIcon extends StatefulWidget {
  const AnimatedWaitingDownloadIcon({super.key, required this.animation});

  final Animation<double> animation;

  @override
  State<StatefulWidget> createState() => _AnimatedWaitingDownloadIconState();
}

class _AnimatedWaitingDownloadIconState
    extends State<AnimatedWaitingDownloadIcon> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) => IconBuilder(
        builder: (color) => WaitingDownloadIconPainter(
          color: color,
          progress: widget.animation.value,
        ),
      ),
    );
  }
}

class WaitingDownloadIconPainter extends DownloadCircleIconPainter {
  WaitingDownloadIconPainter({required super.color, required this.progress});

  final double progress;

  @override
  void drawCircle(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(side / 2, side / 2);
    canvas.rotate(2 * pi * progress);
    canvas.translate(-side / 2, -side / 2);
    final rect = Rect.fromLTWH(side / 2 - 1.0, 0.0, 2.0, side);
    canvas.clipRect(rect, clipOp: ClipOp.difference);
    super.drawCircle(canvas, size);
    canvas.restore();
  }

  @mustCallSuper
  @override
  bool shouldRepaint(WaitingDownloadIconPainter oldDelegate) {
    return super.shouldRepaint(oldDelegate) || progress != oldDelegate.progress;
  }
}