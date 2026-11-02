import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tsukuyomi/providers/preferences/preferences_provider.dart';

Future<Preferences> preferencesFixture([Map<String, Object> values = const {}]) async {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData(values);
  final preferences = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
  return Preferences(preferences);
}
