import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/constants/constants.dart';

import 'connection/connection.dart';
import 'row/row.dart';
import 'table/table.dart';

export 'package:drift/drift.dart' hide Column, JsonKey;

export 'row/row.dart';
export 'table/table.dart';

part 'database.g.dart';

@DriftDatabase(tables: [SourceTable, MangaTable, ChapterTable, DownloadTable], include: {'sql/sql.drift'})
class TsukuyomiDatabase extends _$TsukuyomiDatabase {
  TsukuyomiDatabase._() : super(connect());

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
        await batch((batch) async {
          final mockDatabase = await getMockDatabase();
          batch.insertAllOnConflictUpdate(sourceTable, mockDatabase.sources);
          batch.insertAllOnConflictUpdate(mangaTable, mockDatabase.mangas);
        });
      },
    );
  }
}

@Riverpod(keepAlive: true)
TsukuyomiDatabase database(DatabaseRef ref) {
  final database = TsukuyomiDatabase._();
  ref.onDispose(database.close);
  return database;
}
