import 'package:flutter/widgets.dart';
import 'package:tsukuyomi_pixel_snap/src/pixel_snap.dart';

/// [BoxConstraints.constrainSizeAndAttemptToPreserveAspectRatio]
extension BoxConstraintsPixelSnapExtension on BoxConstraints {
  /// Returns a size that attempts to meet the following conditions, in order:
  ///
  ///  * The size must satisfy these constraints.
  ///  * The aspect ratio of the returned size matches the aspect ratio of the
  ///    given size.
  ///  * The returned size is as big as possible while still being equal to or
  ///    smaller than the given size.
  Size pixelSnapConstrainSizeAndAttemptToPreserveAspectRatio(Size size, double? scale) {
    if (isTight) {
      Size result = smallest;
      return result;
    }

    if (size.isEmpty) {
      return constrain(size);
    }

    double width = size.width;
    double height = size.height;
    final double aspectRatio = width / height;

    if (width > maxWidth) {
      width = maxWidth;
      height = width / aspectRatio;
    }

    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspectRatio;
    }

    if (width < minWidth) {
      width = minWidth;
      height = width / aspectRatio;
    }

    if (height < minHeight) {
      height = minHeight;
      width = height * aspectRatio;
    }

    Size result = Size(constrainWidth(width.pixelSnap(scale)), constrainHeight(height.pixelSnap(scale)));
    return result;
  }
}
