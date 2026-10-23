import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox, RenderProxySliver, SliverGeometry;
import 'package:flutter/scheduler.dart';
import 'package:meta/meta.dart';
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
  late List<Object> _itemKeys;
  late Object? _anchorKey;
  late int _anchorIndex;
  final _centerKey = UniqueKey();
  final _elements = <int, _TsukuyomiListItemElement>{};
  final _scrollController = _TsukuyomiListScrollController();

  /// 在列表中心之前的滚动区域范围
  double _scrollExtentBeforeCenter = 0.0;

  /// 在列表中心之前的滚动区域范围
  double _scrollExtentAfterCenter = 0.0;

  /// 在列表主轴方向的视口区域范围
  double? _viewportDimension;

  @override
  void initState() {
    super.initState();
    _itemKeys = List.of(widget.itemKeys);
    _anchorIndex = _itemKeys.isEmpty ? 0 : widget.initialScrollIndex;
    _anchorKey = _itemKeys.isEmpty ? null : _itemKeys[_anchorIndex];
    _scrollController.addListener(() => _scheduleUpdateItems(reselectAnchor: true));
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
    // 更新列表项标识
    if (!listEquals(_itemKeys, widget.itemKeys)) {
      _itemKeys = List.of(widget.itemKeys);
      // 修正锚点列表项位置
      if (_itemKeys.isEmpty || _anchorKey == null) {
        _updateAnchor(0);
      } else if (_itemKeys.indexWhere((key) => key == _anchorKey) case final newAnchorIndex when newAnchorIndex >= 0) {
        _updateAnchor(newAnchorIndex);
      } else {
        _updateAnchor(math.min(_anchorIndex, _itemKeys.length - 1));
      }
      _scheduleUpdateItems(reselectAnchor: true);
    }
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
                _scrollController.position.correctByDelta(-delta);
                _scheduleUpdateItems(reselectAnchor: false);
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
        // 锚点变化时重建前后列表，避免沿用其他列表项的布局偏移
        _SliverLayout(
          onPerformLayout: (geometry) => _scrollExtentBeforeCenter = geometry.scrollExtent,
          sliver: SliverList.builder(
            key: ValueKey(_anchorKey),
            itemCount: _anchorIndex > 0 ? _anchorIndex : 0,
            itemBuilder: (context, index) => _buildItem(context, _anchorIndex - index - 1),
          ),
        ),
        _SliverLayout(
          key: _centerKey,
          onPerformLayout: (geometry) => _scrollExtentAfterCenter = geometry.scrollExtent,
          sliver: SliverList.builder(
            key: ValueKey(_anchorKey),
            itemCount: _itemKeys.length - _anchorIndex,
            itemBuilder: (context, index) => _buildItem(context, _anchorIndex + index),
          ),
        ),
        // 在列表主轴方向尺寸不足一个屏幕时填充剩余区域，统一列表回弹复位时的视觉效果
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final extentBefore = _scrollExtentBeforeCenter;
            final extentAfter = _scrollExtentAfterCenter;
            final extentMax = constraints.viewportMainAxisExtent;
            final extentLeft = clampDouble(extentMax - extentBefore - extentAfter, 0.0, extentMax);
            if (_viewportDimension != extentMax) {
              _viewportDimension = extentMax;
              _scheduleUpdateItems(reselectAnchor: false);
            }
            return SliverToBoxAdapter(
              child: Container(
                color: _pinkDebugMask,
                width: switch (widget.scrollDirection) {
                  Axis.vertical => null,
                  Axis.horizontal => extentLeft,
                },
                height: switch (widget.scrollDirection) {
                  Axis.vertical => extentLeft,
                  Axis.horizontal => null,
                },
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
                _scrollController.position.correctByDelta(delta);
                _scheduleUpdateItems(reselectAnchor: false);
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

  Widget _buildItem(BuildContext context, int index) {
    return _TsukuyomiListItem(
      index: index - _anchorIndex,
      onMount: (element) {
        _elements[element.requiredIndex] = element;
        _scheduleUpdateItems(reselectAnchor: false);
      },
      onUnmount: (element) {
        final elementIndex = element.requiredIndex;
        if (_elements[elementIndex] == element) {
          _elements.remove(elementIndex);
        }
        _scheduleUpdateItems(reselectAnchor: false);
      },
      onPerformLayout: (box, oldSize, newSize) {
        if (oldSize != newSize) _scheduleUpdateItems(reselectAnchor: false);
      },
      child: Container(
        foregroundDecoration: index == _anchorIndex ? BoxDecoration(color: _pinkDebugMask) : null,
        child: KeyedSubtree(
          key: _TsukuyomiListChildGlobalKey(listKey: _centerKey, itemKey: _itemKeys[index]),
          child: widget.itemBuilder(context, index),
        ),
      ),
    );
  }

  void _updateAnchor(int anchorIndex) {
    assert(anchorIndex >= 0);
    if (anchorIndex != _anchorIndex) setState(() {});
    _anchorIndex = anchorIndex;
    _anchorKey = _itemKeys.isEmpty ? null : _itemKeys[_anchorIndex];
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
  bool _anchorReselectScheduled = false;
  void _scheduleUpdateItems({required bool reselectAnchor}) {
    _anchorReselectScheduled |= reselectAnchor;
    if (_updateScheduled) return;
    _updateScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final reselectAnchor = _anchorReselectScheduled;
      _updateScheduled = false;
      _anchorReselectScheduled = false;
      final position = _scrollController.hasClients ? _scrollController.position : null;
      if (!mounted || position == null || !position.hasViewportDimension || !position.hasPixels) return;
      final items = <TsukuyomiListItem>[];
      final anchor = widget.anchor ?? _calculateAnchor(position);
      final sortedElements = _elements.values.toList()..sort((a, b) => a.requiredIndex.compareTo(b.requiredIndex));
      int? anchorIndex;
      double anchorOffset = 0.0;
      RenderViewportBase? viewport;
      for (final element in sortedElements) {
        final index = element.requiredIndex + _anchorIndex;
        if (index >= _itemKeys.length) continue;

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
        // 选择第一个符合条件的列表项作为锚点列表项
        if (reselectAnchor && anchorIndex == null && item.leading <= anchor && item.trailing >= anchor) {
          anchorIndex = item.index;
          anchorOffset = offset;
        }
      }
      // 当前锚点列表项发生位移时才更新锚点列表项索引，避免初始化或者跳转时发生预期外的偏移
      if (anchorIndex != null && _anchorIndex != anchorIndex && (position.pixels != 0.0 && position.pixels != position.maxScrollExtent)) {
        _scrollController.position.correctByDelta(-anchorOffset);
        _updateAnchor(anchorIndex);
      }
      // 回调根据索引顺序进行排序的所有已渲染列表项数据
      widget.onItemsChanged?.call(items);
    });
  }

  void _jumpToIndex(int index) {
    _scrollController.position.correctByJump(0.0);
    _updateAnchor(index);
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

  /// 列表项索引
  final int index;

  /// 列表项起点相对于视窗的位置
  late final double leading;

  /// 列表项终点相对于视窗的位置
  late final double trailing;

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

class _TsukuyomiListChildGlobalKey extends GlobalObjectKey {
  const _TsukuyomiListChildGlobalKey({required this.listKey, required this.itemKey}) : super(listKey);

  final Key listKey;

  final Object itemKey;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _TsukuyomiListChildGlobalKey && other.listKey == listKey && other.itemKey == itemKey;
  }

  @override
  int get hashCode => Object.hash(listKey, itemKey);
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
  int get anchorIndex {
    assert(_tsukuyomiListState != null);
    return _tsukuyomiListState!._anchorIndex;
  }

  @visibleForTesting
  double? get correction {
    assert(_tsukuyomiListState != null);
    return _tsukuyomiListState!._scrollController.position._correction;
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

  double? _origin = 0.0;

  double? _correction;

  /// 在布局更新滚动范围之前，将边界同步到修正后的滚动坐标
  ScrollMetrics get _correctedMetrics {
    final correction = _correction;
    if (correction == null) return this;
    return copyWith(
      minScrollExtent: minScrollExtent + correction,
      maxScrollExtent: maxScrollExtent + correction,
    );
  }

  /// 跳转到指定位置并修正越界偏移
  void correctByJump(double value) {
    _origin = value;
    jumpTo(value);
  }

  /// 在下次布局时修正指定滚动偏移
  void correctByDelta(double delta) {
    if (delta != 0.0) {
      _correction = (_correction ?? 0.0) + delta;
      correctBy(delta);
    }
  }

  @override
  double applyBoundaryConditions(double value) {
    if (_correction == null) return super.applyBoundaryConditions(value);
    return physics.applyBoundaryConditions(_correctedMetrics, value);
  }

  @override
  bool correctForNewDimensions(ScrollMetrics oldPosition, ScrollMetrics newPosition) {
    // 是否需要修正滚动偏移
    if (_correction != null) {
      _correction = null;
      return false;
    }
    return super.correctForNewDimensions(oldPosition, newPosition);
  }

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    // 是否需要修正默认索引和索引跳转的越界偏移
    if (_origin == pixels && maxScrollExtent < pixels) {
      _origin = _correction = null;
      correctBy(maxScrollExtent);
      return false;
    }
    _origin = null;
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }

  @override
  void goBallistic(double velocity) {
    assert(hasPixels);
    // 惯性活动会叠加待布局的修正量，创建模拟时先还原到与边界一致的旧坐标
    final correction = _correction;
    final metrics = correction == null ? this : copyWith(pixels: pixels - correction);
    final Simulation? simulation = physics.createBallisticSimulation(metrics, velocity);
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
    final activity = _TsukuyomiListDeltaScrollActivity(
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

class _TsukuyomiListDeltaScrollActivity extends TsukuyomiDeltaScrollActivity {
  _TsukuyomiListDeltaScrollActivity(
    _TsukuyomiListScrollPosition super.delegate, {
    required super.from,
    required super.to,
    required super.duration,
    required super.curve,
    required super.vsync,
  });

  @override
  _TsukuyomiListScrollPosition get delegate => super.delegate as _TsukuyomiListScrollPosition;

  @override
  @protected
  ScrollMetrics get metrics => delegate._correctedMetrics;
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
  const _TsukuyomiListItem({this.index, this.onMount, this.onUnmount, this.onPerformLayout, required super.child});

  final int? index;

  final ValueChanged<_TsukuyomiListItemElement>? onMount;

  final ValueChanged<_TsukuyomiListItemElement>? onUnmount;

  final _OnPerformLayout? onPerformLayout;

  @override
  SingleChildRenderObjectElement createElement() => _TsukuyomiListItemElement(this);

  @override
  _RenderTsukuyomiListItem createRenderObject(BuildContext context) => _RenderTsukuyomiListItem(onPerformLayout: onPerformLayout);

  @override
  void updateRenderObject(BuildContext context, _RenderTsukuyomiListItem renderObject) => renderObject.onPerformLayout = onPerformLayout;
}

class _TsukuyomiListItemElement extends SingleChildRenderObjectElement {
  _TsukuyomiListItemElement(super.widget);

  int get requiredIndex => widget.index!;

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
