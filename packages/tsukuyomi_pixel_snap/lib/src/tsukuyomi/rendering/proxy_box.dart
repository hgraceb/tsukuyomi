import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:tsukuyomi_pixel_snap/src/pixel_snap.dart';

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
          final Size unconstrainedSize = sizeConstraints
              .constrainSizeAndAttemptToPreserveAspectRatio(childSize);
          return constraints.constrain(unconstrainedSize);
        case BoxFit.contain:
        case BoxFit.cover:
        case BoxFit.fill:
        case BoxFit.fitHeight:
        case BoxFit.fitWidth:
        case BoxFit.none:
          return constraints.constrainSizeAndAttemptToPreserveAspectRatio(childSize);
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
          final Size unconstrainedSize = sizeConstraints
              .constrainSizeAndAttemptToPreserveAspectRatio(child!.size);
          size = constraints.constrain(unconstrainedSize);
        case BoxFit.contain:
        case BoxFit.cover:
        case BoxFit.fill:
        case BoxFit.fitHeight:
        case BoxFit.fitWidth:
        case BoxFit.none:
          size = constraints.constrainSizeAndAttemptToPreserveAspectRatio(child!.size);
      }
      _clearPaintData();
    } else {
      size = constraints.smallest;
    }
  }

  // @override
  // Size computeDryLayout(BoxConstraints constraints) {
  //   if (child != null) {
  //     final Size childSize = child!.getDryLayout(const BoxConstraints());
  //
  //     // During [RenderObject.debugCheckingIntrinsics] a child that doesn't
  //     // support dry layout may provide us with an invalid size that triggers
  //     // assertions if we try to work with it. Instead of throwing, we bail
  //     // out early in that case.
  //     bool invalidChildSize = false;
  //     assert(() {
  //       if (RenderObject.debugCheckingIntrinsics && childSize.width * childSize.height == 0.0) {
  //         invalidChildSize = true;
  //       }
  //       return true;
  //     }());
  //     if (invalidChildSize) {
  //       assert(debugCannotComputeDryLayout(
  //         reason: 'Child provided invalid size of $childSize.',
  //       ));
  //       return Size.zero;
  //     }
  //
  //     switch (fit) {
  //       case BoxFit.scaleDown:
  //         final BoxConstraints sizeConstraints = constraints.loosen();
  //         // region Tsukuyomi: 修改尺寸计算方法
  //         final Size unconstrainedSize = sizeConstraints.pixelSnapConstrainSizeAndAttemptToPreserveAspectRatio(childSize, scale);
  //         // endregion Tsukuyomi
  //         return constraints.constrain(unconstrainedSize);
  //       case BoxFit.contain:
  //       case BoxFit.cover:
  //       case BoxFit.fill:
  //       case BoxFit.fitHeight:
  //       case BoxFit.fitWidth:
  //       case BoxFit.none:
  //         // region Tsukuyomi: 修改尺寸计算方法
  //         return constraints.pixelSnapConstrainSizeAndAttemptToPreserveAspectRatio(childSize, scale);
  //         // endregion Tsukuyomi
  //     }
  //   } else {
  //     return constraints.smallest;
  //   }
  // }
  //
  // @override
  // void performLayout() {
  //   if (child != null) {
  //     child!.layout(const BoxConstraints(), parentUsesSize: true);
  //     switch (fit) {
  //       case BoxFit.scaleDown:
  //         final BoxConstraints sizeConstraints = constraints.loosen();
  //         // region Tsukuyomi: 修改尺寸计算方法
  //         final Size unconstrainedSize = sizeConstraints.pixelSnapConstrainSizeAndAttemptToPreserveAspectRatio(child!.size, scale);
  //         // endregion Tsukuyomi
  //         size = constraints.constrain(unconstrainedSize);
  //       case BoxFit.contain:
  //       case BoxFit.cover:
  //       case BoxFit.fill:
  //       case BoxFit.fitHeight:
  //       case BoxFit.fitWidth:
  //       case BoxFit.none:
  //         // region Tsukuyomi: 修改尺寸计算方法
  //         size = constraints.pixelSnapConstrainSizeAndAttemptToPreserveAspectRatio(child!.size, scale);
  //         // endregion Tsukuyomi
  //     }
  //     _clearPaintData();
  //   } else {
  //     size = constraints.smallest;
  //   }
  // }
}
