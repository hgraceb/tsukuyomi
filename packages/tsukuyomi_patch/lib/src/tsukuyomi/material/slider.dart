import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/services.dart';

part 'package:tsukuyomi_patch/src/flutter/material/slider.dart';

class PatchedSlider extends Slider {
  const PatchedSlider({
    super.key,
    required super.value,
    super.secondaryTrackValue,
    required super.onChanged,
    super.onChangeStart,
    super.onChangeEnd,
    super.min,
    super.max,
    super.divisions,
    super.label,
    super.activeColor,
    super.inactiveColor,
    super.secondaryActiveColor,
    super.thumbColor,
    super.overlayColor,
    super.mouseCursor,
    super.semanticFormatterCallback,
    super.focusNode,
    super.autofocus,
    super.allowedInteraction,
    super.padding,
  });

  const PatchedSlider.adaptive({
    super.key,
    required super.value,
    super.secondaryTrackValue,
    required super.onChanged,
    super.onChangeStart,
    super.onChangeEnd,
    super.min,
    super.max,
    super.divisions,
    super.label,
    super.mouseCursor,
    super.activeColor,
    super.inactiveColor,
    super.secondaryActiveColor,
    super.thumbColor,
    super.overlayColor,
    super.semanticFormatterCallback,
    super.focusNode,
    super.autofocus,
    super.allowedInteraction,
  }) : super.adaptive();

  @override
  State<Slider> createState() => _PatchedSliderState();
}

class _PatchedSliderState extends _SliderState {
  @override
  void _handleChanged(double value) {
    assert(widget.onChanged != null);
    final double lerpValue = _lerp(value);
    if (lerpValue != widget.value) {
      widget.onChanged!(lerpValue);
      // region Tsukuyomi: 注释多余的焦点请求，修复 overlay 在桌面端可能无法自动隐藏的问题
      // https://github.com/flutter/flutter/issues/123313
      // ```
      // _focusNode?.requestFocus();
      // ```
      // endregion Tsukuyomi
    }
  }
}
