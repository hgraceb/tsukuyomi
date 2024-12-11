// Copyright (c) 2022 Matej Knopp and the contributors
//
// MIT LICENSE
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
// OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
// IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import 'package:flutter/widgets.dart';

double _pixelSnap(double value, [double? scale]) {
  if (value.isFinite) {
    final devicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    final ratio = devicePixelRatio * (scale ?? 1.0);
    // Ensure that 1.5 is rounded down. 1 logical pixel at 150% scale
    // should render at 1 physical pixel. At 175% it should render at
    // 2 physical pixels.
    return (value * ratio - 0.05).round() / ratio;
  }
  return value;
}

extension NumberPixelSnapExtension on num {
  double pixelSnap([double? scale]) => _pixelSnap(toDouble(), scale);
}

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

    double width = size.width;
    double height = size.height;
    assert(width > 0.0);
    assert(height > 0.0);
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

    Size result = Size(constrainWidth(width.pixelSnap(scale)), constrainHeight(height).pixelSnap(scale));
    return result;
  }
}
