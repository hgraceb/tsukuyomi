import 'package:flutter/widgets.dart';

class IconBuilder extends StatelessWidget {
  const IconBuilder({super.key, required this.builder});

  final CustomPainter Function(Color color) builder;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final iconSize = iconTheme.size!;
    final iconOpacity = iconTheme.opacity ?? 1.0;
    Color iconColor = iconTheme.color!;
    if (iconOpacity != 1.0) {
      iconColor = iconColor.withOpacity(iconColor.opacity * iconOpacity);
    }

    return CustomPaint(
      size: Size(iconSize, iconSize),
      painter: builder(iconColor),
    );
  }
}

abstract class IconPainter extends CustomPainter {
  IconPainter({required this.color});

  final Color color;

  final side = 24.0;

  final strokeWidth = 2.0;

  Paint get stokePaint => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth;

  Paint get fillPaint => Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  @mustCallSuper
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / side;
    final dx = (size.width - size.shortestSide) / scale / 2;
    final dy = (size.height - size.shortestSide) / scale / 2;
    canvas.scale(scale, scale);
    canvas.translate(dx, dy);
  }

  @mustCallSuper
  @override
  bool shouldRepaint(IconPainter oldDelegate) => color != oldDelegate.color;
}
