import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/extension/extension.dart';
import 'package:tsukuyomi/pages/library/library_service.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

part 'library_controller.freezed.dart';

part 'library_controller.g.dart';

/// 书架页面控制器
@riverpod
class LibraryController extends _$LibraryController with AsyncNotifierMixin {
  @override
  Future<LibraryState> build() async {
    final mangas = await listenAsync(
      provider: favoriteMangasGroupBySourceProvider,
      update: (state, data) => state.copyWith(mangas: data),
    );
    return LibraryState(mangas: mangas);
  }
}

/// 书架页面配置
@freezed
class LibraryState with _$LibraryState {
  const factory LibraryState({
    /// 漫画列表
    required Map<Source, List<DatabaseManga>> mangas,
  }) = _LibraryState;
}
