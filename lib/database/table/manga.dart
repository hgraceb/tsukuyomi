import 'package:tsukuyomi/database/converter/manga.dart';
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

  /// 连载状态
  TextColumn get status => text().map(const MangaStatusConverter()).withDefault(const Constant('unknown'))();

  /// 漫画简介
  TextColumn get description => text().withDefault(const Constant(''))();

  /// 创作者列表
  TextColumn get creators => text().map(const MangaCreatorsConverter()).withDefault(const Constant('[]'))();

  /// 标签列表
  TextColumn get tags => text().map(const MangaTagsConverter()).withDefault(const Constant('[]'))();

  /// 内容语言
  TextColumn get languages => text().map(const MangaLanguagesConverter()).withDefault(const Constant('[]'))();

  /// 是否收藏
  BoolColumn get favorite => boolean()();

  /// 是否自动下载
  BoolColumn get auto => boolean().withDefault(const Constant(false))();

  /// 上次检查时间
  DateTimeColumn get lastCheckAt => dateTime().nullable()();
}
