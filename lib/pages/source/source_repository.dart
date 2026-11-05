import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';

part 'source_repository.g.dart';

class SourceRepository {
  const SourceRepository._(this.database);

  final TsukuyomiDatabase database;

  Future<DatabaseSource?> querySourceOrNull(int sourceId) {
    final query = database.select(database.sourceTable);
    query.where((row) => row.id.equals(sourceId));
    return query.getSingleOrNull();
  }

  Future<Map<int, String>> querySourceNames(Iterable<int> sourceIds) async {
    final table = database.sourceTable;
    final query = database.selectOnly(table);
    query.addColumns([table.id, table.name]);
    query.where(table.id.isIn(sourceIds));
    final rows = await query.get();
    return {for (final row in rows) row.read(table.id)!: row.read(table.name)!};
  }

  Stream<List<DatabaseSource>> watchSources() {
    return database.select(database.sourceTable).watch();
  }
}

@riverpod
SourceRepository sourceRepository(SourceRepositoryRef ref) {
  return SourceRepository._(ref.watch(databaseProvider));
}
