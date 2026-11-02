import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/providers/theme/theme_preferences_provider.dart';

ProviderContainer _container(SharedPreferences preferences) {
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'theme.mode': 1, 'debug.theme.mode': 2});
  });

  test('Debug restores its own theme instead of the Release theme', () async {
    final preferences = await SharedPreferences.getInstance();
    expect(_container(preferences).read(themePreferenceProvider).themeMode, ThemeMode.dark);
  });

  test('Theme modes persist under the Debug key and preserve the Release theme', () async {
    final preferences = await SharedPreferences.getInstance();
    final container = _container(preferences);
    for (final mode in ThemeMode.values) {
      container.read(themePreferenceProvider.notifier).setThemeMode(mode);
      expect(container.read(themePreferenceProvider).themeMode, mode);
      await preferences.reload();
      expect(_container(preferences).read(themePreferenceProvider).themeMode, mode);
      expect(preferences.getInt('theme.mode'), 1);
    }
  });
}
