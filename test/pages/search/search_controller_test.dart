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

  setUp(() async {
    source = _SearchSource();
    errors = _Errors();
    final container = ProviderContainer(
      overrides: [
        errorHandlerProvider.overrideWithValue(errors),
        keyboardVisibleProvider.overrideWithValue(false),
        sourcesStreamProvider.overrideWith((ref) => Stream.value([installed])),
        sourceByIdProvider(installed.id).overrideWith((ref) async => source),
      ],
    );
    addTearDown(container.dispose);
    subscription = container.listen(searchControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(searchControllerProvider.future);
    controller = container.read(searchControllerProvider.notifier);
  });

  Future<void> search(String keyword) async {
    current().textController.text = keyword;
    await controller.onTextChanged(keyword);
    await controller.onSearch();
  }

  test('Search follows the source continuation and appends results until the last page', () async {
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

  for (final fails in [false, true]) {
    test('Repeating a search ignores the previous pagination ${fails ? 'error' : 'result'}', () async {
      await search('example');
      final oldPage = Completer<void>();
      source.pendingPage = oldPage.future;
      final oldPagination = controller.onNext(source, current().results[installed.id]);
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
  _SearchSource() : super(1);

  final continuation = HttpSourceQuery(page: 7, keyword: 'example');
  final requests = <SourceQuery>[];
  Future<void>? pendingPage;

  @override
  Future<HttpSourceMangaEntries> getMangaEntries(SourceQuery query) async {
    requests.add(query);
    if (query.page != 1) await pendingPage;
    final manga = HttpSourceManga(url: '${query.page}', name: 'Example', cover: 'cover');
    return HttpSourceMangaEntries(mangas: [manga], nextQuery: query.page == 1 ? continuation : null);
  }
}

class _Errors extends Fake implements ErrorHandler {
  final shown = <Object>[];

  @override
  void show(Object error, [StackTrace? stackTrace]) => shown.add(error);
}
