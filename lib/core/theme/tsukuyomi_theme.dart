import 'package:flutter/material.dart';
import 'package:tsukuyomi/core/core.dart';

/// 主题配置
class TsukuyomiTheme {
  TsukuyomiTheme(TsukuyomiThemeConfig themeConfig) {
    final colorScheme = themeConfig.colorScheme;
    const buttonStyle = ButtonStyle(
      textStyle: MaterialStatePropertyAll(
        TextStyle(
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    themeData = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      cardColor: themeConfig.card,
      cardTheme: CardThemeData(
        elevation: 0,
        color: themeConfig.card,
        clipBehavior: Clip.none,
        margin: const EdgeInsets.all(4.0),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.outlineVariant),
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: colorScheme.primary.withOpacity(0.24), // [_SliderDefaultsM2.inactiveTrackColor]
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0), // [_LisTileDefaultsM2.contentPadding]
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: buttonStyle,
      ),
      elevatedButtonTheme: const ElevatedButtonThemeData(
        style: buttonStyle,
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: buttonStyle,
      ),
      segmentedButtonTheme: const SegmentedButtonThemeData(
        style: buttonStyle,
      ),
    );
  }

  /// 主题数据
  late final ThemeData themeData;
}
