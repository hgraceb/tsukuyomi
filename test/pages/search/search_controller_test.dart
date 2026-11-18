import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/database/database.dart' show DatabaseSource;
import 'package:tsukuyomi/pages/search/search_controller.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/providers/platform/platform_metadata_provider.dart';
import 'package:tsukuyomi/source/source.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const installed = DatabaseSource(id: 1, name: 'Example', source: '');
  late _SearchSource source;
  late ProviderContainer container;
  late SearchController controller;

  setUp(() async {
    source = _SearchSource();
    container = ProviderContainer(overrides: [
      keyboardVisibleProvider.overrideWithValue(false),
      sourcesStreamProvider.overrideWith((ref) => Stream.value([installed])),
      sourceByIdProvider(installed.id).overrideWith((ref) async => source),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(searchControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(searchControllerProvider.future);
    controller = container.read(searchControllerProvider.notifier);
  });

  Future<void> search(String keyword) async {
    container.read(searchControllerProvider).requireValue.textController.text = keyword;
    await controller.onTextChanged(keyword);
    await controller.onSearch();
  }

  SearchResult result() => container.read(searchControllerProvider).requireValue.results[installed.id]!;

  test('Search follows the source continuation and appends results until the last page', () async {
    await search('example');
    expect(result().mangas.map((manga) => manga.url), ['1']);
    expect(result().nextQuery, same(source.continuation));

    await Future.wait([controller.onNext(source), controller.onNext(source)]);
    expect(source.requests.last, same(source.continuation));
    expect(result().mangas.map((manga) => manga.url), ['1', '7']);
    expect(result().nextQuery, isNull);

    await controller.onNext(source);
    expect(source.requests.map((query) => query.page), [1, 7]);
  });

  test('A pending page from the previous search leaves the new results intact', () async {
    await search('first');
    source.nextPage = Completer<void>();
    final pending = controller.onNext(source);
    await search('second');
    final current = result();
    source.nextPage!.complete();
    await pending;

    expect(source.requests.map((query) => query.page), [1, 7, 1]);
    expect(result().mangas, same(current.mangas));
    expect(result().nextQuery, same(source.continuation));
  });
}

class _SearchSource extends NoInstalledSource {
  _SearchSource() : super(1);

  final continuation = HttpSourceQuery(page: 7, keyword: 'example');
  final requests = <SourceQuery>[];
  Completer<void>? nextPage;

  @override
  Future<HttpSourceMangaEntries> getMangaEntries(SourceQuery query) async {
    requests.add(query);
    if (query.page == 7) await nextPage?.future;
    final manga = HttpSourceManga(url: '${query.page}', name: 'Example', cover: 'cover');
    return HttpSourceMangaEntries(mangas: [manga], nextQuery: query.page == 1 ? continuation : null);
  }
}
