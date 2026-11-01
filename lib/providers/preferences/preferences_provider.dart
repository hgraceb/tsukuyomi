import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:shared_preferences_linux/shared_preferences_linux.dart';
import 'package:shared_preferences_windows/shared_preferences_windows.dart';
import 'package:tsukuyomi/constants/constants.dart';

part 'preferences_provider.g.dart';

/// 加载偏好缓存，支持的平台按应用名称分文件
Future<SharedPreferencesWithCache> loadSharedPreferences() {
  final platform = kIsWeb ? null : defaultTargetPlatform;
  final options = switch (platform) {
    TargetPlatform.android => const SharedPreferencesAsyncAndroidOptions(
      backend: SharedPreferencesAndroidBackendLibrary.SharedPreferences,
      originalSharedPreferencesOptions: AndroidSharedPreferencesStoreOptions(fileName: App.name),
    ),
    TargetPlatform.linux => const SharedPreferencesLinuxOptions(fileName: App.name),
    TargetPlatform.windows => const SharedPreferencesWindowsOptions(fileName: App.name),
    _ => const SharedPreferencesOptions(),
  };
  return SharedPreferencesWithCache.create(
    sharedPreferencesOptions: options,
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
}

/// 本地键值对储存
@Riverpod(keepAlive: true)
SharedPreferencesWithCache sharedPreferences(SharedPreferencesRef ref) => throw UnimplementedError();
