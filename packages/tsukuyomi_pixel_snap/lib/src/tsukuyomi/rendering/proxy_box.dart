import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:tsukuyomi_pixel_snap/src/tsukuyomi/rendering/box.dart';

part 'package:tsukuyomi_pixel_snap/src/flutter/rendering/proxy_box.dart';

class TsukuyomiPixelRenderFittedBox extends RenderFittedBox {
  TsukuyomiPixelRenderFittedBox({
    double? scale,
    super.fit,
    super.alignment,
    super.textDirection,
    super.child,
    super.clipBehavior,
  }) : _scale = scale;

  /// 缩放比例
  double? get scale => _scale;
  double? _scale;
  set scale(double? value) {
    if (_scale == value) {
      return;
    }
    _scale = value;
    markNeedsLayout();
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    if (child != null) {
      final Size childSize = child!.getDryLayout(const BoxConstraints());

      switch (fit) {
        case BoxFit.scaleDown:
          final BoxConstraints sizeConstraints = constraints.loosen();
          // region Tsukuyomi: 修改尺寸计算方法
          // ```
          // final Size unconstrainedSize = sizeConstraints.constrainSizeAndAttemptToPreserveAspectRatio(childSize);
          // ```
          final Size unconstrainedSize = sizeConstraints.pixelSnapConstrainSizeAndAttemptToPreserveAspectRatio(child!.size, scale);
          // endregion Tsukuyomi
          return constraints.constrain(unconstrainedSize);
        case BoxFit.contain:
        case BoxFit.cover:
        case BoxFit.fill:
        case BoxFit.fitHeight:
        case BoxFit.fitWidth:
        case BoxFit.none:
          // region Tsukuyomi: 修改尺寸计算方法
          // ```
          // return constraints.constrainSizeAndAttemptToPreserveAspectRatio(childSize);
          // ```
          return constraints.pixelSnapConstrainSizeAndAttemptToPreserveAspectRatio(childSize, scale);
          // endregion Tsukuyomi
      }
    } else {
      return constraints.smallest;
    }
  }

  @override
  void performLayout() {
    if (child != null) {
      child!.layout(const BoxConstraints(), parentUsesSize: true);
      switch (fit) {
        case BoxFit.scaleDown:
          final BoxConstraints sizeConstraints = constraints.loosen();
          // region Tsukuyomi: 修改尺寸计算方法
          // ```
          // final Size unconstrainedSize = sizeConstraints.constrainSizeAndAttemptToPreserveAspectRatio(child!.size);
          // ```
          final Size unconstrainedSize = sizeConstraints.pixelSnapConstrainSizeAndAttemptToPreserveAspectRatio(child!.size, scale);
          // endregion Tsukuyomi
          size = constraints.constrain(unconstrainedSize);
        case BoxFit.contain:
        case BoxFit.cover:
        case BoxFit.fill:
        case BoxFit.fitHeight:
        case BoxFit.fitWidth:
        case BoxFit.none:
          // region Tsukuyomi: 修改尺寸计算方法
          // ```
          // size = constraints.constrainSizeAndAttemptToPreserveAspectRatio(child!.size);
          // ```
          size = constraints.pixelSnapConstrainSizeAndAttemptToPreserveAspectRatio(child!.size, scale);
          // endregion Tsukuyomi
      }
      _clearPaintData();
    } else {
      size = constraints.smallest;
    }
  }
}
