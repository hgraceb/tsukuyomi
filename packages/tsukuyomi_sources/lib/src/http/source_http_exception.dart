import 'package:dio/dio.dart' show DioException;

/// 网络漫画源错误 TODO 捕获网络错误并转化为更通用的网络错误类型
typedef HttpSourceException = DioException;
