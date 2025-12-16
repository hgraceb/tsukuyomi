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

    // "\"、"/"、":"、"*"、"?"、"""、"<"、">"、"|"、"."
    // "⧹"、"⧸"、"∶"、"∗"、"？"、"″"、"˂"、"˃"、"∣"、"․"

    // \\\\\ ⧵⧵⧵⧵⧵ ⧹⧹⧹⧹⧹ ＼＼＼＼＼ ∖∖∖∖∖ ⟍⟍⟍⟍⟍ ⑊⑊⑊⑊⑊

    // ///// ⧸⧸⧸⧸⧸ ／／／／／ ∕∕∕∕∕ ⁄⁄⁄⁄⁄ ⟋⟋⟋⟋⟋ ⳆⳆⳆⳆⳆ ノノノノノ

    // ::::: ꞉꞉꞉꞉꞉ ∶∶∶∶∶ ：：：：： ːːːːː ꓽꓽꓽꓽꓽ ︓︓︓︓︓

    // ***** ⁎⁎⁎⁎⁎ ∗∗∗∗∗ ＊＊＊＊＊ ✱✱✱✱✱ ⋆⋆⋆⋆⋆ ✳✳✳✳✳ ﹡﹡﹡﹡﹡

    // ????? ？？？？？ ʔʔʔʔʔ ɁɁɁɁɁ ॽॽॽॽॽ ꛫꛫꛫꛫꛫ ﹖﹖﹖﹖﹖

    // """"" ″″″″″ ＂＂＂＂＂ ʺʺʺʺʺ ˝˝˝˝˝ ˮˮˮˮˮ ‟‟‟‟‟ ❝❝❝❝❝

    // <<<<< ˂˂˂˂˂ ＜＜＜＜＜ ‹‹‹‹‹ ᐸᐸᐸᐸᐸ ≺≺≺≺≺ ❮❮❮❮❮ ⟨⟨⟨⟨⟨ 〈〈〈〈〈

    // >>>>> ˃˃˃˃˃ ＞＞＞＞＞ ››››› ᐳᐳᐳᐳᐳ ≻≻≻≻≻ ❯❯❯❯❯ ⟩⟩⟩⟩⟩ 〉〉〉〉〉

    // ||||| ǀǀǀǀǀ ∣∣∣∣∣ ｜｜｜｜｜ │││││ ⵏⵏⵏⵏⵏ ᛁᛁᛁᛁᛁ ︱︱︱︱︱

    // ..... ․․․․․ ．．．．． 。。。。。 ⋅⋅⋅⋅⋅ ・・・・・ ••••• ‧‧‧‧‧

    //                                                                                                                                    "\"
    //                                                                                                                                    "⧵" U+29F5 Reverse Solidus Operator
    //                                                                                                                                    "⧹" U+29F9 Big Reverse Solidus
    //                                                                                                                                    "＼" U+FF3C Fullwidth Reverse Solidus
    //                                                                                                                                    "∖" U+2216 Set Minus
    //                                                                                                                                    "⟍" U+27CD Mathematical Falling Diagonal
    //                                                                                                                                    "⑊" U+244A OCR Double Backslash

    //                                                                                                                                    "/"
    //                                                                                                                                    "⧸" U+29F8 Big Solidus
    //                                                                                                                                    "／" U+FF0F Fullwidth Solidus
    //                                                                                                                                    "∕" U+2215 Division Slash
    //                                                                                                                                    "⁄" U+2044 Fraction Slash
    //                                                                                                                                    "⟋" U+27CB Mathematical Rising Diagonal
    //                                                                                                                                    "Ⳇ" U+2CC6 Coptic Capital Letter Old Coptic Esh
    //                                                                                                                                    "ノ" U+30CE Katakana Letter No

    //                                                                                                                                    ":"
    //                                                                                                                                    "꞉" U+A789 Modifier Letter Colon
    //                                                                                                                                    "∶" U+2236 Ratio
    //                                                                                                                                    "：" U+FF1A Fullwidth Colon
    //                                                                                                                                    "ː" U+02D0 Modifier Letter Triangular Colon
    //                                                                                                                                    "ꓽ" U+A4FD Lisu Letter Tone Mya Jeu
    //                                                                                                                                    "︓" U+FE13 Presentation Form For Vertical Colon

    //                                                                                                                                    "*"
    //                                                                                                                                    "⁎" U+204E Low Asterisk
    //                                                                                                                                    "∗" U+2217 Asterisk Operator
    //                                                                                                                                    "＊" U+FF0A Fullwidth Asterisk
    //                                                                                                                                    "✱" U+2731 Heavy Asterisk
    //                                                                                                                                    "⋆" U+22C6 Star Operator
    //                                                                                                                                    "✳" U+2733 Eight Spoked Asterisk
    //                                                                                                                                    "﹡" U+FE61 Small Asterisk

    //                                                                                                                                    "?"
    //                                                                                                                                    "？" U+FF1F Fullwidth Question Mark
    //                                                                                                                                    "ʔ" U+0294 Latin Letter Glottal Stop
    //                                                                                                                                    "Ɂ" U+0241 Latin Capital Letter Glottal Stop
    //                                                                                                                                    "ॽ" U+097D Devanagari Letter Glottal Stop
    //                                                                                                                                    "ꛫ" U+A6EB Bamum Letter Ntuu
    //                                                                                                                                    "﹖" U+FE56 Small Question Mark

    //                                                                                                                                    """
    //                                                                                                                                    "″" U+2033 Double Prime
    //                                                                                                                                    "＂" U+FF02 Fullwidth Quotation Mark
    //                                                                                                                                    "ʺ" U+02BA Modifier Letter Double Prime
    //                                                                                                                                    "˝" U+02DD Double Acute Accent
    //                                                                                                                                    "ˮ" U+02EE Modifier Letter Double Apostrophe
    //                                                                                                                                    "‟" U+201F Double High-Reversed-9 Quotation Mark
    //                                                                                                                                    "❝" U+275D Heavy Double Turned Comma Quotation Mark Ornament

    //                                                                                                                                    "<"
    //                                                                                                                                    "˂" U+02C2 Modifier Letter Left Arrowhead
    //                                                                                                                                    "＜" U+FF1C Fullwidth Less-Than Sign
    //                                                                                                                                    "‹" U+2039 Single Left-Pointing Angle Quotation Mark
    //                                                                                                                                    "ᐸ" U+1438 Canadian Syllabics Pa
    //                                                                                                                                    "≺" U+227A Precedes
    //                                                                                                                                    "❮" U+276E Heavy Left-Pointing Angle Quotation Mark Ornament
    //                                                                                                                                    "⟨" U+27E8 Mathematical Left Angle Bracket
    //                                                                                                                                    "〈" U+2329 Left-Pointing Angle Bracket

    //                                                                                                                                    ">"
    //                                                                                                                                    "˃" U+02C3 Modifier Letter Right Arrowhead
    //                                                                                                                                    "＞" U+FF1E Fullwidth Greater-Than Sign
    //                                                                                                                                    "›" U+203A Single Right-Pointing Angle Quotation Mark
    //                                                                                                                                    "ᐳ" U+1433 Canadian Syllabics Po
    //                                                                                                                                    "≻" U+227B Succeeds
    //                                                                                                                                    "❯" U+276F Heavy Right-Pointing Angle Quotation Mark Ornament
    //                                                                                                                                    "⟩" U+27E9 Mathematical Right Angle Bracket
    //                                                                                                                                    "〉" U+232A Right-Pointing Angle Bracket

    //                                                                                                                                    "|"
    //                                                                                                                                    "ǀ" U+01C0 Latin Letter Dental Click
    //                                                                                                                                    "∣" U+2223 Divides
    //                                                                                                                                    "｜" U+FF5C Fullwidth Vertical Line
    //                                                                                                                                    "│" U+2502 Box Drawings Light Vertical
    //                                                                                                                                    "ⵏ" U+2D4F Tifinagh Letter Yan
    //                                                                                                                                    "ᛁ" U+16C1 Runic Letter Isaz Is Iss I
    //                                                                                                                                    "︱" U+FE31 Presentation Form For Vertical Em Dash

    //                                                                                                                                    "."
    //                                                                                                                                    "․" U+2024 One Dot Leader
    //                                                                                                                                    "．" U+FF0E Fullwidth Full Stop
    //                                                                                                                                    "。" U+3002 Ideographic Full Stop
    //                                                                                                                                    "⋅" U+22C5 Dot Operator
    //                                                                                                                                    "・" U+30FB Katakana Middle Dot
    //                                                                                                                                    "•" U+2022 Bullet
    //                                                                                                                                    "‧" U+2027 Hyphenation Point
  }
}
