import 'dart:math';

import 'package:flutter/material.dart';

/// 主题配色配置
class TsukuyomiThemeConfig {
  TsukuyomiThemeConfig({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.foreground,
    required this.card,
    required this.error,
    required this.border,
    required this.active,
  });

  /// 主题名称
  final String name;

  /// 主要颜色
  final Color primary;

  /// 次要颜色
  final Color secondary;

  /// 背景颜色
  final Color background;

  /// 前景颜色
  final Color foreground;

  /// 前景颜色
  final Color card;

  /// 错误颜色
  final Color error;

  /// 边框颜色
  final Color border;

  /// 激活颜色
  final Color active;

  /// 主题调色配置
  late final ColorScheme colorScheme = ColorScheme(
    // 根据背景颜色决定背景亮度
    brightness: ThemeData.estimateBrightnessForColor(background),
    primary: primary,
    onPrimary: active,
    secondary: secondary,
    onSecondary: foreground,
    error: error,
    // 根据错误颜色计算要在错误颜色上显示的颜色
    onError: Colors.white.withOpacity(min(error.computeLuminance() * 3, 1.0)),
    background: background,
    onBackground: border,
    surface: background,
    onSurface: foreground,
  );
}
