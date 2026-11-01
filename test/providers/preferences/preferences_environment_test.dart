import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';
import 'package:tsukuyomi/providers/theme/theme_preferences_provider.dart';
import 'package:tsukuyomi/providers/update/update_report_store.dart';

import '../../fixtures/update_fixtures.dart';

Future<SharedPreferences> _open(String prefix) {
  SharedPreferences.resetStatic();
  SharedPreferences.setPrefix(prefix);
  return SharedPreferences.getInstance();
}

ProviderContainer _container(SharedPreferences preferences) {
  final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(preferences)]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(SharedPreferences.resetStatic);

  test('Debug starts separately while Release keeps existing theme, report and source storage', () async {
    final releaseReport = updateReportFixture().copyWith(sessionId: 'release');
    SharedPreferences.setMockInitialValues({
      'themeMode': 2,
      UpdateReportStore.reportKey: jsonEncode(releaseReport.toJson()),
      'source.1': '{"token":"release"}',
    });
    final debug = await _open(App.preferencesPrefix);
    final debugContainer = _container(debug);
    expect(debugContainer.read(themePreferenceProvider).themeMode, ThemeMode.system);
    expect(debugContainer.read(updateReportStoreProvider), isNull);
    expect(debug.getString('source.1'), isNull);

    await debug.setInt('themeMode', 1);
    final debugReport = releaseReport.copyWith(sessionId: 'debug');
    await debugContainer.read(updateReportStoreProvider.notifier).save(debugReport);
    await debug.setString('source.1', '{"token":"debug"}');

    final release = await _open('flutter.');
    final releaseContainer = _container(release);
    expect(releaseContainer.read(themePreferenceProvider).themeMode, ThemeMode.dark);
    expect(releaseContainer.read(updateReportStoreProvider), releaseReport);
    expect(release.getString('source.1'), '{"token":"release"}');
    await release.setInt('themeMode', 0);

    final restartedDebug = await _open(App.preferencesPrefix);
    final restartedContainer = _container(restartedDebug);
    expect(restartedContainer.read(themePreferenceProvider).themeMode, ThemeMode.light);
    expect(restartedContainer.read(updateReportStoreProvider), debugReport);
    expect(restartedDebug.getString('source.1'), '{"token":"debug"}');
  });

  test('Removing or clearing preferences only affects the current environment', () async {
    final release = await _open('flutter.');
    await release.setInt('themeMode', 2);
    await release.setString('source.1', 'release');
    final debug = await _open(App.preferencesPrefix);
    await debug.setInt('themeMode', 1);
    await debug.setString('source.1', 'debug');
    await debug.remove('source.1');

    final restoredRelease = await _open('flutter.');
    expect(restoredRelease.getString('source.1'), 'release');
    await restoredRelease.clear();

    final restoredDebug = await _open(App.preferencesPrefix);
    expect(restoredDebug.getInt('themeMode'), 1);
    expect(restoredDebug.getString('source.1'), isNull);
    await restoredDebug.setString('source.1', 'debug');

    final clearedRelease = await _open('flutter.');
    expect(clearedRelease.getKeys(), isEmpty);
    await clearedRelease.setInt('themeMode', 2);
    final debugToClear = await _open(App.preferencesPrefix);
    await debugToClear.clear();
    final retainedRelease = await _open('flutter.');
    expect(retainedRelease.getInt('themeMode'), 2);
  });
}
