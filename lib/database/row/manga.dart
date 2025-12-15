import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/extension/extension_string.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

part 'manga.freezed.dart';

@freezed
class DatabaseManga with _$DatabaseManga, $MangaTableTableToColumns {
  const DatabaseManga._();

  const factory DatabaseManga({
    required int id,
    required int source,
    required String url,
    required String title,
    required String cover,
    required bool favorite,
  }) = _DatabaseManga;

  MangaTableCompanion toUpdatable() {
    return MangaTableCompanion.insert(
      id: Value(id),
      source: source,
      url: url,
      title: title,
      cover: cover,
      favorite: favorite,
    );
  }

  // TODO 判断是否可以做通用处理直接返回不同类型的 SourceManga
  HttpSourceManga toHttpSourceManga() {
    return HttpSourceManga(
      url: url,
      name: title,
      cover: cover,
    );
  }
}

extension SourceMangaExtension on SourceManga {
  MangaTableCompanion toUpdatable(DatabaseManga manga) {
    return MangaTableCompanion.insert(
      id: Value(manga.id),
      source: manga.source,
      url: url,
      title: name.toValidPath,
      cover: cover,
      favorite: manga.favorite,
    );
  }

  MangaTableCompanion toInsertable(int source) {
    return MangaTableCompanion.insert(
      source: source,
      url: url,
      title: name.toValidPath,
      cover: cover,
      favorite: false,
    );
  }
}
