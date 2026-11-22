import 'package:flutter/cupertino.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/extension/extension.dart';
import 'package:tsukuyomi/pages/manga/manga_service.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/providers/providers.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

part 'search_controller.freezed.dart';
part 'search_controller.g.dart';

/// 搜索页面控制器
@riverpod
class SearchController extends _$SearchController with AsyncNotifierMixin {
  int _searchId = 0;
  SourceQuery? _firstPageQuery;

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
      searchId: 0,
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

  /// 判断搜索请求是否已过期
  bool _isStaleSearch(int searchId) {
    return !mounted || searchId != _searchId || searchId != data?.searchId;
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

  /// 请求单个漫画源第一页
  Future<void> _searchFirstPage(int searchId, int sourceId, SourceQuery query, {bool retry = false}) async {
    try {
      final cachedSource = data?.cachedSources[sourceId];
      if (retry && cachedSource == null) ref.invalidate(sourceByIdProvider(sourceId));
      final Source source = cachedSource ?? await ref.read(sourceByIdProvider(sourceId).future);
      if (_isStaleSearch(searchId)) return;
      if (cachedSource != source) state = state.whenData((state) => state.copyWith(cachedSources: state.addCachedSource(sourceId, source)));
      final provider = searchMangasProvider(searchId, source, query);
      final page = retry ? await ref.refresh(provider.future) : await ref.read(provider.future);
      if (_isStaleSearch(searchId)) return;
      state = state.whenData((state) => state.copyWith(loadings: state.removeLoading(sourceId), results: state.addResult(sourceId, page)));
    } catch (e) {
      if (_isStaleSearch(searchId)) return;
      state = state.whenData((state) => state.copyWith(loadings: state.removeLoading(sourceId), errors: state.addError(sourceId, e)));
    }
  }

  /// 请求搜索指定的漫画源
  Future<void> _search(List<DatabaseSource>? sources, String? keyword) async {
    if (sources == null || sources.isEmpty) return;
    if (keyword == null || keyword.isEmpty) return;
    final searchId = ++_searchId;
    final query = _firstPageQuery = HttpSourceQuery(keyword: keyword);
    final ids = sources.map((source) => source.id).toSet();
    state = state.whenData((state) => state.copyWith(searchId: searchId, loadings: ids, errors: {}, results: {}, searchingText: keyword));
    for (final sourceId in ids) {
      await _searchFirstPage(searchId, sourceId, query);
      if (_isStaleSearch(searchId)) return;
    }
    state = state.whenData((state) => state.copyWith(searchingText: ''));
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

  /// 重试单个漫画源第一页
  Future<void> onRetryFirstPage(int sourceId) async {
    final current = data;
    final query = _firstPageQuery;
    if (current == null || query == null || _isStaleSearch(current.searchId)) return;
    if (!current.errors.containsKey(sourceId) || current.results.containsKey(sourceId)) return;
    state = state.whenData((state) => state.copyWith(loadings: state.addLoading(sourceId), errors: state.removeError(sourceId)));
    await _searchFirstPage(current.searchId, sourceId, query, retry: true);
  }

  /// 搜索下一页的数据
  Future<void> onNext(Source? source, SourceMangaEntries? page, {bool retry = false}) async {
    final current = data;
    final id = source?.id;
    if (source == null || page == null || page.nextQuery == null) return;
    if (current == null || id == null || _isStaleSearch(current.searchId)) return;
    if (current.loadings.contains(id) || current.results[id] != page || current.errors.containsKey(id) != retry) return;
    try {
      state = state.whenData((state) => state.copyWith(loadings: state.addLoading(id), errors: state.removeError(id)));
      final provider = searchMangasProvider(current.searchId, source, page.nextQuery!);
      final result = retry ? await ref.refresh(provider.future) : await ref.read(provider.future);
      if (_isStaleSearch(current.searchId)) return;
      final entries = result.prepend(page);
      state = state.whenData((state) => state.copyWith(loadings: state.removeLoading(id), results: state.addResult(id, entries)));
    } catch (error, stackTrace) {
      if (_isStaleSearch(current.searchId)) return;
      state = state.whenData((state) => state.copyWith(loadings: state.removeLoading(id), errors: state.addError(id, error)));
      handlerError(error, stackTrace);
    }
  }

  /// 处理文本更新事件
  Future<void> onTextChanged(String text) async {
    try {
      state = state.whenData((state) => state.copyWith(editingText: text.trim()));
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

    /// 当前搜索轮次编号
    required int searchId,

    /// 正在搜索的漫画源
    required Set<int> loadings,

    /// 搜索出错的漫画源
    required Map<int, String> errors,

    /// 搜索完成的漫画源
    required Map<int, SourceMangaEntries> results,

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

  Map<int, String> addError(int sourceId, Object error) => {...errors}..addAll({sourceId: error.toString()});

  Map<int, String> removeError(int sourceId) => {...errors}..remove(sourceId);

  Map<int, SourceMangaEntries> addResult(int sourceId, SourceMangaEntries page) => {...results}..addAll({sourceId: page});
}

/// 搜索页面扩展配置
extension SearchStateExtension on SearchState {
  bool get searchable => editingText != searchingText && editingText.isNotEmpty && searchingText.isEmpty;
}
