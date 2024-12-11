import 'package:flutter/widgets.dart';
import 'package:tsukuyomi/widgets/icon/icon.dart';

class CircleIcon extends StatelessWidget {
  const CircleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return IconBuilder(
      builder: (color) => CircleIconPainter(
        color: color,
      ),
    );
  }
}

class CircleIconPainter extends IconPainter {
  CircleIconPainter({required super.color});

  final radius = 9.0;

  Offset get center => Offset(side / 2, side / 2);

  void drawCircle(Canvas canvas, Size size) {
    canvas.drawCircle(center, radius, stokePaint);
  }

  @mustCallSuper
  @override
  void paint(Canvas canvas, Size size) {
    super.paint(canvas, size);

    drawCircle(canvas, size);
  }
}
