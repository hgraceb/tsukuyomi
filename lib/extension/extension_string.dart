extension StringExtension on String {
  /// 替换文件命名中不能使用的首尾空白字符、部分半角字符（“\”、“/”、“:”、“*”、“?”、“"”、“<”、“>”、“|”）
  /// TODO 添加更多的半角字符规则，如：将 “!” 转换为 “！”，保持文件夹命名统一，特别要注意半角空格的转换不能简单加 65248
  String get toLegalPath {
    assert(trim().isNotEmpty);
    // 去除首尾空白字符并将部分半角字符替换为全角字符
    return trim().replaceAllMapped(RegExp(r'[\\/:*?"<>|]'), (match) => String.fromCharCode(match[0]!.codeUnits[0] + 0xfee0));
  }
}
