import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:shared_preferences_linux/shared_preferences_linux.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/providers/theme/theme_preferences_provider.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';

import '../../fixtures/update_fixtures.dart';

ProviderContainer _container(Preferences preferences) {
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

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

  for (final platform in [TargetPlatform.android, TargetPlatform.linux, TargetPlatform.windows]) {
    test('$platform selects a separate preference file using App.name', () async {
      debugDefaultTargetPlatformOverride = platform;
      final backend = _Platform();
      SharedPreferencesAsyncPlatform.instance = backend;
      final preferences = await loadSharedPreferences();
      await preferences.setInt('themeMode', 1);
      switch (backend.options) {
        case SharedPreferencesAsyncAndroidOptions options:
          expect(platform, TargetPlatform.android);
          expect(options.backend, SharedPreferencesAndroidBackendLibrary.SharedPreferences);
          expect(options.originalSharedPreferencesOptions?.fileName, App.name);
        case SharedPreferencesLinuxOptions options:
          expect(platform, TargetPlatform.linux);
          expect(options.fileName, App.name);
        case SharedPreferencesWindowsOptions options:
          expect(platform, TargetPlatform.windows);
          expect(options.fileName, App.name);
        default:
          fail('Missing named preference file for $platform');
      }
      expect(await SharedPreferencesAsync().getInt('themeMode'), 1);
    });
  }

  for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
    test('$platform restores only the current environment from shared storage', () async {
      debugDefaultTargetPlatformOverride = platform;
      final report = updateReportFixture();
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({
        'themeMode': 1,
        'themeMode.Tsukuyomi': 1,
        'themeMode.${App.name}': 2,
        '${UpdateReportStore.reportKey}.${App.name}': jsonEncode(report.toJson()),
        'source.1.${App.name}': '{"value":"debug"}',
        'source.1.Tsukuyomi': '{"value":"release"}',
      });
      final preferences = await loadSharedPreferences();
      final container = _container(preferences);
      expect(container.read(themePreferenceProvider).themeMode, ThemeMode.dark);
      expect(container.read(updateReportStoreProvider), report);
      expect(preferences.getString('source.1'), '{"value":"debug"}');
      expect(preferences.keys, {'themeMode', UpdateReportStore.reportKey, 'source.1'});

      await preferences.setInt('themeMode', 0);
      await preferences.setString('source.1', 'updated');
      final restored = await loadSharedPreferences();
      expect(restored.getInt('themeMode'), 0);
      expect(restored.getString('source.1'), 'updated');
      await restored.clear();
      expect((await loadSharedPreferences()).keys, isEmpty);
      final raw = await SharedPreferencesAsync().getAll();
      expect(raw, {'themeMode': 1, 'themeMode.Tsukuyomi': 1, 'source.1.Tsukuyomi': '{"value":"release"}'});
    });
  }

  test('Environment suffixes isolate writes, removal and clearing in both directions', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({'unrelated': 'keep'});
    Future<Preferences> load(String name) async {
      final cache = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
      return Preferences(cache, suffix: '.$name');
    }

    final debug = await load('TsukuyomiDebug');
    final release = await load('Tsukuyomi');
    await debug.setInt('themeMode', 1);
    await release.setInt('themeMode', 2);
    await debug.setString(UpdateReportStore.reportKey, 'debug-report');
    await release.setString(UpdateReportStore.reportKey, 'release-report');
    await debug.setString('source.1', 'debug-source');
    await release.setString('source.1', 'release-source');

    final restoredDebug = await load('TsukuyomiDebug');
    final restoredRelease = await load('Tsukuyomi');
    expect(restoredDebug.getInt('themeMode'), 1);
    expect(restoredRelease.getInt('themeMode'), 2);
    expect(restoredDebug.getString(UpdateReportStore.reportKey), 'debug-report');
    expect(restoredRelease.getString(UpdateReportStore.reportKey), 'release-report');
    expect(restoredDebug.getString('source.1'), 'debug-source');
    expect(restoredRelease.getString('source.1'), 'release-source');

    await restoredDebug.remove('source.1');
    expect((await load('TsukuyomiDebug')).getString('source.1'), isNull);
    expect((await load('Tsukuyomi')).getString('source.1'), 'release-source');
    await restoredDebug.clear();
    expect((await load('TsukuyomiDebug')).keys, isEmpty);
    expect((await load('Tsukuyomi')).getString(UpdateReportStore.reportKey), 'release-report');

    await restoredDebug.setString('source.1', 'new-debug-source');
    await restoredRelease.remove('themeMode');
    await restoredRelease.clear();
    expect((await load('Tsukuyomi')).keys, isEmpty);
    expect((await load('TsukuyomiDebug')).getString('source.1'), 'new-debug-source');
    expect(await SharedPreferencesAsync().getAll(), {'unrelated': 'keep', 'source.1.TsukuyomiDebug': 'new-debug-source'});
  });
}

base class _Platform extends InMemorySharedPreferencesAsync {
  _Platform() : super.empty();

  SharedPreferencesOptions? options;

  @override
  Future<Map<String, Object>> getPreferences(GetPreferencesParameters parameters, SharedPreferencesOptions options) {
    this.options = options;
    return super.getPreferences(parameters, options);
  }
}
