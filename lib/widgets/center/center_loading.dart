import 'dart:math' as math;

import 'package:flutter/material.dart';

const double _kMinCenterLoadingSize = 36.0;

class CenterLoading extends StatelessWidget {
  const CenterLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      // 使用 SingleChildScrollView 的话 CircularProgressIndicator 边缘会被裁剪
      builder: (context, constraints) => OverflowBox(
        maxWidth: math.max(_kMinCenterLoadingSize, constraints.maxWidth),
        maxHeight: math.max(_kMinCenterLoadingSize, constraints.maxHeight),
        alignment: Alignment.topCenter,
        child: const Center(
          // 与 CircularProgressIndicator 内部默认尺寸解耦合
          child: SizedBox(
            width: _kMinCenterLoadingSize,
            height: _kMinCenterLoadingSize,
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
