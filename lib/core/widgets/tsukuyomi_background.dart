import 'package:flutter/material.dart';

class TsukuyomiBackground extends StatelessWidget {
  const TsukuyomiBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: double.infinity,
      height: double.infinity,
      duration: kThemeChangeDuration,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topCenter,
          end: AlignmentDirectional.bottomCenter,
          // TODO 动态获取背景颜色
          colors: [
            Color.fromARGB(255, 30, 32, 60),
            Color.fromARGB(255, 50, 52, 80),
          ],
        ),
      ),
      child: child,
    );
  }
}
