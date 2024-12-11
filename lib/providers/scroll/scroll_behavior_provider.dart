import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scroll_behavior_provider.g.dart';

/// 滚动配置
@Riverpod(keepAlive: true)
ScrollBehavior scrollBehavior(ScrollBehaviorRef ref) {
  const scrollBehavior = MaterialScrollBehavior();
  return scrollBehavior.copyWith(
    // 扩展支持鼠标滚动操作
    dragDevices: {...scrollBehavior.dragDevices, PointerDeviceKind.mouse},
    // 修改默认滚动效果
    physics: const AlwaysScrollableScrollPhysics(
      parent: BouncingScrollPhysics(
        parent: RangeMaintainingScrollPhysics(),
      ),
    ),
  );
}
