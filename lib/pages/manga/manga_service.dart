import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/manga/manga_repository.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

part 'manga_service.g.dart';

class MangaService {
  MangaService._({required this.ref});

  final MangaServiceRef ref;

  Future<int> updateFavorite(int mangaId, bool favorite) {
    return ref.read(mangaRepositoryProvider).updateManga(MangaTableCompanion(id: Value(mangaId), favorite: Value(favorite)));
  }

  Future<int> insertSourceManga(int source, SourceManga manga) {
    return ref.read(mangaRepositoryProvider).upsertManga(manga.toInsertable(source));
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
