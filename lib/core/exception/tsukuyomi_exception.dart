import 'package:freezed_annotation/freezed_annotation.dart';

part 'tsukuyomi_exception.freezed.dart';

sealed class TsukuyomiException {}

/// 漫画源错误
@freezed
class TsukuyomiSourceException with _$TsukuyomiSourceException implements TsukuyomiException {
  /// 漫画源未安装
  const factory TsukuyomiSourceException.notInstalled(int id) = SourceNotInstalled;

  /// 漫画列表为空
  const factory TsukuyomiSourceException.mangasNotFound(String type) = SourceMangasNotFound;
}

/// 下载错误
@freezed
class TsukuyomiDownloadException with _$TsukuyomiDownloadException implements TsukuyomiException {
  /// 数据库操作失败
  const factory TsukuyomiDownloadException.databaseError(String operator) = DownloadDatabaseError;

  /// 下载图片未找到
  const factory TsukuyomiDownloadException.imagesNotFound(String chapter) = DownloadImagesNotFound;

  /// 下载路径已存在
  const factory TsukuyomiDownloadException.pathAlreadyExists(String path) = DownloadPathAlreadyExists;

  /// 下载任务已取消
  const factory TsukuyomiDownloadException.canceled() = DownloadCanceled;
}
