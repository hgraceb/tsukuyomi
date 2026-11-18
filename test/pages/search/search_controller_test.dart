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

  test('Search follows the source continuation and appends results until the last page', () async {
    final source = _SearchSource();
    const installed = DatabaseSource(id: 1, name: 'Example', source: '');
    final container = ProviderContainer(overrides: [
      keyboardVisibleProvider.overrideWithValue(false),
      sourcesStreamProvider.overrideWith((ref) => Stream.value([installed])),
      sourceByIdProvider(installed.id).overrideWith((ref) async => source),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(searchControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    final state = await container.read(searchControllerProvider.future);
    final controller = container.read(searchControllerProvider.notifier);
    state.textController.text = 'example';
    await controller.onTextChanged('example');
    await controller.onSearch();

    final first = subscription.read().requireValue.results[installed.id]!;
    expect(first.mangas.map((manga) => manga.url), ['1']);
    expect(first.nextQuery, same(source.continuation));

    await controller.onNext(source);
    final last = subscription.read().requireValue.results[installed.id]!;
    expect(source.requests.last, same(source.continuation));
    expect(last.mangas.map((manga) => manga.url), ['1', '7']);
    expect(last.nextQuery, isNull);

    await controller.onNext(source);
    expect(source.requests.map((query) => query.page), [1, 7]);
  });
}

class _SearchSource extends NoInstalledSource {
  _SearchSource() : super(1);

  final continuation = HttpSourceQuery(page: 7, keyword: 'example');
  final requests = <SourceQuery>[];

  @override
  Future<HttpSourceMangaEntries> getMangaEntries(SourceQuery query) async {
    requests.add(query);
    final manga = HttpSourceManga(url: '${query.page}', name: 'Example', cover: 'cover');
    return HttpSourceMangaEntries(mangas: [manga], nextQuery: query.page == 1 ? continuation : null);
  }
}
