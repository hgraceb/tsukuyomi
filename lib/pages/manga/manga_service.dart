import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/manga/manga_repository.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

part 'manga_service.g.dart';

class MangaService {
  MangaService._({required this.ref});

  final MangaServiceRef ref;

  Future<int> updateManga(DatabaseManga manga) {
    return ref.read(mangaRepositoryProvider).updateManga(manga.toUpdatable());
  }

  Future<int> insertSourceManga(int source, SourceManga manga) async {
    final repository = ref.read(mangaRepositoryProvider);
    final result = await repository.queryMangaOrNull(source, manga.url);
    if (result == null) {
      return repository.insertManga(manga.toInsertable(source));
    } else {
      return repository.updateManga(manga.toUpdatable(result));
    }
  }
}

@riverpod
MangaService mangaService(MangaServiceRef ref) {
  return MangaService._(ref: ref);
}

@riverpod
Stream<DatabaseManga> mangaStreamById(MangaStreamByIdRef ref, int mangaId) {
  return ref.watch(mangaRepositoryProvider).watchManga(mangaId);
}

@riverpod
Stream<List<DatabaseChapter>> chaptersStreamByManga(ChaptersStreamByMangaRef ref, int mangaId) {
  return ref.watch(mangaRepositoryProvider).watchChapters(mangaId);
}
