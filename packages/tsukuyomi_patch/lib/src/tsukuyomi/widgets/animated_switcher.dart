import 'package:flutter/cupertino.dart';

class PatchedAnimatedSwitcher extends StatelessWidget {
  const PatchedAnimatedSwitcher({
    super.key,
    this.child,
    required this.duration,
    this.reverseDuration,
    this.switchInCurve = Curves.linear,
    this.switchOutCurve = Curves.linear,
    this.transitionBuilder = PatchedAnimatedSwitcher.defaultTransitionBuilder,
    this.layoutBuilder = PatchedAnimatedSwitcher.defaultLayoutBuilder,
  });

  final Widget? child;

  final Duration duration;

  final Duration? reverseDuration;

  final Curve switchInCurve;

  final Curve switchOutCurve;

  final AnimatedSwitcherTransitionBuilder transitionBuilder;

  final AnimatedSwitcherLayoutBuilder layoutBuilder;

  // region Tsukuyomi: 删除 key 以修复 “node.isRepaintBoundary” 和 “Duplicate keys found.” 问题
  // https://github.com/flutter/flutter/issues/120874#issuecomment-1454414743
  static Widget sliverTransitionBuilder(Widget child, Animation<double> animation) {
    return SliverFadeTransition(
      // key: ValueKey<Key?>(child.key),
      opacity: animation,
      sliver: child,
    );
  }

  static Widget defaultTransitionBuilder(Widget child, Animation<double> animation) {
    return FadeTransition(
      // key: ValueKey<Key?>(child.key),
      opacity: animation,
      child: child,
    );
  }
  // endregion Tsukuyomi

  static Widget defaultLayoutBuilder(Widget? currentChild, List<Widget> previousChildren) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        ...previousChildren,
        if (currentChild != null) currentChild,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: reverseDuration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder: transitionBuilder,
      layoutBuilder: layoutBuilder,
      child: child,
    );
  }
}
