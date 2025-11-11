import 'package:flutter/cupertino.dart';
import 'package:sliver_tools/sliver_tools.dart';

class TsukuyomiAnimatedSwitcher extends StatelessWidget {
  TsukuyomiAnimatedSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.switchInCurve = Curves.easeInOutCubic,
    this.switchOutCurve = Curves.easeInOutCubic,
    this.transitionBuilder = AnimatedSwitcher.defaultTransitionBuilder,
    this.layoutBuilder = AnimatedSwitcher.defaultLayoutBuilder,
  }) : assert(child.key != null);

  final Widget child;

  final Duration duration;

  final Curve switchInCurve;

  final Curve switchOutCurve;

  final AnimatedSwitcherTransitionBuilder transitionBuilder;

  final AnimatedSwitcherLayoutBuilder layoutBuilder;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: duration,
    switchInCurve: switchInCurve,
    switchOutCurve: switchOutCurve,
    transitionBuilder: transitionBuilder,
    layoutBuilder: layoutBuilder,
    child: child,
  );
}

class TsukuyomiSliverAnimatedSwitcher extends StatelessWidget {
  TsukuyomiSliverAnimatedSwitcher({
    super.key,
    required this.sliver,
  }) : assert(sliver.key != null);

  final Widget sliver;

  static Widget defaultTransitionBuilder(Widget child, Animation<double> animation) => SliverFadeTransition(
    key: ValueKey<Key?>(child.key),
    opacity: animation,
    sliver: child,
  );

  static Widget defaultLayoutBuilder(Widget? currentChild, List<Widget> previousChildren) => SliverStack(
    positionedAlignment: Alignment.center,
    children: <Widget>[...previousChildren, if (currentChild != null) currentChild],
  );

  @override
  Widget build(BuildContext context) => TsukuyomiAnimatedSwitcher(
    transitionBuilder: defaultTransitionBuilder,
    layoutBuilder: defaultLayoutBuilder,
    child: sliver,
  );
}
