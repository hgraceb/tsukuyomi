import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/library/library_repository.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

part 'library_service.g.dart';

@riverpod
Stream<List<DatabaseManga>> favoriteMangasStream(FavoriteMangasStreamRef ref) {
  return ref.watch(libraryRepositoryProvider).watchFavoriteMangas();
}

@riverpod
Future<Map<Source, List<DatabaseManga>>> favoriteMangasGroupBySource(FavoriteMangasGroupBySourceRef ref) async {
  final mangas = await ref.watch(favoriteMangasStreamProvider.future);
  final result = <Source, List<DatabaseManga>>{};
  final sources = <int, Source>{};
  for (final manga in mangas) {
    final source = sources[manga.source] ??= await ref.read(sourceByIdProvider(manga.source).future);
    final mangas = result[source] ??= [];
    mangas.add(manga);
  }
  return result;
}
