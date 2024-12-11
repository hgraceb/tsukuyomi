import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/providers/providers.dart';

part 'theme_preferences_provider.freezed.dart';

part 'theme_preferences_provider.g.dart';

/// 主题配置
@Riverpod(keepAlive: true)
class ThemePreference extends _$ThemePreference {
  late SharedPreferences _sharedPreferences;

  @override
  ThemePreferences build() {
    _sharedPreferences = ref.watch(sharedPreferencesProvider);
    return ThemePreferences(themeMode: _getThemeMode());
  }

  /// 获取主题模式
  ThemeMode _getThemeMode() {
    return switch (_sharedPreferences.getInt('themeMode')) {
      0 => ThemeMode.system,
      1 => ThemeMode.light,
      2 => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// 设置主题模式
  void setThemeMode(ThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
    switch (themeMode) {
      case ThemeMode.system:
        _sharedPreferences.setInt('themeMode', 0);
      case ThemeMode.light:
        _sharedPreferences.setInt('themeMode', 1);
      case ThemeMode.dark:
        _sharedPreferences.setInt('themeMode', 2);
    }
  }
}

@freezed
class ThemePreferences with _$ThemePreferences {
  const factory ThemePreferences({
    required ThemeMode themeMode,
  }) = _ThemeSettings;
}
