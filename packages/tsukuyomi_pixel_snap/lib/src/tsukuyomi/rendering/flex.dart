import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

part 'package:tsukuyomi_pixel_snap/src/flutter/rendering/flex.dart';

class TsukuyomiPixelRenderFlex extends RenderFlex {
  TsukuyomiPixelRenderFlex({
    super.children,
    super.direction,
    super.mainAxisSize,
    super.mainAxisAlignment,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    super.clipBehavior,
    super.spacing,
  });

  static int _getFlex(RenderBox child) => RenderFlex._getFlex(child);

  static FlexFit _getFit(RenderBox child) => RenderFlex._getFit(child);

  @override
  _LayoutSizes _computeSizes({
    required BoxConstraints constraints,
    required ChildLayouter layoutChild,
    required ChildBaselineGetter getBaseline,
  }) {
    assert(_debugHasNecessaryDirections);

    // Determine used flex factor, size inflexible items, calculate free space.
    final double maxMainSize = _getMainSize(constraints.biggest);
    final bool canFlex = maxMainSize.isFinite;
    final BoxConstraints nonFlexChildConstraints = _constraintsForNonFlexChild(constraints);
    // Null indicates the children are not baseline aligned.
    final TextBaseline? textBaseline = _isBaselineAligned
        ? (this.textBaseline ??
              (throw FlutterError(
                'To use CrossAxisAlignment.baseline, you must also specify which baseline to use using the "textBaseline" argument.',
              )))
        : null;

    // The first pass lays out non-flex children and computes total flex.
    int totalFlex = 0;
    RenderBox? firstFlexChild;
    _AscentDescent accumulatedAscentDescent = _AscentDescent.none;
    // Initially, accumulatedSize is the sum of the spaces between children in the main axis.
    _AxisSize accumulatedSize = _AxisSize._(Size(spacing * (childCount - 1), 0.0));
    for (RenderBox? child = firstChild; child != null; child = childAfter(child)) {
      final int flex;
      if (canFlex && (flex = _getFlex(child)) > 0) {
        totalFlex += flex;
        firstFlexChild ??= child;
      } else {
        final _AxisSize childSize = _AxisSize.fromSize(
          size: layoutChild(child, nonFlexChildConstraints),
          direction: direction,
        );
        accumulatedSize += childSize;
        // Baseline-aligned children contributes to the cross axis extent separately.
        final double? baselineOffset = textBaseline == null ? null : getBaseline(child, nonFlexChildConstraints, textBaseline);
        accumulatedAscentDescent += _AscentDescent(
          baselineOffset: baselineOffset,
          crossSize: childSize.crossAxisExtent,
        );
      }
    }

    assert((totalFlex == 0) == (firstFlexChild == null));
    assert(
      firstFlexChild == null || canFlex,
    ); // If we are given infinite space there's no need for this extra step.

    // The second pass distributes free space to flexible children.
    final double flexSpace = math.max(0.0, maxMainSize - accumulatedSize.mainAxisExtent);
    final double spacePerFlex = flexSpace / totalFlex;
    for (RenderBox? child = firstFlexChild; child != null && totalFlex > 0; child = childAfter(child)) {
      final int flex = _getFlex(child);
      if (flex == 0) {
        continue;
      }
      totalFlex -= flex;
      assert(spacePerFlex.isFinite);
      final double maxChildExtent = spacePerFlex * flex;
      assert(_getFit(child) == FlexFit.loose || maxChildExtent < double.infinity);
      final BoxConstraints childConstraints = _constraintsForFlexChild(
        child,
        constraints,
        maxChildExtent,
      );
      final _AxisSize childSize = _AxisSize.fromSize(
        size: layoutChild(child, childConstraints),
        direction: direction,
      );
      accumulatedSize += childSize;
      final double? baselineOffset = textBaseline == null ? null : getBaseline(child, childConstraints, textBaseline);
      accumulatedAscentDescent += _AscentDescent(
        baselineOffset: baselineOffset,
        crossSize: childSize.crossAxisExtent,
      );
    }
    assert(totalFlex == 0);

    // The overall height of baseline-aligned children contributes to the cross axis extent.
    accumulatedSize += switch (accumulatedAscentDescent) {
      null => _AxisSize.empty,
      (final double ascent, final double descent) => _AxisSize(
        mainAxisExtent: 0,
        crossAxisExtent: ascent + descent,
      ),
    };

    final double idealMainSize = switch (mainAxisSize) {
      MainAxisSize.max when maxMainSize.isFinite => maxMainSize,
      MainAxisSize.max || MainAxisSize.min => accumulatedSize.mainAxisExtent,
    };

    final _AxisSize constrainedSize = _AxisSize(
      mainAxisExtent: idealMainSize,
      crossAxisExtent: accumulatedSize.crossAxisExtent,
    ).applyConstraints(constraints, direction);
    return _LayoutSizes(
      axisSize: constrainedSize,
      mainAxisFreeSpace: constrainedSize.mainAxisExtent - accumulatedSize.mainAxisExtent,
      baselineOffset: accumulatedAscentDescent.baselineOffset,
      spacePerFlex: firstFlexChild == null ? null : spacePerFlex,
    );
  }

  // @override
  // _LayoutSizes _computeSizes({required BoxConstraints constraints, required ChildLayouter layoutChild}) {
  //   assert(_debugHasNecessaryDirections);
  //
  //   // Determine used flex factor, size inflexible items, calculate free space.
  //   int totalFlex = 0;
  //   final double maxMainSize = _direction == Axis.horizontal ? constraints.maxWidth : constraints.maxHeight;
  //   final bool canFlex = maxMainSize < double.infinity;
  //
  //   double crossSize = 0.0;
  //   double allocatedSize = 0.0; // Sum of the sizes of the non-flexible children.
  //   RenderBox? child = firstChild;
  //   RenderBox? lastFlexChild;
  //   while (child != null) {
  //     final FlexParentData childParentData = child.parentData! as FlexParentData;
  //     final int flex = _getFlex(child);
  //     if (flex > 0) {
  //       totalFlex += flex;
  //       lastFlexChild = child;
  //     } else {
  //       final BoxConstraints innerConstraints;
  //       if (crossAxisAlignment == CrossAxisAlignment.stretch) {
  //         switch (_direction) {
  //           case Axis.horizontal:
  //             innerConstraints = BoxConstraints.tightFor(height: constraints.maxHeight);
  //           case Axis.vertical:
  //             innerConstraints = BoxConstraints.tightFor(width: constraints.maxWidth);
  //         }
  //       } else {
  //         switch (_direction) {
  //           case Axis.horizontal:
  //             innerConstraints = BoxConstraints(maxHeight: constraints.maxHeight);
  //           case Axis.vertical:
  //             innerConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
  //         }
  //       }
  //       final Size childSize = layoutChild(child, innerConstraints);
  //       allocatedSize += _getMainSize(childSize);
  //       crossSize = math.max(crossSize, _getCrossSize(childSize));
  //     }
  //     assert(child.parentData == childParentData);
  //     child = childParentData.nextSibling;
  //   }
  //
  //   // Distribute free space to flexible children.
  //   final double freeSpace = math.max(0.0, (canFlex ? maxMainSize : 0.0) - allocatedSize);
  //   double allocatedFlexSpace = 0.0;
  //   if (totalFlex > 0) {
  //     final double spacePerFlex = canFlex ? (freeSpace / totalFlex) : double.nan;
  //     child = firstChild;
  //     while (child != null) {
  //       final int flex = _getFlex(child);
  //       if (flex > 0) {
  //         // region Tsukuyomi: 修改尺寸计算方法
  //         final double maxChildExtent = canFlex ? (child == lastFlexChild ? (freeSpace - allocatedFlexSpace) : spacePerFlex * flex).pixelSnap() : double.infinity;
  //         // endregion Tsukuyomi
  //         late final double minChildExtent;
  //         switch (_getFit(child)) {
  //           case FlexFit.tight:
  //             assert(maxChildExtent < double.infinity);
  //             minChildExtent = maxChildExtent;
  //           case FlexFit.loose:
  //             minChildExtent = 0.0;
  //         }
  //         final BoxConstraints innerConstraints;
  //         if (crossAxisAlignment == CrossAxisAlignment.stretch) {
  //           switch (_direction) {
  //             case Axis.horizontal:
  //               innerConstraints = BoxConstraints(
  //                 minWidth: minChildExtent,
  //                 maxWidth: maxChildExtent,
  //                 minHeight: constraints.maxHeight,
  //                 maxHeight: constraints.maxHeight,
  //               );
  //             case Axis.vertical:
  //               innerConstraints = BoxConstraints(
  //                 minWidth: constraints.maxWidth,
  //                 maxWidth: constraints.maxWidth,
  //                 minHeight: minChildExtent,
  //                 maxHeight: maxChildExtent,
  //               );
  //           }
  //         } else {
  //           switch (_direction) {
  //             case Axis.horizontal:
  //               innerConstraints = BoxConstraints(
  //                 minWidth: minChildExtent,
  //                 maxWidth: maxChildExtent,
  //                 maxHeight: constraints.maxHeight,
  //               );
  //             case Axis.vertical:
  //               innerConstraints = BoxConstraints(
  //                 maxWidth: constraints.maxWidth,
  //                 minHeight: minChildExtent,
  //                 maxHeight: maxChildExtent,
  //               );
  //           }
  //         }
  //         final Size childSize = layoutChild(child, innerConstraints);
  //         final double childMainSize = _getMainSize(childSize);
  //         assert(childMainSize <= maxChildExtent);
  //         allocatedSize += childMainSize;
  //         allocatedFlexSpace += maxChildExtent;
  //         crossSize = math.max(crossSize, _getCrossSize(childSize));
  //       }
  //       final FlexParentData childParentData = child.parentData! as FlexParentData;
  //       child = childParentData.nextSibling;
  //     }
  //   }
  //
  //   final double idealSize = canFlex && mainAxisSize == MainAxisSize.max ? maxMainSize : allocatedSize;
  //   return _LayoutSizes(
  //     mainSize: idealSize,
  //     crossSize: crossSize,
  //     allocatedSize: allocatedSize,
  //   );
  // }
}
