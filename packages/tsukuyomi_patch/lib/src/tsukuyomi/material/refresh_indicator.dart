import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/material.dart';

part 'package:tsukuyomi_patch/src/flutter/material/refresh_indicator.dart';

/// - 自定义 [scrollController] 以解决与可滚动组件一起使用时的视差问题
class PatchedRefreshIndicator extends RefreshIndicator {
  const PatchedRefreshIndicator({
    super.key,
    required super.child,
    super.displacement,
    super.edgeOffset,
    required super.onRefresh,
    super.color,
    super.backgroundColor,
    super.notificationPredicate,
    super.semanticsLabel,
    super.semanticsValue,
    super.strokeWidth,
    super.triggerMode,
    required this.scrollController,
  });

  const PatchedRefreshIndicator.adaptive({
    super.key,
    required super.child,
    super.displacement,
    super.edgeOffset,
    required super.onRefresh,
    super.color,
    super.backgroundColor,
    super.notificationPredicate,
    super.semanticsLabel,
    super.semanticsValue,
    super.strokeWidth,
    super.triggerMode,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  PatchedRefreshIndicatorState createState() => PatchedRefreshIndicatorState();
}

class PatchedRefreshIndicatorState extends RefreshIndicatorState {
  double _pixels = 0.0;

  void _onScroll() {
    final position = widget.scrollController.position;
    // 如果正处于被拖动状态并且指示器正在显示
    if ((_mode == _RefreshIndicatorMode.drag || _mode == _RefreshIndicatorMode.armed) && _positionController.value > 0) {
      _handleScrollNotification(ScrollUpdateNotification(
        context: context,
        scrollDelta: position.pixels - _pixels,
        dragDetails: DragUpdateDetails(globalPosition: Offset.zero), // 传递任意非空值避免命中开始刷新的条件导致上下拖动时意外开始刷新
        metrics: position.copyWith(pixels: 0, minScrollExtent: 0, maxScrollExtent: 0), // 修改位置参数避免命中取消刷新的条件导致上下拖动时意外取消刷新
      ));
      // 禁用其他滚动
      position.correctBy(_pixels - position.pixels);
    }
    // 保存当前滚动位置
    _pixels = position.pixels;
  }

  @override
  void _show() {
    final position = _positionController.value;
    if (0.0 < position && position < 1.0 / _kDragSizeFactorLimit) {
      // 如果指示器在可刷新范围外
      _dismiss(_RefreshIndicatorMode.canceled);
    } else {
      // 如果指示器在可刷新范围内
      super._show();
    }
  }

  @override
  void _checkDragOffset(double containerExtent) {
    assert(_mode == _RefreshIndicatorMode.drag || _mode == _RefreshIndicatorMode.armed);
    double newValue = _dragOffset! / (containerExtent * _kDragContainerExtentPercentage);

    // region Tsukuyomi: 解除复位限制并允许重复显示指示器
    // ```
    // if (_mode == _RefreshIndicatorMode.armed) {
    //   newValue = math.max(newValue, 1.0 / _kDragSizeFactorLimit);
    // }
    // _positionController.value = clampDouble(newValue, 0.0, 1.0); // this triggers various rebuilds
    // ```
    _positionController.value = clampDouble(newValue, 1e-10, 1.0);
    // endregion Tsukuyomi

    if (_mode == _RefreshIndicatorMode.drag && _valueColor.value!.alpha == 0xFF) {
      _mode = _RefreshIndicatorMode.armed;
    }
  }

  @override
  PatchedRefreshIndicator get widget {
    return super.widget as PatchedRefreshIndicator;
  }

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PatchedRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollController != oldWidget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
  }
}
