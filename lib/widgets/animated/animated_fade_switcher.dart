import 'package:flutter/cupertino.dart';

class AnimatedFadeSwitcher extends StatelessWidget {
  AnimatedFadeSwitcher({
    super.key,
    required this.child,
  }) : assert(child.key != null);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        key: ValueKey<Key?>(child.key),
        opacity: animation,
        child: child,
      ),
      child: child,
    );
  }
}
