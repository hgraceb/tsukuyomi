import 'package:flutter/cupertino.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:tsukuyomi_patch/widgets.dart';

class TsukuyomiAnimatedSwitcher extends StatelessWidget {
  TsukuyomiAnimatedSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.switchInCurve = Curves.easeInOutCubic,
    this.switchOutCurve = Curves.easeInOutCubic,
    this.transitionBuilder = PatchedAnimatedSwitcher.defaultTransitionBuilder,
    this.layoutBuilder = PatchedAnimatedSwitcher.defaultLayoutBuilder,
  }) : assert(child.key != null);

  final Widget child;

  final Duration duration;

  final Curve switchInCurve;

  final Curve switchOutCurve;

  final AnimatedSwitcherTransitionBuilder transitionBuilder;

  final AnimatedSwitcherLayoutBuilder layoutBuilder;

  @override
  Widget build(BuildContext context) {
    return PatchedAnimatedSwitcher(
      duration: duration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder: transitionBuilder,
      layoutBuilder: layoutBuilder,
      child: child,
    );
  }
}

class TsukuyomiSliverAnimatedSwitcher extends StatelessWidget {
  TsukuyomiSliverAnimatedSwitcher({
    super.key,
    required this.sliver,
  }) : assert(sliver.key != null);

  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    return TsukuyomiAnimatedSwitcher(
      transitionBuilder: PatchedAnimatedSwitcher.sliverTransitionBuilder,
      layoutBuilder: (currentChild, previousChildren) => SliverStack(
        positionedAlignment: Alignment.center,
        children: <Widget>[
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
      child: sliver,
    );
  }
}
