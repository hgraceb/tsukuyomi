import 'package:flutter/cupertino.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/pages/chapter/chapter_controller.dart';

class ChapterScaffold extends StatefulWidget {
  const ChapterScaffold({super.key, required this.provider, required this.appBar, required this.body});

  final ChapterControllerProvider provider;

  final PreferredSizeWidget appBar;

  final Widget body;

  @override
  State<ChapterScaffold> createState() => _ChapterScaffoldState();
}

class _ChapterScaffoldState extends State<ChapterScaffold> {
  @override
  Widget build(BuildContext context) {
    return _AnimatedMediaQuery(
      curve: Curves.easeInOutCubic,
      padding: MediaQuery.paddingOf(context),
      duration: const Duration(milliseconds: 300),
      child: TsukuyomiAsyncHandler(
        provider: widget.provider,
        builder: (state) => TsukuyomiScaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          appBar: widget.appBar,
          body: widget.body,
        ),
      ),
    );
  }
}

class _AnimatedMediaQuery extends ImplicitlyAnimatedWidget {
  _AnimatedMediaQuery({super.curve, required this.child, required this.padding, required super.duration}) : assert(padding.isNonNegative);

  final Widget child;

  final EdgeInsets padding;

  @override
  AnimatedWidgetBaseState<_AnimatedMediaQuery> createState() => _AnimatedMediaQueryState();
}

class _AnimatedMediaQueryState extends AnimatedWidgetBaseState<_AnimatedMediaQuery> {
  EdgeInsetsTween? _padding;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _padding = visitor(_padding, widget.padding, (dynamic value) => EdgeInsetsTween(begin: value as EdgeInsets)) as EdgeInsetsTween?;
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: _padding!.evaluate(animation).clamp(EdgeInsets.zero, EdgeInsetsGeometry.infinity) as EdgeInsets,
      ),
      child: widget.child,
    );
  }
}
