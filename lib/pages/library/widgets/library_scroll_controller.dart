import 'package:flutter/material.dart';

/// 临时修复 NestedScrollView 和 TabBarView 一起使用时的滚动问题
///
/// See also:
///
/// * https://github.com/flutter/flutter/issues/36419#issuecomment-1418274233
class LibraryScrollBuilder extends StatefulWidget {
  const LibraryScrollBuilder({
    super.key,
    required this.ids,
    required this.scrollController,
    required this.tabController,
    required this.builder,
  }) : assert(ids.length == tabController.length);

  final Iterable<int> ids;

  final ScrollController scrollController;

  final TabController tabController;

  final Widget Function(BuildContext context, Map<int, ScrollController> controllers) builder;

  @override
  State<LibraryScrollBuilder> createState() => _LibraryScrollBuilderState();
}

class _LibraryScrollBuilderState extends State<LibraryScrollBuilder> {
  Map<int, _LibraryScrollController> controllers = {};

  void onTabChanged() {
    final activeIndex = widget.tabController.index;
    for (final (index, controller) in controllers.values.indexed) {
      if (controller.isActive = index == activeIndex) {
        controller.forceAttach();
      } else {
        controller.forceDetach();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final activeIndex = widget.tabController.index;
    for (final (index, id) in widget.ids.indexed) {
      controllers[id] = _LibraryScrollController(isActive: index == activeIndex, delegate: widget.scrollController);
    }
    widget.tabController.addListener(onTabChanged);
  }

  @override
  void didUpdateWidget(covariant LibraryScrollBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(widget.ids.length == widget.tabController.length);
    assert(widget.scrollController == oldWidget.scrollController);
    if (widget.ids != oldWidget.ids) {
      final deleted = {...controllers};
      final updated = <int, _LibraryScrollController>{};
      final activeIndex = widget.tabController.index;
      for (final (index, id) in widget.ids.indexed) {
        final controller = deleted.remove(id);
        updated[id] = controller ?? _LibraryScrollController(isActive: index == activeIndex, delegate: widget.scrollController);
      }
      for (final controller in deleted.values) {
        controller.dispose();
      }
      controllers = updated;
    }
    if (widget.tabController != oldWidget.tabController) {
      oldWidget.tabController.removeListener(onTabChanged);
      widget.tabController.addListener(onTabChanged);
    }
  }

  @override
  void dispose() {
    widget.tabController.removeListener(onTabChanged);
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, controllers);
  }
}

class _LibraryScrollController extends ScrollController {
  _LibraryScrollController({
    required this.delegate,
    required this.isActive,
  }) : super(initialScrollOffset: delegate.initialScrollOffset, keepScrollOffset: delegate.keepScrollOffset);

  final ScrollController delegate;

  bool isActive;

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) {
    return delegate.createScrollPosition(physics, context, oldPosition);
  }

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    if (isActive && !delegate.positions.contains(position)) {
      delegate.attach(position);
    }
  }

  @override
  void detach(ScrollPosition position) {
    if (delegate.positions.contains(position)) {
      delegate.detach(position);
    }
    super.detach(position);
  }

  void forceDetach() {
    for (final position in positions) {
      if (delegate.positions.contains(position)) {
        delegate.detach(position);
      }
    }
  }

  void forceAttach() {
    for (final position in positions) {
      if (!delegate.positions.contains(position)) {
        delegate.attach(position);
      }
    }
  }

  @override
  void dispose() {
    forceDetach();
    super.dispose();
  }
}
