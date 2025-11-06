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

  Stream<List<DatabaseSource>> watchSources() {
    return database.select(database.sourceTable).watch();
  }
}

@riverpod
SourceRepository sourceRepository(SourceRepositoryRef ref) {
  return SourceRepository._(ref.watch(databaseProvider));
}
