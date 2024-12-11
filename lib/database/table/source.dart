import 'package:drift/drift.dart';
import 'package:tsukuyomi/database/database.dart';

/// 漫画源
@UseRowClass(DatabaseSource)
class SourceTable extends Table {
  @override
  String get tableName => 'source';

  @override
  Set<Column> get primaryKey => {id};

  /// 漫画源标识
  IntColumn get id => integer()();

  /// 漫画源名称
  TextColumn get name => text()();

  /// 漫画源代码
  TextColumn get source => text()();
}
