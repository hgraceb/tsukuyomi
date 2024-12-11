import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/providers/providers.dart';

part 'theme_data_provider.freezed.dart';

part 'theme_data_provider.g.dart';

@Riverpod(keepAlive: true)
ThemeInfo themeData(ThemeDataRef ref) {
  final themePreferences = ref.watch(themePreferenceProvider);
  final themePredefined = ref.watch(themePredefinedProvider);
  final lightThemeConfig = themePredefined[0];
  final darkThemeConfig = themePredefined[0];

  return ThemeInfo(
    themeMode: themePreferences.themeMode,
    lightTheme: TsukuyomiTheme(lightThemeConfig).themeData,
    darkTheme: TsukuyomiTheme(darkThemeConfig).themeData,
    // TODO 根据主题配置动态计算状态栏和导航栏图标的明暗度
    systemUiOverlayStyle: const SystemUiOverlayStyle(
      // 透明显示系统状态栏
      statusBarColor: Colors.transparent,
      // 透明显示系统导航栏
      systemNavigationBarColor: Colors.transparent,
    ),
  );
}

@freezed
class ThemeInfo with _$ThemeInfo {
  const factory ThemeInfo({
    required ThemeMode themeMode,
    required ThemeData lightTheme,
    required ThemeData darkTheme,
    required SystemUiOverlayStyle systemUiOverlayStyle,
  }) = _ThemeInfo;
}
