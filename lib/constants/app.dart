import 'package:flutter/foundation.dart';

/// 应用常量
class App {
  /// 应用名称
  static const String name = 'Tsukuyomi' '${kDebugMode ? 'Debug' : ''}';

  /// 下载目录
  static const String downloadsPath = 'Downloads';

  /// 图片缓存目录
  static const String cachedImagesPath = '${name}CachedImages';

  /// 临时文件夹前缀
  static const String prefixTemp = '__temp__';
}
