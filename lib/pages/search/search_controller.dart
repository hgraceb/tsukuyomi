import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/extension/extension.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/providers/providers.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

part 'search_controller.freezed.dart';
part 'search_controller.g.dart';

/// 搜索页面控制器
@riverpod
class SearchController extends _$SearchController with AsyncNotifierMixin {
  @override
  Future<SearchState> build() async {
    final keyboardVisible = listenSync(
      provider: keyboardVisibleProvider,
      update: (state, data) => state.copyWith(keyboardVisible: data),
    );
    final sources = await listenAsync(
      provider: sourcesStreamProvider,
      update: (state, data) => state.copyWith(sources: data),
    );
    return SearchState(
      sources: sources,
      cachedSources: {},
      loadings: {},
      errors: {},
      results: {},
      keyboardVisible: keyboardVisible,
      focusNode: _createFocusNode(),
      textController: _createTextEditingController(),
      editingText: '',
      searchingText: '',
    );
  }

  /// 创建搜索框焦点控制器
  FocusNode _createFocusNode() {
    final focusNode = FocusNode();
    ref.onDispose(() => focusNode.dispose());
    return focusNode;
  }

  /// 创建搜索框文本控制器
  TextEditingController _createTextEditingController() {
    final controller = TextEditingController();
    ref.onDispose(() => controller.dispose());
    return controller;
  }

  /// 搜索指定的漫画源
  Future<void> _search(List<DatabaseSource>? sources, String? keyword) async {
    if (sources == null || sources.isEmpty) return;
    if (keyword == null || keyword.isEmpty) return;
    final ids = sources.map((source) => source.id).toSet();
    await update((state) => state.copyWith(loadings: ids, errors: {}, results: {}, searchingText: keyword));
    for (final id in ids) {
      try {
        final cachedSource = data?.cachedSources[id];
        final Source source = cachedSource ?? await ref.read(sourceByIdProvider(id).future);
        if (cachedSource != source) await update((state) => state.copyWith(cachedSources: state.addCachedSource(id, source)));
        final page = await ref.read(searchMangasProvider(source, HttpSourceQuery(keyword: keyword)).future);
        await update((state) => state.copyWith(loadings: state.removeLoading(id), results: state.addResult(id, page)));
      } catch (e) {
        await update((state) => state.copyWith(loadings: state.removeLoading(id), errors: state.addError(id, e.toString())));
      }
    }
    await update((state) => state.copyWith(searchingText: ''));
  }

  /// 搜索所有的漫画源
  Future<void> onSearch() async {
    if (data?.searchable != true) return;
    try {
      // 判断是否需要通过释放焦点的方式隐藏软键盘
      if (data?.keyboardVisible == true) data?.focusNode.unfocus();
      await _search(data?.sources, data?.textController.text.trim());
    } catch (error, stackTrace) {
      handlerError(error, stackTrace);
    }
  }

  /// 搜索下一页的数据
  Future<void> onNext(Source? source, SourcePage<SourceManga>? page) async {
    if (source == null || page == null || page.next != true) return;
    if (data?.loadings.contains(source.id) == true) return;
    final id = source.id;
    try {
      await update((state) => state.copyWith(loadings: state.addLoading(id)));
      final result = await ref.read(searchMangasProvider(source, page.nextQuery).future);
      await update((state) => state.copyWith(results: state.addResult(id, result.prepend(page))));
    } catch (error, stackTrace) {
      handlerError(error, stackTrace);
    } finally {
      await update((state) => state.copyWith(loadings: state.removeLoading(id)));
    }
  }

  /// 处理文本更新事件
  Future<void> onTextChanged(String text) async {
    try {
      await update((state) => state.copyWith(editingText: text.trim()));
    } catch (error, stackTrace) {
      handlerError(error, stackTrace);
    }
  }

  /// 跳转到漫画详情页
  Future<void> pushMangaPage(BuildContext context, DatabaseSource source, SourceManga manga) async {
    try {
      final id = await ref.read(mangaServiceProvider).insertSourceManga(source.id, manga);
      if (context.mounted) await context.pushNamed(TsukuyomiRouter.manga.name, params: {'mangaId': '$id'});
    } catch (error, stackTrace) {
      handlerError(error, stackTrace);
    }
  }
}

/// 搜索页面配置
@freezed
class SearchState with _$SearchState {
  const factory SearchState({
    /// 所有可用的漫画源
    required List<DatabaseSource> sources,

    /// 当前缓存的漫画源
    required Map<int, Source> cachedSources,

    /// 正在搜索的漫画源
    required Set<int> loadings,

    /// 搜索出错的漫画源
    required Map<int, String> errors,

    /// 搜索完成的漫画源
    required Map<int, SourcePage<SourceManga>> results,

    /// 键盘是否正在显示
    required bool keyboardVisible,

    /// 搜索框焦点控制器
    required FocusNode focusNode,

    /// 搜索框文本控制器
    required TextEditingController textController,

    /// 当前搜索框的文本
    required String editingText,

    /// 正在搜索中的文本
    required String searchingText,
  }) = _SearchState;
}

/// 搜索页面扩展方法
extension on SearchState {
  Map<int, Source> addCachedSource(int id, Source source) => {...cachedSources}..addAll({id: source});

  Set<int> addLoading(int sourceId) => {...loadings}..add(sourceId);

  Set<int> removeLoading(int sourceId) => {...loadings}..remove(sourceId);

  Map<int, String> addError(int sourceId, String error) => {...errors}..addAll({sourceId: error});

  Map<int, SourcePage<SourceManga>> addResult(int sourceId, SourcePage<SourceManga> page) => {...results}..addAll({sourceId: page});
}

/// 搜索页面扩展配置
extension SearchStateExtension on SearchState {
  bool get searchable => editingText != searchingText && editingText.isNotEmpty && searchingText.isEmpty;
}
