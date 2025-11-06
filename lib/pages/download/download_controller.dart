import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/extension/extension.dart';
import 'package:tsukuyomi/pages/download/download_repository.dart';
import 'package:tsukuyomi/pages/download/download_service.dart';

part 'download_controller.freezed.dart';

part 'download_controller.g.dart';

/// 下载页面控制器
@riverpod
class DownloadController extends _$DownloadController with AsyncNotifierMixin {
  @override
  Future<DownloadState> build() async {
    final downloads = await listenAsync(
      provider: downloadsStreamProvider,
      update: (state, data) => state.copyWith(downloads: data),
    );
    return DownloadState(downloads: downloads);
  }

  Future<void> resumeDownload(DatabaseDownload download) async {
    try {
      await ref.read(downloadServiceProvider).resumeDownload(download);
    } catch (error, stackTrace) {
      handlerError(error, stackTrace);
    }
  }

  Future<void> deleteDownload(DatabaseDownload download) async {
    try {
      await ref.read(downloadServiceProvider).deleteDownload(download);
    } catch (error, stackTrace) {
      handlerError(error, stackTrace);
    }
  }
}

@freezed
class DownloadState with _$DownloadState {
  const factory DownloadState({
    required List<DownloadWithExtra> downloads,
  }) = _DownloadState;
}
