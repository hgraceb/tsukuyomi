import 'package:tsukuyomi/database/database.dart';

/// 章节列表
@UseRowClass(DatabaseChapter)
class ChapterTable extends Table {
  @override
  String get tableName => 'chapter';

  /// 自增主键
  IntColumn get id => integer().autoIncrement()();

  /// 漫画 ID
  IntColumn get manga => integer().references(MangaTable, #id, onDelete: KeyAction.cascade)();

  /// 章节索引
  IntColumn get index => integer()();

  /// 章节标题
  TextColumn get title => text()();

  /// 章节地址
  TextColumn get url => text()();

  /// 章节日期
  TextColumn get date => text()();

  /// 是否公开
  BoolColumn get public => boolean()();

  /// 图片数量
  IntColumn get images => integer().withDefault(const Constant(0))();

  /// 阅读进度
  IntColumn get progress => integer().withDefault(const Constant(0))();
}
