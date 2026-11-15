import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

import 'connection/connection.dart';
import 'converter/manga.dart';
import 'row/row.dart';
import 'table/table.dart';

export 'package:drift/drift.dart' hide Column, JsonKey;

export 'row/row.dart';
export 'table/table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [SourceTable, MangaTable, ChapterTable, DownloadTable], include: {'sql/sql.drift'})
class TsukuyomiDatabase extends _$TsukuyomiDatabase {
  TsukuyomiDatabase._() : super(connect());

  @visibleForTesting
  TsukuyomiDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');

        // TODO 删除默认测试数据
        // final migrator = createMigrator();
        // for (final table in allTables) {
        //   await migrator.deleteTable(table.actualTableName);
        //   await migrator.createTable(table);
        // }
        await seedDatabase(await getMockDatabase());
      },
    );
  }

  /// 导入索引数据
  ///
  /// 已有作品仅更新配置提供的内容字段，用户设置仅在首次插入时初始化
  Future<void> seedDatabase(MockDatabase data) {
    return batch((batch) {
      batch.insertAllOnConflictUpdate(sourceTable, data.sources);
      for (final manga in data.mangas) {
        batch.insert(
          mangaTable,
          manga,
          onConflict: DoUpdate(
            (_) => manga.copyWith(
              id: const Value.absent(),
              favorite: const Value.absent(),
              auto: const Value.absent(),
              lastCheckAt: const Value.absent(),
            ),
          ),
        );
      }
    });
  }
}

@Riverpod(keepAlive: true)
TsukuyomiDatabase database(DatabaseRef ref) {
  final database = TsukuyomiDatabase._();
  ref.onDispose(database.close);
  return database;
}
