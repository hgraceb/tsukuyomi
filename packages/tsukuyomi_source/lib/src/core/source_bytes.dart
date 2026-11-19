/// 漫画源字节数据
class SourceBytes {
  SourceBytes({
    required this.type,
    required this.data,
    this.extra,
  }) : assert(!type.startsWith('.'));

  /// 文件扩展名
  final String type;

  /// 字节数据
  final List<int> data;

  /// 额外数据
  final dynamic extra;
}
