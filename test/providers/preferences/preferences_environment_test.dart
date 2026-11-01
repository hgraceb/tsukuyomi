import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/providers/theme/theme_preferences_provider.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';

import '../../fixtures/update_fixtures.dart';

ProviderContainer _container(SharedPreferencesWithCache preferences) {
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Startup loads theme, report and source storage into the synchronous cache', () async {
    final report = updateReportFixture();
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({
      'themeMode': 2,
      UpdateReportStore.reportKey: jsonEncode(report.toJson()),
      'source.1': '{"value":"stored"}',
    });
    final preferences = await loadSharedPreferences();
    final container = _container(preferences);
    expect(container.read(themePreferenceProvider).themeMode, ThemeMode.dark);
    expect(container.read(updateReportStoreProvider), report);
    expect(preferences.getString('source.1'), '{"value":"stored"}');
  });

  test('Awaited writes survive a new cache and removal remains persistent', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final preferences = await loadSharedPreferences();
    await preferences.setInt('themeMode', 1);
    await preferences.setString('source.1', 'stored');
    final restored = await loadSharedPreferences();
    expect(restored.getInt('themeMode'), 1);
    expect(restored.getString('source.1'), 'stored');
    await restored.remove('source.1');
    final removed = await loadSharedPreferences();
    expect(removed.getString('source.1'), isNull);
    expect(removed.getInt('themeMode'), 1);
    await removed.clear();
    expect((await loadSharedPreferences()).keys, isEmpty);
  });
}
