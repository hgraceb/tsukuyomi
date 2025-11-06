import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tsukuyomi/database/database.dart';

part 'source.freezed.dart';

@freezed
class DatabaseSource with _$DatabaseSource, SourceTableToColumns {
  const DatabaseSource._();

  const factory DatabaseSource({
    required int id,
    required String name,
    required String source,
  }) = _DatabaseSource;
}
