import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:shared_preferences_linux/shared_preferences_linux.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';
import 'package:tsukuyomi/constants/app.dart';

part 'preferences_provider.g.dart';

/// 本地偏好，未分文件时统一为键名添加环境后缀
class Preferences {
  Preferences(this._preferences, {String suffix = ''}) : _suffix = suffix;

  final SharedPreferencesWithCache _preferences;

  final String _suffix;

  Set<String> get keys => {
    for (final key in _preferences.keys) ...{
      if (key.endsWith(_suffix)) key.substring(0, key.length - _suffix.length),
    },
  };

  int? getInt(String key) => _preferences.getInt('$key$_suffix');

  String? getString(String key) => _preferences.getString('$key$_suffix');

  Future<void> setInt(String key, int value) => _preferences.setInt('$key$_suffix', value);

  Future<void> setString(String key, String value) => _preferences.setString('$key$_suffix', value);

  Future<void> remove(String key) => _preferences.remove('$key$_suffix');

  Future<void> clear() async {
    for (final key in keys) {
      await remove(key);
    }
  }
}

/// 可指定文件的平台分文件，其他平台按键名后缀隔离
Future<Preferences> loadSharedPreferences() async {
  final platform = kIsWeb ? null : defaultTargetPlatform;
  final options = switch (platform) {
    TargetPlatform.android => const SharedPreferencesAsyncAndroidOptions(
      backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
      originalSharedPreferencesOptions: AndroidSharedPreferencesStoreOptions(fileName: App.name),
    ),
    TargetPlatform.linux => const SharedPreferencesLinuxOptions(fileName: App.name),
    TargetPlatform.windows => const SharedPreferencesWindowsOptions(fileName: App.name),
    _ => null,
  };
  final preferences = await SharedPreferencesWithCache.create(
    sharedPreferencesOptions: options ?? const SharedPreferencesOptions(),
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
  return Preferences(preferences, suffix: options == null ? '.${App.name}' : '');
}

/// 本地键值对储存
@Riverpod(keepAlive: true)
Preferences sharedPreferences(SharedPreferencesRef ref) => throw UnimplementedError();
