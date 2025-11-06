import 'package:drift/drift.dart';
import 'package:tsukuyomi/database/database.dart';

/// 下载列表 TODO 添加章节和漫画的下载顺序
@UseRowClass(DatabaseDownload)
class DownloadTable extends Table {
  @override
  String get tableName => 'download';

  @override
  Set<Column> get primaryKey => {source, manga, chapter};

  /// 漫画源 ID
  IntColumn get source => integer()();

  /// 漫画 ID
  IntColumn get manga => integer().references(MangaTable, #id, onDelete: KeyAction.cascade)();

  /// 章节 ID
  IntColumn get chapter => integer().references(ChapterTable, #id, onDelete: KeyAction.cascade)();

  /// 图片总数
  IntColumn get total => integer().withDefault(const Constant(0))();

  /// 下载进度
  IntColumn get progress => integer().withDefault(const Constant(0))();

  /// 错误信息
  TextColumn get error => text().nullable()();
}
