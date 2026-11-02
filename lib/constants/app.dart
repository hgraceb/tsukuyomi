import 'package:flutter/foundation.dart';

/// 应用常量
abstract class App {
  /// 应用名称
  static const String name = 'Tsukuyomi${kDebugMode ? 'Debug' : ''}';

  /// 下载目录
  static const String downloadsPath = 'Downloads';

  /// 图片缓存目录
  static const String cachedImagesPath = '${name}CachedImages';

  /// 临时文件夹前缀
  static const String prefixTemp = '__temp__';
}

/// 偏好键名
abstract class Keys {
  /// 调试环境前缀
  static const String _prefix = kDebugMode ? 'debug.' : '';

  /// 全局主题模式
  static const String themeMode = '${_prefix}theme.mode';

  /// 最近更新报告
  static const String updateReportLatest = '${_prefix}update.report.latest';

  /// 漫画源本地存储
  static String sourceStorage(int id) => '${_prefix}source.storage.$id';
}
