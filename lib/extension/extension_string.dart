extension StringExtension on String {
  /// 去除首尾空白字符并转换为合法的文件路径名
  String get toValidPath {
    // 去除首尾空白字符
    final trimmed = trim();
    // 将部分半角字符 "\"、"/"、":"、"*"、"?"、"""、"<"、">"、"|" 替换为全角字符
    // TODO 判断是否添加更多的半角字符规则，如：将"!"转换为"！"以保持文件夹命名统一，特别要注意半角空格的转换不能简单加 65248
    final validFullWidth = trimmed.replaceAllMapped(RegExp(r'[\\/:*?"<>|]'), (m) => String.fromCharCode(m[0]!.codeUnits[0] + 0xfee0));
    // 将末尾单独或连续的 "." 全部替换为 "․" (One Dot Leader U+2024) 并去除空格
    return validFullWidth.replaceAllMapped(RegExp(r'[. ]+$'), (m) => m[0]!.replaceAll('.', '\u2024').replaceAll(' ', ''));

    //                                                                                                                                    "\"

    //                                                                                                                                    "/"

    //                                                                                                                                    ":"
    //                                                                                                                                    "∶"

    //                                                                                                                                    "*"

    //                                                                                                                                    "?"

    //                                                                                                                                    """

    //                                                                                                                                    "<"

    //                                                                                                                                    ">"

    //                                                                                                                                    "|"

    //                                                                                                                                    "."
    //                                                                                                                                    "․"
  }
}
