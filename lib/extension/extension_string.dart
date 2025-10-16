extension StringExtension on String {
  /// 去除首尾空白字符并将部分半角字符替换为全角字符（“\”、“/”、“:”、“*”、“?”、“"”、“<”、“>”、“|”）
  /// TODO 判断是否添加更多的半角字符规则，如：将“!”转换为“！”以保持文件夹命名统一，特别要注意半角空格的转换不能简单加 65248
  String get toLegalPath {
    assert(trim().isNotEmpty);
    return trim().replaceAllMapped(RegExp(r'[\\/:*?"<>|]'), (match) => String.fromCharCode(match[0]!.codeUnits[0] + 0xfee0));
  }
}
