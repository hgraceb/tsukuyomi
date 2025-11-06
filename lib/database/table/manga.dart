import 'package:tsukuyomi/database/database.dart';

/// 漫画列表
@UseRowClass(DatabaseManga)
class MangaTable extends Table {
  @override
  String get tableName => 'manga';

  /// 自增主键
  IntColumn get id => integer().autoIncrement()();

  /// 漫画源
  IntColumn get source => integer()();

  /// 漫画地址
  TextColumn get url => text()();

  /// 漫画标题
  TextColumn get title => text()();

  /// 漫画封面
  TextColumn get cover => text()();

  /// 是否收藏
  BoolColumn get favorite => boolean()();
}
