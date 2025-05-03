import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/core/router/tsukuyomi_router.dart';

part 'router_provider.g.dart';

/// 路由索引
@Riverpod(keepAlive: true)
GlobalKey<NavigatorState> routerNavigatorKey(RouterNavigatorKeyRef ref) {
  return GlobalKey<NavigatorState>();
}

/// 路由配置
@Riverpod(keepAlive: true)
RouterConfig<Object> routerConfig(RouterConfigRef ref) {
  const initialLocation = '/debug/list'; // TODO 删除测试代码
  final navigatorKey = ref.watch(routerNavigatorKeyProvider);
  return TsukuyomiRouterConfig(initialLocation: initialLocation, navigatorKey: navigatorKey);
}
