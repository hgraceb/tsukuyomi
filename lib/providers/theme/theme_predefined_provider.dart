import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/core/core.dart';

part 'theme_predefined_provider.g.dart';

final _tsukuyomiTheme = TsukuyomiThemeConfig(
  name: 'Tsukuyomi',
  primary: const Color.fromARGB(255, 111, 111, 244),
  secondary: const Color.fromARGB(255, 244, 111, 177),
  background: const Color.fromARGB(255, 36, 38, 54),
  foreground: const Color.fromARGB(255, 244, 244, 244),
  card: const Color.fromARGB(255, 30, 32, 48),
  error: const Color.fromARGB(255, 244, 77, 77),
  border: const Color.fromARGB(255, 111, 122, 188),
  active: const Color.fromARGB(255, 244, 244, 244),
);

/// See <https://marketplace.visualstudio.com/items?itemName=atomiks.moonlight>.
final _moonlightTheme = TsukuyomiThemeConfig(
  name: 'Moonlight II',

  /// colors.progressBar.background
  primary: const Color(0xff82aaff),

  /// colors.button.background
  secondary: const Color(0xff3e68d7),

  /// colors.editor.background
  background: const Color(0xff222436),

  /// colors.foreground
  foreground: const Color(0xffc8d3f5),

  /// colors.sideBar.background
  card: const Color(0xff1e2030),

  /// colors.editorError.foreground
  error: const Color(0xffff5370),

  /// colors.focusBorder
  border: const Color(0xaa82aaff),

  /// colors.list.activeSelectionForeground
  active: const Color(0xffffffff),
);

/// See <https://marketplace.visualstudio.com/items?itemName=dracula-theme.theme-dracula>.
final _draculaTheme = TsukuyomiThemeConfig(
  name: 'Dracula',

  /// colors.statusBarItem.prominentBackground
  primary: const Color(0xffbd93f9),

  /// colors.progressBar.background
  secondary: const Color(0xffff79c6),

  /// colors.editor.background
  background: const Color(0xff282a36),

  /// colors.foreground
  foreground: const Color(0xfff8f8f2),

  /// colors.sideBar.background
  card: const Color(0xff21222c),

  /// colors.editorError.foreground
  error: const Color(0xffff5555),

  /// colors.focusBorder
  border: const Color(0xff6272a4),

  /// colors.list.activeSelectionForeground
  active: const Color(0xfff8f8f2),
);

/// See <https://marketplace.visualstudio.com/items?itemName=enkia.tokyo-night>.
final _tokyoNightTheme = TsukuyomiThemeConfig(
  name: 'Tokyo Night',

  /// colors.progressBar.background
  primary: const Color(0xff3d59a1),

  /// colors.button.background
  secondary: const Color(0xdd3d59a1),

  /// colors.editor.background
  background: const Color(0xff1a1b26),

  /// colors.foreground
  foreground: const Color(0xff787c99),

  /// colors.sideBar.background
  card: const Color(0xff16161e),

  /// colors.editorError.foreground
  error: const Color(0xffdb4b4b),

  /// colors.focusBorder
  border: const Color(0x33545c7e),

  /// colors.list.activeSelectionForeground
  active: const Color(0xffa9b1d6),
);

/// See <https://marketplace.visualstudio.com/items?itemName=GitHub.github-vscode-theme>.
final _githubLightDefaultTheme = TsukuyomiThemeConfig(
  name: 'GitHub Light Default',

  /// colors.progressBar.background
  primary: const Color(0xff0969da),

  /// colors.terminal.ansiBrightBlue
  secondary: const Color(0xff218bff),

  /// colors.sideBar.background
  background: const Color(0xfff6f8fa),

  /// colors.foreground
  foreground: const Color(0xff24292f),

  /// colors.editor.background
  card: const Color(0xffffffff),

  /// colors.errorForeground
  error: const Color(0xffcf222e),

  /// colors.sideBar.border
  border: const Color(0xffd0d7de),

  /// colors.editor.background
  active: const Color(0xffffffff),
);

/// 预设主题
@Riverpod(keepAlive: true)
List<TsukuyomiThemeConfig> themePredefined(ThemePredefinedRef ref) {
  return [
    _tsukuyomiTheme,
    _moonlightTheme,
    _draculaTheme,
    _tokyoNightTheme,
    _githubLightDefaultTheme,
  ];
}
