import 'package:flutter/material.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

class DownloadCircleIcon extends StatelessWidget {
  const DownloadCircleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return IconBuilder(
      builder: (color) => DownloadCircleIconPainter(
        color: color,
      ),
    );
  }
}

class DownloadCircleIconPainter extends CircleIconPainter {
  DownloadCircleIconPainter({required super.color});

  void drawDownload(Canvas canvas, Size size) {
    final downloadPath = Path()
      ..moveTo(11.0, 7.0)
      ..lineTo(13.0, 7.0)
      ..relativeLineTo(0.0, 6.18)
      ..relativeLineTo(2.59, -2.59)
      ..lineTo(17.0, 12.0)
      ..lineTo(12.0, 17.0)
      ..lineTo(7.0, 12.0)
      ..relativeLineTo(1.41, -1.41)
      ..relativeLineTo(2.59, 2.59);
    canvas.drawPath(downloadPath, fillPaint);
  }

  @mustCallSuper
  @override
  void paint(Canvas canvas, Size size) {
    super.paint(canvas, size);

    drawDownload(canvas, size);
  }
}
