import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:tsukuyomi/pages/pages.dart';

export 'package:go_router/go_router.dart';

/// 路由页面信息
class TsukuyomiRouter {
  const TsukuyomiRouter._(this.name, this._path, this._builder);

  final String name;

  final String _path;

  final Widget Function(Map<String, String> params) _builder;

  static final home = TsukuyomiRouter._('home', '/', (params) => const HomePage());
  static final search = TsukuyomiRouter._('search', 'search', (params) => const SearchPage());
  static final manga = TsukuyomiRouter._('manga', 'manga/:mangaId', (params) => MangaPage(mangaId: params['mangaId']!));
  static final chapter = TsukuyomiRouter._('chapter', 'chapter/:chapterId', (params) => ChapterPage(chapterId: params['chapterId']!));
  static final appearance = TsukuyomiRouter._('appearance', 'appearance', (params) => const AppearancePage());

  static final debug = TsukuyomiRouter._('debug', 'debug', (params) => const DebugPage());
  static final debugList = TsukuyomiRouter._('debugList', 'list', (params) => const DebugListPage());
  static final debugScaffold = TsukuyomiRouter._('debugScaffold', 'scaffold', (params) => const DebugScaffoldPage());
  static final debugInterpreter = TsukuyomiRouter._('debugInterpreter', 'interpreter', (params) => const DebugInterpreterPage());

  static final themePreview = TsukuyomiRouter._('themePreview', 'themePreview', (params) => const ThemePreviewPage());
}

/// 路由页面配置
class TsukuyomiRouterConfig extends GoRouter {
  TsukuyomiRouterConfig({super.initialLocation, super.navigatorKey}) : super(routes: routers);

  static final List<RouteBase> routers = [
    buildRoute(TsukuyomiRouter.home, routes: [
      buildRoute(TsukuyomiRouter.search),
      buildRoute(TsukuyomiRouter.manga, routes: [
        buildRoute(TsukuyomiRouter.chapter),
      ]),
      buildRoute(TsukuyomiRouter.appearance),
      buildRoute(TsukuyomiRouter.themePreview),
      buildRoute(TsukuyomiRouter.debug, routes: [
        buildRoute(TsukuyomiRouter.debugList),
        buildRoute(TsukuyomiRouter.debugScaffold),
        buildRoute(TsukuyomiRouter.debugInterpreter),
      ]),
    ]),
  ];
}

/// 构建路由页面
RouteBase buildRoute(TsukuyomiRouter router, {List<RouteBase> routes = const <RouteBase>[]}) {
  return GoRoute(
    name: router.name,
    path: router._path,
    routes: routes,
    pageBuilder: (context, state) => CupertinoPage(
      key: state.pageKey,
      name: state.name ?? state.path,
      arguments: <String, String>{...state.params, ...state.queryParams},
      restorationId: state.pageKey.value,
      child: router._builder(state.params),
    ),
  );
}
