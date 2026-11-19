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

  /// 创建字节数据副本
  SourceBytes copyWith({String? type, List<int>? data, dynamic extra}) {
    return SourceBytes(type: type ?? this.type, data: data ?? this.data, extra: extra ?? this.extra);
  }
}
