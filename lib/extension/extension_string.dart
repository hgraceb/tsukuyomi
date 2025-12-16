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
    //                                                                                                                                    "＼" U+FF3C Fullwidth Reverse Solidus
    //                                                                                                                                    "⧵" U+29F5 Reverse Solidus Operator
    //                                                                                                                                    "∖" U+2216 Set Minus
    //                                                                                                                                    "⟍" U+27CD Mathematical Falling Diagonal

    //                                                                                                                                    "/"
    //                                                                                                                                    "／" U+FF0F Fullwidth Solidus
    //                                                                                                                                    "⧸" U+29F8 Big Solidus
    //                                                                                                                                    "∕" U+2215 Division Slash
    //                                                                                                                                    "⁄" U+2044 Fraction Slash
    //                                                                                                                                    "⟋" U+27CB Mathematical Rising Diagonal

    //                                                                                                                                    ":"
    //                                                                                                                                    "：" U+FF1A Fullwidth Colon
    //                                                                                                                                    "꞉" U+A789 Modifier Letter Colon
    //                                                                                                                                    "∶" U+2236 Ratio
    //                                                                                                                                    "ː" U+02D0 Modifier Letter Triangular Colon

    //                                                                                                                                    "*"
    //                                                                                                                                    "＊" U+FF0A Fullwidth Asterisk
    //                                                                                                                                    "∗" U+2217 Asterisk Operator
    //                                                                                                                                    "✱" U+2731 Heavy Asterisk
    //                                                                                                                                    "⁎" U+204E Low Asterisk
    //                                                                                                                                    "٭" U+066D Arabic Five Pointed Star

    //                                                                                                                                    "?"
    //                                                                                                                                    "？" U+FF1F Fullwidth Question Mark

    //                                                                                                                                    """
    //                                                                                                                                    "＂" U+FF02 Fullwidth Quotation Mark
    //                                                                                                                                    "″" U+2033 Double Prime
    //                                                                                                                                    "ʺ" U+02BA Modifier Letter Double Prime
    //                                                                                                                                    "˝" U+02DD Double Acute Accent
    //                                                                                                                                    """ U+201C Left Double Quotation Mark

    //                                                                                                                                    "<"
    //                                                                                                                                    "＜" U+FF1C Fullwidth Less-Than Sign
    //                                                                                                                                    "‹" U+2039 Single Left-Pointing Angle Quotation Mark
    //                                                                                                                                    "˂" U+02C2 Modifier Letter Left Arrowhead
    //                                                                                                                                    "ᐸ" U+1438 Canadian Syllabics Pa
    //                                                                                                                                    "≺" U+227A Precedes

    //                                                                                                                                    ">"
    //                                                                                                                                    "＞" U+FF1E Fullwidth Greater-Than Sign
    //                                                                                                                                    "›" U+203A Single Right-Pointing Angle Quotation Mark
    //                                                                                                                                    "˃" U+02C3 Modifier Letter Right Arrowhead
    //                                                                                                                                    "ᐳ" U+1433 Canadian Syllabics Po
    //                                                                                                                                    "≻" U+227B Succeeds

    //                                                                                                                                    "|"
    //                                                                                                                                    "｜" U+FF5C Fullwidth Vertical Line
    //                                                                                                                                    "ǀ" U+01C0 Latin Letter Dental Click
    //                                                                                                                                    "│" U+2502 Box Drawings Light Vertical
    //                                                                                                                                    "∣" U+2223 Divides

    //                                                                                                                                    "."
    //                                                                                                                                    "․" U+2024 One Dot Leader
    //                                                                                                                                    "．" U+FF0E Fullwidth Full Stop
    //                                                                                                                                    "。" U+3002 Ideographic Full Stop
    //                                                                                                                                    "⋅" U+22C5 Dot Operator
  }
}
