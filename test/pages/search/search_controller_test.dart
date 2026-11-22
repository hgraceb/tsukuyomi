import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/database/database.dart' show DatabaseSource;
import 'package:tsukuyomi/pages/search/search_controller.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/providers/error/error_handler_provider.dart';
import 'package:tsukuyomi/providers/platform/platform_metadata_provider.dart';
import 'package:tsukuyomi/source/source.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const installed = DatabaseSource(id: 1, name: 'Example', source: '');
  late _SearchSource source;
  late _Errors errors;
  late SearchController controller;
  late ProviderSubscription<AsyncValue<SearchState>> subscription;

  SearchState current() => subscription.read().requireValue;

  Future<ProviderContainer> loadSources([_SearchSource? other]) async {
    source = _SearchSource(installed.id);
    errors = _Errors();
    final sources = [installed, if (other != null) installed.copyWith(id: other.id)];
    final container = ProviderContainer(
      overrides: [
        errorHandlerProvider.overrideWithValue(errors),
        keyboardVisibleProvider.overrideWithValue(false),
        sourcesStreamProvider.overrideWith((ref) => Stream.value(sources)),
        sourceByIdProvider(installed.id).overrideWith((ref) async => source),
        if (other != null) sourceByIdProvider(other.id).overrideWith((ref) async => other),
      ],
    );
    addTearDown(container.dispose);
    subscription = container.listen(searchControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(searchControllerProvider.future);
    controller = container.read(searchControllerProvider.notifier);
    return container;
  }

  Future<void> edit(String keyword) {
    current().textController.text = keyword;
    return controller.onTextChanged(keyword);
  }

  Future<void> search(String keyword) async {
    await edit(keyword);
    await controller.onSearch();
  }

  test('Search follows the source continuation and appends results until the last page', () async {
    await loadSources();
    await search('example');
    final first = current().results[installed.id]!;
    expect(first.mangas.map((manga) => manga.url), ['1']);
    expect(first.nextQuery, same(source.continuation));

    await controller.onNext(source, first);
    final last = current().results[installed.id]!;
    expect(source.requests.last, same(source.continuation));
    expect(last.mangas.map((manga) => manga.url), ['1', '7']);
    expect(last.nextQuery, isNull);

    await controller.onNext(source, last);
    expect(source.requests.map((query) => query.page), [1, 7]);
  });

  test('Editing immediately after submitting keeps the submitted search pageable', () async {
    await loadSources();
    await edit('example');
    await Future.wait([controller.onSearch(), edit('draft')]);

    await controller.onNext(source, current().results[installed.id]);
    expect(source.requests.first.keyword, 'example');
    expect(current().editingText, 'draft');
    expect(current().results[installed.id]!.mangas.map((manga) => manga.url), ['1', '7']);
  });

  test('Submitting immediately after editing searches and paginates the latest text', () async {
    await loadSources();
    await edit('draft');
    await Future.wait([edit('example'), controller.onSearch()]);

    await controller.onNext(source, current().results[installed.id]);
    expect(source.requests.first.keyword, 'example');
    expect(current().editingText, 'example');
    expect(current().results[installed.id]!.mangas.map((manga) => manga.url), ['1', '7']);
  });

  test('Starting pagination preserves another source finishing its first page', () async {
    final other = _SearchSource(2);
    await loadSources(other);
    final firstPage = Completer<void>();
    other.pendingFirstPage = firstPage.future;
    final searching = search('example');
    await pumpEventQueue(times: 1);

    final first = current().results[installed.id]!;
    firstPage.complete();
    final paging = Future.microtask(() => controller.onNext(source, first));
    await Future.wait([searching, paging]);
    expect(current().results[installed.id]!.mangas.map((manga) => manga.url), ['1', '7']);
    expect(current().results[other.id]?.mangas.map((manga) => manga.url), ['1']);
    expect(current().loadings, isEmpty);
    expect(current().searchingText, isEmpty);
  });

  for (final fails in [false, true]) {
    test('Pagination keeps its results when another source ${fails ? 'fails' : 'finishes'} loading its first page', () async {
      final other = _SearchSource(2);
      await loadSources(other);
      final firstPage = Completer<void>();
      other.pendingFirstPage = firstPage.future;
      final searching = search('example');
      await pumpEventQueue(times: 1);

      final nextPage = Completer<void>();
      source.pendingPage = nextPage.future;
      final paging = controller.onNext(source, current().results[installed.id]!);
      await pumpEventQueue(times: 1);
      expect(current().loadings, {source.id, other.id});

      final error = StateError('first page');
      if (fails) {
        firstPage.completeError(error);
      } else {
        firstPage.complete();
      }
      nextPage.complete();
      await Future.wait([searching, paging]);
      expect(current().results[installed.id]!.mangas.map((manga) => manga.url), ['1', '7']);
      expect(current().loadings, isEmpty);
      if (fails) {
        expect(current().errors[other.id], error.toString());
      } else {
        expect(current().results[other.id]!.mangas.map((manga) => manga.url), ['1']);
      }
    });
  }

  for (final fails in [false, true]) {
    test('Repeating a search ignores the previous pagination ${fails ? 'error' : 'result'}', () async {
      final container = await loadSources();
      await search('example');
      final oldPage = Completer<void>();
      source.pendingPage = oldPage.future;
      final oldPagination = controller.onNext(source, current().results[installed.id]);
      // 保留旧分页请求，验证新一轮搜索会独立请求同一页
      final oldProvider = searchMangasProvider(current().searchId, source, source.continuation);
      addTearDown(container.listen(oldProvider, (_, _) {}).close);
      await pumpEventQueue(times: 1);

      await search('example');
      final first = current().results[installed.id]!;
      final newPage = Completer<void>();
      source.pendingPage = newPage.future;
      final newPagination = controller.onNext(source, first);
      await pumpEventQueue(times: 1);
      expect(source.requests.map((query) => query.page), [1, 7, 1, 7]);

      if (fails) {
        oldPage.completeError(StateError('old page'));
      } else {
        oldPage.complete();
      }
      await oldPagination;
      expect(current().results[installed.id], same(first));
      expect(current().loadings, contains(installed.id));
      expect(errors.shown, isEmpty);

      newPage.complete();
      await newPagination;
      expect(current().results[installed.id]!.mangas.map((manga) => manga.url), ['1', '7']);
      expect(current().loadings, isEmpty);
    });
  }
}

class _SearchSource extends NoInstalledSource {
  _SearchSource(super.id);

  final continuation = HttpSourceQuery(page: 7, keyword: 'example');
  final requests = <SourceQuery>[];
  Future<void>? pendingFirstPage;
  Future<void>? pendingPage;

  @override
  Future<HttpSourceMangaEntries> getMangaEntries(SourceQuery query) async {
    requests.add(query);
    final pending = query.page == 1 ? pendingFirstPage : pendingPage;
    if (pending != null) await pending;
    final manga = HttpSourceManga(url: '${query.page}', name: 'Example', cover: 'cover');
    return HttpSourceMangaEntries(mangas: [manga], nextQuery: query.page == 1 ? continuation : null);
  }
}

class _Errors extends Fake implements ErrorHandler {
  final shown = <Object>[];

  @override
  void show(Object error, [StackTrace? stackTrace]) => shown.add(error);
}
