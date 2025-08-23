import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:flutter/rendering.dart' show RenderProxySliver, SliverGeometry;
import 'package:flutter/scheduler.dart';
import 'package:meta/meta.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:tsukuyomi_list/src/tsukuyomi/rendering/viewport.dart';
import 'package:tsukuyomi_list/src/tsukuyomi/widgets/scroll_activity.dart';
import 'package:tsukuyomi_list/src/tsukuyomi/widgets/scroll_view.dart';

typedef _OnPerformLayout = void Function(RenderBox box, Size? oldSize, Size newSize);

class TsukuyomiList extends StatefulWidget {
  const TsukuyomiList.builder({
    super.key,
    required this.itemKeys,
    required this.itemBuilder,
    this.controller,
    this.physics,
    this.leadingExtent = 0.0,
    this.trailingExtent = 0.0,
    this.anchor,
    this.trailing = true,
    this.debugMask = false,
    this.ignorePointer = false,
    this.scrollDirection = Axis.vertical,
    this.initialScrollIndex = 0,
    this.onItemsChanged,
  })  : assert(initialScrollIndex >= 0),
        assert(initialScrollIndex < itemKeys.length || itemKeys.length == 0),
        assert(anchor == null || (anchor >= 0.0 && anchor <= 1.0));

  /// 列表项标识
  final List<Object> itemKeys;

  /// 列表项构建器
  final IndexedWidgetBuilder itemBuilder;

  /// 列表控制器
  final TsukuyomiListController? controller;

  /// 物理滚动效果
  final ScrollPhysics? physics;

  /// 列表起始位置占位间距
  final double leadingExtent;

  /// 列表结束位置占位间距
  final double trailingExtent;

  /// 列表锚点位置
  final double? anchor;

  /// 是否填充列表末尾空白部分
  final bool trailing;

  /// 是否显示列表调试遮罩
  final bool debugMask;

  /// 是否忽略列表触摸事件
  final bool ignorePointer;

  /// 列表滚动方向
  final Axis scrollDirection;

  /// 列表初始位置索引
  final int initialScrollIndex;

  /// 列表项更新
  final ValueChanged<List<TsukuyomiListItem>>? onItemsChanged;

  @override
  State<TsukuyomiList> createState() => _TsukuyomiListState();
}

class _TsukuyomiListState extends State<TsukuyomiList> {
  late int _centerIndex, _anchorIndex;
  late List<Object> _oldItemKeys;
  final _centerKey = UniqueKey();
  final _elements = <_TsukuyomiListItemElement>{};
  final _extents = <int, double>{};
  final _scrollController = _TsukuyomiListScrollController();

  /// 在列表中心之前的滚动区域范围
  double _scrollExtentBeforeCenter = 0.0;

  /// 在列表中心之前的滚动区域范围
  double _scrollExtentAfterCenter = 0.0;

  @override
  void initState() {
    super.initState();
    _centerIndex = _anchorIndex = widget.initialScrollIndex;
    _oldItemKeys = [...widget.itemKeys];
    _scrollController.addListener(_scheduleUpdateItems);
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(TsukuyomiList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 更新列表控制器
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    // 重置列表项尺寸
    if (widget.scrollDirection != oldWidget.scrollDirection) {
      _extents.clear();
    }
    // 修正锚点列表项位置
    if (widget.itemKeys.indexOf(_oldItemKeys[_anchorIndex]) case final newAnchorIndex when newAnchorIndex != _anchorIndex) {
      if (newAnchorIndex >= 0) {
        for (var i = _anchorIndex - _centerIndex; i < 0; i++) {
          final extent = _extents[i];
          if (extent == null) continue;
          _scrollController.position.correctImmediate(extent);
        }
        for (var i = 0; i < _anchorIndex - _centerIndex; i++) {
          final extent = _extents[i];
          if (extent == null) continue;
          _scrollController.position.correctImmediate(-extent);
        }
        _centerIndex = _anchorIndex = newAnchorIndex;
      } else {
        // TODO 处理旧的 _centerIndex 和 _anchorIndex 越界的情况
      }
    }
    // 更新列表项标识
    _oldItemKeys = [...widget.itemKeys];
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TsukuyomiScrollView(
      center: _centerKey,
      controller: _scrollController,
      physics: widget.physics,
      ignorePointer: widget.ignorePointer,
      scrollDirection: widget.scrollDirection,
      slivers: [
        SliverToBoxAdapter(
          child: _TsukuyomiListItem(
            onPerformLayout: (box, oldSize, newSize) {
              if (oldSize == null) return;
              final (oldExtent, newExtent) = switch (widget.scrollDirection) {
                Axis.vertical => (oldSize.height, newSize.height),
                Axis.horizontal => (oldSize.width, newSize.width),
              };
              final delta = newExtent - oldExtent;
              final viewport = RenderAbstractViewport.maybeOf(box) as RenderViewportBase?;
              // 只在尺寸变小时需要修正滚动偏移
              if (delta >= 0 || viewport == null) return;
              final offset = viewport.getOffsetToReveal(box, 0.0).offset;
              final trailing = offset - viewport.offset.pixels + newExtent;
              // 如果占位区域底部可见
              if (trailing > Tolerance.defaultTolerance.distance) {
                _scrollController.position.correctImmediate(-delta);
              }
            },
            child: Container(
              color: _purpleDebugMask,
              width: switch (widget.scrollDirection) {
                Axis.vertical => null,
                Axis.horizontal => widget.leadingExtent,
              },
              height: switch (widget.scrollDirection) {
                Axis.vertical => widget.leadingExtent,
                Axis.horizontal => null,
              },
            ),
          ),
        ),
        _SliverLayout(
          onPerformLayout: (geometry) => _scrollExtentBeforeCenter = geometry.scrollExtent,
          sliver: SliverList.builder(
            itemCount: _centerIndex > 0 ? _centerIndex : 0,
            itemBuilder: (context, index) => _buildItem(context, _centerIndex - index - 1),
          ),
        ),
        _SliverLayout(
          key: _centerKey,
          onPerformLayout: (geometry) => _scrollExtentAfterCenter = geometry.scrollExtent,
          sliver: SliverStack(
            children: [
              // 从列表中心位置开始计算和显示列表末尾空白部分，避免受到视窗或列表项尺寸变化的影响
              if (widget.trailing && trailingFraction > 0.0)
                SliverFillViewport(
                  padEnds: false,
                  viewportFraction: trailingFraction,
                  delegate: SliverChildBuilderDelegate(
                    childCount: 1,
                    (context, index) => Container(color: _purpleDebugMask),
                  ),
                ),
              SliverList.builder(
                itemCount: widget.itemKeys.length - _centerIndex,
                itemBuilder: (context, index) => _buildItem(context, _centerIndex + index),
              ),
            ],
          ),
        ),
        // 在列表主轴方向尺寸不足一个屏幕时填充剩余区域，统一列表回弹复位时的视觉效果
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final extentBefore = _scrollExtentBeforeCenter;
            final extentAfter = _scrollExtentAfterCenter;
            final extentMax = constraints.viewportMainAxisExtent;
            final extentLeft = extentMax - extentBefore - extentAfter;
            return SliverToBoxAdapter(
              child: Container(
                color: _pinkDebugMask,
                height: clampDouble(extentLeft, 0.0, extentMax),
              ),
            );
          },
        ),
        SliverToBoxAdapter(
          child: _TsukuyomiListItem(
            onPerformLayout: (box, oldSize, newSize) {
              if (oldSize == null) return;
              final (oldExtent, newExtent) = switch (widget.scrollDirection) {
                Axis.vertical => (oldSize.height, newSize.height),
                Axis.horizontal => (oldSize.width, newSize.width),
              };
              final delta = newExtent - oldExtent;
              final viewport = RenderAbstractViewport.maybeOf(box) as RenderViewportBase?;
              // 只在尺寸变小时需要修正滚动偏移
              if (delta >= 0 || viewport == null) return;
              final offset = viewport.getOffsetToReveal(box, 0.0).offset;
              final viewportDimension = _scrollController.position.viewportDimension;
              final leading = offset - viewport.offset.pixels - viewportDimension;
              // 如果占位区域顶部可见
              if (-leading > Tolerance.defaultTolerance.distance) {
                _scrollController.position.correctImmediate(delta);
              }
            },
            child: Container(
              color: _purpleDebugMask,
              width: switch (widget.scrollDirection) {
                Axis.vertical => null,
                Axis.horizontal => widget.trailingExtent,
              },
              height: switch (widget.scrollDirection) {
                Axis.vertical => widget.trailingExtent,
                Axis.horizontal => null,
              },
            ),
          ),
        ),
      ],
    );
  }

  /// 粉色调试遮罩
  Color? get _pinkDebugMask => widget.debugMask ? Colors.pink.withOpacity(0.33) : null;

  /// 紫色调试遮罩
  Color? get _purpleDebugMask => widget.debugMask ? Colors.purple.withOpacity(0.33) : null;

  /// 列表末尾空白部分占比
  double get trailingFraction => _trailingFraction;
  double _trailingFraction = 1.0;

  set trailingFraction(double value) {
    final trailingFraction = value.clamp(0.0, 1.0);
    // 列表末尾空白部分占比只能减少不能增加
    if (trailingFraction < _trailingFraction) {
      setState(() => _trailingFraction = trailingFraction);
    }
  }

  Widget _buildItem(BuildContext context, int index) {
    return _TsukuyomiListItem(
      // 保证添加列表项和移除列表项的对应关系
      key: ValueKey(index - _centerIndex),
      onMount: (element) {
        _elements.add(element);
        _scheduleUpdateItems();
      },
      onUnmount: (element) {
        _elements.remove(element);
        _scheduleUpdateItems();
      },
      onPerformLayout: (box, oldSize, newSize) {
        // 获取主轴方向尺寸
        final newExtent = switch (widget.scrollDirection) {
          Axis.vertical => newSize.height,
          Axis.horizontal => newSize.width,
        };
        // 保存最新的列表项尺寸
        _extents[index - _centerIndex] = newExtent;
      },
      child: Container(
        foregroundDecoration: BoxDecoration(color: index == _anchorIndex ? _pinkDebugMask : null),
        child: index < widget.itemKeys.length ? widget.itemBuilder(context, index) : null,
      ),
    );
  }

  double _calculateAnchor(ScrollPosition position) {
    final extentBefore = position.extentBefore;
    final extentInside = position.extentInside;
    final extentAfter = position.extentAfter;
    // 顶部和底部剩余滚动区域一样时优先使用上半部分作为锚点
    if (extentBefore <= extentAfter && extentBefore < extentInside) {
      return (extentBefore / extentInside / 2).clamp(0.0, 0.5);
    }
    // 底部剩余滚动区域比顶部大时再选择使用下半部分作为锚点
    if (extentAfter < extentBefore && extentAfter < extentInside) {
      return (1.0 - extentAfter / extentInside / 2).clamp(0.5, 1.0);
    }
    return 0.5;
  }

  bool _updateScheduled = false;

  void _scheduleUpdateItems() {
    if (_updateScheduled) return;
    _updateScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      final position = _scrollController.hasClients ? _scrollController.position : null;
      if (!mounted || position == null || !position.hasViewportDimension || !position.hasPixels) return;
      final items = <TsukuyomiListItem>[];
      final anchor = widget.anchor ?? _calculateAnchor(position);
      final sortedElements = _elements.toList()..sort((a, b) => a.widget.key!.value.compareTo(b.widget.key!.value));
      int? anchorIndex;
      RenderViewportBase? viewport;
      for (final element in sortedElements) {
        final index = element.widget.key!.value + _centerIndex;
        if (index >= widget.itemKeys.length) continue;

        final box = element.findRenderObject() as RenderBox?;
        viewport ??= RenderAbstractViewport.maybeOf(box) as RenderViewportBase?;
        if (box == null || !box.hasSize || viewport == null) continue;

        final offset = viewport.getOffsetToReveal(box, 0.0).offset;
        final item = TsukuyomiListItem(
          index: index,
          size: box.size,
          axis: widget.scrollDirection,
          offset: offset - viewport.offset.pixels,
          viewport: position.viewportDimension,
        );
        // 添加列表项信息
        items.add(item);
        // 根据中心列表项起始位置计算列表末尾空白部分占比
        if (widget.trailing && item.index == _centerIndex) {
          trailingFraction = 1.0 - item.leading;
        }
        // 选择第一个符合条件的列表项作为锚点列表项
        if (item.leading <= anchor && item.trailing >= anchor) {
          anchorIndex ??= item.index;
        }
      }
      // 当前锚点列表项发生位移时才更新锚点列表项索引，避免初始化或者跳转时发生预期外的偏移
      if (anchorIndex != null && _anchorIndex != anchorIndex && (_anchorIndex != _centerIndex || position.pixels != 0.0)) {
        for (var i = anchorIndex - _centerIndex; i < 0; i++) {
          final extent = _extents[i];
          if (extent == null) {
            continue;
          }
          _scrollController.position.correctImmediate(extent);
        }
        for (var i = 0; i < anchorIndex - _centerIndex; i++) {
          final extent = _extents[i];
          if (extent == null) {
            continue;
          }
          _scrollController.position.correctImmediate(-extent);
        }
        _centerIndex = _anchorIndex = anchorIndex;
        setState(() {});
      }
      // 回调根据索引顺序进行排序的所有已渲染列表项数据
      widget.onItemsChanged?.call(items);
    });
  }

  void _jumpToIndex(int index) {
    assert(index >= 0);
    assert(index < widget.itemKeys.length || widget.itemKeys.isEmpty);
    setState(() {
      _trailingFraction = 1.0;
      _scrollController.jumpTo(0.0);
      _centerIndex = _anchorIndex = index;
      _extents.clear();
    });
  }

  Future<void> _slideViewport(double viewportFraction, {required Duration duration, required Curve curve}) async {
    assert(viewportFraction >= -1.0 && viewportFraction <= 1.0);
    if (viewportFraction == 0.0) return;
    final position = _scrollController.position;
    final currentPixels = position.pixels;
    final delta = position.viewportDimension * viewportFraction;
    if (delta < 0.0 && currentPixels > position.minScrollExtent) {
      final to = math.max(currentPixels + delta, position.minScrollExtent);
      return position.animateTo(to, duration: duration, curve: curve);
    }
    if (delta > 0.0 && currentPixels < position.maxScrollExtent) {
      final to = math.min(currentPixels + delta, position.maxScrollExtent);
      return position.animateTo(to, duration: duration, curve: curve);
    }
  }
}

class TsukuyomiListItem {
  /// 列表项索引
  final int index;

  /// 列表项起点相对于视窗的位置
  late final double leading;

  /// 列表项终点相对于视窗的位置
  late final double trailing;

  TsukuyomiListItem({
    required this.index,
    required Size size,
    required Axis axis,
    required double offset,
    required double viewport,
  }) {
    final extent = axis == Axis.vertical ? size.height : size.width;
    leading = _position(offset, viewport);
    trailing = _position(offset + extent, viewport);
  }

  /// 计算相对于视窗的位置
  double _position(double offset, double viewport) {
    final value = offset / viewport;
    if (nearEqual(value, 0.0, Tolerance.defaultTolerance.distance)) {
      return 0.0;
    }
    if (nearEqual(value, 1.0, Tolerance.defaultTolerance.distance)) {
      return 1.0;
    }
    return value;
  }
}

class TsukuyomiListController {
  _TsukuyomiListState? _tsukuyomiListState;

  void _attach(_TsukuyomiListState state) {
    _tsukuyomiListState = state;
  }

  void _detach(_TsukuyomiListState state) {
    if (_tsukuyomiListState == state) {
      _tsukuyomiListState = null;
    }
  }

  @internal
  ScrollPosition get position {
    assert(_tsukuyomiListState != null);
    return _tsukuyomiListState!._scrollController.position;
  }

  @visibleForTesting
  int get centerIndex {
    assert(_tsukuyomiListState != null);
    return _tsukuyomiListState!._centerIndex;
  }

  @visibleForTesting
  int get anchorIndex {
    assert(_tsukuyomiListState != null);
    return _tsukuyomiListState!._anchorIndex;
  }

  void jumpToIndex(int index) {
    assert(_tsukuyomiListState != null);
    _tsukuyomiListState!._jumpToIndex(index);
  }

  Future<void> slideViewport(
    double viewportFraction, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOutCubic,
  }) async {
    assert(_tsukuyomiListState != null);
    return _tsukuyomiListState!._slideViewport(
      viewportFraction,
      duration: duration,
      curve: curve,
    );
  }
}

class _TsukuyomiListScrollController extends ScrollController {
  @override
  _TsukuyomiListScrollPosition get position => super.position as _TsukuyomiListScrollPosition;

  @override
  _TsukuyomiListScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) {
    return _TsukuyomiListScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class _TsukuyomiListScrollPosition extends ScrollPositionWithSingleContext {
  _TsukuyomiListScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  double? _correction;

  /// 在下次布局时修正滚动偏移
  void correctImmediate(double correction) {
    if (correction != 0.0) {
      _correction = (_correction ?? 0.0) + correction;
      correctBy(correction);
    }
  }

  @override
  @protected
  bool correctForNewDimensions(ScrollMetrics oldPosition, ScrollMetrics newPosition) {
    // 是否需要修正滚动偏移
    if (_correction != null) {
      _correction = null;
      return false;
    }
    return super.correctForNewDimensions(oldPosition, newPosition);
  }

  @override
  void goBallistic(double velocity) {
    assert(hasPixels);
    final Simulation? simulation = physics.createBallisticSimulation(this, velocity);
    if (simulation != null) {
      // 进行惯性滚动时需要在中心列表项已经更新但还没有重新布局时修正滚动偏移
      beginActivity(_TsukuyomiListBallisticScrollActivity(
        this,
        simulation,
        context.vsync,
        activity?.shouldIgnorePointer ?? true,
      ));
    } else {
      goIdle();
    }
  }

  @override
  Future<void> animateTo(double to, {required Duration duration, required Curve curve}) {
    if (nearEqual(to, pixels, physics.toleranceFor(this).distance)) {
      jumpTo(to);
      return Future<void>.value();
    }

    // 根据相对位置变化进行动画处理
    final activity = TsukuyomiDeltaScrollActivity(
      this,
      from: pixels,
      to: to,
      duration: duration,
      curve: curve,
      vsync: context.vsync,
    );
    beginActivity(activity);
    return activity.done;
  }
}

class _TsukuyomiListBallisticScrollActivity extends BallisticScrollActivity {
  _TsukuyomiListBallisticScrollActivity(
    _TsukuyomiListScrollPosition super.delegate,
    super.simulation,
    super.vsync,
    super.shouldIgnorePointer,
  );

  @override
  _TsukuyomiListScrollPosition get delegate => super.delegate as _TsukuyomiListScrollPosition;

  @override
  @protected
  bool applyMoveTo(double value) => delegate.setPixels(value + (delegate._correction ?? 0.0)).abs() < precisionErrorTolerance;
}

class _TsukuyomiListItem extends SingleChildRenderObjectWidget {
  const _TsukuyomiListItem({ValueKey<int>? super.key, this.onMount, this.onUnmount, this.onPerformLayout, required super.child});

  final ValueChanged<_TsukuyomiListItemElement>? onMount;

  final ValueChanged<_TsukuyomiListItemElement>? onUnmount;

  final _OnPerformLayout? onPerformLayout;

  @override
  ValueKey<int>? get key => super.key as ValueKey<int>?;

  @override
  SingleChildRenderObjectElement createElement() => _TsukuyomiListItemElement(this);

  @override
  _RenderTsukuyomiListItem createRenderObject(BuildContext context) => _RenderTsukuyomiListItem(onPerformLayout: onPerformLayout);

  @override
  void updateRenderObject(BuildContext context, _RenderTsukuyomiListItem renderObject) => renderObject.onPerformLayout = onPerformLayout;
}

class _TsukuyomiListItemElement extends SingleChildRenderObjectElement {
  _TsukuyomiListItemElement(super.widget);

  @override
  _TsukuyomiListItem get widget => super.widget as _TsukuyomiListItem;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    widget.onMount?.call(this);
  }

  @override
  void unmount() {
    widget.onUnmount?.call(this);
    super.unmount();
  }
}

class _RenderTsukuyomiListItem extends RenderProxyBox {
  _RenderTsukuyomiListItem({required this.onPerformLayout});

  _OnPerformLayout? onPerformLayout;

  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    onPerformLayout?.call(this, _oldSize, size);
    _oldSize = size;
  }
}

class _SliverLayout extends SingleChildRenderObjectWidget {
  const _SliverLayout({super.key, this.onPerformLayout, required Widget sliver}) : super(child: sliver);

  final void Function(SliverGeometry geometry)? onPerformLayout;

  @override
  _RenderSliverLayout createRenderObject(BuildContext context) => _RenderSliverLayout(onPerformLayout: onPerformLayout);

  @override
  void updateRenderObject(BuildContext context, _RenderSliverLayout renderObject) => renderObject.onPerformLayout = onPerformLayout;
}

class _RenderSliverLayout extends RenderProxySliver {
  _RenderSliverLayout({this.onPerformLayout});

  void Function(SliverGeometry geometry)? onPerformLayout;

  @override
  void performLayout() {
    super.performLayout();
    onPerformLayout?.call(geometry!);
  }
}
