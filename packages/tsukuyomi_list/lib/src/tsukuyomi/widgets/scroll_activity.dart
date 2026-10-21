import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

part 'package:tsukuyomi_list/src/flutter/widgets/scroll_activity.dart';

class TsukuyomiDeltaScrollActivity extends DrivenScrollActivity {
  TsukuyomiDeltaScrollActivity(
    ScrollPositionWithSingleContext super.delegate, {
    required super.from,
    required super.to,
    required super.duration,
    required super.curve,
    required super.vsync,
  }) : _value = from;

  late double _value;

  @override
  ScrollPositionWithSingleContext get delegate => super.delegate as ScrollPositionWithSingleContext;

  @protected
  ScrollMetrics get metrics => delegate;

  @override
  void _tick() {
    final delta = _controller.value - _value;
    _value = _controller.value;
    final metrics = this.metrics;
    final oldPixels = metrics.pixels;
    final newPixels = oldPixels + delta;
    final minPixels = math.min(oldPixels, metrics.minScrollExtent);
    final maxPixels = math.max(oldPixels, metrics.maxScrollExtent);
    // 在指定范围内更新滚动位置
    if (!applyMoveTo(newPixels.clamp(minPixels, maxPixels))) {
      delegate.goIdle();
    }
  }
}
