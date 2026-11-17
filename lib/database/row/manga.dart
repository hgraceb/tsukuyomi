import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/extension/extension_string.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

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
    required bool auto,
    required DateTime? lastCheckAt,
    @Default(SourceMangaStatus.unknown) SourceMangaStatus status,
    @Default('') String description,
    @Default([]) List<SourceMangaAuthor> authors,
    @Default([]) List<SourceMangaTag> tags,
    @Default([]) List<String> languages,
  }) = _DatabaseManga;

  // TODO 判断是否可以做通用处理直接返回不同类型的 SourceManga
  HttpSourceManga toHttpSourceManga() {
    return HttpSourceManga(
      url: url,
      name: title,
      cover: cover,
      status: status,
      description: description,
      authors: authors,
      tags: tags,
      languages: languages,
    );
  }
}

extension SourceMangaExtension on SourceManga {
  MangaTableCompanion toUpdatable(int mangaId) {
    return _toCompanion().copyWith(id: Value(mangaId));
  }

  MangaTableCompanion toInsertable(int source) {
    return _toCompanion().copyWith(source: Value(source));
  }

  MangaTableCompanion _toCompanion() {
    return MangaTableCompanion(
      url: Value(url),
      title: Value(name.toValidDirectoryName),
      cover: Value(cover),
      status: Value.absentIfNull(status),
      description: Value.absentIfNull(description),
      authors: Value.absentIfNull(authors),
      tags: Value.absentIfNull(tags),
      languages: Value.absentIfNull(languages),
    );
  }
}
