import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/providers/providers.dart';
import 'package:tsukuyomi_metadata/tsukuyomi_metadata.dart';

Future<void> main() async {
  // 引擎组件初始化
  WidgetsFlutterBinding.ensureInitialized();
  // 本地键值对储存
  final sharedPreferences = await SharedPreferences.getInstance();
  // 设备状态栏高度
  final statusBarHeight = await TsukuyomiMetadata().getStatusBarHeight() ?? 0;
  // 全局的状态管理
  runApp(ProviderScope(
    overrides: [
      statusBarHeightProvider.overrideWithValue(statusBarHeight),
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
    child: const TsukuyomiApp(),
  ));
}

class TsukuyomiApp extends ConsumerWidget {
  const TsukuyomiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final routerConfig = ref.watch(routerConfigProvider);

    return MaterialApp.router(
      title: App.name,

      // 主题配置
      theme: themeData.lightTheme,
      darkTheme: themeData.darkTheme,
      themeMode: themeData.themeMode,

      // 路由配置
      routerConfig: routerConfig,

      // 滚动配置
      scrollBehavior: ref.watch(scrollBehaviorProvider),

      // 本地化配置
      supportedLocales: TsukuyomiLocalizations.supportedLocales,
      localizationsDelegates: TsukuyomiLocalizations.localizationsDelegates,

      // 构建器配置
      builder: (context, child) => AnnotatedRegion(
        value: themeData.systemUiOverlayStyle,
        child: GestureDetector(
          onTap: FocusScope.of(context).unfocus,
          child: TsukuyomiMediaQuery(
            child: child,
          ),
        ),
      ),
    );
  }
}
