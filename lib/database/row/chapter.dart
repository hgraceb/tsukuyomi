import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/extension/extension_string.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

part 'chapter.freezed.dart';

@freezed
class DatabaseChapter with _$DatabaseChapter, ChapterTableToColumns {
  const DatabaseChapter._();

  const factory DatabaseChapter({
    required int id,
    required int manga,
    required int index,
    required String title,
    required String url,
    required String date,
    required bool public,
    required int images,
    required int progress,
  }) = _DatabaseChapter;
}

extension DatabaseChapterExtension on DatabaseChapter {
  ChapterTableCompanion toUpdatable() {
    return ChapterTableCompanion.insert(
      id: Value(id),
      manga: manga,
      index: index,
      title: title,
      url: url,
      date: date,
      public: public,
      images: Value(images),
      progress: Value(progress),
    );
  }

  // TODO 判断是否可以做通用处理直接返回不同类型的 SourceChapter
  HttpSourceChapter toHttpSourceChapter() {
    return HttpSourceChapter(
      url: url,
      name: title,
      date: date,
      public: public,
    );
  }

  DownloadTableCompanion toDownloadable(int source) {
    // TODO 完善章节数据
    return DownloadTableCompanion.insert(
      source: source,
      manga: manga,
      chapter: id,
    );
  }
}

extension SourceChapterExtension on SourceChapter {
  ChapterTableCompanion toUpdatable(DatabaseChapter chapter) {
    return ChapterTableCompanion.insert(
      id: Value(chapter.id),
      manga: chapter.manga,
      index: chapter.index,
      title: name.toLegalPath,
      url: url,
      date: date,
      public: public,
      images: Value(chapter.images),
      progress: Value(chapter.progress),
    );
  }

  ChapterTableCompanion toInsertable(int manga) {
    // TODO 完善章节数据
    return ChapterTableCompanion.insert(
      manga: manga,
      index: 0,
      title: name.toLegalPath,
      url: url,
      date: date,
      public: public,
    );
  }
}
