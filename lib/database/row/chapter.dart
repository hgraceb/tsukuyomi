import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/extension/extension_string.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

part 'chapter.freezed.dart';

@freezed
class DatabaseChapter with _$DatabaseChapter, $ChapterTableTableToColumns {
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
  ChapterTableCompanion toUpdatable(int chapterId) {
    return ChapterTableCompanion(
      id: Value(chapterId),
      title: Value(name.toValidDirectoryName),
      date: Value(date),
      public: Value(public),
    );
  }

  ChapterTableCompanion toInsertable(int manga, {required int index}) {
    // TODO 完善章节数据
    return ChapterTableCompanion.insert(
      manga: manga,
      index: index,
      title: name.toValidDirectoryName,
      url: url,
      date: date,
      public: public,
    );
  }
}
